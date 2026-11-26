-- ForeverTrading: Market page - every item with its price and moves, the chart of one item, its order
-- book, indicators, signals and price alerts. With no item chosen: the market overview.
local ADDON, FT = ...
local UI = FT.UI
local L = FT.L

local T = {}
FT.Tabs.market = T

-- open: under "My recipes", the item whose materials are shown under it
local state = { filter = "all", cls = "all", sub = "all", sort = "cap", desc = true, search = "", selected = nil, open = nil }
-- the auction house's own filters: required level, usable, not collected, quality
local QUALITIES = { 0, 1, 2, 3, 4, 5 }
local filt = { min = nil, max = nil, usable = false, uncollected = false, quality = {} }
for _, q in ipairs(QUALITIES) do filt.quality[q] = true end

local function FiltersOn()
    if filt.min or filt.max or filt.usable or filt.uncollected then return true end
    for _, q in ipairs(QUALITIES) do
        if not filt.quality[q] then return true end
    end
    return false
end

-- the game's own "can this character use it" (armor and weapon skills, class); without it only the level counts
local CanUse = C_PlayerInfo and C_PlayerInfo.CanUseItem
local Transmog = C_TransmogCollection
local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

-- collected: true / false; nil when it isn't something to collect (an appearance, a toy)
local function Collected(id)
    if PlayerHasToy and C_ToyBox and C_ToyBox.GetToyInfo and C_ToyBox.GetToyInfo(id) then return PlayerHasToy(id) end
    if Transmog and Transmog.PlayerHasTransmog then
        local equip = GetInstant and select(4, GetInstant(id))
        if equip and equip ~= "" and equip ~= "INVTYPE_NON_EQUIP_IGNORE" and equip ~= "INVTYPE_BAG" then
            local ok, has = pcall(Transmog.PlayerHasTransmog, id)
            if ok then return has and true or false end
        end
    end
    return nil
end

-- the "not collected" filter only where the game keeps collections
local function CanCollect()
    return (Transmog and Transmog.PlayerHasTransmog) ~= nil or PlayerHasToy ~= nil
end

