-- ForeverTrading: minimap button, the button on the auction house, item tooltip lines, alert toasts.
local ADDON, FT = ...
local UI = FT.UI
local L = FT.L

local ICON = "Interface\\Icons\\INV_Misc_Coin_02"

---------------------------------------------------------------------------
-- Minimap button (and a launcher for broker bars when one is loaded)
---------------------------------------------------------------------------
local mb

local function PlaceMinimap()
    local a = math.rad(FT.S.minimapAngle or 205)
    local r = (Minimap:GetWidth() or 140) / 2 + 8
    mb:ClearAllPoints()
    mb:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function MinimapTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cfff0b90bForever|r|cffeaecefTrading|r")
    local last = FT.Hist.LastScan()
    GameTooltip:AddLine(L["Scan"] .. ": " .. (last and FT.Ago(last) or L["never"]), 0.6, 0.64, 0.7)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L["Click: open / close"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Right-click: signals"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Drag: move"], 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

local function BuildMinimap()
    mb = CreateFrame("Button", "ForeverTradingMinimapButton", Minimap)
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFrameLevel(8)
    mb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mb:RegisterForDrag("LeftButton")
    mb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local bg = mb:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(22, 22)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("CENTER")
    local icon = mb:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    icon:SetPoint("CENTER")
    local border = mb:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")
    mb:SetScript("OnClick", function(_, button)
        if button == "RightButton" then FT.Show("signals") else FT.Toggle() end
    end)
    mb:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            FT.S.minimapAngle = math.deg(math.atan2(py / s - my, px / s - mx))
            PlaceMinimap()
        end)
    end)
    mb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    mb:SetScript("OnEnter", MinimapTooltip)
    mb:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function FT.UpdateMinimap()
    if not FT.S.minimap then
        if mb then mb:Hide() end
        return
    end
    if not mb then BuildMinimap() end
    PlaceMinimap()
    mb:Show()
end

local function MakeBroker()
    local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
    if not (ldb and ldb.NewDataObject) then return end
    ldb:NewDataObject("ForeverTrading", {
        type = "launcher", label = "ForeverTrading", text = "ForeverTrading", icon = ICON,
        OnClick = function(_, button)
            if button == "RightButton" then FT.Show("signals") else FT.Toggle() end
        end,
        OnTooltipShow = function(tt)
            if not (tt and tt.AddLine) then return end
            tt:AddLine("ForeverTrading")
            local last = FT.Hist.LastScan()
            tt:AddLine(L["Scan"] .. ": " .. (last and FT.Ago(last) or L["never"]), 0.6, 0.64, 0.7)
        end,
    })
end

---------------------------------------------------------------------------
-- Auction house: a button that opens ForeverTrading right next to it
---------------------------------------------------------------------------
local ahButton
local docked = false

local function AHFrame()
    return AuctionFrame or AuctionHouseFrame
end

local function Dock()
    if FT.WindowMaximized() then return end
    local win = FT.Window()
    local ah = AHFrame()
    if not (win and ah and ah:IsShown()) then return end
    local scale = win:GetEffectiveScale()
    local right = (ah:GetRight() or 0) * ah:GetEffectiveScale()
    local room = GetScreenWidth() * UIParent:GetEffectiveScale() - right
    if room >= win:GetWidth() * scale then
        win:ClearAllPoints()
        win:SetPoint("TOPLEFT", ah, "TOPRIGHT", 6, -2)
        docked = true
    end
end

local function ToggleFromAH()
    if FT.IsShown() then
        FT.Window():Hide()
    else
        FT.Show("market")
        if FT.S.dockAH then Dock() end
    end
end

