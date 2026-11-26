-- ForeverTrading: the main window - header with navigation, the ticker tape, pages, status bar.
local ADDON, FT = ...
local UI = FT.UI
local L = FT.L

FT.Tabs = {}

local TAB_ORDER = { "market", "craft", "signals", "portfolio", "sell", "settings" }
local TAB_LABELS = { market = "Market", craft = "Craft", signals = "Signals", portfolio = "Portfolio", sell = "Selling",
    settings = "Settings" }

local win, nav, content, ticker, statusLeft, statusRight, scanDot, scanText, sizeBox, gearBtn, brand
local lastPage = "market"
local pages = {}

-- three sizes instead of dragging a corner: compact, standard, the whole screen
local SIZES = { min = { 1100, 640 }, std = { 1240, 740 } }
local SIZE_ORDER = { "min", "std", "max" }

local function SizeMode()
    local m = FT.db.frame.size
    return (m == "min" or m == "max") and m or "std"
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
local function SavePos()
    if not win or SizeMode() == "max" then return end
    local p = FT.db.frame
    local point, _, relPoint, x, y = win:GetPoint(1)
    p.point, p.relPoint, p.x, p.y = point, relPoint, x, y
end

local function UpdateSizeButtons()
    if not sizeBox then return end
    local mode = SizeMode()
    for _, b in ipairs(sizeBox.buttons) do
        local on = b.mode == mode
        b.box:SetBorderColor(on and "accent" or "muted", on and 1 or 0.9)
        b.fill:SetShown(on)
    end
end

local function PlaceWindow()
    local p = FT.db.frame
    local mode = SizeMode()
    win:ClearAllPoints()
    if mode == "max" then
        -- the whole screen, whatever the window's scale (Settings)
        local scale = win:GetScale()
        win:SetSize(UIParent:GetWidth() / scale, UIParent:GetHeight() / scale)
        win:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    else
        local size = SIZES[mode]
        win:SetSize(size[1], size[2])
        if p.point then
            win:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
        else
            win:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
        end
    end
    UpdateSizeButtons()
end

function FT.ResetWindow()
    if win then PlaceWindow() end
end

-- the pages lay themselves out for the size (compact: charts only)
local function LayoutPages()
    for name, p in pairs(pages) do
        local tab = FT.Tabs[name]
        if tab and tab.OnLayout and p.built then
            local ok, err = pcall(tab.OnLayout, p)
            if not ok then geterrorhandler()(err) end
        end
    end
end

