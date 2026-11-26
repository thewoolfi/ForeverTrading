-- ForeverTrading: an item in a window of its own ("More" on the charts) - several at once, to look at two items
-- side by side: large price and profit charts, the numbers that matter, its order book and what buying costs
-- (compact: the charts alone, half as wide). With the auction house open its price and order book stay live
-- (searched again every few seconds).
local ADDON, FT = ...
local UI = FT.UI
local L = FT.L

local D = {}
FT.Detail = D

local W, H = 1000, 620
local BOOK_W = 250

local GetClassInfo = (C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo
local GetSubClassInfo = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo

---------------------------------------------------------------------------
-- Chart data, shared with the Market page
---------------------------------------------------------------------------
local function MoneyAxis(v) return FT.Money(v, "short") end

-- the price line of an item: tf "1H" / "4H" / "1D" / "1W", moving averages when ma is on
function UI.PriceChartData(id, tf, ma)
    local candles = FT.Hist.Series(id, tf)
    local overlays = {}
    -- the averages show from 3 points on (until there are 7 / 25, of the points there are); MA25 once there
    -- are more than 7, else it would be the same line
    if ma and #candles >= 3 then
        local closes = {}
        for i, c in ipairs(candles) do closes[i] = c.c end
        overlays[#overlays + 1] = { values = FT.An.SMA(closes, 7, true), color = "blue", label = "MA7" }
        if #candles > 7 then
            overlays[#overlays + 1] = { values = FT.An.SMA(closes, 25, true), color = "purple", label = "MA25" }
        end
    end
    local intraday = (tf == "1H" or tf == "4H")
    local emptyBody
    if intraday then
        emptyBody = L["Hourly prices are recorded for the items you track (recipes, watchlist, what you own, what you open). This item is tracked now: its hourly line starts with the next scan."]
    else
        emptyBody = L["No prices for it yet: scan My items or run a full scan at the auction house."]
    end
    return {
        candles = candles, mode = "line", lineColor = "accent", tagColor = "accent", fmt = MoneyAxis,
        title = L["Price"], overlays = overlays, hourly = intraday, defaultCount = intraday and 72 or 60,
        emptyTitle = L["No price history"], emptyBody = emptyBody,
    }
end

-- the profitability line, in money: the profit of one craft (your recipe), else what selling one now brings
-- above or below its average price
function UI.ProfitChartData(id)
    local best = FT.Craft.Best(id)
    if best then
        return {
            candles = UI.LineCandles(FT.Craft.History(best, 30), "profit"),
            mode = "line", centerZero = true, fmt = FT.SignedMoney, defaultCount = 30,
            title = L["Profit per craft"],
            emptyTitle = L["No history yet"],
            emptyBody = L["Needs a few days of prices for the item and its materials."],
        }
    end
    return {
        candles = UI.LineCandles(FT.An.DevSeries(id, 30)),
        mode = "line", centerZero = true, fmt = FT.SignedMoney, defaultCount = 30,
        title = string.format(L["Selling now: price vs its %d-day average"], FT.S.avgDays),
        emptyTitle = L["Not enough price history yet"],
        emptyBody = L["Shows once there are a few days of prices."],
    }
end

-- where the price comes from and how old it is; "live" while the auction house keeps it fresh
function UI.PriceAgeText(id, s)
    if not (s and s.t) then return "" end
    if FT.Scanner.LiveOn(id) then
        return FT.C("up", L["live"]) .. " || " .. FT.Ago(s.t)
    end
    return FT.SourceName(s.source) .. " || " .. FT.Ago(s.t)
end

-- Stackable goods come from the auction house as one row per price, not per auction: "auctions" of them are
-- the prices the order book has. Gear comes auction by auction.
function UI.AuctionsLabel(id)
    return (id and FT.Buy.IsCommodity(id)) and L["Price levels"] or L["Auctions"]
end
function UI.AuctionsText(id, n)
    return string.format((id and FT.Buy.IsCommodity(id)) and L["%d price levels"] or L["%d auctions"], n)
end

-- how much really sells, as estimated from the listings seen go (FT.Sales): "Sells ~4.2 a day (14 h watched)"
function UI.SalesText(s)
    local r = s and s.sales
    -- and what sells in the region, by TradeSkillMaster (when on)
    local tsm = s and FT.TSM.SalesText(s.tsm)
    tsm = tsm and (FT.C("dim", "   ||   ") .. FT.C("text", tsm)) or ""
    if not r then return L["Sells"] .. " " .. FT.C("dim", L["not seen yet"]) .. tsm end
    return L["Sells"] .. " " .. FT.C(s.slow and "down" or "text", FT.Sales.PerDayText(r))
        .. FT.C("dim", " " .. string.format(L["(%d h watched)"], math.max(1, math.floor(r.hours + 0.5)))) .. tsm
end

-- listed / auctions / sellers of the newest measurement, and how many more (+, red: competition) or fewer
-- (-, green) than at the last check half an hour or more ago
function UI.CountText(s, key)
    local val, d
    if key == "listed" then
        val, d = s.listed, s.sinceQ
    elseif key == "auctions" then
        val, d = s.auctionsNow or s.auctions, s.auctionsNow and s.sinceN
    else
        val, d = s.sellersNow or s.sellers, s.sellersNow and s.sinceS
    end
    if not val then return "—" end
    local text = FT.Num(val)
    if d and d ~= 0 then
        text = text .. " " .. FT.C(d > 0 and "down" or "up", (d > 0 and "+" or "-") .. FT.Num(math.abs(d)))
    end
    return text
end

-- what to know first, before the item's name line: a price jump or a fast fall, a fall since the last check,
-- a flooded market, more sellers than usual
function UI.RiskHead(s)
    local head = {}
    if s.spike then
        head[#head + 1] = FT.C("accent", string.format(L["price jump (buyout?): fair ~%s"], FT.Money(s.fair, "short")))
    elseif s.falling then
        head[#head + 1] = FT.C("down", string.format(L["falling fast: %s, fair ~%s"], FT.Pct(s.price / s.fair - 1, true), FT.Money(s.fair, "short")))
    end
    for _, note in ipairs(FT.An.RiskNotes(s)) do head[#head + 1] = FT.C("down", note) end
    return head
end

-- "More" in the corner of a chart: the item in its own window
function UI.MoreButton(chart, getID)
    local b = UI.Button(chart, L["More"], 10, 18, "default", function()
        local id = getID()
        if id then FT.ShowDetail(id) end
    end)
    b.label:SetFont(UI.FONT, 11, "")
    b:FitText(14)
    b:SetPoint("TOPRIGHT", -3, -2)
    b:SetFrameLevel(chart:GetFrameLevel() + 14)
    b:SetTip(L["More"], L["The item in its own window: large charts and its order book. With the auction house open they stay live."])
    return b
end

---------------------------------------------------------------------------
-- The windows: up to MAX_WINDOWS at once (two items side by side), each compact or standard - compact: no order
-- book and materials column, no buttons in the header, the charts half as wide
---------------------------------------------------------------------------
local MAX_WINDOWS = 4
local CASCADE = 30
local COMPACT_W = 380
local wins, used = {}, {} -- every window made; the order they were looked at (the latest last)

local Layout, Refresh, Draw, UpdateWatch, FitHeader, SetCompact, SetHouse

local function StatPair(parent, label)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(100, 34)
    f.label = UI.Text(f, 10, "dim")
    f.label:SetPoint("TOPLEFT", 0, -2)
    f.label:SetText(label)
    f.value = UI.Text(f, 12, "text")
    f.value:SetPoint("TOPLEFT", 0, -17)
    return f
end

-- what a window keeps between sessions: where it was, compact or not (the one window of before is the first)
local function Saved(w)
    FT.db.detailFrames = FT.db.detailFrames or {}
    local list = FT.db.detailFrames
    if w.index == 1 and not list[1] and FT.db.detailFrame then list[1] = FT.db.detailFrame end
    list[w.index] = list[w.index] or {}
    return list[w.index]
end

local function SavePos(w)
    local point, _, relPoint, x, y = w:GetPoint(1)
    local s = Saved(w)
    s.point, s.relPoint, s.x, s.y = point, relPoint, x, y
end

-- looked at now: the last to be replaced when all windows are open
local function Touch(w)
    for i = #used, 1, -1 do
        if used[i] == w then table.remove(used, i) end
    end
    used[#used + 1] = w
end

local function EachShown(fn)
    for _, w in ipairs(wins) do
        if w:IsShown() and w.id then fn(w) end
    end
end

-- the numbers: one row, or two rows of four in the compact window
local function PlaceStrip(w, sw)
    if not sw or sw <= 0 then return end
    local perRow = w.compact and 4 or #w.pairs
    local cw = (sw - 20) / perRow
    for i, pr in ipairs(w.pairs) do
        local col, row = (i - 1) % perRow, math.floor((i - 1) / perRow)
        pr:ClearAllPoints()
        pr:SetPoint("TOPLEFT", 10 + col * cw, -4 - row * 34)
        pr:SetWidth(cw - 6)
    end
end

-- compact / standard: two buttons with a picture of each (like the main window's)
local function SizeButtons(w, header)
    local f = CreateFrame("Frame", nil, header)
    f:SetSize(2 * 24 + 2, 24)
    f.buttons = {}
    local defs = { { true, 8, 10, L["Compact"] }, { false, 14, 10, L["Standard"] } }
    for i, d in ipairs(defs) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(24, 24)
        b:SetPoint("LEFT", (i - 1) * 26, 0)
        b.compact = d[1]
        b.hover = UI.RoundTex(b, "BACKGROUND", "bg2", 1)
        b.hover:SetAllPoints()
        b.hover:Hide()
        b.box = CreateFrame("Frame", nil, b)
        b.box:SetSize(d[2], d[3])
        b.box:SetPoint("CENTER")
        UI.Border(b.box, "muted", nil, "none")
        b.fill = UI.Tex(b.box, "ARTWORK", "accent", 0.25)
        b.fill:SetAllPoints()
        b:SetScript("OnEnter", function(self)
            self.hover:Show()
            UI.TipText(self, d[4])
        end)
        b:SetScript("OnLeave", function(self)
            self.hover:Hide()
            GameTooltip:Hide()
        end)
        b:SetScript("OnClick", function(self) SetCompact(w, self.compact) end)
        f.buttons[i] = b
    end
    function f:Update()
        for _, b in ipairs(self.buttons) do
            local on = b.compact == (w.compact == true)
            b.box:SetBorderColor(on and "accent" or "muted", on and 1 or 0.9)
            b.fill:SetShown(on)
        end
    end
    return f
end

local function New(index)
    local w = CreateFrame("Frame", "ForeverTradingDetail" .. index, UIParent, UI.EdgeTemplate())
    w.index = index
    w:SetFrameStrata("HIGH")
    w:SetToplevel(true)
    w:SetClampedToScreen(true)
    w:SetMovable(true)
    w:EnableMouse(true)
    w:SetScale(FT.S.scale or 1)
    local s = Saved(w)
    w.compact = s.compact == true
    w:SetSize(w.compact and COMPACT_W or W, H)
    if s.point then
        w:SetPoint(s.point, UIParent, s.relPoint or s.point, s.x or 0, s.y or 0)
    else
        -- a new one a little down and right of the one before: both in sight
        local prev = wins[index - 1]
        local point, _, relPoint, x, y
        if prev then point, _, relPoint, x, y = prev:GetPoint(1) end
        if point then
            w:SetPoint(point, UIParent, relPoint, (x or 0) + CASCADE, (y or 0) - CASCADE)
        else
            w:SetPoint("CENTER", UIParent, "CENTER", 30, -20)
        end
    end
    -- a shadow round it and a clear edge: it stands out from the main window under it
    if UI.theme ~= "classic" then
        local light = UI.theme == "light"
        w.shadowOut = UI.RoundTex(w, "BACKGROUND", "black", light and 0.06 or 0.22, -8, nil, 9)
        w.shadowOut:SetPoint("TOPLEFT", -8, 8)
        w.shadowOut:SetPoint("BOTTOMRIGHT", 8, -8)
        w.shadowIn = UI.RoundTex(w, "BACKGROUND", "black", light and 0.10 or 0.32, -8, nil, 6)
        w.shadowIn:SetPoint("TOPLEFT", -4, 4)
        w.shadowIn:SetPoint("BOTTOMRIGHT", 4, -4)
    end
    UI.Fill(w, "bg0")
    if not UI.ClassicEdge(w, "accent", { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } }) then
        -- a gold outline two wide: seen on any background, the main window's included
        UI.Border(w, "accent", 1)
        w.edge = CreateFrame("Frame", nil, w)
        w.edge:SetPoint("TOPLEFT", 1, -1)
        w.edge:SetPoint("BOTTOMRIGHT", -1, 1)
        UI.Border(w.edge, "accent", 0.55, nil, UI.RADIUS - 1)
    end
    table.insert(UISpecialFrames, w:GetName())

    -- header: the item, its price, buttons; dragging it moves the window
    local header = CreateFrame("Frame", nil, w)
    header:SetPoint("TOPLEFT", UI.INSET, -UI.INSET)
    header:SetPoint("TOPRIGHT", -UI.INSET, -UI.INSET)
    header:SetHeight(58)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        Touch(w)
        w:StartMoving()
    end)
    header:SetScript("OnDragStop", function()
        w:StopMovingOrSizing()
        SavePos(w)
    end)
    w.header = header
    local hl = UI.HLine(header, "line")
    hl:SetPoint("BOTTOMLEFT")
    hl:SetPoint("BOTTOMRIGHT")

    w.icon = UI.Icon(header, 38)
    w.icon:SetPoint("LEFT", 12, 0)
    w.icon:EnableMouse(true)
    w.icon:SetScript("OnEnter", function(self) if w.id then UI.TipItem(self, w.id) end end)
    w.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    w.name = UI.Text(header, 16, "text")
    w.name:SetPoint("TOPLEFT", w.icon, "TOPRIGHT", 10, -1)
    w.sub = UI.Text(header, 11, "dim")
    w.sub:SetPoint("TOPLEFT", w.name, "BOTTOMLEFT", 0, -6)

    local close = UI.Button(header, "×", 30, 30, "ghost", function() w:Hide() end)
    close.label:SetFont(UI.FONT, 18, "")
    w.close = close
    w.sizes = SizeButtons(w, header)
    w.sizes:SetPoint("RIGHT", close, "LEFT", -6, 0)
    w.market = UI.Button(header, L["Open in Market"], 10, 24, "default", function()
        if w.id then FT.OpenItem(w.id) end
    end)
    w.market:FitText(20)
    w.market:SetPoint("RIGHT", w.sizes, "LEFT", -10, 0)
    w.watch = UI.Button(header, L["Watch"], 10, 24, "default", function()
        if w.id then
            FT.Market.ToggleWatch(w.id)
            UpdateWatch(w)
        end
    end)
    w.watch:SetPoint("RIGHT", w.market, "LEFT", -6, 0)
    w.search = UI.Button(header, L["Search on AH"], 10, 24, "primary", function()
        if w.id then FT.SearchItems({ w.id }) end
    end)
    w.search:FitText(20)
    w.search:SetPoint("RIGHT", w.watch, "LEFT", -6, 0)

    w.change = UI.Text(header, 14, "text", "RIGHT")
    w.price = UI.Text(header, 22, "text", "RIGHT")
    w.priceAge = UI.Text(header, 10, "dim", "RIGHT")
    -- the countdown to its next live search
    -- (live only when its house is the one on)
    w.ring = UI.LiveRingFor(header, 9, function() return w.house == FT.house and w.id or nil end)

    -- body: charts on the left, the order book on the right (standard)
    local body = CreateFrame("Frame", nil, w)
    body:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 8, -8)
    body:SetPoint("BOTTOMRIGHT", -UI.INSET - 8, UI.INSET + 8)

    w.book = UI.OrderBook(body)
    w.book:SetWidth(BOOK_W)
    -- under it the materials of one craft (a material clicked opens in this window)
    w.mats = UI.Materials(body, function(id) FT.ShowDetail(id, w) end)
    w.mats:SetPoint("BOTTOMRIGHT", 0, 0)
    w.mats:SetWidth(BOOK_W)
    w.mats:Hide()

    w.left = CreateFrame("Frame", nil, body)
    w.strip = UI.Panel(w.left, "bg1", "line")
    w.strip:SetPoint("TOPLEFT", 0, 0)
    w.strip:SetPoint("TOPRIGHT", 0, 0)
    local defs = {
        { "hi7", L["7d high"] }, { "lo7", L["7d low"] }, { "avg", L["Average"] }, { "hi30", L["30d high"] },
        { "lo30", L["30d low"] }, { "listed", L["Listed"] }, { "auctions", L["Auctions"] }, { "sellers", L["Sellers"] },
    }
    w.pairs = {}
    for i, d in ipairs(defs) do
        local pr = StatPair(w.strip, d[2])
        pr.key = d[1]
        w.pairs[i] = pr
    end
    UI.OnSize(w.strip, function(self, sw) PlaceStrip(w, sw) end)

    w.tf = UI.Segmented(w.left, { { "1H", L["1H"] }, { "4H", L["4H"] }, { "1D", L["1D"] }, { "1W", L["1W"] } }, function(tf)
        FT.S.chartTF = tf
        EachShown(function(x)
            x.tf:SetValue(tf)
            Draw(x)
        end)
    end)
    w.ma = UI.Check(w.left, L["Averages"], function(on)
        FT.S.showMA = on
        EachShown(function(x)
            x.ma:SetChecked(on)
            Draw(x, true)
        end)
    end)
    w.ma:SetPoint("LEFT", w.tf, "RIGHT", 16, 0)
    w.ma:SetTip(L["Moving averages"], L["Two smoothed lines on the price chart: MA7 and MA25, the average price of the last 7 and 25 points (days on 1D). Until there are that many, of the points there are; MA25 shows once there are more than 7."])
    -- whose prices: this window's own auction house, whatever the others show
    w.houseChip = UI.HouseChip(w.left, {
        get = function() return w.house or FT.house end,
        toggle = function() SetHouse(w, (w.house or FT.house) == "neutral" and "faction" or "neutral") end,
    })
    w.ind = UI.Text(w.left, 11, "muted", "RIGHT")

    w.chart = UI.Chart(w.left)
    UI.Border(w.chart, "line")
    w.pchart = UI.Chart(w.left)
    w.pchart:SetPoint("TOPLEFT", w.chart, "BOTTOMLEFT", 0, -6)
    w.pchart:SetPoint("BOTTOMRIGHT", 0, 0)
    UI.Border(w.pchart, "line")
    UI.OnSize(w.left, function(self, lw, lh)
        w.chart:SetHeight(math.max(120, math.floor((lh - (w.chartTop or 78) - 6) * 0.6)))
    end)

    w:SetScript("OnHide", function() w:StopMovingOrSizing() end)
    w:SetScript("OnMouseDown", function() Touch(w) end)
    wins[index] = w
    Layout(w)
    w:Hide()
    return w
end

-- the window's parts for its size
Layout = function(w)
    local c = w.compact
    w:SetWidth(c and COMPACT_W or W)
    w.header:SetHeight(c and 76 or 58)
    w.close:ClearAllPoints()
    w.icon:ClearAllPoints()
    if c then
        w.close:SetPoint("TOPRIGHT", -6, -4)
        w.icon:SetPoint("TOPLEFT", 12, -10)
    else
        w.close:SetPoint("RIGHT", -8, 0)
        w.icon:SetPoint("LEFT", 12, 0)
    end
    w.market:SetShown(not c)
    w.watch:SetShown(not c)
    w.search:SetShown(not c)
    -- the price: on the right of the header (standard), under the name (compact: no room beside it)
    w.change:ClearAllPoints()
    w.price:ClearAllPoints()
    w.priceAge:ClearAllPoints()
    w.ring:ClearAllPoints()
    w.name:ClearAllPoints()
    if c then
        w.sub:Hide()
        w.name:SetPoint("TOPLEFT", w.icon, "TOPRIGHT", 10, 1)
        w.price:SetPoint("TOPLEFT", w.name, "BOTTOMLEFT", 0, -3)
        w.change:SetPoint("BOTTOMLEFT", w.price, "BOTTOMRIGHT", 10, 3)
        w.ring:SetPoint("TOPLEFT", w.price, "BOTTOMLEFT", 0, -5)
        w.priceAge:SetPoint("LEFT", w.ring, "RIGHT", 5, 0)
        w.priceAge:SetJustifyH("LEFT")
    else
        w.sub:Show()
        w.name:SetPoint("TOPLEFT", w.icon, "TOPRIGHT", 10, -1)
        w.change:SetPoint("RIGHT", w.search, "LEFT", -20, 8)
        w.price:SetPoint("RIGHT", w.change, "LEFT", -12, -1)
        w.priceAge:SetPoint("TOPRIGHT", w.change, "BOTTOMRIGHT", 0, -7)
        w.priceAge:SetJustifyH("RIGHT")
        w.priceAge:SetWidth(0)
        w.ring:SetPoint("RIGHT", w.priceAge, "LEFT", -5, 0)
    end
    -- the order book and the materials: standard only
    w.book:SetShown(not c)
    if c then w.mats:Hide() end
    w.left:ClearAllPoints()
    w.left:SetPoint("TOPLEFT", 0, 0)
    w.left:SetPoint("BOTTOMRIGHT", c and 0 or -(BOOK_W + 10), 0)
    -- the numbers, the toolbar (and the indicators on their own line when narrow), the charts
    local stripH = c and 76 or 42
    w.strip:SetHeight(stripH)
    local barY = stripH + 8
    w.tf:ClearAllPoints()
    w.tf:SetPoint("TOPLEFT", 0, -barY)
    w.houseChip:ClearAllPoints()
    w.ind:ClearAllPoints()
    if c then
        -- under the toolbar: the indicators (up to two lines), the auction house on their right
        local y = barY + w.tf:GetHeight() + 8
        w.houseChip:SetPoint("TOPRIGHT", w.left, "TOPRIGHT", 0, -y)
        w.ind:SetPoint("TOPLEFT", w.left, "TOPLEFT", 0, -(y + 4))
        w.ind:SetPoint("TOPRIGHT", w.houseChip, "TOPLEFT", -10, -4)
        w.ind:SetJustifyH("LEFT")
        w.ind:SetJustifyV("TOP")
        if w.ind.SetWordWrap then w.ind:SetWordWrap(true) end
        if w.ind.SetMaxLines then w.ind:SetMaxLines(2) end
        w.chartTop = y + 30 + 6
    else
        if w.ind.SetWordWrap then w.ind:SetWordWrap(false) end
        if w.ind.SetMaxLines then w.ind:SetMaxLines(1) end
        w.houseChip:SetPoint("RIGHT", w.left, "TOPRIGHT", 0, -(barY + w.tf:GetHeight() / 2))
        w.ind:SetPoint("LEFT", w.ma, "RIGHT", 40, 0)
        w.ind:SetPoint("RIGHT", w.houseChip, "LEFT", -12, 0)
        w.ind:SetJustifyH("RIGHT")
        w.chartTop = barY + w.tf:GetHeight() + 6
    end
    w.chart:ClearAllPoints()
    w.chart:SetPoint("TOPLEFT", 0, -w.chartTop)
    w.chart:SetPoint("TOPRIGHT", 0, -w.chartTop)
    local lh = w.left:GetHeight()
    if lh and lh > 0 then w.chart:SetHeight(math.max(120, math.floor((lh - w.chartTop - 6) * 0.6))) end
    w.sizes:Update()
    PlaceStrip(w, w.strip:GetWidth())
    FitHeader(w)
end

-- the window's own auction house: its numbers, charts, order book and materials are of it
SetHouse = function(w, house)
    w.house = (house == "neutral") and "neutral" or "faction"
    w.book.house = w.house
    w.mats.house = w.house
    w.houseChip:Update()
    if GameTooltip:IsOwned(w.houseChip) then w.houseChip:GetScript("OnEnter")(w.houseChip) end
    if w.id and w:IsShown() then Refresh(w) end
end

SetCompact = function(w, on)
    w.compact = on and true or false
    Saved(w).compact = w.compact
    Layout(w)
    if w.id and w:IsShown() then Refresh(w, true) end
end

UpdateWatch = function(w)
    if not w.id then return end
    local on = FT.Market.IsWatched(w.id)
    w.watch:SetLabel(on and L["In watchlist"] or L["Watch"])
    w.watch:SetActive(on)
    w.watch:FitText(20)
    FitHeader(w)
end

-- the name and the line under it stop before the price block and the buttons (cut with "...")
FitHeader = function(w)
    local hw = w.header:GetWidth()
    if not hw or hw <= 0 then return end
    local right = hw - 8 - 30 - 6 - w.sizes:GetWidth()
    local left = 12 + 38 + 10
    if w.compact then
        w.name:SetWidth(math.max(60, right - 10 - left))
        w.priceAge:SetWidth(math.max(60, hw - left - 12 - 14 - 12))
        return
    end
    right = right - 10 - w.market:GetWidth() - 6 - w.watch:GetWidth() - 6 - w.search:GetWidth() - 20
    w.name:SetWidth(math.max(60, right - w.change:GetStringWidth() - 12 - w.price:GetStringWidth() - 14 - left))
    w.sub:SetWidth(math.max(60, right - w.priceAge:GetStringWidth() - 5 - 9 - 14 - left))
end

local function DrawIn(w, keepView)
    w.chart:SetData(UI.PriceChartData(w.id, FT.S.chartTF, FT.S.showMA), keepView)
    w.pchart:SetData(UI.ProfitChartData(w.id), keepView)
end

Draw = function(w, keepView)
    if not w.id then return end
    FT.House.With(w.house, DrawIn, w, keepView)
end

local LIQ_NAMES = { high = "high", medium = "medium", low = "low", unknown = "no data" }
local LIQ_COLORS = { high = "up", medium = "accent", low = "down", unknown = "dim" }

local function RefreshIn(w, keepView)
    local id = w.id
    w.icon:SetItem(id)
    w.name:SetText(FT.ItemText(id, 34))
    local parts = {}
    local cls, sub = FT.ItemClass(id)
    if cls then
        local name = GetClassInfo and GetClassInfo(cls)
        if name and name ~= "" then parts[#parts + 1] = name end
        local subName = GetSubClassInfo and sub and GetSubClassInfo(cls, sub)
        if subName and subName ~= "" and subName ~= name then parts[#parts + 1] = subName end
    end
    local rs = FT.Craft.ByOutput(id)
    if rs and rs[1] then parts[#parts + 1] = FT.C("up", L["you can craft it"]) end
    local own = FT.Port.Count(id)
    if own > 0 then parts[#parts + 1] = FT.C("text", string.format(L["you have %s"], FT.Num(own))) end
    local s = FT.An.Stats(id)
    local head = UI.RiskHead(s)
    for i = #head, 1, -1 do table.insert(parts, 1, head[i]) end
    w.sub:SetText(table.concat(parts, FT.C("dim", "  ||  ")))

    w.price:SetText(s.price and FT.Money(s.price) or "—")
    w.change:SetText(FT.Pct(s.ch1) .. (w.compact and "" or FT.C("dim", " " .. L["24h"])))
    w.priceAge:SetText(UI.PriceAgeText(id, s))
    for _, pr in ipairs(w.pairs) do
        local val = s[pr.key]
        if pr.key == "listed" or pr.key == "auctions" or pr.key == "sellers" then
            pr.value:SetText(UI.CountText(s, pr.key))
            if pr.key == "auctions" then pr.label:SetText(UI.AuctionsLabel(id)) end
        else
            pr.value:SetText(val and FT.Money(val, "short") or "—")
        end
    end

    local ind = {}
    if s.rsi then
        local color = (s.rsi >= 70 and "down") or (s.rsi <= 30 and "up") or "text"
        ind[#ind + 1] = "RSI " .. FT.C(color, string.format("%.0f", s.rsi))
    end
    if s.dev then ind[#ind + 1] = L["vs average"] .. " " .. FT.Pct(s.dev) end
    if s.vol then ind[#ind + 1] = L["Daily volatility"] .. " " .. FT.C("text", string.format("%.1f%%", s.vol * 100)) end
    local liq = FT.An.Liquidity(s)
    ind[#ind + 1] = L["Liquidity"] .. " " .. FT.C(LIQ_COLORS[liq], L[LIQ_NAMES[liq]])
    ind[#ind + 1] = UI.SalesText(s)
    w.ind:SetText(table.concat(ind, FT.C("dim", "   ||   ")))

    w.tf:SetValue(FT.S.chartTF)
    w.ma:SetChecked(FT.S.showMA)
    DrawIn(w, keepView)
    if not w.compact then
        w.book:SetItem(id)
        local show, h = w.mats:SetItem(id)
        w.mats:SetShown(show)
        w.book:ClearAllPoints()
        w.book:SetPoint("TOPRIGHT", 0, 0)
        w.book:SetWidth(BOOK_W)
        if show then
            w.mats:SetHeight(h)
            w.book:SetPoint("BOTTOMRIGHT", w.mats, "TOPRIGHT", 0, 8)
        else
            w.book:SetPoint("BOTTOMRIGHT", 0, 0)
        end
    end
    UpdateWatch(w)
end

-- with the window's own auction house on
Refresh = function(w, keepView)
    if not (w.id and w:IsShown()) then return end
    w.houseChip:Update()
    FT.House.With(w.house, RefreshIn, w, keepView)
end

-- the item of the window looked at last (nil: none open)
function D.Item()
    for i = #used, 1, -1 do
        local w = used[i]
        if w:IsShown() and w.id then return w.id end
    end
    return nil
end

function D.Refresh(keepView)
    EachShown(function(w) Refresh(w, keepView) end)
end

-- kept live: every open item of the house on, and the materials of one craft of those in a standard window
function D.Items()
    local out, seen = {}, {}
    local function Add(id)
        if id and not seen[id] then
            seen[id] = true
            out[#out + 1] = id
        end
    end
    EachShown(function(w)
        if w.house ~= FT.house then return end
        Add(w.id)
        if w.mats:IsShown() and w.mats.r then
            for _, m in ipairs(FT.Craft.MarketMaterials(w.mats.r)) do Add(m) end
        end
    end)
    return #out > 0 and out or nil
end

-- open an item in a window of its own: the window that has it, else one not on the screen, else a new one (up to
-- MAX_WINDOWS), else the one looked at longest ago; `into`: that window (a material clicked in it)
function FT.ShowDetail(id, into)
    if not id then return end
    local w = into
    if not w then
        for _, x in ipairs(wins) do
            if x:IsShown() and x.id == id then
                w = x
                break
            end
        end
    end
    if not w then
        for _, x in ipairs(wins) do
            if not x:IsShown() then
                w = x
                break
            end
        end
    end
    if not w and #wins < MAX_WINDOWS then w = New(#wins + 1) end
    if not w then
        for _, x in ipairs(used) do
            if x:IsShown() then
                w = x
                break
            end
        end
        w = w or wins[1]
    end
    local same = w.id == id and w:IsShown()
    -- a new item in it (not a material clicked in it): the house on, to begin with
    if not (into or same) then
        w.house = FT.house
        w.book.house, w.mats.house = w.house, w.house
    end
    w.id = id
    FT.Hist.Viewed(id)
    w:Show()
    w:Raise()
    Touch(w)
    Layout(w)
    Refresh(w, same)
    -- with the auction house open its search goes out now
    FT.Scanner.LiveNow(id)
end

-- Settings: the window scale changed
function D.Rescale(scale)
    for _, w in ipairs(wins) do w:SetScale(scale or 1) end
end

FT.On("FT_LIVE_UPDATED", function(id)
    if not id then return end
    EachShown(function(w)
        if w.house == FT.house and (id == w.id or (w.mats:IsShown() and w.mats:Has(id))) then Refresh(w, true) end
    end)
end)
FT.On("FT_AH_CHANGED", function() D.Refresh(true) end)
local function Later()
    if D.Item() then FT.Debounce("detailRefresh", 0.8, function() D.Refresh(true) end) end
end
FT.On("FT_PRICES_CHANGED", Later)
FT.On("FT_SCAN_DONE", Later)
FT.On("FT_ITEMS_LOADED", Later)
FT.On("FT_HOUSE_CHANGED", Later)
FT.On("FT_WATCH_CHANGED", function() EachShown(UpdateWatch) end)