-- an item passes the filters (what the game hasn't loaded yet passes the level and usable ones)
local function PassFilters(id)
    local q, lvl = FT.ItemFacts(id)
    if q and filt.quality[q] == false then return false end
    if lvl then
        if filt.min and lvl < filt.min then return false end
        if filt.max and lvl > filt.max then return false end
    end
    if filt.usable then
        if lvl and lvl > (UnitLevel("player") or 0) then return false end
        if CanUse and FT.ItemCached(id) then
            local ok, usable = pcall(CanUse, id)
            if ok and usable == false then return false end
        end
    end
    if filt.uncollected and Collected(id) ~= false then return false end
    return true
end
local page, list, countText, overview, itemView, book, center, mats
local LEFT_W, RIGHT_W = 372, 232
local CARDS_H = 118 -- the indicator, signal and alert cards under the charts

local GetClassInfo = (C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo
local GetSubClassInfo = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo
local CLASSES = { 7, 0, 9, 5, 4, 2, 15, 1 }
local CLASS_FALLBACK = { [7] = "Trade goods", [0] = "Consumables", [9] = "Recipes", [5] = "Reagents", [4] = "Armor",
    [2] = "Weapons", [15] = "Miscellaneous", [1] = "Containers" }
local KNOWN = {}
for _, c in ipairs(CLASSES) do KNOWN[c] = true end

local function ClassName(id)
    local name = GetClassInfo and GetClassInfo(id)
    return (name and name ~= "") and name or L[CLASS_FALLBACK[id] or "Other"]
end

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------
-- what your recipes make (their materials show under an item when you open it)
local function RecipeOutputs()
    local set = {}
    for _, r in ipairs(FT.Craft.List()) do set[r.output] = true end
    return set
end

local SOURCE_TAG = { ah = "AH", vendor = "vendor", ["vendor~"] = "vendor~", craft = "craft" }

-- the materials of one craft of the item, as rows under it: each at its cheapest (auction house, vendor,
-- your own craft), with the market's moves when it has them
local function MaterialRows(id)
    local r = FT.Craft.Best(id)
    if not r then return {} end
    local kids = {}
    for _, part in ipairs(FT.Craft.Eval(r).parts or {}) do
        if part.itemID then
            local m = FT.Market.Row(part.itemID)
            kids[#kids + 1] = {
                id = part.itemID, child = true, parent = id, qty = part.qty, unit = part.unit, source = part.source,
                price = part.unit or (m and m.price), ch1 = m and m.ch1, ch7 = m and m.ch7, spark = m and m.spark or {},
            }
        end
    end
    return kids
end

local SORTS = {
    cap = function(r) return r.price * (r.qty or 0) end,
    price = function(r) return r.price end,
    ch1 = function(r) return r.ch1 end,
    ch7 = function(r) return r.ch7 end,
    qty = function(r) return r.qty end,
}

local function Filtered()
    local rows = FT.Market.Rows()
    if not rows then return nil end
    local out = {}
    -- "name" in quotes: that name exactly (not the recipes for it and such); otherwise a part of the name
    local matches = FT.NameMatcher(state.search)
    local mine = state.filter == "mine" and RecipeOutputs() or nil
    local filtersOn = FiltersOn()
    local holdings = state.filter == "bags" and FT.Port.Holdings() or nil
    for _, r in ipairs(rows) do
        local ok = true
        local f = state.filter
        if f == "fav" then
            ok = FT.db.watch[r.id] ~= nil
        elseif f == "mine" then
            ok = mine[r.id] == true
        elseif f == "bags" then
            ok = holdings[r.id] ~= nil
        elseif f == "up" then
            ok = r.ch1 ~= nil and r.ch1 > 0.001
        elseif f == "down" then
            ok = r.ch1 ~= nil and r.ch1 < -0.001
        end
        if ok and state.cls ~= "all" then
            if state.cls == "other" then ok = not KNOWN[r.cls] else ok = r.cls == state.cls end
        end
        if ok and state.sub ~= "all" then ok = r.sub == state.sub end
        if ok and filtersOn then ok = PassFilters(r.id) end
        if ok and matches then ok = matches(r.id) end
        if ok then out[#out + 1] = r end
    end
    local key, desc = state.sort, state.desc
    if key == "name" then
        local names = {}
        for _, r in ipairs(out) do names[r.id] = FT.Fold(FT.Name(r.id) or "~") end
        table.sort(out, function(a, b)
            if names[a.id] ~= names[b.id] then
                if desc then return names[a.id] > names[b.id] end
                return names[a.id] < names[b.id]
            end
            return a.id < b.id
        end)
    else
        local get = SORTS[key] or SORTS.cap
        local missing = desc and -math.huge or math.huge
        table.sort(out, function(a, b)
            local va, vb = get(a) or missing, get(b) or missing
            if va ~= vb then
                if desc then return va > vb end
                return va < vb
            end
            return a.id < b.id
        end)
    end
    -- My recipes: the open item's materials under it
    local count = #out
    if mine and state.open then
        for i, r in ipairs(out) do
            if r.id == state.open then
                for k, kid in ipairs(MaterialRows(r.id)) do table.insert(out, i + k, kid) end
                break
            end
        end
    end
    return out, count
end

-- names the game hasn't loaded yet, asked for a few at a time while you search (no flood of requests)
local loader
function T.LoadMissingNames()
    if loader then return end
    local missing = {}
    for _, r in ipairs(FT.Market.Rows() or {}) do
        if not FT.Name(r.id) then missing[#missing + 1] = r.id end
    end
    if #missing == 0 then return end
    local i = 1
    loader = C_Timer.NewTicker(0.5, function()
        if (state.search == "" and not FiltersOn()) or i > #missing then
            loader:Cancel()
            loader = nil
            return
        end
        for k = i, math.min(i + 39, #missing) do FT.RequestItem(missing[k]) end
        i = i + 40
    end)
end

-- names arrived: the rows on screen show them; a search takes the new matches in now and then
function T.OnItems()
    -- an item opened from elsewhere before the game had its name: now it goes in the search box
    local id = state.focusFor
    local name = id and state.search == "" and FT.Name(id)
    if name then
        state.focusFor = nil
        state.search = '"' .. name .. '"'
        if T.searchBox then T.searchBox:SetValue(state.search) end
        T.RefreshList()
        return
    end
    if list then list:Refresh() end
    if state.search ~= "" or FiltersOn() then
        FT.Debounce("marketSearchMore", 1.5, function() T.RefreshList(true) end)
    end
end

-- the subcategories of the chosen category that are on the market, with how many items each
local function UpdateSubs()
    local dd = T.subDD
    if not dd then return end
    local opts = { { "all", L["All subcategories"] } }
    local real = state.cls ~= "all" and state.cls ~= "other"
    if real then
        local counts = {}
        for _, r in ipairs(FT.Market.Rows() or {}) do
            if r.cls == state.cls and r.sub then counts[r.sub] = (counts[r.sub] or 0) + 1 end
        end
        local subs = {}
        for sub, n in pairs(counts) do
            local name = GetSubClassInfo and GetSubClassInfo(state.cls, sub)
            subs[#subs + 1] = { sub, (name and name ~= "") and name or ("#" .. sub), n }
        end
        table.sort(subs, function(a, b) return a[2] < b[2] end)
        for _, s in ipairs(subs) do opts[#opts + 1] = { s[1], s[2] .. FT.C("dim", "  " .. FT.Num(s[3])) } end
    end
    dd:SetOptions(opts)
    local found = false
    for _, o in ipairs(opts) do
        if o[1] == state.sub then found = true end
    end
    if not found then state.sub = "all" end
    dd:SetValue(state.sub)
    UI.SetTextColor(dd.label, real and "text" or "dim")
end

function T.RefreshList(keepOffset)
    if not list then return end
    UpdateSubs()
    local items, count = Filtered()
    if not items then
        list:SetEmptyText(FT.Market.Building() and L["Reading the market..."] or
            L["No market data yet: open the auction house and press Full scan."])
        list:SetItems({}, keepOffset)
        countText:SetText("")
        return
    end
    list:SetEmptyText(L["Nothing matches"])
    list:SetItems(items, keepOffset)
    countText:SetText(string.format(L["%s items"], FT.Num(count)))
end

-- My recipes: open an item's materials under it (again: close them)
local function ToggleOpen(id)
    state.open = state.open ~= id and id or nil
    T.RefreshList(true)
    if not (state.open and list) then return end
    for i, x in ipairs(list.items) do
        if x.id == id and not x.child then
            -- its materials in sight, the item too
            local last = i
            while list.items[last + 1] and list.items[last + 1].child do last = last + 1 end
            list:ScrollTo(last)
            list:ScrollTo(i)
            break
        end
    end
end

local function NameCell(row)
    local f = CreateFrame("Frame", nil, row)
    f:SetHeight(24)
    -- My recipes: an arrow to open the materials
    f.chev = UI.Chevron(f, 8, "muted")
    f.chev:SetPoint("LEFT", 2, 0)
    f.chev:Hide()
    f.icon = UI.Icon(f, 18)
    f.icon:SetPoint("LEFT", 0, 0)
    f.star = UI.Text(f, 11, "accent")
    f.star:SetPoint("LEFT", f.icon, "RIGHT", 5, 0)
    f.text = UI.Text(f, 12, "text")
    f.text:SetPoint("LEFT", f.icon, "RIGHT", 6, 0)
    f.text:SetPoint("RIGHT", 0, 0)
    return f
end

local function SparkCell(row)
    local s = UI.Sparkline(row, 40, 16)
    return s
end

local function BuildList(parent)
    local panel = UI.Panel(parent, "bg1", "line")
    T.listPanel = panel
    panel:SetPoint("TOPLEFT", 8, -8)
    panel:SetPoint("BOTTOMLEFT", 8, 8)
    panel:SetWidth(LEFT_W)

    -- the filters: a grid of four columns, rows of one height, one gap between them all
    local IW, GAP, RH = LEFT_W - 20, 6, 20
    local CW = math.floor((IW - 3 * GAP) / 4)
    local function Cell(col, span) return 10 + (col - 1) * (CW + GAP), span * CW + (span - 1) * GAP end
    local search = UI.Input(panel, IW - 84, 24, L["Search item..."], function(text)
        state.search = text or ""
        state.focusFor = nil
        FT.Debounce("marketSearch", 0.25, function()
            T.RefreshList()
            if state.search ~= "" then T.LoadMissingNames() end
        end)
    end)
    search:SetPoint("TOPLEFT", 10, -10)
    T.searchBox = search
    T.filterBtn = UI.Button(panel, L["Filter"], 78, 24, "default", function(self) T.ToggleFilters(self) end)
    T.filterBtn:SetPoint("LEFT", search, "RIGHT", 6, 0)
    T.filterBtn:SetTip(L["Filter"], L["Required level, usable, not collected, quality - as on the auction house."])
    panel:HookScript("OnHide", function() if T.filterPanel then T.filterPanel:Hide() end end)
    -- × : the whole list again, the item you have open still in sight
    UI.ClearButton(search, function()
        state.search, state.focusFor = "", nil
        T.RefreshList()
        T.ShowSelectedInList()
    end)

    local chips = {}
    local function Chip(key, label)
        local c = UI.Chip(panel, label, function()
            state.filter = key
            for _, ch in ipairs(chips) do ch:SetOn(ch.key == key) end
            T.RefreshList()
        end)
        c.key = key
        chips[#chips + 1] = c
        return c
    end
    local row1 = { Chip("all", L["All"]), Chip("fav", L["Watchlist"]), Chip("mine", L["My recipes"]),
        Chip("bags", L["I own"]) }
    local row2 = { Chip("up", L["Rising"]), Chip("down", L["Falling"]) }
    local Y1, Y2, Y3 = -42, -42 - RH - GAP, -42 - 2 * (RH + GAP)
    for i, c in ipairs(row1) do
        local x, w = Cell(i, 1)
        c:SetSize(w, RH)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", x, Y1)
    end
    for i, c in ipairs(row2) do
        local x, w = Cell(i, 1)
        c:SetSize(w, RH)
        c:ClearAllPoints()
        c:SetPoint("TOPLEFT", x, Y2)
    end
    for _, c in ipairs(chips) do c:SetOn(c.key == state.filter) end
    T.chips = chips

    local clsOptions = { { "all", L["All categories"] } }
    for _, c in ipairs(CLASSES) do clsOptions[#clsOptions + 1] = { c, ClassName(c) } end
    clsOptions[#clsOptions + 1] = { "other", L["Other"] }
    -- what kind: the category and its subcategory side by side (the row under the chips)
    local half = select(2, Cell(1, 2))
    local cls = UI.Dropdown(panel, half, clsOptions, function(v)
        state.cls, state.sub = v, "all"
        T.RefreshList()
    end)
    cls:SetHeight(RH)
    cls:SetPoint("TOPLEFT", Cell(1, 2), Y3)
    cls:SetValue("all")
    T.clsDD = cls

    local sortOptions = {
        { "cap", L["Sort: market value"] }, { "ch1", L["Sort: 24h change"] }, { "ch7", L["Sort: 7d change"] },
        { "price", L["Sort: price"] }, { "qty", L["Sort: listed"] }, { "name", L["Sort: name"] },
    }
    local sortDD = UI.Dropdown(panel, half, sortOptions, function(v)
        state.sort = v
        state.desc = v ~= "name"
        T.header:SetSort(v, state.desc)
        T.RefreshList()
    end)
    -- the order: on the right of the rising / falling chips
    sortDD:SetHeight(RH)
    sortDD:SetPoint("TOPLEFT", Cell(3, 2), Y2)
    sortDD:SetValue(state.sort)
    T.sortDD = sortDD
    -- the subcategory of the chosen category (armor: cloth, leather...; trade goods: cloth, metal...)
    local subDD = UI.Dropdown(panel, half, { { "all", L["All subcategories"] } }, function(v)
        state.sub = v
        T.RefreshList()
    end)
    subDD:SetHeight(RH)
    subDD:SetPoint("TOPLEFT", Cell(3, 2), Y3)
    subDD:SetValue("all")
    T.subDD = subDD
    countText = UI.Text(panel, 11, "dim", "RIGHT")
    countText:SetPoint("BOTTOMRIGHT", -12, 6)

    local cols = {
        { key = "name", title = L["Item"], width = "fill", sort = "name", make = NameCell, cellHeight = 24 },
        { key = "price", title = L["Price"], width = 70, justify = "RIGHT", sort = "price" },
        { key = "ch1", title = L["24h"], width = 52, justify = "RIGHT", sort = "ch1" },
        { key = "spark", title = L["7d"], width = 40, justify = "RIGHT", sort = "ch7", make = SparkCell, cellHeight = 16 },
    }
    T.header = UI.Header(panel, cols, function(key)
        if state.sort == key then
            state.desc = not state.desc
        else
            state.sort, state.desc = key, key ~= "name"
        end
        T.header:SetSort(state.sort, state.desc)
        T.sortDD:SetValue(state.sort)
        T.RefreshList()
    end)
    T.header:SetPoint("TOPLEFT", 1, Y3 - RH - 8)
    T.header:SetPoint("TOPRIGHT", -1, Y3 - RH - 8)
    T.header:SetSort(state.sort, state.desc)

    list = UI.List(panel, {
        rowHeight = 26,
        cols = cols,
        liveID = function(r) return r.id end,
        update = function(row, r)
            local cell = row.cells.name
            -- My recipes: the items with an arrow, their materials indented under them
            local indent = 0
            if state.filter == "mine" then
                if r.child then
                    indent = 30
                    cell.chev:Hide()
                else
                    indent = 14
                    local open = state.open == r.id
                    cell.chev:Show()
                    cell.chev:SetDir(open and "down" or "right", open and "accent" or "muted")
                end
            else
                cell.chev:Hide()
            end
            cell.icon:ClearAllPoints()
            cell.icon:SetPoint("LEFT", indent, 0)
            cell.icon:SetItem(r.id)
            local watched = FT.db.watch[r.id] ~= nil
            cell.star:SetText(watched and "*" or "")
            cell.text:ClearAllPoints()
            cell.text:SetPoint("LEFT", cell.icon, "RIGHT", watched and 14 or 6, 0)
            cell.text:SetPoint("RIGHT", cell, "RIGHT", 0, 0)
            if r.child then
                cell.text:SetText(FT.ItemText(r.id) .. FT.C("dim", " x" .. r.qty))
            else
                cell.text:SetText(FT.ItemText(r.id))
            end
            row.cells.price:SetText(FT.Money(r.price, "short"))
            row.cells.ch1:SetText(FT.Pct(r.ch1))
            local color = (r.ch7 and r.ch7 < 0) and "down" or ((r.ch7 and r.ch7 > 0) and "up" or "muted")
            row.cells.spark:SetValues(r.spark, color)
        end,
        isSelected = function(r) return r.id == state.selected end,
        onClick = function(r, button)
            if UI.ItemClick(r.id) then return end
            if button == "RightButton" then
                FT.Market.ToggleWatch(r.id)
                return
            end
            T.Select(r.id)
            if state.filter == "mine" and not r.child then ToggleOpen(r.id) end
        end,
        onEnter = function(row, r)
            GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
            if GameTooltip.SetItemByID then GameTooltip:SetItemByID(r.id) end
            GameTooltip:AddLine(" ")
            if r.child then
                -- a material: how many one craft takes and where it is cheapest
                GameTooltip:AddLine(string.format(L["%s per craft of %s"], "x" .. r.qty, FT.ItemText(r.parent)), 0.85, 0.87, 0.9)
                if r.unit then
                    local tag = r.source and L[SOURCE_TAG[r.source] or r.source] or ""
                    GameTooltip:AddLine(FT.Money(r.unit) .. "  " .. FT.C("dim", tag) .. "  =  " .. FT.Money(r.unit * r.qty), 0.85, 0.87, 0.9)
                end
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(L["Click: chart || Right-click: watchlist || Shift-click: link"], 0.52, 0.56, 0.61)
            elseif state.filter == "mine" then
                GameTooltip:AddLine(L["Click: chart and materials || Right-click: watchlist || Shift-click: link"], 0.52, 0.56, 0.61)
            else
                GameTooltip:AddLine(L["Click: chart || Right-click: watchlist || Shift-click: link"], 0.52, 0.56, 0.61)
            end
            GameTooltip:Show()
        end,
    })
    list:SetPoint("TOPLEFT", T.header, "BOTTOMLEFT", 0, -2)
    list:SetPoint("BOTTOMRIGHT", -1, 22)
    return panel
end

---------------------------------------------------------------------------
-- Overview (no item chosen)
---------------------------------------------------------------------------
local function MoverList(parent, title)
    local box = UI.Panel(parent, "bg1", "line")
    box.title = UI.Text(box, 12, "text")
    box.title:SetPoint("TOPLEFT", 12, -10)
    box.title:SetText(title)
    local cols = {
        { key = "name", title = "", width = "fill", make = NameCell, cellHeight = 24 },
        { key = "price", title = "", width = 74, justify = "RIGHT" },
        { key = "ch", title = "", width = 60, justify = "RIGHT" },
    }
    box.list = UI.List(box, {
        rowHeight = 24, cols = cols,
        update = function(row, r)
            local cell = row.cells.name
            cell.icon:SetItem(r.id)
            cell.star:SetText("")
            cell.text:SetText(FT.ItemText(r.id))
            row.cells.price:SetText(FT.Money(r.price, "short"))
            row.cells.ch:SetText(FT.Pct(r.ch1))
        end,
        onClick = function(r) if not UI.ItemClick(r.id) then T.Select(r.id) end end,
        onEnter = function(row, r) UI.TipItem(row, r.id) end,
    })
    box.list:SetPoint("TOPLEFT", 1, -32)
    box.list:SetPoint("BOTTOMRIGHT", -1, 4)
    return box
end

local function BuildOverview(parent)
    local v = CreateFrame("Frame", nil, parent)
    v:SetAllPoints()
    v.title = UI.Text(v, 18, "text")
    v.title:SetPoint("TOPLEFT", 4, -6)
    v.title:SetText(L["Market overview"])
    v.hint = UI.Text(v, 11, "dim")
    v.hint:SetPoint("LEFT", v.title, "RIGHT", 12, -1)
    v.hint:SetText(L["Pick an item on the left to see its chart"])

    v.cards = {}
    local titles = { L["Items on the market"], L["Listed value"], L["Market mood"], L["Last scan"] }
    for i, t in ipairs(titles) do
        local c = UI.Stat(v, t)
        c:SetHeight(70)
        v.cards[i] = c
    end
    v.moodBar = CreateFrame("Frame", nil, v.cards[3])
    v.moodBar:SetHeight(3)
    v.moodBar:SetPoint("BOTTOMLEFT", 10, 6)
    v.moodBar:SetPoint("BOTTOMRIGHT", -10, 6)
    UI.Fill(v.moodBar, "bg3", nil, "none")
    v.moodFill = UI.Tex(v.moodBar, "ARTWORK", "up", 1)
    v.moodFill:SetPoint("TOPLEFT")
    v.moodFill:SetPoint("BOTTOMLEFT")

    v.chartTitle = UI.Text(v, 12, "text")
    v.chartTitle:SetText(L["Value listed on the auction house, by scan"])
    v.chart = UI.Chart(v)
    v.gainers = MoverList(v, L["Top gainers 24h"])
    v.losers = MoverList(v, L["Top losers 24h"])

    UI.OnSize(v, function(self, w, h)
        local cw = (w - 3 * 8) / 4
        for i, c in ipairs(self.cards) do
            c:ClearAllPoints()
            c:SetPoint("TOPLEFT", (i - 1) * (cw + 8), -34)
            c:SetWidth(cw)
        end
        self.chartTitle:ClearAllPoints()
        self.chartTitle:SetPoint("TOPLEFT", 4, -116)
        self.chart:ClearAllPoints()
        self.chart:SetPoint("TOPLEFT", 0, -134)
        self.chart:SetPoint("TOPRIGHT", 0, -134)
        local listsH = math.max(180, math.floor(h * 0.36))
        self.chart:SetPoint("BOTTOM", 0, listsH + 8)
        local half = (w - 8) / 2
        self.gainers:ClearAllPoints()
        self.gainers:SetPoint("BOTTOMLEFT", 0, 0)
        self.gainers:SetSize(half, listsH)
        self.losers:ClearAllPoints()
        self.losers:SetPoint("BOTTOMRIGHT", 0, 0)
        self.losers:SetSize(half, listsH)
    end)
    return v
end

function T.ShowOverview()
    if not overview then return end
    itemView:Hide()
    overview:Show()
    book:SetItem(nil)
    T.LayoutRight()
    local rows = FT.Market.Rows()
    overview.cards[1]:Set(rows and FT.Num(#rows) or "—", rows and L["seen in scans"] or L["no data"])
    local scans = FT.R().scans
    local lastScan = scans[#scans]
    if lastScan then
        local prev = scans[#scans - 1]
        local ch = prev and prev.value and prev.value > 0 and (lastScan.value / prev.value - 1) or nil
        overview.cards[2]:Set(FT.Money(lastScan.value, "short"), string.format(L["%s auctions"], FT.Num(lastScan.auctions))
            .. "  " .. FT.Pct(ch))
    else
        overview.cards[2]:Set("—", L["after a full scan"])
    end
    local mood, counted = FT.Market.Mood()
    local moodText, moodColor = FT.Market.MoodText(mood)
    overview.cards[3]:Set(mood and (FT.C(moodColor, mood) .. "  " .. FT.C(moodColor, moodText)) or "—",
        mood and string.format(L["%d%% of %d liquid items rose this week"], mood, counted) or L["needs a few days of prices"])
    if mood then
        overview.moodFill:Show()
        overview.moodFill:SetWidth(math.max(1, overview.moodBar:GetWidth() * mood / 100))
        UI.SetTexColor(overview.moodFill, moodColor, 1)
    else
        overview.moodFill:Hide()
    end
    local last = FT.Hist.LastScan()
    overview.cards[4]:Set(last and FT.Ago(last) or "—", last and date("%d.%m %H:%M", last) or L["press Full scan at the auction house"])

    local points = {}
    for _, s in ipairs(scans) do
        if s.value and s.value > 0 then points[#points + 1] = { t = s.t, value = s.value } end
    end
    overview.chart:SetData({
        candles = UI.LineCandles(points), mode = "line", hourly = true, lineColor = "accent", tagColor = "accent",
        fmt = function(v) return FT.Thousands(v / 10000) .. FT.COIN.gold end,
        emptyTitle = L["No full scans yet"],
        emptyBody = L["Each full scan (yours or Auctionator's) adds a point: the total buyout of everything listed."],
    })
    overview.gainers.list:SetItems(FT.Market.Movers(20, "ch1", true))
    overview.losers.list:SetItems(FT.Market.Movers(20, "ch1", false))
end

---------------------------------------------------------------------------
-- One item
---------------------------------------------------------------------------
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

local function Card(parent, title)
    local c = UI.Panel(parent, "bg1", "line")
    c.title = UI.Text(c, 11, "muted")
    c.title:SetPoint("TOPLEFT", 10, -8)
    c.title:SetText(title)
    return c
end

local function BuildItemView(parent)
    local v = CreateFrame("Frame", nil, parent)
    v:SetAllPoints()

    -- head: icon, name, price, change
    v.icon = UI.Icon(v, 38)
    v.icon:SetPoint("TOPLEFT", 2, -4)
    v.icon:EnableMouse(true)
    v.icon:SetScript("OnEnter", function(self) UI.TipItem(self, state.selected) end)
    v.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    v.name = UI.Text(v, 16, "text")
    v.name:SetPoint("TOPLEFT", v.icon, "TOPRIGHT", 10, -1)
    v.sub = UI.Text(v, 11, "dim")
    v.sub:SetPoint("TOPLEFT", v.name, "BOTTOMLEFT", 0, -5)
    v.back = UI.Button(v, "×", 24, 24, "ghost", function() T.ClearSelection() end)
    v.back.label:SetFont(UI.FONT, 16, "")
    v.back:SetPoint("TOPRIGHT", 0, -2)
    v.back:SetTip(L["Back to the market overview"])
    v.change = UI.Text(v, 14, "text", "RIGHT")
    v.change:SetPoint("TOPRIGHT", -30, -6)
    v.price = UI.Text(v, 22, "text", "RIGHT")
    v.price:SetPoint("RIGHT", v.change, "LEFT", -12, -1)
    v.priceAge = UI.Text(v, 10, "dim", "RIGHT")
    v.priceAge:SetPoint("TOPRIGHT", -30, -28)
    -- the countdown to its next live search
    v.ring = UI.LiveRingFor(v, 9, function() return state.selected end)
    v.ring:SetPoint("RIGHT", v.priceAge, "LEFT", -5, 0)

    -- stats strip
    v.strip = UI.Panel(v, "bg1", "line")
    v.strip:SetPoint("TOPLEFT", 0, -50)
    v.strip:SetPoint("TOPRIGHT", 0, -50)
    v.strip:SetHeight(42)
    local pairsDef = {
        { "hi7", L["7d high"] }, { "lo7", L["7d low"] }, { "avg", L["Average"] }, { "hi30", L["30d high"] },
        { "lo30", L["30d low"] }, { "listed", L["Listed"] }, { "auctions", L["Auctions"] }, { "sellers", L["Sellers"] },
    }
    v.pairs = {}
    for i, d in ipairs(pairsDef) do
        local p = StatPair(v.strip, d[2])
        p.key = d[1]
        v.pairs[i] = p
    end
    UI.OnSize(v.strip, function(self, w)
        local cw = (w - 20) / #v.pairs
        for i, p in ipairs(v.pairs) do
            p:ClearAllPoints()
            p:SetPoint("LEFT", 10 + (i - 1) * cw, 0)
            p:SetWidth(cw - 6)
        end
    end)

    -- toolbar
    v.tf = UI.Segmented(v, { { "1H", L["1H"] }, { "4H", L["4H"] }, { "1D", L["1D"] }, { "1W", L["1W"] } }, function(tf)
        FT.S.chartTF = tf
        T.DrawChart()
    end)
    v.tf:SetPoint("TOPLEFT", 0, -100)
    v.ma = UI.Check(v, L["Averages"], function(on)
        FT.S.showMA = on
        T.DrawChart(true)
    end)
    v.ma:SetPoint("LEFT", v.tf, "RIGHT", 16, 0)
    v.ma:SetTip(L["Moving averages"], L["Two smoothed lines on the price chart: MA7 and MA25, the average price of the last 7 and 25 points (days on 1D). Until there are that many, of the points there are; MA25 shows once there are more than 7."])

    v.search = UI.Button(v, L["Search on AH"], 10, 22, "default", function()
        if state.selected then FT.SearchItems({ state.selected }) end
    end)
    v.search:FitText(20)
    v.search:SetPoint("TOPRIGHT", 0, -100)
    v.watch = UI.Button(v, "", 10, 22, "default", function()
        FT.Market.ToggleWatch(state.selected)
        T.UpdateWatchButton()
    end)
    v.watch:SetPoint("RIGHT", v.search, "LEFT", -6, 0)

    -- charts: the price on top, the profitability under it (zero in the middle)
    v.chart = UI.Chart(v)
    v.chart:SetPoint("TOPLEFT", 0, -128)
    v.chart:SetPoint("TOPRIGHT", 0, -128)
    UI.Border(v.chart, "line")
    v.more = UI.MoreButton(v.chart, function() return state.selected end)
    T.more = v.more
    v.pchart = UI.Chart(v)
    v.pchart:SetPoint("TOPLEFT", v.chart, "BOTTOMLEFT", 0, -6)
    v.pchart:SetPoint("BOTTOMRIGHT", 0, CARDS_H)
    UI.Border(v.pchart, "line")

    -- bottom cards
    v.ind = Card(v, L["Indicators"])
    v.sig = Card(v, L["Signal"])
    v.alert = Card(v, L["Price alert"])
    for _, c in ipairs({ v.ind, v.sig, v.alert }) do c:SetHeight(110) end
    UI.OnSize(v, function(self, w, h)
        T.FitHeader()
        local cards = self.compact and 0 or CARDS_H
        self.chart:SetHeight(math.max(80, math.floor((h - 128 - cards - 6) * 0.56)))
        local cw = (w - 16) / 3
        self.ind:ClearAllPoints()
        self.ind:SetPoint("BOTTOMLEFT", 0, 0)
        self.ind:SetWidth(cw)
        self.sig:ClearAllPoints()
        self.sig:SetPoint("BOTTOMLEFT", cw + 8, 0)
        self.sig:SetWidth(cw)
        self.alert:ClearAllPoints()
        self.alert:SetPoint("BOTTOMLEFT", 2 * (cw + 8), 0)
        self.alert:SetWidth(cw)
    end)

    -- indicators
    local function IndLine(y, label)
        local l = UI.Text(v.ind, 11, "muted")
        l:SetPoint("TOPLEFT", 10, y)
        l:SetText(label)
        local r = UI.Text(v.ind, 12, "text", "RIGHT")
        r:SetPoint("TOPRIGHT", -10, y)
        return r
    end
    v.rsi = IndLine(-28, "RSI (14)")
    v.rsiBar = CreateFrame("Frame", nil, v.ind)
    v.rsiBar:SetHeight(3)
    v.rsiBar:SetPoint("TOPLEFT", 10, -44)
    v.rsiBar:SetPoint("TOPRIGHT", -10, -44)
    UI.Fill(v.rsiBar, "bg3", nil, "none")
    v.rsiZoneL = UI.Tex(v.rsiBar, "ARTWORK", "up", 0.35)
    v.rsiZoneL:SetPoint("TOPLEFT")
    v.rsiZoneL:SetPoint("BOTTOMLEFT")
    v.rsiZoneH = UI.Tex(v.rsiBar, "ARTWORK", "down", 0.35)
    v.rsiZoneH:SetPoint("TOPRIGHT")
    v.rsiZoneH:SetPoint("BOTTOMRIGHT")
    v.rsiMark = UI.Tex(v.rsiBar, "OVERLAY", "text", 1)
    v.rsiMark:SetSize(3, 9)
    v.dev = IndLine(-54, L["vs average"])
    v.vol = IndLine(-72, L["Daily volatility"])
    v.liq = IndLine(-90, L["Liquidity"])
    -- TradeSkillMaster's values of the item (when on): on hover
    v.ind:EnableMouse(true)
    v.ind:SetScript("OnEnter", function(self)
        if not (state.selected and FT.TSM.On()) then return end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(L["Indicators"], 1, 1, 1)
        if FT.TSM.AddTooltip(state.selected) then GameTooltip:Show() else GameTooltip:Hide() end
    end)
    v.ind:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- signal: what to do with it if you sell, if you buy
    local function SigRow(y, label)
        local l = UI.Text(v.sig, 11, "muted")
        l:SetPoint("TOPLEFT", 10, y)
        l:SetText(label)
        local b = UI.Badge(v.sig, 84, 17)
        b:SetPoint("TOPRIGHT", -10, y + 2)
        local r = UI.Text(v.sig, 11, "dim")
        r:SetPoint("TOPLEFT", 10, y - 17)
        r:SetPoint("RIGHT", v.sig, "RIGHT", -10, 0)
        return b, r
    end
    v.sellBadge, v.sellText = SigRow(-28, L["If you sell"])
    v.buyBadge, v.buyText = SigRow(-64, L["If you buy"])
    v.craft = UI.Button(v.sig, L["Recipe"], 10, 18, "default", function()
        local rs = FT.Craft.ByOutput(state.selected)
        if rs and rs[1] then FT.OpenRecipe(rs[1].key) end
    end)
    v.craft.label:SetFont(UI.FONT, 11, "")
    v.craft:FitText(16)
    v.craft:SetPoint("TOPRIGHT", -6, -4)

    -- alert: below / above, each in gold, silver and copper
    local function AlertRow(y, label)
        local l = UI.Text(v.alert, 11, "muted")
        l:SetPoint("TOPLEFT", 10, y - 5)
        l:SetText(label)
        local m = UI.MoneyInput(v.alert, nil, true)
        m:SetPoint("TOPRIGHT", -10, y)
        return m
    end
    v.below = AlertRow(-26, L["Below"])
    v.above = AlertRow(-52, L["Above"])
    v.save = UI.Button(v.alert, L["Save"], 10, 20, "primary", function()
        local id = state.selected
        if not id then return end
        local below, above = v.below:GetValue(), v.above:GetValue()
        if below == 0 then below = nil end
        if above == 0 then above = nil end
        -- nothing to save and nothing saved: the item doesn't go on the watchlist for it
        if below or above or FT.db.watch[id] then
            FT.Market.SetAlert(id, "below", below)
            FT.Market.SetAlert(id, "above", above)
        end
        for _, m in ipairs({ v.below, v.above }) do
            for _, e in ipairs(m.boxes) do e:ClearFocus() end
        end
        v.alertFor = nil
        T.UpdateAlert()
        FT.Market.CheckAlerts()
    end)
    v.save:FitText(24)
    v.save:SetPoint("TOPLEFT", 10, -80)
    v.save:SetTip(L["Price alert"], L["Checked after every scan. Empty = no alert."])
    v.alertText = UI.Text(v.alert, 11, "muted")
    v.alertText:SetPoint("LEFT", v.save, "RIGHT", 10, 0)
    v.alertText:SetPoint("RIGHT", v.alert, "RIGHT", -10, 0)
    return v
end

-- the name and the line under it stop before the price, its change and its age (cut with "...")
function T.FitHeader()
    local v = itemView
    local w = v and v:GetWidth()
    if not w or w <= 0 then return end
    local left = 2 + 38 + 10
    local top = 30 + v.change:GetStringWidth() + 12 + v.price:GetStringWidth() + 14
    local bottom = 30 + v.priceAge:GetStringWidth() + 5 + 9 + 14
    v.name:SetWidth(math.max(60, w - left - top))
    v.sub:SetWidth(math.max(60, w - left - bottom))
end

function T.UpdateWatchButton()
    local v = itemView
    if not (v and state.selected) then return end
    local on = FT.Market.IsWatched(state.selected)
    v.watch:SetLabel(on and L["In watchlist"] or L["Watch"])
    v.watch:SetActive(on)
    v.watch:FitText(20)
end

function T.UpdateAlert()
    local v = itemView
    local w = FT.db.watch[state.selected]
    local parts = {}
    if w and w.below then parts[#parts + 1] = L["below"] .. " " .. FT.Money(w.below) end
    if w and w.above then parts[#parts + 1] = L["above"] .. " " .. FT.Money(w.above) end
    v.alertText:SetText(#parts > 0 and (L["Alert when"] .. ": " .. table.concat(parts, ", ")) or FT.C("dim", L["No alert set"]))
end

-- draw the charts of the chosen item (price; profit in money, zero in the middle); keepView: same zoom
function T.DrawChart(keepView)
    local v = itemView
    local id = state.selected
    if not (v and id) then return end
    v.chart:SetData(UI.PriceChartData(id, FT.S.chartTF, FT.S.showMA), keepView)
    v.pchart:SetData(UI.ProfitChartData(id), keepView)
end

function T.ShowItem(id, keepView)
    if not itemView then return end
    overview:Hide()
    itemView:Show()
    local v = itemView
    local _, _, icon = FT.Item(id)
    v.icon:SetIcon(icon)
    v.name:SetText(FT.ItemText(id, 40))
    local cls, sub = FT.ItemClass(id)
    local parts = {}
    if cls then
        parts[#parts + 1] = ClassName(cls)
        local subName = GetSubClassInfo and sub and GetSubClassInfo(cls, sub)
        if subName and subName ~= "" and subName ~= parts[1] then parts[#parts + 1] = subName end
    end
    if FT.Hist.Tracked(id) then parts[#parts + 1] = FT.C("accent", L["tracked intraday"]) end
    local rs = FT.Craft.ByOutput(id)
    if rs and rs[1] then parts[#parts + 1] = FT.C("up", L["you can craft it"]) end
    local own = FT.Port.Count(id)
    if own > 0 then parts[#parts + 1] = FT.C("text", string.format(L["you have %s"], FT.Num(own))) end
    local s = FT.An.Stats(id)
    local head = UI.RiskHead(s)
    for i = #head, 1, -1 do table.insert(parts, 1, head[i]) end
    v.sub:SetText(table.concat(parts, FT.C("dim", "  ||  ")))
    v.craft:SetShown(rs ~= nil and rs[1] ~= nil)

    v.price:SetText(s.price and FT.Money(s.price) or "—")
    v.change:SetText(FT.Pct(s.ch1) .. FT.C("dim", " " .. L["24h"]))
    v.priceAge:SetText(UI.PriceAgeText(id, s))

    for _, p in ipairs(v.pairs) do
        local val = s[p.key]
        if p.key == "listed" or p.key == "auctions" or p.key == "sellers" then
            p.value:SetText(UI.CountText(s, p.key))
            if p.key == "auctions" then p.label:SetText(UI.AuctionsLabel(id)) end
        else
            p.value:SetText(val and FT.Money(val, "short") or "—")
        end
    end

    v.tf:SetValue(FT.S.chartTF)
    v.ma:SetChecked(FT.S.showMA)
    T.DrawChart(keepView)

    -- indicators
    if s.rsi then
        local color = (s.rsi >= 70 and "down") or (s.rsi <= 30 and "up") or "text"
        v.rsi:SetText(FT.C(color, string.format("%.0f", s.rsi)))
        local w = v.rsiBar:GetWidth()
        v.rsiZoneL:SetWidth(w * 0.3)
        v.rsiZoneH:SetWidth(w * 0.3)
        v.rsiMark:ClearAllPoints()
        v.rsiMark:SetPoint("CENTER", v.rsiBar, "LEFT", w * s.rsi / 100, 0)
        v.rsiMark:Show()
    else
        v.rsi:SetText(FT.C("dim", "—"))
        v.rsiMark:Hide()
    end
    v.dev:SetText(FT.Pct(s.dev))
    v.vol:SetText(s.vol and string.format("%.1f%%", s.vol * 100) or FT.C("dim", "—"))
    local liq = FT.An.Liquidity(s)
    local liqNames = { high = L["high"], medium = L["medium"], low = L["low"], unknown = L["no data"] }
    local liqColors = { high = "up", medium = "accent", low = "down", unknown = "dim" }
    -- and how much really sells, when seen (FT.Sales)
    -- (not seen yet: how much sells in the region, by TradeSkillMaster)
    local tsmSold = not s.sales and s.tsm and s.tsm.soldPerDay
    v.liq:SetText(FT.C(liqColors[liq], liqNames[liq])
        .. (s.sales and (FT.C("dim", "  ||  ") .. FT.C(s.slow and "down" or "text", FT.Sales.PerDayText(s.sales))) or "")
        .. (tsmSold and (FT.C("dim", "  ||  ") .. FT.C("text", string.format(L["TSM ~%s/day"],
            tsmSold < 10 and string.format("%.1f", tsmSold) or FT.Num(math.floor(tsmSold + 0.5))))) or ""))

    -- signals
    local sell, sellStrength, sellReason = FT.An.SellSignal(s)
    v.sellBadge:Set(sell, nil, sellStrength)
    v.sellText:SetText(sellReason or "")
    local buy, buyStrength, buyReason = FT.An.BuySignal(s)
    v.buyBadge:Set(buy, nil, buyStrength)
    v.buyText:SetText(buyReason or "")

    -- alert: the boxes are filled when another item is opened (and after Save), never while you type in them
    if v.alertFor ~= id and not (v.below:HasFocus() or v.above:HasFocus()) then
        v.alertFor = id
        local w = FT.db.watch[id]
        v.below:SetValue(w and w.below or nil)
        v.above:SetValue(w and w.above or nil)
    end
    T.UpdateAlert()
    T.UpdateWatchButton()
    book:SetItem(id)
    T.LayoutRight()
    T.FitHeader()
end

---------------------------------------------------------------------------
-- Page
---------------------------------------------------------------------------
function T.Build(p)
    page = p
    BuildList(p)
    center = CreateFrame("Frame", nil, p)
    overview = BuildOverview(center)
    itemView = BuildItemView(center)
    itemView:Hide()
    book = UI.OrderBook(p)
    T.book = book
    book:SetPoint("TOPRIGHT", -8, -8)
    book:SetPoint("BOTTOMRIGHT", -8, 8)
    book:SetWidth(RIGHT_W)
    -- a material clicked opens it here (the list stays as it is)
    mats = UI.Materials(p, function(id) T.Select(id) end)
    mats:SetPoint("BOTTOMRIGHT", -8, 8)
    mats:SetWidth(RIGHT_W)
    mats:Hide()
    T.OnLayout()
end

-- the right side: the order book, and under it the materials of one craft when you can make the item
function T.LayoutRight()
    if not (book and mats) then return end
    local show, h = false, 0
    if not FT.Compact() and itemView:IsShown() and state.selected then
        show, h = mats:SetItem(state.selected)
    end
    mats:SetShown(show)
    book:ClearAllPoints()
    book:SetPoint("TOPRIGHT", -8, -8)
    book:SetWidth(RIGHT_W)
    if show then
        mats:SetHeight(h)
        book:SetPoint("BOTTOMRIGHT", mats, "TOPRIGHT", 0, 8)
    else
        book:SetPoint("BOTTOMRIGHT", -8, 8)
    end
end

-- the compact window: charts only - no order book on the side, no cards under the charts ("More" has them)
function T.OnLayout()
    if not page then return end
    local compact = FT.Compact()
    book:SetShown(not compact)
    center:ClearAllPoints()
    center:SetPoint("TOPLEFT", LEFT_W + 18, -8)
    center:SetPoint("BOTTOMRIGHT", compact and -8 or -(RIGHT_W + 18), 8)
    local v = itemView
    v.compact = compact
    for _, c in ipairs({ v.ind, v.sig, v.alert }) do c:SetShown(not compact) end
    v.pchart:ClearAllPoints()
    v.pchart:SetPoint("TOPLEFT", v.chart, "BOTTOMLEFT", 0, -6)
    v.pchart:SetPoint("BOTTOMRIGHT", 0, compact and 0 or CARDS_H)
    local h = v:GetHeight()
    if h and h > 0 then
        v.chart:SetHeight(math.max(80, math.floor((h - 128 - (compact and 0 or CARDS_H) - 6) * 0.56)))
    end
    T.LayoutRight()
end

-- the list scrolled to the item you have open
function T.ShowSelectedInList()
    if not (list and state.selected) then return end
    for i, x in ipairs(list.items) do
        if x.id == state.selected and not x.child then
            list:ScrollTo(i)
            return
        end
    end
end

---------------------------------------------------------------------------
-- The filters panel (the button next to the search box)
---------------------------------------------------------------------------
local function FiltersChanged()
    if T.filterBtn then T.filterBtn:SetActive(FiltersOn()) end
    FT.Debounce("marketFilters", 0.2, function()
        T.RefreshList()
        if FiltersOn() then T.LoadMissingNames() end
    end)
end

local function QualityName(q)
    local name = _G["ITEM_QUALITY" .. q .. "_DESC"]
    return "|c" .. FT.QualityHex(q) .. (name or tostring(q)) .. "|r"
end

local function BuildFilters()
    local p = CreateFrame("Frame", nil, UIParent)
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:SetFrameLevel(60)
    p:SetClampedToScreen(true)
    p:EnableMouse(true)
    p:SetWidth(220)
    UI.Fill(p, "bg1")
    UI.Border(p, "line")
    -- a click anywhere else closes it
    local blocker = CreateFrame("Button", nil, UIParent)
    blocker:SetAllPoints(UIParent)
    blocker:SetFrameStrata("FULLSCREEN_DIALOG")
    blocker:SetFrameLevel(50)
    blocker:SetScript("OnClick", function() p:Hide() end)
    blocker:Hide()
    p:SetScript("OnShow", function() blocker:Show() end)
    p:SetScript("OnHide", function() blocker:Hide() end)

    local y = -12
    local function Title(text)
        local t = UI.Text(p, 12, "accent")
        t:SetPoint("TOPLEFT", 14, y)
        t:SetText(text)
        y = y - 22
    end

    Title(L["Levels"])
    local function LevelBox(onSet)
        local e = UI.Input(p, 48, 22, "", function(text)
            onSet(tonumber(text))
            FiltersChanged()
        end)
        e:SetNumeric(true)
        e:SetMaxLetters(3)
        e:SetJustifyH("CENTER")
        return e
    end
    p.min = LevelBox(function(v) filt.min = v end)
    p.min:SetPoint("TOPLEFT", 14, y)
    local dash = UI.Text(p, 12, "muted")
    dash:SetPoint("LEFT", p.min, "RIGHT", 6, 0)
    dash:SetText("-")
    p.max = LevelBox(function(v) filt.max = v end)
    p.max:SetPoint("LEFT", dash, "RIGHT", 6, 0)
    y = y - 34

    p.usable = UI.Check(p, L["Usable only"], function(on)
        filt.usable = on
        FiltersChanged()
    end)
    p.usable:SetPoint("TOPLEFT", 14, y)
    y = y - 24
    if CanCollect() then
        p.uncollected = UI.Check(p, L["Not collected only"], function(on)
            filt.uncollected = on
            FiltersChanged()
        end)
        p.uncollected:SetPoint("TOPLEFT", 14, y)
        y = y - 24
    end
    y = y - 6

    Title(L["Quality"])
    p.quality = {}
    for _, q in ipairs(QUALITIES) do
        local c = UI.Check(p, QualityName(q), function(on)
            filt.quality[q] = on
            FiltersChanged()
        end)
        c:SetPoint("TOPLEFT", 14, y)
        p.quality[q] = c
        y = y - 22
    end
    y = y - 8

    p.reset = UI.Button(p, L["Reset"], 10, 22, "default", function()
        T.ResetFilters()
        T.SyncFilters()
    end)
    p.reset:FitText(24)
    p.reset:SetPoint("TOPLEFT", 14, y)
    y = y - 22 - 12
    p:SetHeight(-y)
    p:Hide()
    T.filterPanel = p
    return p
end

-- the panel shows what is set
function T.SyncFilters()
    local p = T.filterPanel
    if not p then return end
    p.min:SetValue(filt.min and tostring(filt.min) or "")
    p.max:SetValue(filt.max and tostring(filt.max) or "")
    p.usable:SetChecked(filt.usable)
    if p.uncollected then p.uncollected:SetChecked(filt.uncollected) end
    for q, c in pairs(p.quality) do c:SetChecked(filt.quality[q]) end
end

function T.ResetFilters()
    filt.min, filt.max, filt.usable, filt.uncollected = nil, nil, false, false
    for _, q in ipairs(QUALITIES) do filt.quality[q] = true end
    FiltersChanged()
end

function T.ToggleFilters(button)
    local p = T.filterPanel or BuildFilters()
    if p:IsShown() then
        p:Hide()
        return
    end
    p:SetScale(button:GetEffectiveScale() / UIParent:GetEffectiveScale())
    p:ClearAllPoints()
    p:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
    T.SyncFilters()
    p:Show()
end

-- An item opened from elsewhere (Craft, Signals, Portfolio, the ticker, the item window): the list shows just
-- it - its exact name in quotes in the search box, the filters back to all. × brings the whole list back.
-- (Picking an item in the list itself leaves the list as it is.)
function T.Focus(id)
    if not id then return end
    if not page then FT.Show("market") end
    state.filter, state.cls, state.sub = "all", "all", "all"
    if FiltersOn() then
        T.ResetFilters()
        T.SyncFilters()
    end
    if T.chips then
        for _, c in ipairs(T.chips) do c:SetOn(c.key == "all") end
    end
    if T.clsDD then T.clsDD:SetValue("all") end
    local name = FT.Name(id) or FT.Item(id)
    -- no name yet: the search box gets it when it arrives
    state.focusFor = not name and id or nil
    state.search = name and ('"' .. name .. '"') or ""
    if T.searchBox then T.searchBox:SetValue(state.search) end
    T.RefreshList()
    T.Select(id)
end

function T.Select(id)
    if not id then return end
    if not page then FT.Show("market") end
    state.selected = id
    FT.Hist.Viewed(id)
    if list then list:Refresh() end
    T.ShowItem(id)
    FT.Scanner.LiveNow(id)
end

-- the item kept live at the auction house: the one open here
function T.LiveItem()
    return itemView and itemView:IsVisible() and state.selected or nil
end

-- and the materials of one craft of it (when they show): its cost and profit follow the market too
function T.LiveItems()
    local id = T.LiveItem()
    if not id then return nil end
    local out = { id }
    if mats and mats:IsVisible() and mats.r then
        for _, m in ipairs(FT.Craft.MarketMaterials(mats.r)) do out[#out + 1] = m end
    end
    return out
end

-- a live price came in (id), or the auction house opened or closed (nil)
function T.OnLive(_, id)
    if list then list:Refresh() end
    local ours = id == nil or id == state.selected or (mats and mats:IsShown() and mats:Has(id))
    if state.selected and itemView and itemView:IsShown() and ours then
        T.ShowItem(state.selected, true)
    end
end

function T.OnShow()
    FT.Market.EnsureFresh()
    T.Refresh()
end

function T.Refresh()
    T.RefreshList(true)
    if state.selected then
        T.ShowItem(state.selected, true)
    else
        T.ShowOverview()
    end
end

-- Escape-like: back to the overview
-- the item open (nil: the overview)
function T.Selected()
    return state.selected
end

function T.ClearSelection()
    state.selected = nil
    if list then list:Refresh() end
    T.ShowOverview()
end