local function TipAH(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:AddLine("|cfff0b90bForever|r|cffeaecefTrading|r")
    GameTooltip:AddLine(L["Charts, order books, craft profit and signals"], 0.8, 0.8, 0.8, true)
    GameTooltip:Show()
end

-- the text of the button (with how far a scan got)
local function AHLabel()
    local frac = FT.Scanner.Running() and FT.Scanner.Progress()
    return frac and string.format("ForeverTrading  %d%%", math.floor(frac * 100)) or "ForeverTrading"
end

-- The modern auction house: a tab in the row of its tabs, the game's own look. With Auctionator its tab
-- library places it after Auctionator's tabs; without it we put it after the game's last tab.
local function BuildAHTab(ah)
    local tab
    local lib = LibStub and LibStub("LibAHTab-1-0", true)
    if lib and lib.CreateTab then
        local ok = pcall(function()
            if not lib:DoesIDExist("ForeverTrading") then
                local holder = CreateFrame("Frame", nil, ah)
                lib:CreateTab("ForeverTrading", holder, "ForeverTrading")
            end
            tab = lib:GetButton("ForeverTrading")
        end)
        if not ok then tab = nil end
    end
    if not tab then
        local ok, made = pcall(CreateFrame, "Button", "ForeverTradingAHTab", ah, "AuctionHouseFrameDisplayModeTabTemplate")
        if not ok or not made then return nil end
        tab = made
        tab:SetText("ForeverTrading")
        -- after the game's last tab (the template may have put ours in that list already: not after itself)
        local last
        for i = #(ah.Tabs or {}), 1, -1 do
            local t = ah.Tabs[i]
            if t and t ~= tab and t.IsShown and t:IsShown() then
                last = t
                break
            end
        end
        tab:ClearAllPoints()
        if not (last and pcall(tab.SetPoint, tab, "TOPLEFT", last, "TOPRIGHT", 3, 0)) then
            tab:SetPoint("TOPRIGHT", ah, "BOTTOMRIGHT", -4, 2)
        end
    end
    -- it opens our window; it never becomes the auction house's chosen tab
    tab:SetScript("OnClick", function(self)
        ToggleFromAH()
        if PanelTemplates_DeselectTab then PanelTemplates_DeselectTab(self) end
    end)
    tab:HookScript("OnEnter", TipAH)
    tab:HookScript("OnLeave", function() GameTooltip:Hide() end)
    if PanelTemplates_TabResize then PanelTemplates_TabResize(tab, 20, nil, 70) end
    if PanelTemplates_DeselectTab then PanelTemplates_DeselectTab(tab) end
    tab.SetLabel = function(self, text)
        self:SetText(text)
        if PanelTemplates_TabResize then PanelTemplates_TabResize(self, 20, nil, 70) end
    end
    tab.GetLabel = function(self) return self:GetText() end
    return tab
end

-- The classic auction house (or no tab template): our own button
local function BuildAHPlainButton(ah)
    local b = UI.Button(ah, "ForeverTrading", 10, 22, "default", ToggleFromAH)
    b.style = { bg = "bg0", bgA = 0.92, hover = "bg2", hoverA = 1, text = "accent", border = "line" }
    b:SetActive(false)
    b:FitText(24)
    b:SetFrameStrata("HIGH")
    if ah == AuctionFrame then
        b:SetPoint("TOPRIGHT", ah, "TOPRIGHT", -40, -13)
    else
        b:SetPoint("TOPRIGHT", ah, "BOTTOMRIGHT", -4, -2)
    end
    b:SetTip("ForeverTrading", L["Charts, order books, craft profit and signals"])
    local set = b.SetLabel
    b.SetLabel = function(self, text)
        set(self, text)
        self:FitText(24)
    end
    b.GetLabel = function(self) return self.label:GetText() end
    return b
end

local function BuildAHButton()
    local ah = AHFrame()
    if not ah or ahButton then return end
    if ah == AuctionHouseFrame then ahButton = BuildAHTab(ah) end
    ahButton = ahButton or BuildAHPlainButton(ah)
    -- while ForeverTrading scans, the button shows how far it got
    ahButton.ftElapsed = 0
    ahButton:HookScript("OnUpdate", function(self, elapsed)
        self.ftElapsed = self.ftElapsed + elapsed
        if self.ftElapsed < 0.3 then return end
        self.ftElapsed = 0
        local label = AHLabel()
        if self:GetLabel() ~= label then self:SetLabel(label) end
    end)
end

FT.On("AUCTION_HOUSE_SHOW", function()
    -- a moment later: Auctionator adds its tabs first, ours goes after them
    C_Timer.After(0.4, function()
        if not FT.S.ahButton then
            if ahButton then ahButton:Hide() end
            return
        end
        BuildAHButton()
        if ahButton then ahButton:Show() end
    end)
end)

FT.On("AUCTION_HOUSE_CLOSED", function()
    if docked then
        docked = false
        local win = FT.Window()
        if win and win:IsShown() then
            win:Hide()
            FT.ResetWindow()
        end
    end
end)

---------------------------------------------------------------------------
-- Item tooltips
---------------------------------------------------------------------------
local function AddLines(tt, itemID)
    if not (FT.S and FT.S.tooltip and itemID) then return end
    local ok, err = pcall(function()
        local s = FT.An.Stats(itemID)
        local rs = FT.Craft.ByOutput(itemID)
        if not s.price and not rs then return end
        local right = s.price and (FT.Money(s.price, "short") .. "  " .. FT.Pct(s.ch1)) or ""
        tt:AddDoubleLine("|cfff0b90bForever|r|cffeaecefTrading|r", right)
        local parts = {}
        if s.ch7 then parts[#parts + 1] = L["7d"] .. " " .. FT.Pct(s.ch7) end
        if s.rsi then parts[#parts + 1] = "RSI " .. string.format("%.0f", s.rsi) end
        local sig = FT.An.SellSignal(s)
        if sig ~= "NODATA" then
            parts[#parts + 1] = FT.C(FT.SIGNAL_COLORS[sig] or "muted", FT.SignalText(sig))
        end
        if #parts > 0 then tt:AddLine(table.concat(parts, FT.C("dim", "  ||  ")), 0.8, 0.82, 0.86) end
        if rs and rs[1] then
            local e = FT.Craft.Eval(rs[1])
            if e.profit then
                tt:AddLine(string.format(L["Craft: costs %s, profit %s (%d%%)"], FT.Money(e.cost, "short"),
                    FT.C(e.profit >= 0 and "up" or "down", FT.Money(e.profit, "short")),
                    math.floor((e.margin or 0) * 100 + 0.5)), 0.8, 0.82, 0.86)
            end
        end
    end)
    if not ok then FT.Debug(err) end
    tt:Show()
end

local function HookTooltips()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt, data)
            if (tt == GameTooltip or tt == ItemRefTooltip) and data and data.id then AddLines(tt, data.id) end
        end)
        return
    end
    local function OnSet(tt)
        local _, link = tt:GetItem()
        local id = FT.ItemIDFromLink(link)
        if id then AddLines(tt, id) end
    end
    GameTooltip:HookScript("OnTooltipSetItem", OnSet)
    if ItemRefTooltip then ItemRefTooltip:HookScript("OnTooltipSetItem", OnSet) end
end

---------------------------------------------------------------------------
-- Alert toasts
---------------------------------------------------------------------------
local toasts = {}

local function Restack()
    local y = -120
    for _, t in ipairs(toasts) do
        if t:IsShown() then
            t:ClearAllPoints()
            t:SetPoint("TOP", UIParent, "TOP", 0, y)
            y = y - t:GetHeight() - 6
        end
    end
end

local function NewToast()
    local t = CreateFrame("Button", nil, UIParent)
    t:SetSize(360, 56)
    t:SetFrameStrata("FULLSCREEN_DIALOG")
    UI.Fill(t, "bg1")
    UI.Border(t, "line")
    local bar = UI.RoundTex(t, "ARTWORK", "accent", 1, nil, "left", UI.RADIUS - 1)
    bar:SetWidth(3)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("BOTTOMLEFT", 1, 1)
    t.icon = UI.Icon(t, 34)
    t.icon:SetPoint("LEFT", 14, 0)
    t.title = UI.Text(t, 11, "accent")
    t.title:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 10, 0)
    t.title:SetText(L["Price alert"])
    t.text = UI.Text(t, 12, "text")
    t.text:SetPoint("TOPLEFT", t.title, "BOTTOMLEFT", 0, -4)
    t.text:SetPoint("RIGHT", t, "RIGHT", -12, 0)
    t:SetScript("OnClick", function(self)
        if self.itemID then FT.OpenItem(self.itemID) end
        self:Hide()
        Restack()
    end)
    t:SetScript("OnUpdate", function(self, elapsed)
        self.age = (self.age or 0) + elapsed
        if self:IsMouseOver() then
            self.age = math.min(self.age, 6)
            self:SetAlpha(1)
            return
        end
        if self.age > 7 then
            self:SetAlpha(math.max(0, 1 - (self.age - 7)))
            if self.age > 8 then
                self:Hide()
                Restack()
            end
        end
    end)
    return t
end

function FT.Toast(itemID, text)
    UI.ResolveFont()
    local t
    for _, x in ipairs(toasts) do
        if not x:IsShown() then
            t = x
            break
        end
    end
    if not t then
        if #toasts >= 4 then
            t = toasts[1]
            table.remove(toasts, 1)
        else
            t = NewToast()
        end
        toasts[#toasts + 1] = t
    end
    t.itemID = itemID
    t.icon:SetItem(itemID)
    t.text:SetText(FT.ItemText(itemID, 30) .. " " .. text)
    t.age = 0
    t:SetAlpha(1)
    t:Show()
    Restack()
end

---------------------------------------------------------------------------
-- Start and /ft debug
---------------------------------------------------------------------------
FT.On("FT_READY", function()
    UI.ResolveFont()
    FT.UpdateMinimap()
    pcall(MakeBroker)
    pcall(HookTooltips)
end)

function FT.DebugReport()
    FT.Print("side " .. tostring(FT.sideKey) .. ", house " .. tostring(FT.house) .. " (" .. tostring(FT.houseKey)
        .. "), cut " .. string.format("%.1f%%", FT.Cut() * 100) .. ", char " .. tostring(FT.charKey))
    FT.Print("Auctionator " .. tostring(FT.Atr.Loaded()) .. ", days " .. tostring(FT.Atr.HistoryDays()))
    FT.Print("Mastercraft " .. tostring(FT.MC.Loaded()) .. ", last scan " .. tostring(FT.MC.LastScan()))
    local tsmT = FT.TSM.RealmTime()
    FT.Print("TSM " .. tostring(FT.TSM.Loaded()) .. ", realm data " .. (tsmT and FT.Ago(tsmT) or "?")
        .. ", imported " .. tostring(FT.R().meta.tsmImport and FT.Ago(FT.R().meta.tsmImport) or "never"))
    FT.Print("recipes " .. #FT.Craft.List() .. ", tracked " .. FT.Hist.UniverseSize())
    -- recipes by profession: how many the Craft page has, how many ForeverTrading read itself (Mastercraft: the rest)
    local all, own = {}, {}
    for _, r in ipairs(FT.Craft.List()) do all[r.prof] = (all[r.prof] or 0) + 1 end
    for _, profs in pairs(FT.db.recipes or {}) do
        for prof, data in pairs(type(profs) == "table" and profs or {}) do
            local n = type(data) == "table" and type(data.list) == "table" and #data.list or 0
            own[prof] = (own[prof] or 0) + n
            all[prof] = all[prof] or 0
        end
    end
    local parts = {}
    for prof, n in pairs(all) do parts[#parts + 1] = string.format("%s %d (own %d)", L[prof] or prof, n, own[prof] or 0) end
    table.sort(parts)
    FT.Print("by profession: " .. table.concat(parts, ", "))
    local items, size = FT.Hist.Footprint()
    FT.Print("history items " .. items .. ", saved " .. size .. " chars, font " .. tostring(UI.FONT))
    local rows = FT.Market.Rows()
    FT.Print("market rows " .. tostring(rows and #rows) .. (FT.Market.Building() and ", building" or "")
        .. ((FT.Market.errors or 0) > 0 and (", errors " .. FT.Market.errors .. " (" .. tostring(FT.Market.firstError) .. ")") or ""))
    -- the good deals: what the last look saw
    local list, at, building = FT.Deals.List()
    local info = FT.Deals.Info()
    local kinds = {}
    for _, d in ipairs(list) do kinds[d.kind] = (kinds[d.kind] or 0) + 1 end
    FT.Print(string.format("deals %d (vendor %d, resell %d, between houses %d), looked %s%s", #list, kinds.VENDOR or 0,
        kinds.RESELL or 0, kinds.HOUSES or 0, at and FT.Ago(at) or "never", building and ", looking now" or ""))
    if info then
        FT.Print(string.format("deals: items %d, newest price %s, 3+ days %d, under the minimum %d, vendor prices to load %d, errors %d%s",
            info.items, FT.Ago(info.newest), info.history, info.small, FT.Deals.Loading(), info.errors,
            info.firstError and (" (" .. info.firstError .. ")") or ""))
    end
    FT.Print(FT.Scanner.LiveState())
end

---------------------------------------------------------------------------
-- A link to copy (the game can't open a browser): support the author, the project on GitHub
---------------------------------------------------------------------------
local linkDialog

local function LinkDialog()
    if linkDialog then return linkDialog end
    UI.ResolveFont()
    local d = CreateFrame("Frame", "ForeverTradingLinkDialog", UIParent)
    d:SetSize(440, 150)
    d:SetPoint("CENTER", 0, 120)
    d:SetFrameStrata("FULLSCREEN_DIALOG")
    d:SetToplevel(true)
    d:EnableMouse(true)
    d:SetMovable(true)
    d:RegisterForDrag("LeftButton")
    d:SetScript("OnDragStart", d.StartMoving)
    d:SetScript("OnDragStop", d.StopMovingOrSizing)
    UI.Fill(d, "bg1")
    UI.Border(d, "line")
    local bar = UI.RoundTex(d, "ARTWORK", "accent", 1, nil, "top", UI.RADIUS - 1)
    bar:SetHeight(2)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    d.title = UI.Text(d, 14, "text")
    d.title:SetPoint("TOPLEFT", 16, -16)
    d.body = UI.Text(d, 11, "muted")
    d.body:SetPoint("TOPLEFT", 16, -40)
    d.body:SetPoint("RIGHT", d, "RIGHT", -16, 0)
    d.input = UI.Input(d, 408, 26, "")
    d.input:SetPoint("TOPLEFT", 16, -64)
    -- read only: whatever is typed, the link comes back, selected
    d.input:SetScript("OnTextChanged", function(self, user)
        if user then
            self:SetText(d.url or "")
            self:HighlightText()
        end
    end)
    d.input:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    d.input:SetScript("OnEscapePressed", function() d:Hide() end)
    d.input:SetScript("OnEnterPressed", function() d:Hide() end)
    d.hint = UI.Text(d, 11, "dim")
    d.hint:SetPoint("TOPLEFT", 16, -100)
    d.hint:SetText(L["Ctrl+C to copy"])
    d.close = UI.Button(d, L["Close"], 10, 24, "default", function() d:Hide() end)
    d.close:FitText(28)
    d.close:SetPoint("BOTTOMRIGHT", -16, 14)
    tinsert(UISpecialFrames, "ForeverTradingLinkDialog")
    d:Hide()
    linkDialog = d
    return d
end

function FT.ShowLink(title, body, url)
    local d = LinkDialog()
    d.url = url
    d.title:SetText(title)
    d.body:SetText(body)
    d.input:SetText(url)
    d:Show()
    d:Raise()
    d.input:SetFocus()
    d.input:HighlightText()
end

function FT.ShowSupport()
    FT.ShowLink(L["Support ForeverTrading"], L["If the addon is useful to you - thank you for your support! Copy the link and open it in your browser:"],
        FT.URL_SUPPORT)
end

function FT.ShowGitHub()
    FT.ShowLink(L["ForeverTrading on GitHub"], L["Source code, releases and bug reports. Copy the link and open it in your browser:"],
        FT.URL_GITHUB)
end
