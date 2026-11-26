-- ForeverTrading: TradeSkillMaster link (Settings > Sources can turn it off).
-- TSM's desktop app downloads, about once an hour, what the game's servers report of every auction house: for your
-- realm and faction the lowest buyout and the number of auctions of every item (with its own 14-day market value, its
-- recent value and its 60-day historical price), for the region what really sold - the average sale price, how many
-- sell a day and the share of auctions that sell. TSM_AppHelper brings it into the game at login.
-- ForeverTrading only reads it, through TSM's public API (TSM_API):
--  * a download of your realm is a scan of the whole auction house made by the game's servers: at each login (and
--    /reload) the latest one goes into our history once - its lowest prices and auction counts (day candles, and
--    intraday for the items that matter to you), except for the items our own scans saw later - so the charts,
--    averages, RSI and liquidity fill in on the days you log in without scanning;
--  * an item never seen by our scans takes TSM's lowest buyout as its price;
--  * while our own history of an item is short, TSM's market value stands in for the average, its recent value for
--    the fair price, and the region's sales for liquidity.
-- TSM knows one house per faction: nothing of it counts for Blackwater, except what sold in the region (shown only).
local ADDON, FT = ...
local L = FT.L

local T = {}
FT.TSM = T

local MAX_AGE = 3 * 86400 -- a download older than this is not written into the history (TSM's app wasn't running)

-- installed (its API is there)
function T.Loaded()
    return type(TSM_API) == "table" and type(TSM_API.GetCustomPriceValue) == "function"
end

-- installed and allowed in Settings
function T.On()
    return FT.S ~= nil and FT.S.useTSM ~= false and T.Loaded()
end

-- one TSM price source for an item: its value or nil (TSM not ready yet, no data, or an error inside TSM)
local function Get(source, itemID)
    local ok, v = pcall(TSM_API.GetCustomPriceValue, source, "i:" .. itemID)
    if ok and type(v) == "number" and v > 0 then return v end
    return nil
end

-- TSM rounds every value to a whole number: the fractions (sold a day, the sale rate) are asked for x1000
local function GetFraction(source, itemID)
    local v = Get(source .. " * 1000", itemID)
    return v and v / 1000 or nil
end

