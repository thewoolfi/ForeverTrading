-- ForeverTrading: core (saved data, events, formatting helpers, slash commands)
local ADDON, FT = ...
local L = FT.L

-- The version being released: a copy straight from the repository (not packaged) has no version in its TOC yet
-- (the packager puts the tag there) and shows this one. Set it with every release.
local RELEASE = "v1.1.4"
local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
FT.VERSION = (GetMeta and GetMeta(ADDON, "Version")) or RELEASE
if FT.VERSION == "" or FT.VERSION:find("@", 1, true) then FT.VERSION = RELEASE end
FT.VERSION_TEXT = FT.VERSION:match("^%d") and ("v" .. FT.VERSION) or FT.VERSION
FT.MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\media\\"
FT.URL_SUPPORT = "https://boosty.to/andrewwoolfi"
FT.URL_GITHUB = "https://github.com/thewoolfi/ForeverTrading"

---------------------------------------------------------------------------
-- Events: game events and our own ("FT_*") share one dispatcher
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local handlers = {}

function FT.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        if not event:find("^FT_") then
            -- an event this client doesn't know must not break the addon
            pcall(eventFrame.RegisterEvent, eventFrame, event)
        end
    end
    table.insert(handlers[event], fn)
end

function FT.Fire(event, ...)
    local list = handlers[event]
    if not list then return end
    for i = 1, #list do
        local ok, err = pcall(list[i], ...)
        if not ok then
            geterrorhandler()(err)
        end
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...) FT.Fire(event, ...) end)

-- Run fn once, `delay` seconds after the last call with the same key. One timer per key, however
-- often it is called (a full scan saves thousands of prices in a few frames).
local pending = {}
function FT.Debounce(key, delay, fn)
    local due = GetTime() + delay
    local p = pending[key]
    if p then
        p.due, p.fn = due, fn
        return
    end
    p = { due = due, fn = fn }
    pending[key] = p
    local function Check()
        local left = p.due - GetTime()
        if left > 0.01 then
            C_Timer.After(left, Check)
            return
        end
        pending[key] = nil
        local ok, err = pcall(p.fn)
        if not ok then geterrorhandler()(err) end
    end
    C_Timer.After(delay, Check)
end

---------------------------------------------------------------------------
-- Long jobs, a little each frame - and what they cost (/ft perf)
---------------------------------------------------------------------------
-- a job works this many milliseconds of a frame (fewer in a fight): smooth on a slow computer, quick on a fast one
local FRAME_MS, FIGHT_MS = 8, 3
local clock = debugprofilestop
FT.Clock = clock
FT.perf = {} -- name -> its last run: { n, ms (work), frames, worst (the longest frame), wall (seconds), at, runs }

function FT.PerfNote(name, n, ms, frames, worst, wall)
    local p = FT.perf[name] or { runs = 0 }
    FT.perf[name] = p
    p.n, p.ms, p.frames, p.worst, p.wall, p.at = n, ms, frames or 1, worst or ms, wall or ms / 1000, time()
    p.runs = p.runs + 1
end

