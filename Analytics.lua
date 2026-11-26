-- ForeverTrading: indicators and signals.
local ADDON, FT = ...
local L = FT.L

local An = {}
FT.An = An

---------------------------------------------------------------------------
-- Indicators over a list of numbers (oldest first)
---------------------------------------------------------------------------
-- partial: the first values (fewer than n so far) get the average of what there is
function An.SMA(values, n, partial)
    local out, sum = {}, 0
    for i = 1, #values do
        sum = sum + values[i]
        if i > n then sum = sum - values[i - n] end
        if i >= n then
            out[i] = sum / n
        elseif partial then
            out[i] = sum / i
        end
    end
    return out
end

function An.EMA(values, n)
    local out, k, prev = {}, 2 / (n + 1), nil
    for i = 1, #values do
        if prev == nil then
            prev = values[i]
        else
            prev = values[i] * k + prev * (1 - k)
        end
        if i >= math.min(n, #values) then out[i] = prev end
    end
    return out
end

-- Wilder's RSI of the last value (nil with too little data)
function An.RSI(values, n)
    n = n or 14
    if #values < 3 then return nil end
    n = math.min(n, #values - 1)
    local gain, loss = 0, 0
    for i = 2, n + 1 do
        local d = values[i] - values[i - 1]
        if d > 0 then gain = gain + d else loss = loss - d end
    end
    gain, loss = gain / n, loss / n
    for i = n + 2, #values do
        local d = values[i] - values[i - 1]
        gain = (gain * (n - 1) + math.max(d, 0)) / n
        loss = (loss * (n - 1) + math.max(-d, 0)) / n
    end
    if loss == 0 then return gain == 0 and 50 or 100 end
    local rs = gain / loss
    return 100 - 100 / (1 + rs)
end

function An.Mean(values, from, to)
    from, to = from or 1, to or #values
    local sum, n = 0, 0
    for i = math.max(1, from), math.min(#values, to) do
        sum, n = sum + values[i], n + 1
    end
    return n > 0 and sum / n or nil
end

-- standard deviation of day-to-day changes
function An.Volatility(values)
    if #values < 3 then return nil end
    local r = {}
    for i = 2, #values do
        if values[i - 1] > 0 then r[#r + 1] = values[i] / values[i - 1] - 1 end
    end
    local m = An.Mean(r)
    if not m then return nil end
    local s = 0
    for _, x in ipairs(r) do s = s + (x - m) ^ 2 end
    return math.sqrt(s / #r)
end

---------------------------------------------------------------------------
-- Everything about one item, cached until prices change
---------------------------------------------------------------------------
local cache = {}
-- per auction house (an item window may look at the other one for a moment)
local caches, cacheKey = {}, nil
local function UseCache()
    local key = FT.houseKey or "?"
    if key == cacheKey then return end
    if cacheKey then caches[cacheKey] = cache end
    cache = caches[key] or {}
    cacheKey = key
end
-- new prices: the items they are of are counted again (all of them after a whole market came in)
local function Forget()
    local set, _, all = FT.Hist.TakeChanged("stats")
    if all then
        wipe(cache)
        return
    end
    for id in pairs(set) do cache[id] = nil end
end
local STATS_FRESH = 600 -- seconds: counted again after this anyway (the fair price weighs prices by their age)
FT.On("FT_PRICES_CHANGED", Forget)
FT.On("FT_SCAN_DONE", Forget)
FT.On("FT_HOUSE_CHANGED", function()
    UseCache()
    wipe(cache)
end)
FT.On("FT_HOUSE_USE", UseCache)
FT.On("FT_LIVE_UPDATED", function(itemID) if itemID then cache[itemID] = nil end end)
FT.On("FT_SETTINGS_CHANGED", function() wipe(cache) end)

local function CloseAtOrBefore(daily, day)
    for i = #daily, 1, -1 do
        if daily[i].day <= day then return daily[i].c end
    end
    return nil
end

local function Change(now, ref)
    if not now or not ref or ref <= 0 then return nil end
    return now / ref - 1
end

-- the first close from day `from` to day `to`
local function FirstCloseIn(daily, from, to)
    for _, c in ipairs(daily) do
        if c.day >= from and c.day <= to then return c.c end
    end
    return nil
end

-- How long the market of this auction house has been watched (days with a whole-market scan, of the last `window`):
-- while it is little (a new auction house, Auctionator off: our own scans only) fewer days of prices are asked for.
local function Watched(window)
    return FT.Hist.WatchedDays(window)
end

---------------------------------------------------------------------------
-- The fair price right now: what the market stood at lately, so a sudden jump (someone bought out the cheap
-- lots and listed them three times higher) or a sudden fall (other crafters undercutting) shows against it.
-- The median of the prices of the last days up to an hour ago, each weighted by how many were listed at it,
-- how long it stood (not how often it was looked at) and how recent it is (half the weight a day): the hour
-- that just went by doesn't move it, a new level the market keeps for hours does.
---------------------------------------------------------------------------
local HALF_LIFE = 24 * 3600
local LOOK_BACK = 4 * 86400
local SETTLED = 3600
local MAX_SPAN = 3 * 3600
local DROP = 0.10      -- a price this much lower than at the last check: risky
local FLOOD_MIN = 3    -- flooded: at least this many more listed than usual too (2 instead of 1 is no flood)
local CROWD_MIN = 2    -- more sellers: at least this many more than usual too
local SLOW_HOURS = 12  -- "hardly bought" needs at least this many hours watched

-- fair price, and what is usual (the same weights): how many listed, in how many auctions, by how many sellers
-- (nil: no prices from before the last hour; the usual auctions and sellers: nil while none were counted)
function An.FairNow(itemID)
    local now = time()
    local cutoff = now - SETTLED
    local obs = {}
    local function Add(p, q, t, span, n, sl)
        if p and p > 0 and t and t <= cutoff and now - t <= LOOK_BACK then
            obs[#obs + 1] = { p = p, q = q, t = t, span = span, n = n, sl = sl }
        end
    end
    local s = FT.Hist.Snaps(itemID)
    local firstSnap = s and s.t[1]
    -- the days before today: their closing price stood about half a day (where intraday prices don't cover it)
    local today = FT.Day()
    for _, c in ipairs(FT.Hist.Daily(itemID, 5)) do
        if c.day < today then
            local t = c.t + 43200
            if not firstSnap or t < firstSnap then Add(c.c, c.v, t, 12 * 3600, c.n, nil) end
        end
    end
    if s then
        for i = 1, #s.t do Add(s.p[i], s.q[i], s.t[i], nil, s.n[i], s.sl and s.sl[i]) end
    else
        -- not every price of it is kept (it doesn't matter to you): today's count too - its newest price and the one
        -- before it, once they are an hour old (not only the closes of the days before)
        local p, t, _, q, gone = FT.Price(itemID)
        if p and t and not gone and FT.Day(t) == today then Add(p, q, t, nil, nil, nil) end
        local prev = FT.Hist.Previous(itemID)
        if prev and prev.t ~= t and FT.Day(prev.t) == today then Add(prev.p, prev.q, prev.t, nil, prev.n, prev.sl) end
    end
    if #obs == 0 then return nil end
    table.sort(obs, function(a, b) return a.t < b.t end)
    -- an intraday price stood until the next one (at most 3 hours: a long silence says nothing)
    for i, o in ipairs(obs) do
        if not o.span then
            local nextT = obs[i + 1] and obs[i + 1].t or cutoff
            o.span = math.max(600, math.min(nextT - o.t, MAX_SPAN))
        end
    end
    local qs = {}
    for _, o in ipairs(obs) do
        if o.q and o.q > 0 then qs[#qs + 1] = o.q end
    end
    table.sort(qs)
    local qMid = #qs > 0 and qs[math.ceil(#qs / 2)] or 1
    local total, sumQ, sumR = 0, 0, 0
    local sumN, rN, sumS, rS = 0, 0, 0, 0
    for _, o in ipairs(obs) do
        local r = 0.5 ^ ((now - o.t) / HALF_LIFE) * o.span
        local q = (o.q and o.q > 0) and o.q or qMid
        o.w = q * r
        total = total + o.w
        sumQ, sumR = sumQ + q * r, sumR + r
        if o.n and o.n > 0 then sumN, rN = sumN + o.n * r, rN + r end
        if o.sl and o.sl > 0 then sumS, rS = sumS + o.sl * r, rS + r end
    end
    local typicalN = rN > 0 and sumN / rN or nil
    local typicalS = rS > 0 and sumS / rS or nil
    table.sort(obs, function(a, b) return a.p < b.p end)
    local acc, fair = 0, obs[#obs].p
    for _, o in ipairs(obs) do
        acc = acc + o.w
        if acc >= total / 2 then
            fair = o.p
            break
        end
    end
    return fair, sumR > 0 and sumQ / sumR or nil, typicalN, typicalS
end

-- far above the fair price: a buyout (or a shortage) - not to be counted on for long (Settings: by how much)
local function Spike(s)
    if FT.S.spikeGuard == false or not (s.price and s.fair) then return false end
    return s.price > s.fair * (1 + (FT.S.spikeAbove or 50) / 100)
end

-- far below the fair price: falling fast - others undercut (Settings: by how much)
local function Falling(s)
    if not (s.price and s.fair) then return false end
    return s.price < s.fair * (1 - (FT.S.fallBelow or 20) / 100)
end

-- { price, t, source, listed, ch1, ch7, ch30, avg, dev, rsi, hi7, lo7, hi30, lo30, vol, days, auctions,
--   sellers, closes, daily, fair, typicalQ, spike, sale (the price to count on when selling),
--   auctionsNow, sellersNow (of the newest measurement), typicalN, typicalS (usual auctions, sellers),
--   prev (the check half an hour or more before: t, p, q, n, sl), sinceP (price change since, a fraction),
--   sinceQ, sinceN, sinceS (listed, auctions, sellers: more (+) or fewer (-) since), flood, crowd, dropped }
function An.Stats(itemID)
    local s = cache[itemID]
    if s and GetTime() - s.countedAt < STATS_FRESH then return s end
    s = { countedAt = GetTime() }
    s.price, s.t, s.source, s.listed = FT.Price(itemID)
    local daily = FT.Hist.Daily(itemID, 60)
    s.daily = daily
    local today = FT.Day()
    local closes = {}
    for _, c in ipairs(daily) do closes[#closes + 1] = c.c end
    s.closes = closes
    -- No day as old as that known (a new auction house or item, Auctionator off): the change since the first day of
    -- that span known - or since today's first price, when it moved today at all (seen more than once).
    local last = daily[#daily]
    local dayOpen = last and last.day == today and last.o and last.h ~= last.l and last.o or nil
    s.ch1 = Change(s.price, CloseAtOrBefore(daily, today - 1) or dayOpen)
    s.ch7 = Change(s.price, CloseAtOrBefore(daily, today - 7) or FirstCloseIn(daily, today - 6, today - 1) or dayOpen)
    s.ch30 = Change(s.price, CloseAtOrBefore(daily, today - 30) or FirstCloseIn(daily, today - 29, today - 1) or dayOpen)

    -- the average of the last N days, today left out (that's what we compare today with)
    local avgDays = FT.S.avgDays
    local sum, n, days14 = 0, 0, 0
    local hi7, lo7, hi30, lo30
    for _, c in ipairs(daily) do
        local age = today - c.day
        if age >= 1 and age <= avgDays then
            sum, n = sum + c.c, n + 1
        end
        if age <= 13 then days14 = days14 + 1 end
        if age <= 6 then
            hi7 = math.max(hi7 or c.h, c.h)
            lo7 = math.min(lo7 or c.l, c.l)
        end
        if age <= 29 then
            hi30 = math.max(hi30 or c.h, c.h)
            lo30 = math.min(lo30 or c.l, c.l)
        end
    end
    s.avgN = n
    s.avg = n > 0 and sum / n or nil
    s.hi7, s.lo7, s.hi30, s.lo30 = hi7, lo7, hi30, lo30
    s.days = days14
    -- how many days this item has history at all (liquidity can't be judged on a day or two)
    s.span = #daily > 0 and (today - daily[1].day + 1) or 0
    local forRsi = {}
    for i = math.max(1, #closes - 29), #closes do forRsi[#forRsi + 1] = closes[i] end
    if s.price and #forRsi > 0 and daily[#daily].day ~= today then forRsi[#forRsi + 1] = s.price end
    s.rsi = An.RSI(forRsi, 14)
    s.vol = An.Volatility(forRsi)

    local book = FT.Hist.Book(itemID)
    if book then
        s.auctions, s.sellers = book.auctions, book.sellers
        s.listed = s.listed or book.qty
        s.bookT = book.t
    end
    -- the market right now: auctions and sellers of the newest measurement (an older order book doesn't count)
    local l = FT.Hist.Latest(itemID)
    if l and s.t and l.t == s.t and not l.gone then
        s.auctionsNow, s.sellersNow = l.n, l.sl
    end
    if book and s.t and book.t and book.t >= s.t - 600 and book.source ~= "mastercraft" then
        s.auctionsNow = s.auctionsNow or ((book.auctions or 0) > 0 and book.auctions or nil)
        s.sellersNow = s.sellersNow or ((book.sellers or 0) > 0 and book.sellers or nil)
    end
    s.fair, s.typicalQ, s.typicalN, s.typicalS = An.FairNow(itemID)
    -- TradeSkillMaster (FT.TSM, when on): while our own history of the item is short (under 3 days), its 14-day market
    -- value of your realm is the average; with no fair price of our own, its recent value is the fair price
    local tsm = FT.TSM and FT.TSM.Values(itemID)
    s.tsm = tsm
    if tsm and tsm.market and (s.avgN or 0) < 3 then s.avg, s.avgN, s.avgTSM = tsm.market, avgDays, true end
    if tsm and not s.fair and (tsm.recent or tsm.market) then s.fair, s.fairTSM = tsm.recent or tsm.market, true end
    -- the first day the market is watched (no day before today): the fair price of the hours seen is the average
    if not s.avg and s.fair and Watched(avgDays) <= 1 then s.avg, s.avgN, s.avgFair = s.fair, 0, true end
    s.dev = Change(s.price, s.avg)
    s.spike = Spike(s)
    s.falling = Falling(s)
    s.sale = s.spike and s.fair or s.price

    -- what changed since the last check (the scan, or the live update, of half an hour or more ago)
    local prev = FT.Hist.Previous(itemID)
    if prev and s.price and prev.p and prev.p > 0 then
        s.prev = prev
        s.sinceP = s.price / prev.p - 1
        s.sinceQ = (s.listed and prev.q) and (s.listed - prev.q) or nil
        s.sinceN = (s.auctionsNow and prev.n) and (s.auctionsNow - prev.n) or nil
        s.sinceS = (s.sellersNow and prev.sl) and (s.sellersNow - prev.sl) or nil
    end
    local more = 1 + (FT.S.floodAbove or 50) / 100
    -- far more listed than usual: the market is flooded - a price that holds now may not hold long
    s.flood = (s.listed and s.typicalQ and s.typicalQ > 0 and s.listed >= s.typicalQ * more
        and s.listed - s.typicalQ >= FLOOD_MIN) and true or false
    -- far more sellers than usual: competitors have come
    s.crowd = (s.sellersNow and s.typicalS and s.typicalS > 0 and s.sellersNow >= s.typicalS * more
        and s.sellersNow - s.typicalS >= CROWD_MIN) and true or false
    -- what really sells (FT.Sales: told from the listings seen go): slow when a day sells under 5% of what is
    -- usually listed (and under one) - the listed take weeks to clear
    s.sales = FT.Sales.Rate(itemID)
    local usual = s.typicalQ or s.listed or 0
    s.slow = (s.sales and s.sales.hours >= SLOW_HOURS and s.sales.perDay < math.max(1, usual * 0.05)) and true or false
    -- the price fell since the last check (one of the last day)
    s.dropped = (s.sinceP and s.sinceP <= -DROP and time() - s.prev.t <= 86400) and true or false
    cache[itemID] = s
    return s
end

-- Why selling it (or crafting it to sell) is risky right now: reasons, the strongest first.
-- liquidity: An.Liquidity of the same stats (given when known)
function An.Risks(s, liquidity)
    local out = {}
    if not (s and s.price) then return out end
    if s.falling and s.fair then
        out[#out + 1] = string.format(L["Price falling fast: %s vs its fair price"], FT.Pct(s.price / s.fair - 1, true))
    end
    if s.dropped then
        out[#out + 1] = string.format(L["%s since the check %s"], FT.Pct(s.sinceP, true), FT.Ago(s.prev.t))
    end
    if s.flood then
        out[#out + 1] = string.format(L["Flooded: %s listed, usually ~%s"], FT.Num(s.listed), FT.Num(math.floor(s.typicalQ + 0.5)))
    end
    if s.crowd then
        out[#out + 1] = string.format(L["More sellers: %d, usually ~%d"], s.sellersNow, math.floor(s.typicalS + 0.5))
    end
    if s.slow then
        out[#out + 1] = string.format(L["Hardly bought: %s with ~%s usually listed"], FT.Sales.PerDayText(s.sales),
            FT.Num(math.floor((s.typicalQ or s.listed or 0) + 0.5)))
    end
    if liquidity == "low" then out[#out + 1] = L["Rarely listed: it may not sell"] end
    if s.ch7 and s.ch7 <= -0.10 then
        out[#out + 1] = string.format(L["Price falling: %s in 7 days"], FT.Pct(s.ch7, true))
    end
    return out
end

-- the same, short, for the line under an item's name (falling fast and a jump are said there already)
function An.RiskNotes(s)
    local out = {}
    if not (s and s.price) then return out end
    if s.dropped then
        out[#out + 1] = string.format(L["%s since the check %s"], FT.Pct(s.sinceP, true), FT.Ago(s.prev.t))
    end
    if s.flood then
        out[#out + 1] = string.format(L["flooded: %s listed (usually ~%s)"], FT.Num(s.listed), FT.Num(math.floor(s.typicalQ + 0.5)))
    end
    if s.crowd then
        out[#out + 1] = string.format(L["%d sellers (usually ~%d)"], s.sellersNow, math.floor(s.typicalS + 0.5))
    end
    return out
end

-- day by day: how far the price stood above (+) or below (-) its average of the days before it
-- (Settings: average over N days), as a fraction - the "is it a good moment to sell" line
function An.DevSeries(itemID, days)
    local daily = FT.Hist.Daily(itemID, (days or 30) + FT.S.avgDays)
    local out = {}
    -- days in an average: 3, fewer while the market has been watched fewer days
    local need = math.max(1, math.min(3, Watched(FT.S.avgDays) - 1))
    local from = FT.Day() - (days or 30) + 1
    for i, c in ipairs(daily) do
        if c.day >= from then
            local sum, n = 0, 0
            for k = i - 1, 1, -1 do
                local prev = daily[k]
                if c.day - prev.day > FT.S.avgDays then break end
                sum, n = sum + prev.c, n + 1
            end
            if n >= need and sum > 0 then
                -- in money: what selling one now brings above (or below) the average price
                local avg = sum / n
                out[#out + 1] = { t = c.t, value = c.c - avg, pct = c.c / avg - 1 }
            end
        end
    end
    return out
end

-- how easy it is to sell: "high" / "medium" / "low" (by how many of the last 14 days it was listed)
-- "unknown" while the item has less than 5 days of history (fewer while the market itself has been watched fewer
-- days, at least 2): too early to tell. On the market's first day: "medium" when many auctions of it are up now.
function An.Liquidity(s)
    local own = An.OwnLiquidity(s)
    if own ~= "unknown" then return own end
    -- too early to tell from our own history: what sells in the region, by TradeSkillMaster
    local tsm = s and s.tsm
    if tsm and tsm.soldPerDay then
        if tsm.soldPerDay >= 5 and (tsm.saleRate or 0) >= 0.2 then return "high" end
        if tsm.soldPerDay >= 0.5 then return "medium" end
        return "low"
    end
    return "unknown"
end

function An.OwnLiquidity(s)
    if not s or not s.days or not s.span then return "unknown" end
    local watched = Watched(14)
    if s.span >= math.max(2, math.min(5, watched)) then
        -- the share of the days we know of on which it was listed
        local cover = s.days / math.min(14, s.span)
        if cover >= 0.6 and (s.auctions == nil or s.auctions >= 4) then return "high" end
        if cover >= 0.3 then return "medium" end
        return "low"
    end
    if watched <= 1 then
        local auctions = s.auctionsNow or s.auctions
        if (auctions and auctions >= 4) or (not auctions and (s.listed or 0) >= 10) then return "medium" end
    end
    return "unknown"
end

---------------------------------------------------------------------------
-- Signals: kind, strength (1-3), reason
---------------------------------------------------------------------------
-- an average of 3 days or more (fewer while the market has been watched fewer days; its first day: the fair price
-- of the hours seen)
local function Enough(s)
    if not (s and s.price and s.avg) then return false end
    return (s.avgN or 0) >= math.min(3, math.max(0, Watched(FT.S.avgDays) - 1))
end

-- what the average is of, in the reasons: "the 14-day average" (as many days as the setting while there are 3 or
-- more of them, otherwise as many as there are), or the price of the last hours
local function AboveText(s, dev)
    if s.avgTSM then return string.format(L["%s above TSM's market value"], FT.Pct(dev, true)) end
    if s.avgFair then return string.format(L["%s above its price of the last hours"], FT.Pct(dev, true)) end
    return string.format(L["%s above the %d-day average"], FT.Pct(dev, true), (s.avgN or 0) >= 3 and FT.S.avgDays or s.avgN)
end
local function BelowText(s, dev)
    if s.avgTSM then return string.format(L["%s below TSM's market value"], FT.Pct(dev, true)) end
    if s.avgFair then return string.format(L["%s below its price of the last hours"], FT.Pct(dev, true)) end
    return string.format(L["%s below the %d-day average"], FT.Pct(dev, true), (s.avgN or 0) >= 3 and FT.S.avgDays or s.avgN)
end

-- for something you have or make: sell now?
function An.SellSignal(s)
    -- a buyout: worth selling a little under it now - it won't last
    if s.spike then
        return "SELL", 2, string.format(L["Price jump (buyout?): %s above its fair price ~%s - sell a little under it now, it won't last"],
            FT.Pct(s.price / s.fair - 1, true), FT.Money(s.fair, "short"))
    end
    if not Enough(s) then return "NODATA", 0, L["Not enough price history yet"] end
    local th = FT.S.sellAbove / 100
    local dev = s.dev or 0
    local hot = s.rsi and s.rsi >= 70
    if dev >= th or hot then
        local strength = (dev >= th and hot) and 3 or ((dev >= th * 2) and 3 or 2)
        local reason
        if dev >= th then
            reason = AboveText(s, dev)
        else
            reason = string.format(L["RSI %d: overbought"], math.floor(s.rsi + 0.5))
        end
        return "SELL", strength, reason
    end
    if dev <= -th then
        if s.avgTSM then
            return "HOLD", 2, string.format(L["%s below TSM's market value: wait"], FT.Pct(dev, true))
        end
        if s.avgFair then
            return "HOLD", 2, string.format(L["%s below its price of the last hours: wait"], FT.Pct(dev, true))
        end
        return "HOLD", 2, string.format(L["%s below the %d-day average: wait"], FT.Pct(dev, true),
            (s.avgN or 0) >= 3 and FT.S.avgDays or s.avgN)
    end
    return "FAIR", 1, L["Price near its average"]
end

-- for a material you need: buy now?
function An.BuySignal(s)
    if not Enough(s) then return "NODATA", 0, L["Not enough price history yet"] end
    local th = FT.S.buyBelow / 100
    local dev = s.dev or 0
    local cold = s.rsi and s.rsi <= 30
    if dev <= -th or cold then
        local strength = (dev <= -th and cold) and 3 or 2
        local reason
        if dev <= -th then
            reason = BelowText(s, dev)
        else
            reason = string.format(L["RSI %d: oversold"], math.floor(s.rsi + 0.5))
        end
        return "BUY", strength, reason
    end
    if dev >= th then
        return "EXPENSIVE", 2, AboveText(s, dev)
    end
    return "FAIR", 1, L["Price near its average"]
end

-- trend over a week
function An.Trend(s)
    -- no week of our own yet: TradeSkillMaster's recent value against its 14-day market value
    if s and not s.ch7 and s.tsm and s.tsm.recent and s.tsm.market then
        local ch = s.tsm.recent / s.tsm.market - 1
        if ch >= 0.05 then return "up" end
        if ch <= -0.05 then return "down" end
        return "flat"
    end
    if not s or not s.ch7 then return "flat" end
    if s.ch7 >= 0.05 then return "up" end
    if s.ch7 <= -0.05 then return "down" end
    return "flat"
end

FT.SIGNAL_COLORS = {
    SELL = "up", BUY = "up", CRAFT = "up",
    HOLD = "accent", WATCH = "accent", EXPENSIVE = "accent", RISKY = "accent",
    AVOID = "down", LOSS = "down",
    FAIR = "muted", NODATA = "dim",
    VENDOR = "up", RESELL = "blue", UNDERCUT = "down", HOUSES = "accent",
}

function FT.SignalText(kind)
    local names = {
        SELL = L["SELL"], BUY = L["BUY"], CRAFT = L["CRAFT"], HOLD = L["HOLD"], WATCH = L["WATCH"],
        EXPENSIVE = L["PRICEY"], RISKY = L["RISKY"], AVOID = L["AVOID"], LOSS = L["LOSS"], FAIR = L["FAIR"],
        NODATA = L["NO DATA"], VENDOR = L["TO VENDOR"], RESELL = L["RESELL"], UNDERCUT = L["UNDERCUT"],
        HOUSES = L["CARRY OVER"],
    }
    return names[kind] or kind
end