-- the brand: its name only in the full-screen window, else the coin (the pages' names need the room); in the
-- compact window the auction house pill is its light alone
function FT.LayoutBrand()
    if not brand then return end
    local roomy = FT.WindowMaximized()
    for _, w in ipairs(brand.words) do w:SetShown(roomy) end
    FT.UpdateAHPill()
    brand.pill:ClearAllPoints()
    if not roomy then
        brand.pill:SetPoint("LEFT", brand.logo, "RIGHT", 10, 0)
    else
        brand.pill:SetPoint("LEFT", brand.words[2], "RIGHT", 16, 0)
    end
end

function FT.SetWindowSize(mode)
    FT.db.frame.size = mode
    if win then
        PlaceWindow()
        LayoutPages()
        FT.LayoutBrand()
        FT.UpdateScanBox()
    end
end

function FT.WindowMaximized()
    return SizeMode() == "max"
end

-- the compact window: the order book and the cards under the charts make way
function FT.Compact()
    return FT.db ~= nil and SizeMode() == "min"
end

-- three small buttons, each a frame of its size
local function BuildSizeButtons(header, anchor)
    local f = CreateFrame("Frame", nil, header)
    f:SetSize(3 * 24 + 4, 24)
    f:SetPoint("RIGHT", anchor, "LEFT", -6, 0)
    f.buttons = {}
    local frames = { min = { 9, 7 }, std = { 12, 9 }, max = { 16, 12 } }
    local tips = { min = L["Compact"], std = L["Standard"], max = L["Full screen"] }
    for i, mode in ipairs(SIZE_ORDER) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(24, 24)
        b:SetPoint("LEFT", (i - 1) * 26, 0)
        b.mode = mode
        b.hover = UI.RoundTex(b, "BACKGROUND", "bg2", 1)
        b.hover:SetAllPoints()
        b.hover:Hide()
        b.box = CreateFrame("Frame", nil, b)
        b.box:SetSize(frames[mode][1], frames[mode][2])
        b.box:SetPoint("CENTER")
        UI.Border(b.box, "muted", nil, "none")
        b.fill = UI.Tex(b.box, "ARTWORK", "accent", 0.25)
        b.fill:SetAllPoints()
        b:SetScript("OnEnter", function(self)
            self.hover:Show()
            UI.TipText(self, tips[mode])
        end)
        b:SetScript("OnLeave", function(self)
            self.hover:Hide()
            GameTooltip:Hide()
        end)
        b:SetScript("OnClick", function() FT.SetWindowSize(mode) end)
        f.buttons[i] = b
    end
    sizeBox = f
    UpdateSizeButtons()
    return f
end

---------------------------------------------------------------------------
-- Ticker tape: watchlist first, then the day's biggest movers
---------------------------------------------------------------------------
local function BuildTicker(parent)
    local t = CreateFrame("Frame", nil, parent)
    t:SetHeight(26)
    UI.Fill(t, "bg1", nil, "none")
    if t.SetClipsChildren then pcall(t.SetClipsChildren, t, true) end
    t.entries = {}
    t.speed = 28
    local fadeL = UI.Tex(t, "OVERLAY", "bg1", 1, 7)
    fadeL:SetPoint("TOPLEFT")
    fadeL:SetPoint("BOTTOMLEFT")
    fadeL:SetWidth(30)
    UI.Gradient(fadeL, "HORIZONTAL", "bg1", 1, 0)
    local fadeR = UI.Tex(t, "OVERLAY", "bg1", 1, 7)
    fadeR:SetPoint("TOPRIGHT")
    fadeR:SetPoint("BOTTOMRIGHT")
    fadeR:SetWidth(30)
    UI.Gradient(fadeR, "HORIZONTAL", "bg1", 0, 1)

    local function Entry(i)
        local e = t.entries[i]
        if e then return e end
        e = CreateFrame("Button", nil, t)
        e:SetHeight(26)
        e.text = UI.Text(e, 11, "text")
        e.text:SetPoint("LEFT", 0, 0)
        e:SetScript("OnClick", function(self)
            if self.itemID then FT.OpenItem(self.itemID) end
        end)
        e:SetScript("OnEnter", function(self)
            t.paused = true
            if self.itemID then UI.TipItem(self, self.itemID, "ANCHOR_BOTTOM") end
        end)
        e:SetScript("OnLeave", function()
            t.paused = false
            GameTooltip:Hide()
        end)
        t.entries[i] = e
        return e
    end

    -- the entries hang on one strip that moves: one anchor a frame (an entry is placed again only when it goes
    -- round from the left edge to the end)
    t.strip = CreateFrame("Frame", nil, t)
    t.strip:SetSize(1, 26)
    t.offset = 0
    local function PlaceStrip(self)
        self.strip:ClearAllPoints()
        self.strip:SetPoint("LEFT", self, "LEFT", self.offset, 0)
    end
    local function PlaceEntry(self, e)
        e:ClearAllPoints()
        e:SetPoint("LEFT", self.strip, "LEFT", e.x, 0)
    end

    function t:SetEntries(list)
        self.list = list
        self.offset = 0
        PlaceStrip(self)
        local x = 12
        for i, item in ipairs(list) do
            local e = Entry(i)
            e.itemID = item.id
            e.text:SetText(item.text)
            e:SetWidth(math.ceil(e.text:GetStringWidth()) + 4)
            e.x, e.w = x, e:GetWidth()
            x = x + e.w + 34
            PlaceEntry(self, e)
            e:Show()
        end
        for i = #list + 1, #self.entries do self.entries[i]:Hide() end
        self.total = x
        self.right = x - 34 -- the right edge of the last entry, on the strip
    end

    t:SetScript("OnUpdate", function(self, elapsed)
        if self.paused or not self.list or #self.list == 0 then return end
        local W = self:GetWidth()
        if (self.total or 0) <= W then
            -- everything fits: no need to move
            return
        end
        local n = #self.list
        self.offset = self.offset - self.speed * math.min(elapsed, 0.1)
        if self.offset < -10000 then
            -- far along: the strip back to the start, the entries with it
            for i = 1, n do
                local e = self.entries[i]
                e.x = e.x + self.offset
                PlaceEntry(self, e)
            end
            self.right = self.right + self.offset
            self.offset = 0
        end
        PlaceStrip(self)
        for i = 1, n do
            local e = self.entries[i]
            if e.x + e.w + self.offset < 0 then
                -- gone past the left edge: after the last one
                e.x = math.max(self.right + 34, W - self.offset)
                self.right = e.x + e.w
                PlaceEntry(self, e)
            end
            if not self.clips then
                local sx = e.x + self.offset
                e:SetShown(sx >= 0 and sx + e.w <= W)
            end
        end
    end)
    t.clips = t.SetClipsChildren ~= nil
    t:SetScript("OnEnter", function(self) self.paused = true end)
    t:SetScript("OnLeave", function(self) self.paused = false end)
    return t
end

local function TickerText(id, price, ch)
    local name = FT.Trunc(FT.Item(id) or ("#" .. id), 26)
    return FT.C("muted", name) .. "  " .. FT.Money(price, "short") .. "  " .. FT.Pct(ch)
end

function FT.UpdateTicker()
    if not ticker or not FT.S.ticker then return end
    local list, seen = {}, {}
    for id in pairs(FT.db.watch) do
        local r = FT.Market.Row(id)
        local price = r and r.price or FT.Price(id)
        if price then
            list[#list + 1] = { id = id, text = "|cfff0b90b*|r " .. TickerText(id, price, r and r.ch1) }
            seen[id] = true
        end
    end
    local movers = 0
    for _, r in ipairs(FT.Market.Movers(8, "ch1", true)) do
        if not seen[r.id] and r.ch1 > 0 then
            list[#list + 1] = { id = r.id, text = TickerText(r.id, r.price, r.ch1) }
            seen[r.id] = true
            movers = movers + 1
        end
    end
    for _, r in ipairs(FT.Market.Movers(8, "ch1", false)) do
        if not seen[r.id] and r.ch1 < 0 then
            list[#list + 1] = { id = r.id, text = TickerText(r.id, r.price, r.ch1) }
            seen[r.id] = true
            movers = movers + 1
        end
    end
    if movers == 0 then
        -- no moves known yet (the first days of prices - of this auction house too): the most valuable listings,
        -- after the watchlist
        for _, r in ipairs(FT.Market.TopByValue(14)) do
            if not seen[r.id] then
                list[#list + 1] = { id = r.id, text = TickerText(r.id, r.price, r.ch1) }
                seen[r.id] = true
            end
        end
    end
    if #list == 0 then
        list[1] = { text = FT.C("dim", L["No market data yet: open the auction house and press Full scan."]) }
    end
    ticker:SetEntries(list)
end

---------------------------------------------------------------------------
-- Status (header dot + bottom bar)
---------------------------------------------------------------------------
function FT.UpdateStatus()
    if not win then return end
    local last = FT.Hist.LastScan()
    local color, text
    if FT.scanning or FT.atrScanning then
        color, text = "accent", L["Scanning..."]
    elseif not last then
        color, text = "dim", L["No scan yet"]
    else
        local age = time() - last
        color = (age < 3600 and "up") or (age < 12 * 3600 and "accent") or "down"
        text = L["Scan"] .. ": " .. FT.Ago(last)
    end
    UI.SetTexColor(scanDot, color, 1)
    scanText:SetText(text)

    local parts = {}
    local full = FT.Hist.LastScan("full")
    parts[#parts + 1] = L["Full scan"] .. ": " .. (full and FT.Ago(full) or L["never"])
    -- a fresher scan received from someone else
    local peer = FT.Hist.LastScan("peer")
    if peer and (not full or peer > full) then parts[#parts + 1] = L["Exchange"] .. ": " .. FT.Ago(peer) end
    local function Source(name, on)
        return on and (FT.C("up", name) .. " " .. FT.C("up", L["on"])) or FT.C("dim", name .. " " .. L["off"])
    end
    parts[#parts + 1] = Source("Auctionator", FT.Atr.On())
    parts[#parts + 1] = Source("Mastercraft", FT.MC.Loaded())
    if FT.TSM.Loaded() then parts[#parts + 1] = Source("TSM", FT.TSM.On()) end
    parts[#parts + 1] = string.format(L["Recipes: %d"], #FT.Craft.List())
    parts[#parts + 1] = string.format(L["Tracked: %d"], FT.S.trackAll and #(FT.Market.Rows() or {}) or FT.Hist.UniverseSize())
    local rows = FT.Market.Rows()
    if rows then parts[#parts + 1] = string.format(L["Market: %s items"], FT.Num(#rows)) end
    statusLeft:SetText(table.concat(parts, FT.C("dim", "   ||   ")))
end

---------------------------------------------------------------------------
-- Scan buttons and progress (header)
---------------------------------------------------------------------------
local scanBox

local function BuildScanBox(header, anchor, closeButton)
    local f = CreateFrame("Frame", nil, header)
    f:SetSize(280, 40)
    f.anchor, f.closeButton = anchor, closeButton
    f:SetPoint("RIGHT", anchor, "LEFT", -18, 0)
    f.mine = UI.Button(f, L["My items"], 10, 24, "default", function() FT.Scanner.AskMine() end)
    f.mine:FitText(24)
    f.mine:SetPoint("RIGHT", 0, 0)
    f.full = UI.Button(f, L["Full scan"], 10, 24, "primary", function() FT.Scanner.StartFull() end)
    f.full:FitText(24)
    f.full:SetPoint("RIGHT", f.mine, "LEFT", -6, 0)
    -- pressed again while it runs: it stops
    f.share = UI.Button(f, L["Exchange"], 10, 24, "default", function()
        if FT.Share.Status() then FT.Share.Stop() else FT.Share.Ask(true) end
    end)
    f.share:FitText(24)
    f.share.text = L["Exchange"]
    f.share:SetTip(L["Price exchange"], L["Ask ForeverTrading users in your guild and group for fresher prices of the whole market. Works anywhere, no auction house needed. (Settings > Exchange: by itself when your prices are more than an hour old.)"])
    f.stop = UI.Button(f, L["Stop"], 10, 22, "down", function() FT.Scanner.Stop("user") end)
    f.stop:FitText(20)
    f.stop:SetPoint("RIGHT", 0, 0)
    f.bar = CreateFrame("Frame", nil, f)
    f.bar:SetSize(160, 4)
    f.bar:SetPoint("BOTTOMRIGHT", f.stop, "BOTTOMLEFT", -10, 3)
    UI.Fill(f.bar, "bg3", nil, "none")
    f.fill = UI.Tex(f.bar, "ARTWORK", "accent", 1)
    f.fill:SetPoint("TOPLEFT")
    f.fill:SetPoint("BOTTOMLEFT")
    f.text = UI.Text(f, 10, "muted", "RIGHT")
    f.text:SetPoint("BOTTOMRIGHT", f.bar, "TOPRIGHT", 0, 4)
    f.text:SetWidth(160)
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = self.elapsed + elapsed
        if self.elapsed < 0.2 then return end
        self.elapsed = 0
        -- only while a scan or the exchange runs (and once when it ends): the rest comes with the events
        local busy = FT.Scanner.mode ~= nil or FT.Share.Status() ~= nil
        if busy or self.busy then
            self.busy = busy
            FT.UpdateScanBox()
        end
    end)
    scanBox = f
    return f
end

function FT.UpdateScanBox()
    local f = scanBox
    if not f then return end
    local S = FT.Scanner
    local mode = S.mode
    local running = mode ~= nil
    -- only the full-screen window has room for Full scan and Exchange next to a running scan's progress (during
    -- My items Full scan takes over there); My items while nothing runs
    local roomy = SizeMode() == "max"
    local crowded = running and not roomy
    f.full:SetShown(mode ~= "full" and not crowded)
    f.mine:SetShown(not running)
    f.stop:SetShown(running)
    f.bar:SetShown(running)
    f.text:SetShown(running)
    -- the scan status next to it: only in the full-screen window (the status bar at the bottom has it too)
    scanText:SetShown(not running and roomy)
    scanDot:SetShown(not running and roomy)
    f:ClearAllPoints()
    if running or not roomy then
        f:SetPoint("RIGHT", f.closeButton, "LEFT", -12, 0)
    else
        f:SetPoint("RIGHT", f.anchor, "LEFT", -18, 0)
    end
    f.full:ClearAllPoints()
    if running then
        local frac, text = S.Progress()
        f.fill:SetWidth(math.max(1, f.bar:GetWidth() * math.max(0, math.min(1, frac or 0))))
        f.text:SetText(text or "")
        f.full:SetPoint("RIGHT", f.bar, "LEFT", -12, 3)
    else
        f.full:SetPoint("RIGHT", f.mine, "LEFT", -6, 0)
    end
    -- the exchange: how far it is
    local kind, frac = FT.Share.Status()
    local label = L["Exchange"]
    if kind == "receive" then
        label = string.format(L["Exchange %d%%"], math.floor((frac or 0) * 100))
    elseif kind == "send" then
        label = string.format(L["Sharing %d%%"], math.floor((frac or 0) * 100))
    elseif kind == "ask" then
        label = L["Exchange"] .. "..."
    end
    if f.share.text ~= label then
        f.share.text = label
        f.share:SetLabel(label)
        f.share:FitText(24)
    end
    f.share:SetActive(kind ~= nil)
    if (kind ~= nil) ~= f.share.running then
        f.share.running = kind ~= nil
        if kind then
            f.share:SetTip(L["Price exchange"], L["Click: stop the exchange. What has come stays."])
        else
            f.share:SetTip(L["Price exchange"], L["Ask ForeverTrading users in your guild and group for fresher prices of the whole market. Works anywhere, no auction house needed. (Settings > Exchange: by itself when your prices are more than an hour old.)"])
        end
        -- the tooltip on screen follows
        if GameTooltip:IsOwned(f.share) and f.share:GetScript("OnEnter") then f.share:GetScript("OnEnter")(f.share) end
    end
    -- no room for it next to a running scan but in the full-screen window
    f.share:SetShown(not crowded)
    f.share:ClearAllPoints()
    if f.full:IsShown() then
        f.share:SetPoint("RIGHT", f.full, "LEFT", -6, 0)
    else
        f.share:SetPoint("RIGHT", f.bar, "LEFT", -12, 3)
    end
    local ah = FT.ahOpen and S.Supported()
    f.full:SetUsable(ah)
    f.mine:SetUsable(ah)
    if not ah then
        f.full:SetTip(L["Full scan"], L["Open the auction house first."])
        f.mine:SetTip(L["My items"], L["Open the auction house first."])
    else
        f.full:SetTip(L["Full scan"], L["The whole auction house in a few seconds: the lowest price and how many are listed of every item. Any time. (Settings > Scanning: a deep scan reads every auction and order book, once every 15 minutes.)"])
        f.mine:SetTip(L["My items"], L["Only what matters to you: what your recipes make and use, your watchlist and what you own - one search each, cheapest first. Any time; it pauses while you search yourself."])
    end
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local function Build()
    UI.ResolveFont()
    win = CreateFrame("Frame", "ForeverTradingFrame", UIParent, UI.EdgeTemplate())
    win:SetFrameStrata("HIGH")
    win:SetToplevel(true)
    win:SetClampedToScreen(true)
    win:SetMovable(true)
    win:EnableMouse(true)
    win:SetScale(FT.S.scale or 1)
    PlaceWindow()
    UI.Fill(win, "bg0")
    if not UI.ClassicEdge(win, "line", { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } }) then
        UI.Border(win, "line")
    end
    table.insert(UISpecialFrames, "ForeverTradingFrame")

    -- header
    local header = CreateFrame("Frame", nil, win)
    header:SetPoint("TOPLEFT", UI.INSET, -UI.INSET)
    header:SetPoint("TOPRIGHT", -UI.INSET, -UI.INSET)
    header:SetHeight(44)
    UI.Fill(header, "bg0", nil, "top", UI.RADIUS - UI.INSET)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        -- the full-screen window stays where it is
        if SizeMode() ~= "max" then win:StartMoving() end
    end)
    header:SetScript("OnDragStop", function()
        win:StopMovingOrSizing()
        SavePos()
    end)
    local hl = UI.HLine(header, "line")
    hl:SetPoint("BOTTOMLEFT")
    hl:SetPoint("BOTTOMRIGHT")

    local logo = UI.Icon(header, 24)
    logo:SetIcon("Interface\\Icons\\INV_Misc_Coin_02")
    logo:SetPoint("LEFT", 14, 0)
    local brand1 = UI.Text(header, 15, "accent")
    brand1:SetPoint("LEFT", logo, "RIGHT", 10, 0)
    brand1:SetText("FOREVER")
    local brand2 = UI.Text(header, 15, "text")
    brand2:SetPoint("LEFT", brand1, "RIGHT", 1, 0)
    brand2:SetText("TRADING")

    -- the pages; Settings is the gear on the right
    local items = {}
    for _, key in ipairs(TAB_ORDER) do
        if key ~= "settings" then items[#items + 1] = { key, L[TAB_LABELS[key]] } end
    end
    local pill = FT.BuildAHPill(header)
    brand = { logo = logo, words = { brand1, brand2 }, pill = pill }
    FT.LayoutBrand()
    local houseChip = FT.BuildHouseChip(header)
    houseChip:SetPoint("LEFT", pill, "RIGHT", 6, 0)
    nav = UI.NavTabs(header, items, function(key) FT.SelectTab(key) end)
    nav:SetPoint("LEFT", houseChip, "RIGHT", 14, 0)

    local close = UI.Button(header, "×", 30, 30, "ghost", function() win:Hide() end)
    close.label:SetFont(UI.FONT, 18, "")
    close:SetPoint("RIGHT", -8, 0)

    local sizes = BuildSizeButtons(header, close)

    -- Settings: a gear (again: back to the page you were on)
    gearBtn = CreateFrame("Button", nil, header)
    gearBtn:SetSize(28, 28)
    gearBtn:SetPoint("RIGHT", sizes, "LEFT", -6, 0)
    gearBtn.hover = UI.RoundTex(gearBtn, "BACKGROUND", "bg2", 1)
    gearBtn.hover:SetAllPoints()
    gearBtn.hover:Hide()
    gearBtn.gear = UI.Gear(gearBtn, 18, "muted")
    gearBtn.gear:SetPoint("CENTER")
    function gearBtn:Update()
        local on = FT.currentTab == "settings"
        self.gear:SetColor(on and "accent" or (self:IsMouseOver() and "text" or "muted"))
    end
    gearBtn:SetScript("OnEnter", function(self)
        self.hover:Show()
        self:Update()
        UI.TipText(self, L["Settings"])
    end)
    gearBtn:SetScript("OnLeave", function(self)
        self.hover:Hide()
        self:Update()
        GameTooltip:Hide()
    end)
    gearBtn:SetScript("OnClick", function()
        if FT.currentTab == "settings" then FT.SelectTab(lastPage) else FT.SelectTab("settings") end
    end)

    scanText = UI.Text(header, 11, "muted", "RIGHT")
    scanText:SetPoint("RIGHT", gearBtn, "LEFT", -14, 0)
    scanDot = UI.Dot(header, 7, "dim", 1, "OVERLAY")
    scanDot:SetPoint("RIGHT", scanText, "LEFT", -7, 0)
    BuildScanBox(header, scanDot, gearBtn)
    FT.UpdateScanBox()
    -- what the tour points at
    FT.MainRefs = { nav = nav, pill = pill, house = houseChip, gear = gearBtn, scan = scanBox }

    -- ticker tape
    ticker = BuildTicker(win)
    ticker:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
    ticker:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
    if not FT.S.ticker then ticker:SetHeight(1) ticker:Hide() end
    local tl = UI.HLine(win, "line")
    tl:SetPoint("TOPLEFT", ticker, "BOTTOMLEFT")
    tl:SetPoint("TOPRIGHT", ticker, "BOTTOMRIGHT")

    -- status bar
    local status = CreateFrame("Frame", nil, win)
    status:SetPoint("BOTTOMLEFT", UI.INSET, UI.INSET)
    status:SetPoint("BOTTOMRIGHT", -UI.INSET, UI.INSET)
    status:SetHeight(22)
    UI.Fill(status, "bg1", nil, "bottom", UI.RADIUS - UI.INSET)
    local sl = UI.HLine(status, "line")
    sl:SetPoint("TOPLEFT")
    sl:SetPoint("TOPRIGHT")
    statusLeft = UI.Text(status, 10, "muted")
    statusLeft:SetPoint("LEFT", 12, 0)
    statusRight = UI.Text(status, 10, "dim", "RIGHT")
    statusRight:SetPoint("RIGHT", -12, 0)
    statusRight:SetText(FT.VERSION_TEXT .. "   /ft")
    -- links: support the author, the project on GitHub
    local function StatusLink(text, color, onClick)
        local b = CreateFrame("Button", nil, status)
        b.text = UI.Text(b, 10, color)
        b.text:SetPoint("CENTER")
        b.text:SetText(text)
        b:SetSize(math.ceil(b.text:GetStringWidth()) + 12, 20)
        b:SetScript("OnEnter", function(self) UI.SetTextColor(self.text, "text") end)
        b:SetScript("OnLeave", function(self) UI.SetTextColor(self.text, color) end)
        b:SetScript("OnClick", onClick)
        return b
    end
    local gh = StatusLink("GitHub", "muted", function() FT.ShowGitHub() end)
    gh:SetPoint("RIGHT", statusRight, "LEFT", -12, 0)
    local support = StatusLink(L["Support the author"], "accent", function() FT.ShowSupport() end)
    support:SetPoint("RIGHT", gh, "LEFT", -4, 0)
    -- a newer version was heard of: where to get it
    local newer = StatusLink("", "up", function() FT.ShowGitHub() end)
    newer:SetPoint("RIGHT", support, "LEFT", -8, 0)
    local function ShowNewer()
        local v = FT.Ver.Newest()
        newer:SetShown(v ~= nil)
        if v then
            newer.text:SetText(string.format(L["Update available: %s"], v))
            newer:SetWidth(math.ceil(newer.text:GetStringWidth()) + 12)
        end
    end
    ShowNewer()
    FT.On("FT_NEWER_VERSION", ShowNewer)


    -- pages
    content = CreateFrame("Frame", nil, win)
    content:SetPoint("TOPLEFT", ticker, "BOTTOMLEFT", 0, -1)
    content:SetPoint("BOTTOMRIGHT", status, "TOPRIGHT", 0, 0)

    win:SetScript("OnShow", function()
        FT.UpdateStatus()
        FT.UpdateScanBox()
        FT.UpdateTicker()
        FT.Market.EnsureFresh()
    end)
    win:SetScript("OnHide", function()
        UI.CloseMenu()
        win:StopMovingOrSizing()
        -- closing the terminal with the game's window hidden behind it: the visit is over
        -- (not the hiding right after the window is made)
        if win.ready then FT.LeaveAH() end
    end)
    win:Hide()
    win.ready = true
end

local function Page(name)
    local p = pages[name]
    if p then return p end
    p = CreateFrame("Frame", nil, content)
    p:SetAllPoints()
    pages[name] = p
    local tab = FT.Tabs[name]
    if tab and tab.Build then
        local ok, err = pcall(tab.Build, p)
        if not ok then geterrorhandler()(err) end
    end
    p.built = true
    return p
end

function FT.SelectTab(name)
    if not FT.Tabs[name] then name = "market" end
    FT.currentTab = name
    if name ~= "settings" then lastPage = name end
    nav:SetValue(name)
    if gearBtn then gearBtn:Update() end
    local page = Page(name)
    for n, p in pairs(pages) do p:SetShown(n == name) end
    local tab = FT.Tabs[name]
    local fn = tab.OnShow or tab.Refresh
    if fn then
        local ok, err = pcall(fn, page)
        if not ok then geterrorhandler()(err) end
    end
end

function FT.Show(tab)
    if not win then Build() end
    win:Show()
    win:Raise()
    FT.SelectTab(tab or FT.currentTab or "market")
    -- once a version: what's new (or, on a first install, the tour)
    if FT.News then C_Timer.After(0.4, FT.News.OnWindow) end
end

function FT.Toggle()
    if win and win:IsShown() then
        win:Hide()
    else
        FT.Show()
    end
end

function FT.Window()
    return win
end

function FT.IsShown()
    return win ~= nil and win:IsShown()
end

-- open an item on the Market page: its list shows just that item (× in the search box: all again)
function FT.OpenItem(itemID)
    FT.Show("market")
    local T = FT.Tabs.market
    if T.Focus then T.Focus(itemID) elseif T.Select then T.Select(itemID) end
end

-- open a recipe on the Craft page
function FT.OpenRecipe(key)
    FT.Show("craft")
    if FT.Tabs.craft.Select then FT.Tabs.craft.Select(key) end
end

-- the page on screen follows new data (once things have settled)
local function RefreshVisible()
    if not FT.IsShown() then return end
    FT.UpdateStatus()
    local tab = FT.Tabs[FT.currentTab]
    local page = pages[FT.currentTab]
    if tab and tab.Refresh and page then
        local ok, err = pcall(tab.Refresh, page)
        if not ok then geterrorhandler()(err) end
    end
end

local function Later() FT.Debounce("uiRefresh", 0.6, RefreshVisible) end
FT.On("FT_SCAN_DONE", Later)
FT.On("FT_PRICES_CHANGED", Later)
FT.On("FT_RECIPES_CHANGED", Later)
FT.On("FT_INVENTORY_CHANGED", Later)
FT.On("FT_WATCH_CHANGED", function()
    Later()
    if FT.IsShown() then FT.UpdateTicker() end
end)
FT.On("FT_ITEMS_LOADED", function()
    if not FT.IsShown() then return end
    local tab, page = FT.Tabs[FT.currentTab], pages[FT.currentTab]
    if tab and tab.OnItems and page then
        local ok, err = pcall(tab.OnItems, page)
        if not ok then geterrorhandler()(err) end
    else
        FT.Debounce("uiRefresh", 1.5, RefreshVisible)
    end
end)
FT.On("FT_SCAN_START", function()
    if FT.IsShown() then
        FT.UpdateStatus()
        FT.UpdateScanBox()
    end
end)
FT.On("FT_SCAN_FAILED", function() if FT.IsShown() then FT.UpdateStatus() end end)

-- a live price (id), or the auction house opened or closed (nil): the open page's item follows
local function Live(id)
    if not FT.IsShown() then return end
    local tab, page = FT.Tabs[FT.currentTab], pages[FT.currentTab]
    if tab and tab.OnLive and page then
        local ok, err = pcall(tab.OnLive, page, id)
        if not ok then geterrorhandler()(err) end
    end
end
FT.On("FT_LIVE_UPDATED", Live)
FT.On("FT_AH_CHANGED", function()
    if not FT.IsShown() then return end
    FT.UpdateScanBox()
    FT.UpdateAHPill()
    Live(nil)
end)

---------------------------------------------------------------------------
-- In place of the auction house window (Settings): talking to an auctioneer opens ForeverTrading. The game's
-- window stays open behind it, unseen (closing it would end the visit): see-through and off the screen. The
-- pill in the header shows whether you are at the auction house and brings the game's window back for buying
-- and selling (and Auctionator). Walking away ends the visit: the terminal goes "offline".
---------------------------------------------------------------------------
local ahHidden, ahPoints, ahClamped, pill

local function AHFrame()
    return AuctionHouseFrame or AuctionFrame
end

local function OffScreen(f)
    f:SetAlpha(0)
    f:ClearAllPoints()
    f:SetPoint("TOPRIGHT", UIParent, "BOTTOMLEFT", -50, -50)
end

local function HideAHWindow()
    local f = AHFrame()
    if not f or ahHidden then return end
    ahPoints = {}
    for i = 1, f:GetNumPoints() do ahPoints[i] = { f:GetPoint(i) } end
    ahClamped = f.IsClampedToScreen and f:IsClampedToScreen()
    ahHidden = true
    if f.SetClampedToScreen then f:SetClampedToScreen(false) end
    OffScreen(f)
end

local function ShowAHWindow()
    local f = AHFrame()
    if not f or not ahHidden then return end
    ahHidden = false
    f:SetAlpha(1)
    if f.SetClampedToScreen and ahClamped ~= nil then f:SetClampedToScreen(ahClamped) end
    f:ClearAllPoints()
    for _, p in ipairs(ahPoints or {}) do f:SetPoint(unpack(p)) end
    if not (ahPoints and ahPoints[1]) then f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 16, -116) end
end

-- the game puts its windows back in place now and then: ours stays out of sight
local hookedPanels = false
local function HookPanels()
    if hookedPanels or not UpdateUIPanelPositions then return end
    hookedPanels = true
    hooksecurefunc("UpdateUIPanelPositions", function()
        local f = AHFrame()
        if ahHidden and f then OffScreen(f) end
    end)
end

function FT.UpdateAHPill()
    if not pill then return end
    local online = FT.ahOpen and true or false
    -- at an auction house, the other house's prices on: offline here, a yellow light
    local elsewhere = FT.ahHere and not online
    UI.SetTexColor(pill.dot, online and "up" or (elsewhere and "accent" or "dim"), 1)
    UI.SetTextColor(pill.text, online and "up" or (elsewhere and "accent" or "dim"))
    if FT.Compact() then
        pill.text:SetText("")
        pill:SetWidth(25)
    else
        pill.text:SetText(online and L["AH: online"] or L["AH: offline"])
        pill:SetWidth(math.ceil(pill.text:GetStringWidth()) + 30)
    end
end

function FT.BuildAHPill(header)
    pill = CreateFrame("Button", nil, header)
    pill:SetHeight(22)
    pill.bg = UI.RoundTex(pill, "BACKGROUND", "bg2", 1)
    pill.bg:SetAllPoints()
    UI.Border(pill, "line")
    pill.dot = UI.Dot(pill, 7, "dim", 1)
    pill.dot:SetPoint("LEFT", 9, 0)
    pill.text = UI.Text(pill, 11, "dim")
    pill.text:SetPoint("LEFT", pill.dot, "RIGHT", 6, 0)
    pill:SetScript("OnClick", function() FT.ToggleAHWindow() end)
    pill:SetScript("OnEnter", function(self)
        UI.SetTexColor(self.bg, "bg3", 1)
        local H = FT.House
        if FT.ahHere and not FT.ahOpen then
            UI.TipText(self, L["Auction house: offline"], string.format(L["You stand at %s, the prices of %s are on: nothing is read here, bought or posted. The chip next to it switches back."],
                H.Name(FT.atHouse), H.Name()))
        elseif not FT.ahOpen then
            UI.TipText(self, L["Auction house: offline"], L["Talk to an auctioneer. Until then: the last known prices."])
        elseif ahHidden then
            UI.TipText(self, L["Auction house: online"], L["The game's auction house window is hidden behind ForeverTrading. Click: show it (buying, selling, Auctionator)."])
        else
            UI.TipText(self, L["Auction house: online"], L["Click: hide the game's auction house window behind ForeverTrading (Settings: open ForeverTrading in its place)."])
        end
    end)
    pill:SetScript("OnLeave", function(self)
        UI.SetTexColor(self.bg, "bg2", 1)
        GameTooltip:Hide()
    end)
    FT.UpdateAHPill()
    return pill
end

-- Which auction house (House.lua): your faction's or Blackwater - whose prices the pages show. Coloured by it. One
-- in the header, one in every item window: they all follow.
local chips = {}
local HOUSE_COLORS = { Alliance = "blue", Horde = "down", Neutral = "accent" }

local function UpdateChip(c)
    local house = c.get and c.get() or FT.house
    local color = HOUSE_COLORS[FT.House.Faction(house)] or "accent"
    UI.SetTexColor(c.dot, color, 1)
    c.text:SetText(FT.House.Name(house))
    -- the pencil: the header's only (the auction house you stand at is the whole addon's)
    local fix = FT.ahHere == true and not c.own
    c.fix:SetShown(fix)
    c.sep:SetShown(fix)
    c:SetWidth(math.ceil(c.text:GetStringWidth()) + 30 + (fix and 22 or 0))
end

function FT.UpdateHouseChip()
    for _, c in ipairs(chips) do UpdateChip(c) end
end

-- a small pencil drawn with lines
local function Pencil(parent, size)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    f.lines = { UI.NewLine(f, "OVERLAY"), UI.NewLine(f, "OVERLAY"), UI.NewLine(f, "OVERLAY") }
    function f:SetColor(c)
        local sz = self:GetWidth()
        UI.PlaceLine(self.lines[1], sz * 0.30, sz * 0.30, sz * 0.72, sz * 0.72, sz * 0.22, c) -- the body
        UI.PlaceLine(self.lines[2], sz * 0.12, sz * 0.12, sz * 0.27, sz * 0.27, sz * 0.10, c) -- the tip
        UI.PlaceLine(self.lines[3], sz * 0.78, sz * 0.78, sz * 0.90, sz * 0.90, sz * 0.22, c) -- the end
    end
    f:SetColor("muted")
    return f
end

-- opts (an item window's own house): get() - its house, toggle() - to the other; no pencil
function UI.HouseChip(parent, opts)
    local c = CreateFrame("Button", nil, parent)
    opts = opts or {}
    c.get, c.toggle, c.own = opts.get, opts.toggle, opts.get ~= nil
    function c:Update() UpdateChip(self) end
    c:SetHeight(22)
    c.bg = UI.RoundTex(c, "BACKGROUND", "bg2", 1)
    c.bg:SetAllPoints()
    UI.Border(c, "line")
    c.dot = UI.Dot(c, 7, "accent", 1)
    c.dot:SetPoint("LEFT", 9, 0)
    c.text = UI.Text(c, 11, "muted")
    c.text:SetPoint("LEFT", c.dot, "RIGHT", 6, 0)
    c:SetScript("OnClick", function(self)
        if self.toggle then self.toggle() else FT.House.Toggle() end
    end)
    c:SetScript("OnEnter", function(self)
        UI.SetTexColor(self.bg, "bg3", 1)
        local H = FT.House
        local house = self.get and self.get() or FT.house
        local other = H.Name(house == "neutral" and "faction" or "neutral")
        local text
        if self.own then
            text = string.format(L["Whose prices this window shows, whatever the main window and the other windows show. Click: %s."], other)
        else
            text = string.format(L["Whose prices the pages show: your faction's auction house or Blackwater, the neutral one shared by both factions. Each keeps its own prices, history, deals and your auctions. Click: %s."], other)
            if FT.ahHere then
                text = text .. "\n\n" .. string.format(L["You stand at %s: online while its prices are on, offline with the other's."], H.Name(FT.atHouse))
            end
        end
        UI.TipText(self, string.format(L["Auction house: %s"], H.Name(house)), text)
    end)
    c:SetScript("OnLeave", function(self)
        UI.SetTexColor(self.bg, "bg2", 1)
        GameTooltip:Hide()
    end)
    -- at an auctioneer: the pencil - this auction house is the other one
    c.sep = UI.VLine(c, "line")
    c.sep:SetPoint("TOPRIGHT", -22, -4)
    c.sep:SetPoint("BOTTOMRIGHT", -22, 4)
    c.fix = CreateFrame("Button", nil, c)
    c.fix:SetSize(20, 20)
    c.fix:SetPoint("RIGHT", -1, 0)
    c.fix.icon = Pencil(c.fix, 12)
    c.fix.icon:SetPoint("CENTER")
    c.fix:SetScript("OnClick", function() FT.House.Fix() end)
    c.fix:SetScript("OnEnter", function(self)
        self.icon:SetColor("text")
        local H = FT.House
        local here = FT.atHouse or "faction"
        UI.TipText(self, L["Wrong auction house?"], string.format(L["Click if this auctioneer is of %s, not %s: ForeverTrading puts it right and remembers it for the auctioneers here."],
            H.Name(here == "neutral" and "faction" or "neutral"), H.Name(here)))
    end)
    c.fix:SetScript("OnLeave", function(self)
        self.icon:SetColor("muted")
        GameTooltip:Hide()
    end)
    chips[#chips + 1] = c
    UpdateChip(c)
    return c
end

function FT.BuildHouseChip(header)
    return UI.HouseChip(header)
end

FT.On("FT_LOGIN", function() FT.UpdateHouseChip() end)
-- at an auctioneer or not (the pencil), online or not (the pill)
FT.On("FT_AH_CHANGED", function()
    FT.UpdateHouseChip()
    FT.UpdateAHPill()
end)
FT.On("FT_HOUSE_CHANGED", function()
    FT.UpdateHouseChip()
    FT.UpdateAHPill()
    if pill and GameTooltip:IsOwned(pill) then pill:GetScript("OnEnter")(pill) end
    for _, c in ipairs(chips) do
        if GameTooltip:IsOwned(c) then c:GetScript("OnEnter")(c) end
    end
    if FT.IsShown() then
        FT.UpdateScanBox()
        Later()
    end
end)

-- the game's window or ours in front, while you are at the auction house
function FT.ToggleAHWindow()
    if not FT.ahHere then return end
    if ahHidden then
        ShowAHWindow()
    else
        FT.Show()
        HookPanels()
        HideAHWindow()
    end
    if GameTooltip:IsOwned(pill) and pill:GetScript("OnEnter") then pill:GetScript("OnEnter")(pill) end
end

-- the game's window on the screen (when it was hidden behind ForeverTrading)
function FT.ShowGameAH()
    if FT.ahHere and ahHidden then ShowAHWindow() end
end

-- the terminal closed with the game's window hidden: the visit ends (no unseen auction house left open)
function FT.LeaveAH()
    if not (ahHidden and FT.ahHere) then return end
    local f = AHFrame()
    ShowAHWindow()
    if f and HideUIPanel then
        pcall(HideUIPanel, f)
    elseif C_AuctionHouse and C_AuctionHouse.CloseAuctionHouse then
        pcall(C_AuctionHouse.CloseAuctionHouse)
    end
end

-- in place of the game's window: hidden, ours shown
local function Replace()
    if not (FT.ahHere and FT.S.replaceAH) then return end
    -- ours first (made now the first time), then the game's hidden
    FT.Show()
    HookPanels()
    HideAHWindow()
    FT.UpdateAHPill()
end

-- The game (and other addons: Auctionator's tabs...) may put its window back on the screen in the first moments
-- after it opens - the very first time above all, when the game loads it: looked at again for two seconds.
local function KeepReplaced()
    for _, delay in ipairs({ 0.15, 0.4, 0.8, 1.3, 2 }) do
        C_Timer.After(delay, function()
            local f = AHFrame()
            if not (ahHidden and f and FT.ahHere) then return end
            local left = f:GetLeft()
            if f:GetAlpha() > 0.05 or (left and left > -10) then OffScreen(f) end
        end)
    end
end

-- the moment the game shows its window (hooked as soon as the game has loaded it)
local hookedShow = false
local function HookAHShow()
    local f = AHFrame()
    if hookedShow or not f then return end
    hookedShow = true
    f:HookScript("OnShow", function()
        if FT.S.replaceAH then C_Timer.After(0, Replace) end
    end)
end
FT.On("ADDON_LOADED", function(name)
    if name == "Blizzard_AuctionHouseUI" or name == "Blizzard_AuctionUI" then HookAHShow() end
end)
FT.On("FT_READY", HookAHShow)

FT.On("AUCTION_HOUSE_SHOW", function()
    FT.UpdateAHPill()
    HookAHShow()
    if not FT.S.replaceAH then return end
    -- the game shows its window in the same moment: hidden right after, and kept so
    C_Timer.After(0, function()
        Replace()
        KeepReplaced()
    end)
end)

FT.On("AUCTION_HOUSE_CLOSED", function()
    -- the game closed its window: back in place for the next time
    ShowAHWindow()
    FT.UpdateAHPill()
    FT.UpdateHouseChip()
end)
FT.On("FT_MARKET_READY", function()
    if FT.IsShown() then
        FT.UpdateTicker()
        Later()
    end
end)

-- status line ages ("5m ago") even when nothing else happens
C_Timer.NewTicker(30, function() if FT.IsShown() then FT.UpdateStatus() end end)

FT.On("DISPLAY_SIZE_CHANGED", function() if win and SizeMode() == "max" then PlaceWindow() end end)
FT.On("UI_SCALE_CHANGED", function() if win and SizeMode() == "max" then PlaceWindow() end end)