-- step(i) for i = 1..n, as many as fit in each frame's share; done() at the end. A step returning false stops the
-- job (done isn't called). The job: job:Cancel().
function FT.Job(name, n, step, done)
    local job = {}
    local i, spent, frames, worst, began = 1, 0, 0, 0, GetTime()
    local ticker
    ticker = C_Timer.NewTicker(0, function()
        local t0 = clock()
        local stop = t0 + ((InCombatLockdown and InCombatLockdown()) and FIGHT_MS or FRAME_MS)
        while i <= n do
            if step(i) == false then
                ticker:Cancel()
                return
            end
            i = i + 1
            if clock() >= stop then break end
        end
        local d = clock() - t0
        spent, frames = spent + d, frames + 1
        if d > worst then worst = d end
        if i > n then
            ticker:Cancel()
            FT.PerfNote(name, n, spent, frames, worst, GetTime() - began)
            if done then done() end
        end
    end)
    function job.Cancel() ticker:Cancel() end
    return job
end

---------------------------------------------------------------------------
-- Saved data
---------------------------------------------------------------------------
FT.DEFAULTS = {
    lang = "auto",          -- auto / ru / en
    theme = "dark",         -- dark / light / classic (after a reload)
    useAuctionator = true,  -- its scans and searches go into our history; days we don't have come from it
    useMastercraft = true,  -- recipes and holdings of alts ForeverTrading hasn't seen yet
    useTSM = true,          -- TradeSkillMaster's downloads go into our history; its values fill in what we lack
    liveRefresh = true,     -- the item you have open is searched again every few seconds at the auction house
    shareAuto = true,       -- prices older than an hour: ask guild and group for fresher ones
    shareSend = true,       -- give our fresh scan to guild and group members who ask
    autoFull = false,       -- full scan when the auction house opens (at most once an hour)
    deepFull = false,       -- full scan reads every auction (ReplicateItems, once every 15 minutes)
    scanPages = 2,          -- pages (50 auctions each, cheapest first) read per item in "my items"
    keepDaily = 90,         -- days of day candles kept
    ahCut = true,           -- the auction house's cut taken off profits (FT.Cut: as its letters say it is)
    cheapestWay = true,     -- a material you can craft cheaper counts at its craft cost
    minProfit = 2000,       -- copper: below this a craft is not a "CRAFT" signal
    dealBelow = 30,         -- percent under the fair price that makes a lot a resale deal
    dealMin = 2000,         -- copper: deals that bring less aren't shown
    undercutAlert = true,   -- at the auction house: a line in chat when an auction of yours is undercut
    spikeGuard = true,      -- a price blown up by a buyout (few lots far above the fair price) isn't counted on
    spikeAbove = 50,        -- percent above the fair price that counts as a jump (a buyout)
    fallBelow = 20,         -- percent below the fair price that counts as falling fast (crafts get RISKY)
    floodAbove = 50,        -- percent more listed (or more sellers) than usual that counts as a flooded market
    minMargin = 10,         -- percent
    sellAbove = 10,         -- percent above the average price -> SELL
    buyBelow = 15,          -- percent below the average price -> BUY
    avgDays = 14,           -- days in the average price
    tooltip = true,
    versionCheck = true,    -- tell guild and group which version we have, hear about newer ones
    minimap = true,
    minimapAngle = 205,
    alertSound = true,
    alertChat = true,
    trackAll = false,       -- intraday history for every item (more memory)
    keepDays = 45,
    maxSnaps = 240,
    scale = 1.0,
    ticker = true,
    ahButton = true,
    replaceAH = false,      -- talking to an auctioneer opens ForeverTrading in place of the game's window
    sellDuration = 2,       -- posting: 1 short, 2 medium, 3 long (WoW Forever: 2, 8, 24 hours)
    dockAH = true,
    chartTF = "1D",
    showMA = false,
}

local function Fill(t, defaults)
    for k, v in pairs(defaults) do
        if t[k] == nil then
            t[k] = v
        end
    end
end

-- One server of WoW Forever has numbered realms that are layers of it ("CAMWOW EU5 Realm 8 PvP"):
-- they share the auction house, so their data is kept together under "eu-pvp" (the same key
-- Mastercraft uses for its price book).
local SERVER_KINDS = {
    [""] = "normal", pve = "normal", normal = "normal", pvp = "pvp", rp = "roleplay", roleplay = "roleplay",
    ["rp-pvp"] = "roleplay-pvp", rppvp = "roleplay-pvp", ["roleplay-pvp"] = "roleplay-pvp",
    hc = "hardcore", hardcore = "hardcore",
}
local SERVER_REGIONS = { EU = "eu", US = "us", NA = "us", KR = "kr", TW = "tw", CN = "cn" }
function FT.ServerOf(realm)
    if type(realm) ~= "string" or realm == "" then return "?" end
    local init = 1
    while true do
        local s, _, region, kind = realm:find("%f[%a](%a%a)%d*%s+[Rr]ealm%s+%d+%s*(.-)%s*$", init)
        if not s then return realm end
        local r = SERVER_REGIONS[region:upper()]
        if r then
            kind = kind:lower():gsub("[^%w]+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
            kind = SERVER_KINDS[kind] or kind
            return r .. "-" .. kind
        end
        init = s + 1
    end
end

function FT.SideKey()
    local realm = GetRealmName and GetRealmName() or "?"
    local faction = UnitFactionGroup and UnitFactionGroup("player") or "?"
    return FT.ServerOf(realm) .. "-" .. tostring(faction)
end

-- the data key of an auction house: your faction's is the server and side (as always); Blackwater, the neutral
-- one, is shared by both factions
function FT.HouseKey(house)
    if house == "neutral" then return FT.ServerOf(GetRealmName and GetRealmName() or "?") .. "-Neutral" end
    return FT.sideKey or FT.SideKey()
end

local function Realm(key)
    local realms = FT.db.realms
    local r = realms[key]
    if not r then
        r = {}
        realms[key] = r
    end
    r.snaps = r.snaps or {}
    r.books = r.books or {}
    r.scans = r.scans or {}
    r.days = r.days or {}
    r.today = r.today or {}
    r.meta = r.meta or {}
    return r
end

-- Data of the auction house on (snapshots, order books, scan log, sales): your faction's or Blackwater (House.lua)
function FT.R()
    return Realm(FT.houseKey or FT.sideKey or FT.SideKey())
end

-- Data of this server and side whichever the auction house (the deals journal, the craft queue, users met)
function FT.Side()
    return Realm(FT.sideKey or FT.SideKey())
end

local function InitDB()
    FT.freshInstall = ForeverTradingDB == nil
    ForeverTradingDB = ForeverTradingDB or {}
    local db = ForeverTradingDB
    db.settings = db.settings or {}
    Fill(db.settings, FT.DEFAULTS)
    db.realms = db.realms or {}
    db.watch = db.watch or {}
    db.viewed = db.viewed or {}
    db.recipes = db.recipes or {}
    db.chars = db.chars or {}
    db.inv = db.inv or {}
    db.vendor = db.vendor or {}
    db.frame = db.frame or {}
    -- 1.1: price charts are one line; the moving averages start switched off
    if (db.version or 1) < 2 then
        db.settings.showMA = false
        db.settings.chartType = nil
    end
    -- 1.2: "my items" reads the cheapest 100 auctions per item (was 250): a faster scan
    if (db.version or 1) < 3 and db.settings.scanPages == 5 then db.settings.scanPages = 2 end
    -- 1.3: "my items" only when you press it (it takes minutes)
    db.settings.autoMine = nil
    -- 1.4: the full scan at the auction house only when you press it (the setting starts switched off again)
    if (db.version or 1) < 5 then db.settings.autoFull = false end
    db.version = 5
    FT.db = db
    FT.S = db.settings
end

function FT.Lang()
    local lang = FT.S and FT.S.lang or "auto"
    if lang == "auto" then
        return (GetLocale() == "ruRU") and "ru" or "en"
    end
    return lang
end

---------------------------------------------------------------------------
-- Formatting
---------------------------------------------------------------------------
FT.HEX = {
    text = "eaecef", muted = "848e9c", dim = "5e6673", up = "0ecb81", down = "f6465d",
    accent = "f0b90b", blue = "3b82f6", purple = "a78bfa", gold = "e8b923", silver = "c0c6cc", copper = "d9894a",
}

function FT.C(hex, s)
    return "|cff" .. (FT.HEX[hex] or hex) .. tostring(s) .. "|r"
end

-- the game's own coin icons, as tall as the text around them
local function Coin(kind)
    return "|TInterface\\MoneyFrame\\UI-" .. kind .. "Icon:0:0:1:0|t"
end
FT.COIN = { gold = Coin("Gold"), silver = Coin("Silver"), copper = Coin("Copper") }
local G_SUFFIX = FT.COIN.gold
local S_SUFFIX = FT.COIN.silver
local C_SUFFIX = FT.COIN.copper

-- where a price came from, for people
function FT.SourceName(source)
    local names = { full = L["full scan"], mine = L["My items"], auctionator = "Auctionator", mastercraft = "Mastercraft", tsm = "TSM",
        history = L["history"], live = L["live search"], peer = L["exchange"] }
    return names[source] or L["scan"]
end

function FT.Thousands(n)
    local s = tostring(math.floor(n))
    local out, k = s, 0
    repeat
        out, k = out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
    until k == 0
    return out
end

-- copper -> "42g 12s 30c"; mode "short": at most two units ("42g 12s", "1,204g")
function FT.Money(c, mode)
    if c == nil then return "|cff5e6673—|r" end
    local neg = c < 0
    c = math.floor(math.abs(c) + 0.5)
    local g = math.floor(c / 10000)
    local s = math.floor((c % 10000) / 100)
    local cp = c % 100
    local out
    if mode == "short" then
        if g >= 1000 then
            out = FT.Thousands(g) .. G_SUFFIX
        elseif g >= 1 then
            out = g .. G_SUFFIX .. (s > 0 and (" " .. s .. S_SUFFIX) or "")
        elseif s >= 1 then
            out = s .. S_SUFFIX .. (cp > 0 and (" " .. cp .. C_SUFFIX) or "")
        else
            out = cp .. C_SUFFIX
        end
    else
        local parts = {}
        if g > 0 then parts[#parts + 1] = FT.Thousands(g) .. G_SUFFIX end
        if s > 0 or (g > 0 and cp > 0) then parts[#parts + 1] = s .. S_SUFFIX end
        if cp > 0 or #parts == 0 then parts[#parts + 1] = cp .. C_SUFFIX end
        out = table.concat(parts, " ")
    end
    return (neg and "-" or "") .. out
end

-- copper -> "1500g50s25c" for input boxes: exact, no colours, read back by FT.ParseMoney
function FT.MoneyPlain(c)
    if not c then return "" end
    c = math.floor(c + 0.5)
    local g, s, cp = math.floor(c / 10000), math.floor((c % 10000) / 100), c % 100
    local out = ""
    if g > 0 then out = out .. g .. "g" end
    if s > 0 then out = out .. s .. "s" end
    if cp > 0 or out == "" then out = out .. cp .. "c" end
    return out
end

-- a profit with its sign: "+1g 20s" / "-35s"
function FT.SignedMoney(c)
    if c and c > 0 then return "+" .. FT.Money(c, "short") end
    return FT.Money(c, "short")
end

-- Plain number in gold for chart axes: 42.12 / 0.35
function FT.GoldNumber(c)
    if not c then return "" end
    local g = c / 10000
    if math.abs(g) >= 1000 then return FT.Thousands(g) end
    if math.abs(g) >= 100 then return string.format("%.1f", g) end
    if math.abs(g) >= 1 then return string.format("%.2f", g) end
    return string.format("%.4f", g)
end

-- fraction -> "+5.3%" in green / red
function FT.Pct(v, plain)
    if v == nil or v ~= v then return "|cff5e6673—|r" end
    local p = v * 100
    local s
    if math.abs(p) >= 1000 then
        s = string.format("%+.0f%%", p)
    else
        s = string.format("%+.1f%%", p)
    end
    if plain then return s end
    if p > 0.05 then return FT.C("up", s) end
    if p < -0.05 then return FT.C("down", s) end
    return FT.C("muted", s)
end

function FT.Num(n)
    if not n then return "—" end
    return FT.Thousands(n)
end

function FT.Ago(t)
    if not t or t <= 0 then return L["never"] end
    local d = time() - t
    if d < 60 then return L["just now"] end
    if d < 3600 then return string.format(L["%dm ago"], math.floor(d / 60)) end
    if d < 86400 then return string.format(L["%dh ago"], math.floor(d / 3600)) end
    return string.format(L["%dd ago"], math.floor(d / 86400))
end

---------------------------------------------------------------------------
-- Days, as Auctionator counts them (its price history is kept per day)
---------------------------------------------------------------------------
local DAY0 = time({ year = 2020, month = 1, day = 1, hour = 0 })
function FT.Day0()
    return (Auctionator and Auctionator.Constants and Auctionator.Constants.SCAN_DAY_0) or DAY0
end
function FT.Day(t)
    return math.floor(((t or time()) - FT.Day0()) / 86400)
end
function FT.DayStart(day)
    return day * 86400 + FT.Day0()
end

---------------------------------------------------------------------------
-- Items
---------------------------------------------------------------------------
local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

-- Item names we have seen, saved per game language: searching thousands of items needs their names
-- without asking the server for each one
local nameBook
local function NameBook()
    if not nameBook then
        FT.db.names = FT.db.names or {}
        local lang = GetLocale()
        FT.db.names[lang] = FT.db.names[lang] or {}
        nameBook = FT.db.names[lang]
    end
    return nameBook
end

-- Their quality too: the game forgets items for a moment while the auction house loads thousands of others,
-- and a name shown without it would flash white
local qualityBook
local function QualityBook()
    if not qualityBook then
        FT.db.quality = FT.db.quality or {}
        qualityBook = FT.db.quality
    end
    return qualityBook
end

function FT.RememberName(itemID, name)
    if itemID and type(name) == "string" and name ~= "" and FT.db then NameBook()[itemID] = name end
end

-- Lower case for searching, Russian letters too: Lua's lower() knows only A-Z, so "трава" never found "Трава".
-- А-Я are the bytes D0 90..AF, а-п D0 B0..BF, р-я D1 80..8F; Ё D0 81, ё D1 91.
local CYRILLIC = { ["\208\129"] = "\209\145" }
for i = 0, 31 do
    CYRILLIC["\208" .. string.char(0x90 + i)] = i < 16 and ("\208" .. string.char(0xB0 + i)) or ("\209" .. string.char(0x80 + i - 16))
end
function FT.Fold(s)
    if type(s) ~= "string" then return "" end
    return (s:lower():gsub("\208[\128-\175]", CYRILLIC))
end

-- A search as typed: "name" in quotes is that name exactly, anything else a part of the name.
-- Returns a test fn(itemID) -> true when the item's name matches (nil: an empty search, everything matches).
function FT.NameMatcher(text)
    local q = FT.Fold(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if q == "" then return nil end
    local exact = q:match('^"(.+)"$')
    local part = not exact and q:gsub('^"', ""):gsub('"$', "") or nil
    if part == "" then return nil end
    return function(itemID)
        local name = FT.Name(itemID)
        if not name then return false end
        name = FT.Fold(name)
        if exact then return name == exact end
        return name:find(part, 1, true) ~= nil
    end
end

-- the name of an item without asking the server (nil when the game hasn't loaded it and we never saw it).
-- GetItemInfo itself asks the server for an item it doesn't have: only called for items the game has.
local IsCached = C_Item and C_Item.IsItemDataCachedByID
function FT.Name(itemID)
    if not itemID then return nil end
    if IsCached and not IsCached(itemID) then return NameBook()[itemID] end
    local name, _, quality = GetInfo(itemID)
    if name then
        local book = NameBook()
        if book[itemID] ~= name then book[itemID] = name end
        if quality and QualityBook()[itemID] ~= quality then QualityBook()[itemID] = quality end
        return name
    end
    return NameBook()[itemID]
end

-- The auction house's cut of a sale, a fraction: as the last letter of a sale of that house (the one on when not
-- said) told it (its cut over its price - it isn't the same everywhere now), else 5% (Blackwater: 15%)
function FT.Cut(house)
    local neutral = (house or FT.house) == "neutral"
    local c = FT.db and (neutral and FT.db.cutSeenNeutral or FT.db.cutSeen)
    if type(c) == "table" and type(c.rate) == "number" and c.rate >= 0 and c.rate < 0.5 then return c.rate end
    return neutral and 0.15 or 0.05
end

-- name -> item, of every item name seen (in this game language; of two items with one name, one of them)
function FT.NameIndex()
    local idx = {}
    if not FT.db then return idx end
    for id, name in pairs(NameBook()) do
        if type(name) == "string" and not idx[name] then idx[name] = id end
    end
    return idx
end

-- what a vendor pays for one, without asking the server (for looking through thousands of items: nil while
-- the game hasn't loaded the item and we never saw it)
function FT.SellPriceKnown(itemID)
    if not (itemID and FT.db) then return nil end
    FT.db.sellPrices = FT.db.sellPrices or {}
    local book = FT.db.sellPrices
    if IsCached and not IsCached(itemID) then return book[itemID] or nil end
    local _, _, _, _, _, _, _, _, _, _, sellPrice = GetInfo(itemID)
    if type(sellPrice) == "number" and sellPrice > 0 then
        if book[itemID] ~= sellPrice then book[itemID] = sellPrice end
        return sellPrice
    end
    return nil
end

-- name, quality, icon, sellPrice, link (name from our book while the game hasn't loaded the item yet)
function FT.Item(itemID)
    if not itemID then return nil end
    local name, link, quality, _, _, _, _, _, _, icon, sellPrice = GetInfo(itemID)
    if not icon and GetInstant then
        icon = select(5, GetInstant(itemID))
    end
    if name then
        local book = NameBook()
        if book[itemID] ~= name then book[itemID] = name end
        if quality and QualityBook()[itemID] ~= quality then QualityBook()[itemID] = quality end
    else
        FT.RequestItem(itemID)
        name = NameBook()[itemID]
        quality = QualityBook()[itemID]
    end
    return name, quality, icon, sellPrice, link
end

-- quality and required level without asking the server (nil while the game hasn't loaded the item; the
-- quality from our book then)
function FT.ItemFacts(itemID)
    if IsCached and not IsCached(itemID) then return QualityBook()[itemID], nil end
    local name, _, quality, _, minLevel = GetInfo(itemID)
    if name and quality and QualityBook()[itemID] ~= quality then QualityBook()[itemID] = quality end
    return quality or QualityBook()[itemID], minLevel
end

function FT.ItemCached(itemID)
    return not IsCached or IsCached(itemID)
end

-- classID, subClassID, icon without waiting for the item to load
function FT.ItemClass(itemID)
    if not (GetInstant and itemID) then return nil end
    local _, _, _, equipLoc, icon, classID, subClassID = GetInstant(itemID)
    return classID, subClassID, icon, equipLoc
end

local requested = {}
function FT.RequestItem(itemID)
    if requested[itemID] then return end
    requested[itemID] = true
    if C_Item and C_Item.RequestLoadItemDataByID then
        pcall(C_Item.RequestLoadItemDataByID, itemID)
    end
end

FT.On("GET_ITEM_INFO_RECEIVED", function()
    FT.Debounce("itemsLoaded", 0.4, function() FT.Fire("FT_ITEMS_LOADED") end)
end)

function FT.QualityHex(q)
    if FT.UI and FT.UI.theme == "light" then
        if not q or q <= 1 then return "ff" .. FT.HEX.text end
        if q == 2 then return "ff1a9e00" end -- a darker green than the game's, for white
    end
    local c = q and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q]
    if c and c.hex then return c.hex:gsub("^|c", "") end
    return "ffeaecef"
end

-- the first n characters of a UTF-8 text (Russian letters are two bytes each: never cut one in half)
function FT.Trunc(s, n)
    if not s or not n then return s end
    local chars, i, len = 0, 1, #s
    while i <= len do
        chars = chars + 1
        if chars > n then
            -- cut before this character, leaving room for the ellipsis
            local cut, k, c = 1, 1, 0
            while k <= len and c < n - 1 do
                local b = s:byte(k)
                local size = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
                k = k + size
                c = c + 1
                cut = k
            end
            return s:sub(1, cut - 1) .. "…"
        end
        local b = s:byte(i)
        i = i + ((b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1)
    end
    return s
end

function FT.ItemText(itemID, maxLen)
    local name, quality = FT.Item(itemID)
    if not name then return "|cff5e6673" .. L["Loading..."] .. " #" .. tostring(itemID) .. "|r" end
    if maxLen then name = FT.Trunc(name, maxLen) end
    return "|c" .. FT.QualityHex(quality) .. name .. "|r"
end

function FT.ItemIDFromLink(link)
    if type(link) == "number" then return link end
    return link and tonumber(link:match("item:(%d+)"))
end

---------------------------------------------------------------------------
-- Messages
---------------------------------------------------------------------------
function FT.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cfff0b90bForever|r|cffeaecefTrading|r: " .. tostring(msg))
end

function FT.Debug(...)
    if FT.debug then
        local parts = {}
        for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
        FT.Print("|cff848e9c[debug]|r " .. table.concat(parts, " "))
    end
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------
FT.On("ADDON_LOADED", function(name)
    if name ~= ADDON then return end
    InitDB()
    FT.ApplyLocale(FT.Lang())
    FT.Fire("FT_DB_READY")
end)

-- the game stopped one of our calls (one only allowed from its own code or right in a click): say which
local function Blocked(addon, func)
    if addon ~= ADDON then return end
    FT.Debug("blocked:", tostring(func))
    FT.Fire("FT_BLOCKED", tostring(func))
end
FT.On("ADDON_ACTION_BLOCKED", Blocked)
FT.On("ADDON_ACTION_FORBIDDEN", Blocked)

FT.On("PLAYER_LOGIN", function()
    FT.charKey = UnitGUID("player")
    FT.sideKey = FT.SideKey()
    local c = FT.db.chars[FT.charKey] or {}
    FT.db.chars[FT.charKey] = c
    -- the auction house whose prices this character looked at last (talking to an auctioneer picks its own)
    FT.house = (c.house == "neutral") and "neutral" or "faction"
    FT.houseKey = FT.HouseKey(FT.house)
    c.name = UnitName("player")
    c.realm = GetRealmName()
    c.server = FT.ServerOf(c.realm)
    c.faction = UnitFactionGroup("player")
    c.classFile = select(2, UnitClass("player"))
    c.side = FT.sideKey
    FT.Fire("FT_LOGIN")
    -- the other addons finish their own start on PLAYER_LOGIN: hook them a moment later
    C_Timer.After(0.5, function() FT.Fire("FT_READY") end)
end)

---------------------------------------------------------------------------
-- /ft perf: what the long jobs cost the last time, the memory, the saved prices
---------------------------------------------------------------------------
local PERF_JOBS = {
    { "scan:read", "Reading every auction (deep scan)" },
    { "scan:list", "Reading a scan of Auctionator" },
    { "scan:save", "Saving a scan" },
    { "scan:gone", "Marking what is no longer listed" },
    { "tsm:import", "Reading TSM's prices" },
    { "market", "Market: every item" },
    { "market+", "Market: the changed items" },
    { "deals", "Deals: every item" },
    { "deals+", "Deals: the changed items" },
    { "prune", "Pruning old history" },
}

local function Ms(v)
    return string.format("%.1f", v or 0)
end

local function MB(kb)
    return string.format(L["%.1f MB"], (kb or 0) / 1024)
end

function FT.PerfReport()
    FT.Print(L["Performance (this session):"])
    local mine
    local update = UpdateAddOnMemoryUsage or (C_AddOns and C_AddOns.UpdateAddOnMemoryUsage)
    local usage = GetAddOnMemoryUsage or (C_AddOns and C_AddOns.GetAddOnMemoryUsage)
    if update and usage then
        pcall(update)
        local ok, kb = pcall(usage, ADDON)
        if ok and type(kb) == "number" then mine = kb end
    end
    FT.Print("  " .. string.format(L["Memory: ForeverTrading %s, all addons %s"], mine and MB(mine) or "?",
        MB(collectgarbage("count"))))
    local items, size = FT.Hist.Footprint()
    FT.Print("  " .. string.format(L["Saved prices: %s items, %s characters; %s waiting to be written (at logout or /reload)"],
        FT.Num(items), FT.Num(size), FT.Num(FT.Hist.Unwritten())))
    local rowsN, deep, movers = FT.Market.Depth()
    FT.Print("  " .. string.format(L["Market: %s items, %s with prices on 3+ days of the last two weeks, %s can be top gainers or losers"],
        FT.Num(rowsN), FT.Num(deep), FT.Num(movers)) .. (FT.Atr.On() and "" or
        (" " .. L["(Auctionator is off: only the days ForeverTrading saw itself count)"])))
    local lo = FT.db.perfLogout
    if type(lo) == "table" and lo.ms then
        FT.Print("  " .. string.format(L["Writing them at the last logout: %s ms (%s records)"], Ms(lo.ms), FT.Num(lo.n or 0)))
    end
    local any = false
    for _, job in ipairs(PERF_JOBS) do
        local p = FT.perf[job[1]]
        if p then
            any = true
            FT.Print("  " .. string.format(L["%s: %s - %s ms of work in %s frames (the longest %s ms), %s s in all, %s"],
                L[job[2]], FT.Num(p.n), Ms(p.ms), FT.Num(p.frames), Ms(p.worst), string.format("%.1f", p.wall or 0),
                FT.Ago(p.at)))
        end
    end
    if not any then FT.Print("  " .. L["Nothing measured yet this session: make a scan or open the Market."]) end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_FOREVERTRADING1 = "/ft"
SLASH_FOREVERTRADING2 = "/forevertrading"
SLASH_FOREVERTRADING3 = "/ftrade"
SlashCmdList.FOREVERTRADING = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local cmd, rest = msg:match("^(%S*)%s*(.-)$")
    if cmd == "" then
        FT.Toggle()
    elseif cmd == "market" or cmd == "craft" or cmd == "signals" or cmd == "portfolio" or cmd == "sell" or cmd == "settings" then
        FT.Show(cmd)
    elseif cmd == "lang" and (rest == "ru" or rest == "en" or rest == "auto") then
        FT.S.lang = rest
        if FT.AskReload then
            FT.AskReload(L["The new language shows after the interface reloads. Reload now?"])
        else
            FT.Print(L["Language changed. Type /reload to apply."])
        end
    elseif cmd == "reset" then
        FT.db.frame = {}
        if FT.ResetWindow then FT.ResetWindow() end
        FT.Print(L["Window position reset."])
    elseif cmd == "debug" then
        FT.debug = not FT.debug
        FT.Print("debug " .. tostring(FT.debug) .. (FT.debug and " - buying, posting and cancelling tell every step in chat" or ""))
        if FT.debug and FT.DebugReport then FT.DebugReport() end
    elseif cmd == "scan" then
        if rest == "mine" or rest == "my" then
            FT.Scanner.AskMine()
        else
            FT.Scanner.StartFull()
        end
    elseif cmd == "support" or cmd == "donate" then
        FT.ShowSupport()
    elseif cmd == "github" or cmd == "git" then
        FT.ShowGitHub()
    elseif cmd == "stop" then
        FT.Scanner.Stop("user")
    elseif cmd == "share" or cmd == "exchange" then
        if rest == "test" then
            FT.Share.Test()
        elseif rest == "stop" then
            FT.Share.Stop()
        else
            FT.Share.Ask(true)
        end
    elseif cmd == "perf" then
        FT.PerfReport()
    elseif cmd == "news" then
        FT.News.Show()
    elseif cmd == "tour" then
        FT.Tour.Start()
    else
        FT.Print("/ft — " .. L["open / close"])
        FT.Print("/ft market | craft | signals | portfolio | sell | settings")
        FT.Print("/ft scan — " .. L["full scan"] .. ",  /ft scan mine — " .. L["My items"] .. ",  /ft stop")
        FT.Print("/ft share — " .. L["ask guild and group for fresh prices"] .. ",  /ft share test — " .. L["check which ways the exchange can use"])
        FT.Print("/ft news — " .. L["what's new"] .. ",  /ft tour — " .. L["the tour of ForeverTrading"])
        FT.Print("/ft perf — " .. L["how fast it works and the memory it takes"])
        FT.Print("/ft lang ru | en | auto,  /ft reset,  /ft github,  /ft support")
    end
end