---------------------------------------------------------------------------
-- When TSM's data was downloaded, and which items it has: read from the data TSM_AppHelper hands to TSM at load
-- (TSM_API doesn't tell). ForeverTrading loads after TradeSkillMaster and before TradeSkillMaster_AppHelper, so a
-- hook on TSM's loader sees each block go by; it changes nothing of what TSM gets.
---------------------------------------------------------------------------
local blocks = {} -- realm or region -> { [tag] = downloadTime }, realm -> item IDs of its latest prices
local realmIDs = {}

local function OnAppData(tag, realmOrRegion, data)
    if type(tag) ~= "string" or type(realmOrRegion) ~= "string" or type(data) ~= "string" then return end
    if not tag:find("^AUCTIONDB_") then return end
    local t = tonumber(data:sub(1, 200):match("downloadTime=(%d+)"))
    if not t then return end
    blocks[realmOrRegion] = blocks[realmOrRegion] or {}
    blocks[realmOrRegion][tag] = t
    if tag == "AUCTIONDB_NON_COMMODITY_DATA" then
        local from = data:find(",data={", 1, true)
        if from then
            local ids = {}
            for id in data:sub(from):gmatch("{(%d+),") do ids[#ids + 1] = tonumber(id) end
            realmIDs[realmOrRegion] = ids
        end
    end
end

if type(TSM_APPHELPER_LOAD_DATA) == "function" then
    hooksecurefunc("TSM_APPHELPER_LOAD_DATA", OnAppData)
end

local function Squash(s)
    return (tostring(s or ""):gsub("[%s']", ""):lower())
end

-- the realm key of TSM's data for this character: "Realm-Faction", GetRealmName() and the faction, as TSM itself
-- picks it (letter case, spaces and apostrophes aside)
local function MyRealm()
    local faction = UnitFactionGroup("player")
    if not faction then return nil end
    local want = { Squash((GetRealmName() or "") .. "-" .. faction) }
    if GetNormalizedRealmName then want[2] = Squash((GetNormalizedRealmName() or "") .. "-" .. faction) end
    local only, count = nil, 0
    for key, b in pairs(blocks) do
        if b.AUCTIONDB_NON_COMMODITY_DATA then
            local k = Squash(key)
            for _, w in ipairs(want) do
                if k == w then return key end
            end
            if key:sub(-#faction - 1) == "-" .. faction then only, count = key, count + 1 end
        end
    end
    -- the realm written another way: the one realm of this faction there is
    return count == 1 and only or nil
end

-- when TSM's data of your realm (and faction) was downloaded (nil: not known)
function T.RealmTime()
    local key = MyRealm()
    return key and blocks[key].AUCTIONDB_NON_COMMODITY_DATA or nil
end

-- when TSM's data of the region was downloaded (nil: not known)
function T.RegionTime()
    local newest
    for _, b in pairs(blocks) do
        local t = b.AUCTIONDB_REGION_SALE or b.AUCTIONDB_REGION_STAT
        if t and (not newest or t > newest) then newest = t end
    end
    return newest
end

---------------------------------------------------------------------------
-- An item's values: { minBuyout, auctions, recent, market, historical (your realm and faction; not at Blackwater),
-- regionMarket, regionHistorical, regionSale, soldPerDay, saleRate (0..1) } - nil when TSM knows nothing of it.
-- TSM's data changes only at login (and /reload): the values are kept for the session.
---------------------------------------------------------------------------
local ready = false
local cache = { faction = {}, neutral = {} }
local NONE = {}

function T.Values(itemID)
    if not (itemID and T.On()) then return nil end
    local neutral = FT.house == "neutral"
    local c = neutral and cache.neutral or cache.faction
    local v = c[itemID]
    if v then return v ~= NONE and v or nil end
    v = {
        regionMarket = Get("DBRegionMarketAvg", itemID),
        regionHistorical = Get("DBRegionHistorical", itemID),
        regionSale = Get("DBRegionSaleAvg", itemID),
        soldPerDay = GetFraction("DBRegionSoldPerDay", itemID),
        saleRate = GetFraction("DBRegionSaleRate", itemID),
    }
    if not neutral then
        v.minBuyout = Get("DBMinBuyout", itemID)
        v.auctions = Get("DBNumAuctions", itemID)
        v.recent = Get("DBRecent", itemID)
        v.market = Get("DBMarket", itemID)
        v.historical = Get("DBHistorical", itemID)
    end
    local any = next(v) ~= nil
    -- before TSM has read its data nothing is remembered (asked again later)
    if any or ready then c[itemID] = any and v or NONE end
    return any and v or nil
end

-- the price now when our scans have none: TSM's lowest buyout of your realm, when it was downloaded, auctions
function T.Price(itemID)
    local v = T.Values(itemID)
    if not (v and v.minBuyout) then return nil end
    return v.minBuyout, T.RealmTime(), v.auctions
end

local function Forget()
    wipe(cache.faction)
    wipe(cache.neutral)
end
FT.On("FT_SOURCES_CHANGED", Forget)

---------------------------------------------------------------------------
-- Each download of your realm goes into our history once: a whole auction house seen at its time
---------------------------------------------------------------------------
local job

function T.Import()
    if job or not T.On() or FT.house == "neutral" then return 0 end
    local key = MyRealm()
    local t = key and blocks[key].AUCTIONDB_NON_COMMODITY_DATA
    local ids = key and realmIDs[key]
    if not (t and ids and #ids > 0) or t > time() + 600 then return 0 end
    local meta = FT.R().meta
    if (meta.tsmImport or 0) >= t then return 0 end
    if time() - t > MAX_AGE then
        FT.Debug("TSM data too old to import:", FT.Ago(t))
        return 0
    end
    local count = 0
    job = FT.Job("tsm:import", #ids, function(i)
        -- Blackwater switched to meanwhile: stop (the rest comes in next time)
        if FT.house == "neutral" or not T.On() then
            job = nil
            return false
        end
        local id = ids[i]
        -- our own scans (or an exchange) saw it later than this download: theirs stands
        local seen = FT.Hist.LastSeen(id)
        if seen and seen >= t then return end
        local p = Get("DBMinBuyout", id)
        if p then
            FT.Hist.Observe(id, p, nil, Get("DBNumAuctions", id), t, "tsm")
            count = count + 1
        end
    end, function()
        job = nil
        meta.tsmImport = t
        FT.Debug("TSM prices imported:", count, "of", FT.Ago(t))
        if count > 0 then
            -- like Mastercraft's prices: every page looks at everything again
            FT.Hist.MarkAll()
            FT.Fire("FT_PRICES_CHANGED", "tsm")
        end
    end)
    return #ids
end

FT.On("FT_READY", function()
    -- TSM reads its data at login: give it a moment
    C_Timer.After(5, function()
        ready = true
        if T.Loaded() then FT.Fire("FT_SOURCES_CHANGED") end
        T.Import()
    end)
end)
-- your faction's house again (the download is written into its history, never Blackwater's)
FT.On("FT_HOUSE_CHANGED", function(house)
    if ready and house ~= "neutral" then T.Import() end
end)

---------------------------------------------------------------------------
-- For the pages
---------------------------------------------------------------------------
-- "TSM: ~16 a day in the region, 35% of auctions sell" (nil: nothing known)
function T.SalesText(v)
    if not (v and v.soldPerDay) then return nil end
    local text = string.format(L["TSM: ~%s a day in the region"], v.soldPerDay < 10 and string.format("%.1f", v.soldPerDay)
        or FT.Num(math.floor(v.soldPerDay + 0.5)))
    if v.saleRate then text = text .. string.format(L[", %d%% of auctions sell"], math.floor(v.saleRate * 100 + 0.5)) end
    return text
end

-- lines for a tooltip: { label, value } (an empty list: nothing known)
function T.Lines(itemID)
    local v = T.Values(itemID)
    local out = {}
    if not v then return out end
    local function Money(label, val)
        if val then out[#out + 1] = { label, FT.Money(val, "short") } end
    end
    Money(L["Lowest buyout"], v.minBuyout)
    if v.auctions then out[#out + 1] = { L["Auctions"], FT.Num(v.auctions) } end
    Money(L["Recent value"], v.recent)
    Money(L["Market value (14 days)"], v.market)
    Money(L["Historical price (60 days)"], v.historical)
    Money(L["Region market value"], v.regionMarket)
    Money(L["Region historical price"], v.regionHistorical)
    Money(L["Region sale price"], v.regionSale)
    if v.soldPerDay then out[#out + 1] = { L["Region sold a day"], string.format("%.1f", v.soldPerDay) } end
    if v.saleRate then out[#out + 1] = { L["Region sale rate"], string.format("%d%%", math.floor(v.saleRate * 100 + 0.5)) } end
    return out
end

-- the tooltip itself, under what `owner` shows (TSM's values of the item, and how old they are)
function T.AddTooltip(itemID)
    local lines = T.Lines(itemID)
    if #lines == 0 then return false end
    GameTooltip:AddLine(" ")
    local t = FT.house ~= "neutral" and T.RealmTime() or T.RegionTime()
    GameTooltip:AddDoubleLine("TradeSkillMaster", t and FT.Ago(t) or "", 0.95, 0.73, 0.04, 0.55, 0.58, 0.62)
    for _, l in ipairs(lines) do
        GameTooltip:AddDoubleLine(l[1], l[2], 0.75, 0.78, 0.82, 1, 1, 1)
    end
    if FT.house == "neutral" then
        GameTooltip:AddLine(L["TSM knows your faction's auction house only: here just the region's."], 0.55, 0.58, 0.62, true)
    end
    return true
end
