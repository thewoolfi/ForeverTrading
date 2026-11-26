-- ForeverTrading: texts. English is the key; Russian below. The language follows the game (Settings can
-- choose) and is applied once at start.
local ADDON, FT = ...

local L = setmetatable({}, { __index = function(_, k) return k end })
FT.L = L

local ru = {}

function FT.ApplyLocale(lang)
    if lang == "ru" then
        for k, v in pairs(ru) do rawset(L, k, v) end
    end
end

-- pages
ru["Market"] = "Рынок"
ru["Craft"] = "Крафт"
ru["Signals"] = "Сигналы"
ru["Portfolio"] = "Портфель"
ru["Settings"] = "Настройки"

-- signals
ru["SELL"] = "ПРОДАВАТЬ"
ru["BUY"] = "ПОКУПАТЬ"
ru["CRAFT"] = "КРАФТИТЬ"
ru["HOLD"] = "ДЕРЖАТЬ"
ru["WATCH"] = "СЛЕДИТЬ"
ru["PRICEY"] = "ДОРОГО"
ru["RISKY"] = "РИСК"
ru["AVOID"] = "УБЫТОК"
ru["LOSS"] = "УБЫТОК"
ru["FAIR"] = "НОРМА"
ru["NO DATA"] = "НЕТ ДАННЫХ"

-- professions
ru["Alchemy"] = "Алхимия"
ru["Blacksmithing"] = "Кузнечное дело"
ru["Enchanting"] = "Наложение чар"
ru["Engineering"] = "Инженерное дело"
ru["Leatherworking"] = "Кожевничество"
ru["Tailoring"] = "Портняжное дело"
ru["Cooking"] = "Кулинария"
ru["First Aid"] = "Первая помощь"
ru["Mining"] = "Горное дело"
ru["Jewelcrafting"] = "Ювелирное дело"
ru["Poisons"] = "Яды"
ru["Inscription"] = "Начертание"
ru["Fishing"] = "Рыбная ловля"
ru["Skinning"] = "Снятие шкур"
ru["Herbalism"] = "Травничество"
ru["Lockpicking"] = "Взлом замков"

-- item categories
ru["Trade goods"] = "Хозяйственные товары"
ru["Consumables"] = "Расходуемые"
ru["Recipes"] = "Рецепты"
ru["Reagents"] = "Реагенты"
ru["Armor"] = "Доспехи"
ru["Weapons"] = "Оружие"
ru["Miscellaneous"] = "Разное"
ru["Containers"] = "Сумки"
ru["Other"] = "Другое"

-- time and numbers
ru["%dm ago"] = "%d мин назад"
ru["%dh ago"] = "%d ч назад"
ru["%dd ago"] = "%d дн назад"
ru["just now"] = "только что"
ru["never"] = "никогда"
ru["1H"] = "1ч"
ru["4H"] = "4ч"
ru["1D"] = "1д"
ru["1W"] = "1н"
ru["24h"] = "24ч"
ru["7d"] = "7д"
ru["14d"] = "14д"
ru["30d"] = "30д"
ru["60d"] = "60д"
ru["7 days"] = "7 дней"
ru["14 days"] = "14 дней"
ru["30 days"] = "30 дней"
ru["45 days"] = "45 дней"
ru["90 days"] = "90 дней"
ru["in 7 days"] = "за 7 дней"

-- core / chat
ru["Loading..."] = "Загрузка..."
ru["Language changed. Type /reload to apply."] = "Язык изменён. Введите /reload, чтобы применить."
ru["Window position reset."] = "Положение окна сброшено."
ru["open / close"] = "открыть / закрыть"

-- analytics
ru["Not enough price history yet"] = "Пока мало истории цен"
ru["%s above the %d-day average"] = "%s выше средней за %d дн."
ru["%s below the %d-day average"] = "%s ниже средней за %d дн."
ru["%s below the %d-day average: wait"] = "%s ниже средней за %d дн. — лучше подождать"
ru["%s above its price of the last hours"] = "%s выше цены последних часов"
ru["%s below its price of the last hours"] = "%s ниже цены последних часов"
ru["%s below its price of the last hours: wait"] = "%s ниже цены последних часов — лучше подождать"
ru["RSI %d: overbought"] = "RSI %d: перекуплен"
ru["RSI %d: oversold"] = "RSI %d: перепродан"
ru["Price near its average"] = "Цена около средней"

-- craft
ru["No price for %s"] = "Нет цены: %s"
ru["a material"] = "материал"
ru["No price for the crafted item"] = "Нет цены на результат крафта"
ru["Loses %s per craft"] = "Убыток %s за крафт"
ru["Small profit: %s (%d%%)"] = "Малая прибыль: %s (%d%%)"
ru["Rarely listed: it may not sell"] = "Редко бывает на аукционе — может не продаться"
ru["Price falling: %s in 7 days"] = "Цена падает: %s за 7 дней"
ru["Profit %s (%d%%)"] = "Прибыль %s (%d%%)"

-- market
ru["no data"] = "нет данных"
ru["history"] = "история"
ru["No data"] = "Нет данных"
ru["Extreme greed"] = "Крайняя жадность"
ru["Greed"] = "Жадность"
ru["Neutral"] = "Нейтрально"
ru["Fear"] = "Страх"
ru["Extreme fear"] = "Крайний страх"
ru["fell to %s (alert: %s or less)"] = "подешевел до %s (алерт: %s и ниже)"
ru["rose to %s (alert: %s or more)"] = "подорожал до %s (алерт: %s и выше)"

-- order book
ru["Order book"] = "Стакан"
ru["asks"] = "продажи"
ru["Price"] = "Цена"
ru["Qty"] = "Кол-во"
ru["Total"] = "Всего"
ru["Cost to buy"] = "Стоимость покупки"
ru["qty"] = "шт"
ru["Buy up to %s"] = "Купить всё до %s"
ru["%d pcs for %s (avg %s)"] = "%d шт за %s (в среднем %s)"
ru["No listings known yet. Search this item on the auction house or run a full scan."] =
    "Лоты пока неизвестны. Найдите предмет на аукционе или запустите полное сканирование."
ru["Best price"] = "Лучшая цена"
ru["%s pcs listed"] = "выставлено %s шт"
ru["%d auctions"] = "%d лотов"
ru["%d sellers"] = "%d продавцов"
ru["Updated %s"] = "Обновлено %s"
ru["full scan"] = "полный скан"
ru["search"] = "поиск"
ru["scan"] = "скан"
ru["Mastercraft"] = "Mastercraft"
ru["Type a quantity"] = "Введите количество"
ru["No price"] = "Нет цены"
ru["by the lowest price (no listings known)"] = "по минимальной цене (лоты неизвестны)"
ru["avg %s each"] = "в среднем %s за шт"
ru["not that many listed"] = "столько не выставлено"

-- main window
ru["Scanning..."] = "Сканирование..."
ru["No scan yet"] = "Сканов ещё не было"
ru["Scan"] = "Скан"
ru["on"] = "вкл"
ru["off"] = "выкл"
ru["Recipes: %d"] = "Рецептов: %d"
ru["Tracked: %d"] = "Отслеживается: %d"
ru["Market: %s items"] = "Рынок: %s позиций"

-- market page
ru["Reading the market..."] = "Читаю рынок..."
ru["Nothing matches"] = "Ничего не найдено"
ru["%s items"] = "%s позиций"
ru["Search item..."] = "Поиск предмета..."
ru["All"] = "Все"
ru["Watchlist"] = "Избранное"
ru["My recipes"] = "Мои рецепты"
ru["I own"] = "У меня"
ru["Rising"] = "Растут"
ru["Falling"] = "Падают"
ru["All categories"] = "Все категории"
ru["Sort: market value"] = "Сорт.: капитализация"
ru["Sort: 24h change"] = "Сорт.: изменение 24ч"
ru["Sort: 7d change"] = "Сорт.: изменение 7д"
ru["Sort: price"] = "Сорт.: цена"
ru["Sort: listed"] = "Сорт.: предложение"
ru["Sort: name"] = "Сорт.: название"
ru["Item"] = "Предмет"
ru["Click: chart || Right-click: watchlist || Shift-click: link"] = "ЛКМ: график || ПКМ: в избранное || Shift: ссылка в чат"
ru["Market overview"] = "Обзор рынка"
ru["Pick an item on the left to see its chart"] = "Выберите предмет слева, чтобы открыть его график"
ru["Items on the market"] = "Позиций на рынке"
ru["Listed value"] = "Стоимость лотов"
ru["Market mood"] = "Настроение рынка"
ru["Last scan"] = "Последний скан"
ru["Value listed on the auction house, by scan"] = "Стоимость всех лотов на аукционе по сканам"
ru["Top gainers 24h"] = "Лидеры роста 24ч"
ru["Top losers 24h"] = "Лидеры падения 24ч"
ru["%s auctions"] = "%s лотов"
ru["after a full scan"] = "после полного скана"
ru["%d%% of %d liquid items rose this week"] = "%d%% из %d ликвидных позиций выросли за неделю"
ru["needs a few days of prices"] = "мало истории цен"
ru["No full scans yet"] = "Полных сканов ещё не было"
ru["7d high"] = "Макс 7д"
ru["7d low"] = "Мин 7д"
ru["Average"] = "Средняя"
ru["30d high"] = "Макс 30д"
ru["30d low"] = "Мин 30д"
ru["Listed"] = "Предложение"
ru["Auctions"] = "Лотов"
ru["Price levels"] = "Цен"
ru["%d price levels"] = "цен: %d"
ru["Sellers"] = "Продавцов"
ru["Moving averages"] = "Скользящие средние"
ru["Two smoothed lines on the price chart: MA7 and MA25, the average price of the last 7 and 25 points (days on 1D). Until there are that many, of the points there are; MA25 shows once there are more than 7."] =
    "Две сглаженные линии на графике цены: MA7 и MA25 — средняя цена за последние 7 и 25 точек (на 1д — дней). Пока точек меньше, считается по тем, что есть; MA25 появляется, когда точек больше 7."
ru["Search on AH"] = "Найти на АХ"
ru["Recipe"] = "Рецепт"
ru["Indicators"] = "Индикаторы"
ru["Signal"] = "Сигнал"
ru["Price alert"] = "Ценовой алерт"
ru["vs average"] = "От средней"
ru["Daily volatility"] = "Волатильность (день)"
ru["Liquidity"] = "Ликвидность"
ru["If you sell"] = "Если продаёте"
ru["If you buy"] = "Если покупаете"
ru["Save"] = "Сохранить"
ru["Checked after every scan. Empty = no alert."] = "Проверяется после каждого скана. Пусто — без алерта."
ru["In watchlist"] = "В избранном"
ru["Watch"] = "В избранное"
ru["below"] = "ниже"
ru["above"] = "выше"
ru["Alert when"] = "Алерт, если цена"
ru["No alert set"] = "Алерт не задан"
ru["No price history"] = "Нет истории цен"
ru["tracked intraday"] = "почасовая история"
ru["you can craft it"] = "вы можете это скрафтить"
ru["you have %s"] = "у вас %s шт"
ru["Back to the market overview"] = "Назад к обзору рынка"
ru["high"] = "высокая"
ru["medium"] = "средняя"
ru["low"] = "низкая"

-- craft page
ru["Profitable: %s"] = "Прибыльных: %s"
ru["Best"] = "Лучший"
ru["Search recipe..."] = "Поиск рецепта..."
ru["Profitable only"] = "Только прибыльные"
ru["All characters"] = "Все персонажи"
ru["Cost"] = "Себест."
ru["What one craft costs: each material at the cheapest of auction house, vendor or crafting it yourself."] =
    "Сколько стоит один крафт: каждый материал по самой низкой цене — аукцион, торговец или собственный крафт."
ru["Sells for"] = "Выручка"
ru["Profit"] = "Прибыль"
ru["Margin"] = "Маржа"
ru["How the crafted item's price moved in 7 days."] = "Как изменилась цена результата крафта за 7 дней."
ru["Click: details || Right-click: price chart"] = "ЛКМ: подробности || ПКМ: график цены"
ru["No recipes yet. Open each profession window once (or let Mastercraft learn them) and they show up here."] =
    "Рецептов пока нет. Откройте окно каждой профессии хотя бы раз (или дайте Mastercraft их запомнить) — и они появятся здесь."
ru["AH"] = "АХ"
ru["vendor"] = "торговец"
ru["vendor~"] = "торговец~"
ru["craft"] = "крафт"
ru["Cost per craft"] = "Себестоимость крафта"
ru["Brings in"] = "Выручка"
ru["Margin / ROI"] = "Маржа / ROI"
ru["Item price"] = "Цена предмета"
ru["Sell now?"] = "Продавать сейчас?"
ru["Materials"] = "Материалы"
ru["dip"] = "просадка"
ru["no price"] = "нет цены"
ru["Cheaper to craft yourself (%s)"] = "Дешевле скрафтить самому (%s)"
ru["Searches the item and all its materials: in Auctionator's Shopping tab when it is installed, otherwise with ForeverTrading's scanner. The auction house must be open; fresh prices and order books follow."] =
    "Ищет предмет и все его материалы: во вкладке \"Покупки\" Auctionator, если он установлен, иначе сканером ForeverTrading. Аукцион должен быть открыт; свежие цены и стаканы подтянутся сами."
ru["Price chart"] = "График цены"
ru["Pick a recipe"] = "Выберите рецепт"
ru["Its costs, profit and materials show here."] = "Здесь появятся его себестоимость, прибыль и материалы."
ru["incomplete"] = "неполные данные"
ru["liquidity"] = "ликвидность"
ru["No history yet"] = "Истории пока нет"
ru["Needs a few days of prices for the item and its materials."] = "Нужно несколько дней цен на предмет и его материалы."

-- signals page
ru["You have %s: worth %s"] = "У вас %s шт на %s"
ru["price is high now"] = "цена сейчас высокая"
ru["Thresholds"] = "Пороги"
ru["Sell now"] = "Продавать сейчас"
ru["What you own, priced above its average; your auctions undercut"] = "Ваши запасы дороже своей средней цены; ваши перебитые лоты"
ru["Worth crafting"] = "Выгодно крафтить"
ru["Your recipes with a good profit"] = "Ваши рецепты с хорошей прибылью"
ru["Worth buying"] = "Выгодно закупать"
ru["Your materials and watchlist on a dip"] = "Ваши материалы и избранное на просадке"
ru["Hold / avoid"] = "Держать / не крафтить"
ru["Below average - wait; recipes at a loss or at risk"] = "Ниже средней — подождать; убыточные и рискованные рецепты"
ru["Nothing you own is priced high right now."] = "Сейчас ничего из ваших запасов не стоит дороже обычного."
ru["No recipe clears your profit and margin thresholds right now."] = "Сейчас ни один рецепт не проходит ваши пороги прибыли и маржи."
ru["None of your materials is on a dip."] = "Ни один из ваших материалов сейчас не на просадке."
ru["Nothing to worry about."] = "Поводов для беспокойства нет."
ru["Sell: %d%% above the %d-day average or RSI 70+.  Buy: %d%% below or RSI 30-.  Craft: profit from %s and margin from %d%%."] =
    "Продажа: на %d%% выше средней за %d дн. или RSI 70+.  Закупка: на %d%% ниже или RSI 30-.  Крафт: прибыль от %s и маржа от %d%%."

-- portfolio page
ru["Bags, banks and mailboxes of your characters on this server, at auction house prices"] =
    "Сумки, банки и почта ваших персонажей на этом сервере по ценам аукциона"
ru["Total worth"] = "Всего активов"
ru["Items"] = "Предметы"
ru["Gold"] = "Золото"
ru["Positions"] = "Позиций"
ru["Worth of what you own today, day by day"] = "Стоимость текущих запасов по дням"
ru["Value"] = "Стоимость"
ru["Share"] = "Доля"
ru["bags"] = "сумки"
ru["bank"] = "банк"
ru["mail"] = "почта"
ru["Nothing priced yet. Open your bags and bank once per character; Mastercraft's records of your alts are used too."] =
    "Пока нечего оценивать. Откройте сумки и банк на каждом персонаже; данные Mastercraft об альтах тоже учитываются."
ru["No price history yet"] = "Истории цен пока нет"
ru["items and gold"] = "предметы и золото"
ru["all characters on this server"] = "все персонажи на этом сервере"
ru["%d worth selling now"] = "%d стоит продать сейчас"
ru["priced items"] = "оценённых предметов"

-- settings page
ru["General"] = "Общие"
ru["Language"] = "Язык"
ru["Game language"] = "Как в игре"
ru["Takes effect after /reload."] = "Применится после /reload."
ru["Window scale"] = "Масштаб окна"
ru["Ticker tape under the header"] = "Бегущая строка под заголовком"
ru["Your watchlist and the day's biggest movers, scrolling. Takes effect after /reload."] =
    "Избранное и главные движения дня бегущей строкой. Применится после /reload."
ru["Minimap button"] = "Кнопка у миникарты"
ru["Button on the auction house"] = "Кнопка на окне аукциона"
ru["Opens ForeverTrading next to the auction house window."] = "Открывает ForeverTrading рядом с окном аукциона."
ru["Lines in item tooltips"] = "Строки в подсказках предметов"
ru["Price change, RSI, the signal and the craft profit of the item."] = "Изменение цены, RSI, сигнал и прибыль крафта предмета."
ru["Prices"] = "Цены"
ru["Count materials you can craft cheaper at their craft cost"] = "Считать материалы по себестоимости, если скрафтить дешевле"
ru["Bars from ore, cloth bolts from cloth...: when one of your characters knows the recipe and it costs less than buying."] =
    "Слитки из руды, рулоны из ткани...: когда рецепт знает один из ваших персонажей и это дешевле покупки."
ru["Alerts"] = "Алерты"
ru["Sound on a price alert"] = "Звук при ценовом алерте"
ru["Message in chat on a price alert"] = "Сообщение в чат при ценовом алерте"
ru["Craft: minimum profit"] = "Крафт: минимальная прибыль"
ru["Craft: minimum margin"] = "Крафт: минимальная маржа"
ru["Sell when the price is above average by"] = "Продавать, если цена выше средней на"
ru["Buy when the price is below average by"] = "Закупать, если цена ниже средней на"
ru["Average over"] = "Средняя за"
ru["Data"] = "Данные"
ru["Intraday history for every item"] = "Почасовая история для всех предметов"
ru["Normally only the items that matter to you get intraday candles (your recipes and materials, watchlist, what you own, what you open). For every item the saved file grows a lot."] =
    "Обычно почасовая история пишется только для важных вам предметов (рецепты и материалы, избранное, запасы, открытые вами). Для всех предметов файл сохранения сильно вырастет."
ru["Keep intraday history for"] = "Хранить почасовую историю"
ru["Clear history"] = "Очистить историю"
ru["Reload UI"] = "Перезагрузить UI"
ru["Language and ticker changes need a reload."] = "Смена языка и бегущей строки требует перезагрузки."
ru["About"] = "О аддоне"
ru["%d items, about %s KB saved"] = "%d предметов, около %s КБ данных"
ru["Remove"] = "Убрать"
ru["Remove items long gone"] = "Убрать давно не виденные"
ru["Not seen for %d+ days: %s items"] = "Не было на аукционе %d+ дней: %s предм."
ru["Nothing to remove: every item was seen in the last %d days (or matters to you)."] =
    "Убирать нечего: все предметы были на аукционе за последние %d дней (или нужны вам)."
ru["Remove the history of %s items not seen on the auction house for %d days or more (both auction houses, about %s KB)? Those that matter to you stay: your recipes and their materials, watchlist, what you own."] =
    "Убрать историю %s предметов, которых не было на аукционе %d дней и больше (на обоих аукционах, около %s КБ)? Нужные вам остаются: рецепты и их материалы, избранное, то, что у вас есть."
ru["Removed the history of %s items not seen for %d days (about %s KB): the saved file is smaller from the next logout or /reload."] =
    "Убрана история %s предметов, которых не было %d дней (около %s КБ). Файл сохранений уменьшится при следующем выходе или /reload."
ru["connected"] = "подключён"
ru["not loaded"] = "не загружен"

-- own scanner
ru["Full scan"] = "Полный скан"
ru["My items"] = "Мои товары"
ru["Stop"] = "Стоп"
ru["Scanning"] = "Сканирование"
ru["Sources"] = "Источники данных"
ru["A scan is already running."] = "Скан уже идёт."
ru["Open the auction house first."] = "Сначала откройте аукцион."
ru["Full scan: waiting for the server..."] = "Полный скан: ждём ответ сервера..."
ru["Full scan: %s / %s auctions"] = "Полный скан: %s / %s лотов"
ru["Full scan: saving..."] = "Полный скан: сохранение..."
ru["Full scan done: %s items, %s auctions."] = "Полный скан готов: %s предметов, %s лотов."
ru["My items: %d / %d"] = "Мои товары: %d / %d"
ru["(paused: you are searching)"] = "(пауза: вы ищете сами)"
ru["My items scanned: %d."] = "\"Мои товары\" просканированы: %d."
ru["Nothing to scan: your items were all seen in the last 10 minutes (or no recipes are known yet)."] =
    "Нечего сканировать: все ваши товары проверены за последние 10 минут (или рецепты ещё неизвестны)."
ru["Scan stopped: the auction house closed."] = "Скан остановлен: аукцион закрыт."
ru["Full scan stopped: the server didn't answer."] = "Полный скан остановлен: сервер не ответил."
ru["Scan stopped."] = "Скан остановлен."
ru["Only what matters to you: what your recipes make and use, your watchlist and what you own - one search each, cheapest first. Any time; it pauses while you search yourself."] =
    "Только то, что важно вам: результаты и материалы ваших рецептов, избранное и ваши запасы — по одному поиску на предмет, от самых дешёвых лотов. В любое время; встаёт на паузу, пока вы ищете сами."
ru["No market data yet: open the auction house and press Full scan."] = "Данных о рынке пока нет: откройте аукцион и нажмите \"Полный скан\"."
ru["No prices for it yet: scan My items or run a full scan at the auction house."] =
    "Цен на него пока нет: просканируйте \"Мои товары\" или сделайте полный скан на аукционе."
ru["Each full scan (yours or Auctionator's) adds a point: the total buyout of everything listed."] =
    "Каждый полный скан (ваш или Auctionator) добавляет точку: суммарный выкуп всех лотов."
ru["seen in scans"] = "встречено в сканах"
ru["press Full scan at the auction house"] = "нажмите \"Полный скан\" на аукционе"
ru["Shows once there are a few days of prices for what you own."] = "Появится, когда накопится несколько дней цен на ваши предметы."
ru["Full scan when the auction house opens"] = "Полный скан при открытии аукциона"
ru["My items: pages per item"] = "\"Мои товары\": страниц на предмет"
ru["Auctions read per item, cheapest first (50 a page). More pages: a deeper order book, a slower scan."] =
    "Сколько лотов читать на предмет, от самых дешёвых (50 на страницу). Больше страниц — глубже стакан, но дольше скан."
ru["Its full scans and searches go into ForeverTrading's history, and the days you haven't scanned yourself come from its price database."] =
    "Его полные сканы и поиски пишутся в историю ForeverTrading, а дни, которые вы сами не сканировали, берутся из его базы цен."
ru["Its price scans go into ForeverTrading's history; the recipes and holdings of alts you haven't logged in with ForeverTrading come from it."] =
    "Его сканы цен пишутся в историю ForeverTrading; рецепты и запасы альтов, на которых вы ещё не заходили с ForeverTrading, берутся из него."
ru["Keep day candles for"] = "Хранить историю цен по дням"
ru["Every item seen on the auction house keeps one candle a day."] = "Каждый встреченный на аукционе предмет получает одну запись в день: цена на открытии и закрытии, минимум и максимум."
ru["60 days"] = "60 дней"
ru["180 days"] = "180 дней"
ru["Clear ForeverTrading's price history (day candles, intraday, order books) of this server's auction house: %s? The other auction house's, Auctionator's and Mastercraft's data stay."] =
    "Очистить историю цен ForeverTrading (по дням и по часам, стаканы) аукциона этого сервера: %s? Данные другого аукциона, Auctionator и Mastercraft останутся."
ru["Price history cleared."] = "История цен очищена."
ru["Prices come from ForeverTrading's own scans (and Auctionator's and Mastercraft's when they are on); recipes from your profession windows and Mastercraft."] =
    "Цены — из собственных сканов ForeverTrading (и Auctionator с Mastercraft, если включены); рецепты — из окон ваших профессий и Mastercraft."

ru["Full scan stopped: another search was made in the auction house before it finished. Press Full scan again."] =
    "Полный скан остановлен: до его окончания на аукционе был сделан другой поиск. Нажмите \"Полный скан\" ещё раз."
ru["A deep scan is allowed once every 15 minutes (next in %s): reading the browse list instead."] =
    "Глубокий скан разрешён раз в 15 минут (следующий через %s): вместо него читается обзор аукциона."
ru["At most once an hour."] = "Не чаще раза в час."
ru["Deep full scan (every auction)"] = "Глубокий полный скан (каждый лот)"
ru["Full scan done: %s items."] = "Полный скан готов: %s предметов."
ru["Full scan: %s items"] = "Полный скан: %s предметов"
ru["Reads every single auction (the game allows it once every 15 minutes): order books and auction counts of every item, not only the lowest price. The game freezes for a few seconds while it is read. In between, the quick full scan runs."] =
    "Читает каждый лот (игра разрешает раз в 15 минут): стаканы и число лотов по каждому предмету, а не только лучшую цену. Пока данные читаются, игра на несколько секунд подвисает. В промежутках работает быстрый полный скан."
ru["The whole auction house in a few seconds: the lowest price and how many are listed of every item. Any time. (Settings > Scanning: a deep scan reads every auction and order book, once every 15 minutes.)"] =
    "Весь аукцион за несколько секунд: лучшая цена и количество по каждому предмету. В любое время. (Настройки > Сканирование: глубокий скан читает каждый лот и стаканы, раз в 15 минут.)"
ru["This client's auction house can't be scanned by ForeverTrading."] = "Аукцион этого клиента ForeverTrading сканировать не умеет."

ru["Profit per craft"] = "Прибыль за 1 крафт"
ru["Selling now: price vs its %d-day average"] = "Выгодность продажи: цена к средней за %d дн."
ru["Shows once there are a few days of prices."] = "Появится, когда накопится несколько дней цен."
ru["Hourly prices are recorded for the items you track (recipes, watchlist, what you own, what you open). This item is tracked now: its hourly line starts with the next scan."] =
    "Почасовые цены пишутся для отслеживаемых предметов (рецепты, избранное, ваши запасы, открытые вами). Этот предмет теперь отслеживается — почасовая линия появится со следующего скана."

ru["Compact"] = "Компактный"
ru["Standard"] = "Стандартный"
ru["Full screen"] = "Во весь экран"

ru["A recipe with less profit gets WATCH instead of CRAFT."] = "Рецепт с меньшей прибылью получает СЛЕДИТЬ вместо КРАФТИТЬ."

ru["Support the author"] = "Поддержать автора"
ru["Support on Boosty"] = "Поддержать на Boosty"
ru["Support ForeverTrading"] = "Поддержать ForeverTrading"
ru["If the addon is useful to you - thank you for your support! Copy the link and open it in your browser:"] =
    "Если аддон вам полезен — спасибо за поддержку! Скопируйте ссылку и откройте её в браузере:"
ru["Source code, releases and bug reports. Copy the link and open it in your browser:"] =
    "Исходный код, релизы и сообщения об ошибках. Скопируйте ссылку и откройте её в браузере:"
ru["Ctrl+C to copy"] = "Ctrl+C — скопировать"
ru["ForeverTrading on GitHub"] = "ForeverTrading на GitHub"
ru["Close"] = "Закрыть"

ru["A newer ForeverTrading is out: %s (you have %s). Get it on CurseForge or GitHub (/ft github)."] =
    "Вышла новая версия ForeverTrading: %s (у вас %s). Скачайте на CurseForge или GitHub (/ft github)."
ru["Update available: %s"] = "Доступна %s"
ru["Tell me about new versions"] = "Сообщать о новых версиях"
ru["ForeverTrading users in your guild and group tell each other which version they have (a hidden addon message): a newer one shows in chat and in the status bar."] =
    "Пользователи ForeverTrading в гильдии и группе сообщают друг другу свою версию (скрытым сообщением аддона): о более новой вы узнаете в чате и в строке состояния."

ru["Style"] = "Стиль"
ru["Dark"] = "Тёмный"
ru["Light"] = "Светлый"
ru["Classic"] = "Классический"
ru["Dark: an exchange terminal at night. Light: the same by day. Classic: the game's own look. Takes effect after a reload."] =
    "Тёмный — биржевой терминал ночью. Светлый — то же днём. Классический — в духе интерфейса игры. Применяется после перезагрузки интерфейса."
ru["The new style shows after the interface reloads. Reload now?"] = "Новый стиль появится после перезагрузки интерфейса. Перезагрузить сейчас?"

ru["The new language shows after the interface reloads. Reload now?"] = "Новый язык появится после перезагрузки интерфейса. Перезагрузить сейчас?"
ru["This change shows after the interface reloads. Reload now?"] = "Изменение применится после перезагрузки интерфейса. Перезагрузить сейчас?"

ru["Too little price history yet: sell and buy signals need at least 3 days of prices before today. A full scan every day fills it."] =
    "Пока мало истории цен: сигналам продажи и закупки нужно хотя бы 3 дня цен до сегодняшнего. Полный скан каждый день их накопит."

-- minimap, auction house, tooltips
ru["Click: open / close"] = "ЛКМ: открыть / закрыть"
ru["Right-click: signals"] = "ПКМ: сигналы"
ru["Drag: move"] = "Перетащить: переместить"
ru["Charts, order books, craft profit and signals"] = "Графики, стаканы, прибыль крафта и сигналы"
ru["Craft: costs %s, profit %s (%d%%)"] = "Крафт: себест. %s, прибыль %s (%d%%)"

-- live prices, the item window, the price exchange
ru["live"] = "онлайн"
ru["live search"] = "живой поиск"
ru["exchange"] = "обмен"
ru["More"] = "Подробнее"
ru["Open in Market"] = "Открыть на рынке"
ru["The item in its own window: large charts and its order book. With the auction house open they stay live."] =
    "Предмет в отдельном окне: большие графики и стакан. При открытом аукционе они обновляются вживую."
ru["Live price of the open item"] = "Живая цена открытого предмета"
ru["While the auction house is open, the item you have open (on the Market or in its own window) is searched again every 8 seconds: its price and order book stay fresh. On the Craft page the recipe's item and its materials take turns, so its cost and profit stay fresh too. It pauses while you search, buy or sell yourself, and slows down when the server is busy."] =
    "Пока открыт аукцион, открытый у вас предмет (на Рынке или в отдельном окне) запрашивается заново каждые 8 секунд: цена и стакан всегда свежие. В Крафте по очереди обновляются предмет рецепта и его материалы, поэтому себестоимость и прибыль тоже свежие. Пауза, пока вы сами ищете, покупаете или продаёте; реже, когда сервер занят."
ru["Exchange"] = "Обмен"
ru["Exchange %d%%"] = "Обмен %d%%"
ru["Sharing %d%%"] = "Отдаю %d%%"
ru["Price exchange"] = "Обмен ценами"
ru["Ask ForeverTrading users in your guild and group for fresher prices of the whole market. Works anywhere, no auction house needed. (Settings > Exchange: by itself when your prices are more than an hour old.)"] =
    "Спросить у пользователей ForeverTrading в гильдии и группе более свежие цены всего рынка. Работает где угодно, аукцион не нужен. (Настройки > Обмен: сам, когда вашим ценам больше часа.)"
ru["ask guild and group for fresh prices"] = "запросить свежие цены у гильдии и группы"
ru["Ask guild and group for fresh prices"] = "Запрашивать свежие цены у гильдии и группы"
ru["When your prices of the whole market are more than an hour old, ForeverTrading asks its users in your guild (then your group) who has fresher ones; the freshest sends its last full scan in the background. At most once an hour."] =
    "Когда вашим ценам всего рынка больше часа, ForeverTrading спрашивает своих пользователей в гильдии (затем в группе), у кого свежее; самый свежий присылает свой последний полный скан в фоне. Не чаще раза в час."
ru["Share my scans"] = "Делиться своими сканами"
ru["When someone in your guild or group asks, your full scan (less than 3 days old and fresher than theirs) goes to them in the background: hidden addon messages, one a second, paused in a fight."] =
    "Когда кто-то в гильдии или группе спрашивает, ваш полный скан (если ему меньше 3 дней и он свежее, чем у спросившего) уходит ему в фоне: скрытыми сообщениями аддона, по одному в секунду, с паузой в бою."
ru["Ask now"] = "Запросить сейчас"
ru["Last received: %s from %s"] = "Последний раз получено: %s от %s"
ru["Nothing received yet"] = "Пока ничего не получено"
ru["Asking ForeverTrading users in your guild and group for fresher prices..."] =
    "Спрашиваю у пользователей ForeverTrading в гильдии и группе более свежие цены..."
ru["Nobody in your guild or group has fresher prices right now."] = "Сейчас ни у кого в гильдии и группе нет более свежих цен."
ru["The game didn't let the question out (it holds addon messages back for a while): try again in a minute."] =
    "Игра не выпустила запрос (она временно придерживает сообщения аддонов): попробуйте через минуту."
ru["No ForeverTrading user in your guild or group answered: they have to be in the game right now, in your guild or group, on your server and side. (An older ForeverTrading stays silent when it has nothing to give: ask them to update it.)"] =
    "Ни один пользователь ForeverTrading в гильдии и группе не ответил: он должен быть в игре прямо сейчас, в вашей гильдии или группе, на вашем сервере и за вашу фракцию. (Старые версии ForeverTrading молчат, когда им нечего дать, — попросите обновить аддон.)"
ru["hasn't scanned the whole auction house yet"] = "полного скана аукциона ещё нет"
ru["their last scan is too old to pass on (%s, older than 3 days)"] = "последний скан слишком старый (%s, старше 3 дней) — такие не передаются"
ru["their scan (%s) isn't fresher than your prices"] = "скан (%s) не свежее ваших цен"
ru["has Share my scans turned off"] = "выключено «Делиться своими сканами»"
ru["offered its prices but didn't begin sending: try again in a few minutes"] =
    "цены были предложены, но отправка не началась — попробуйте через несколько минут"
ru["busy (sending prices or in a fight): try again in a few minutes"] =
    "сейчас занято: уже идёт отправка цен или бой — попробуйте через несколько минут"
ru["The price exchange is already running."] = "Обмен ценами уже идёт."
ru["Exchange stopped: %s prices from %s kept."] = "Обмен остановлен: %s цен от %s сохранено."
ru["Exchange stopped: no more of your prices are sent."] = "Обмен остановлен: ваши цены больше не отправляются."
ru["Exchange stopped."] = "Обмен остановлен."
ru["Click: stop the exchange. What has come stays."] = "Клик — остановить обмен. Уже полученное останется."
ru["The price exchange needs a guild or a group with other ForeverTrading users."] =
    "Для обмена ценами нужна гильдия или группа с другими пользователями ForeverTrading."
ru["Receiving prices from %s (their scan: %s)..."] = "Получаю цены от %s (их скан: %s)..."
ru["Received %s prices from %s (their scan: %s)."] = "Получено цен: %s от %s (их скан: %s)."

-- My recipes: materials under the item
ru["%s per craft of %s"] = "%s на один крафт: %s"
ru["Click: chart and materials || Right-click: watchlist || Shift-click: link"] = "ЛКМ: график и материалы || ПКМ: в избранное || Shift: ссылка в чат"
ru["the item and its materials"] = "предмет и материалы"
ru["Clear"] = "Очистить"

-- My items asks first
ru["Continue"] = "Продолжить"
ru["Cancel"] = "Отмена"
ru["My items: the order book of every item your recipes make and use, your watchlist and what you own - one search each, %s items now. It can take a few minutes. Your own searches at the auction house pause it, and live prices wait for it."] =
    "Мои товары: будут просканированы стаканы всех предметов ваших рецептов (и их материалов), избранного и ваших запасов — по одному поиску на предмет, сейчас их %s. Это может занять несколько минут. Ваши поиски на аукционе ставят скан на паузу, живые цены ждут его окончания."

-- materials next to the order book, our own dialogs
ru["Materials per craft"] = "Материалы на 1 крафт"
ru["Open it on the Craft page"] = "Открыть во вкладке «Крафт»"
ru["Later"] = "Позже"
ru["Averages"] = "Средние"
ru["Below"] = "Ниже"
ru["Above"] = "Выше"

-- open a recipe in the profession window
ru["Open recipe"] = "Открыть рецепт"
ru["Opens this recipe in the game's profession window."] = "Открывает этот рецепт в окне профессии игры."
ru["Known by %s: log in with them to craft it."] = "Рецепт знает: %s. Зайдите этим персонажем, чтобы скрафтить."
ru["Not during a fight."] = "Не во время боя."
ru["Open the %s window: the recipe is chosen there by itself."] = "Откройте окно профессии «%s» — рецепт выберется в нём сам."

-- buyouts: the fair price now
ru["buyout? counted at %s"] = "перекуп? расчёт по %s"
ru["Don't trust buyouts"] = "Не верить перекупам"
ru["Price jump (buyout?): %s above its fair price ~%s - sell a little under it now, it won't last"] =
    "Скачок цены (перекуп?): на %s выше справедливой ~%s — продавайте чуть дешевле сейчас, долго не продержится"
ru["price jump (buyout?): fair ~%s"] = "скачок цены (перекуп?): справедливая ~%s"
ru["falling fast: %s, fair ~%s"] = "цена быстро падает: %s, справедливая ~%s"
ru["Price falling fast: %s vs its fair price"] = "Цена быстро падает: %s к справедливой"
ru["Jump: above the fair price by"] = "Скачок: выше справедливой на"
ru["Falling fast: below the fair price by"] = "Быстрое падение: ниже справедливой на"
ru["Other crafters undercut: a craft of an item falling this fast gets RISKY - by the time yours is listed the price may be lower still."] =
    "Конкуренты-крафтеры сбивают цену: крафт предмета, который так быстро дешевеет, получает РИСК — пока вы скрафтите и выставите, цена может упасть ещё."
ru["Someone bought out the cheap lots and listed them far higher: the lowest price then says little. The fair price is the median of the prices of the last days up to an hour ago, each weighted by how many were listed at it and how recent it is. When the price is far above it, profits and signals count the fair price."] =
    "Кто-то скупил дешёвые лоты и выставил их намного дороже — тогда минимальная цена мало что значит. Справедливая цена — медиана цен за последние дни (без последнего часа), где каждая цена весит столько, сколько лотов за ней стояло, и тем больше, чем она свежее. Когда цена намного выше справедливой, прибыль и сигналы считаются по справедливой цене."

-- in place of the auction house window
ru["AH: online"] = "АХ: онлайн"
ru["AH: offline"] = "АХ: офлайн"
ru["Auction house: online"] = "Аукцион: онлайн"
ru["Auction house: offline"] = "Аукцион: офлайн"
ru["Talk to an auctioneer. Until then: the last known prices."] = "Подойдите к аукционисту. А пока — последние известные цены."
ru["The game's auction house window is hidden behind ForeverTrading. Click: show it (buying, selling, Auctionator)."] =
    "Окно аукциона игры спрятано за ForeverTrading. Клик — показать его (покупка, продажа, Auctionator)."
ru["Click: hide the game's auction house window behind ForeverTrading (Settings: open ForeverTrading in its place)."] =
    "Клик — спрятать окно аукциона игры за ForeverTrading (Настройки: открывать ForeverTrading вместо него)."
ru["Open ForeverTrading instead of the auction house window"] = "Открывать ForeverTrading вместо окна аукциона"
ru["Talking to an auctioneer opens ForeverTrading; the game's window stays open behind it, unseen. The \"AH: online\" pill in the header brings it back for buying and selling (and Auctionator). Walking away: the terminal goes offline with the last known prices."] =
    "При разговоре с аукционистом открывается ForeverTrading, а окно аукциона игры остаётся открытым, но невидимым. Индикатор «АХ: онлайн» в шапке возвращает его — для покупки и продажи (и Auctionator). Если отойти, терминал переходит в офлайн с последними известными ценами."

-- buying from the order book
ru["Buy"] = "Купить"
ru["Click: that many in the buy box below."] = "Клик — столько в поле покупки внизу."
ru["Talk to an auctioneer to buy."] = "Чтобы купить, подойдите к аукционисту."
ru["Gear is bought one auction at a time: its cheapest with a buyout. You confirm its price first."] =
    "Экипировка покупается по одному лоту — самый дешёвый с выкупом. Сначала вы подтверждаете его цену."
ru["Type a quantity or click a price in the order book."] = "Введите количество или кликните по цене в стакане."
ru["The cheapest that many: the server tells their exact price first, you confirm."] =
    "Столько самых дешёвых: сначала сервер сообщит точную цену, вы подтвердите."
ru["A purchase is waiting for the server."] = "Покупка ждёт ответа сервера."
ru["The purchase didn't go through."] = "Покупка не прошла."
ru["Not enough gold: %s needed."] = "Не хватает золота: нужно %s."
ru["Buy %s x %s for %s?"] = "Купить %s x %s за %s?"
ru["%s each - the server's price right now."] = "По %s за штуку — цена сервера на этот момент."
ru["Dearer than the order book showed (%s each): some lots were bought meanwhile."] =
    "Дороже, чем было в стакане (%s за штуку): часть лотов успели купить."
ru["The price isn't available any more: the lots changed. Try again."] = "Цена больше недоступна: лоты изменились. Попробуйте ещё раз."
ru["Bought: %s x %s for %s."] = "Куплено: %s x %s за %s."
ru["No auction of it to buy out right now."] = "Сейчас нет лота с выкупом."
ru["Buy out %s for %s?"] = "Выкупить %s за %s?"
ru["Its cheapest auction with a buyout right now."] = "Его самый дешёвый лот с выкупом на этот момент."
ru["No answer from the server about the purchase: check your bags and mailbox."] = "Сервер не ответил о покупке — проверьте сумки и почту."
ru["Answer the question about the purchase first."] = "Сначала ответьте на вопрос о покупке."
ru["The game's auction house window is busy buying or selling: finish there first."] = "Окно аукциона игры сейчас занято покупкой или продажей — сначала закончите там."
ru["The item is still loading: try again in a moment."] = "Данные предмета ещё загружаются — попробуйте через мгновение."
ru["The price changed: it was %s, now %s."] = "Цена изменилась: было %s, стало %s."
ru["The server's price ran out: press Buy again."] = "Цена сервера устарела — нажмите «Купить» ещё раз."
ru["Bought out: %s for %s."] = "Выкуплено: %s за %s."
ru["The auction house is busy: try again in a few seconds."] = "Аукцион занят — попробуйте через несколько секунд."
ru["All subcategories"] = "Все подкатегории"

-- the auction house's filters on the Market list
ru["Filter"] = "Фильтр"
ru["Required level, usable, not collected, quality - as on the auction house."] =
    "Требуемый уровень, только используемые, только недостающие, качество — как на аукционе."
ru["Levels"] = "Уровни"
ru["Usable only"] = "Только используемые"
ru["Not collected only"] = "Только недостающие"
ru["Quality"] = "Качество"
ru["Reset"] = "Сбросить"

-- the Selling page
ru["Selling"] = "Продажа"
ru["Your bags"] = "Ваши сумки"
ru["worth %s"] = "на %s"
ru["Nothing in your bags the auction house would take."] = "В сумках нет ничего, что принял бы аукцион."
ru["Cheapest listed"] = "Самая низкая цена"
ru["Fair price"] = "Справедливая"
ru["Vendor pays"] = "Торговец даст"
ru["Quantity"] = "Количество"
ru["Max"] = "Макс"
ru["Price per unit"] = "Цена за штуку"
ru["1%s under"] = "На 1%s дешевле"
ru["A copper under the cheapest"] = "На 1 медь дешевле самой низкой"
ru["Yours becomes the cheapest listing: it sells first."] = "Ваш лот станет самым дешёвым — продастся первым."
ru["At the cheapest"] = "По самой низкой"
ru["The same price as the cheapest listing now."] = "Та же цена, что у самого дешёвого лота сейчас."
ru["The median of the last days' prices, weighted by how many were listed and how recent."] = "Медиана цен за последние дни, взвешенная по числу лотов и свежести."
ru["Duration"] = "Срок"
ru["For all"] = "За весь лот"
ru["Deposit (back when it sells)"] = "Залог (вернётся при продаже)"
ru["You get"] = "Вы получите"
ru["Post"] = "Выставить"
ru["Post anyway"] = "Всё равно выставить"
ru["Post an auction"] = "Выставить лот"
ru["Post asks once more with everything before anything happens."] = "Перед выставлением аддон ещё раз покажет все цифры и спросит."
ru["Pick an item"] = "Выберите предмет"
ru["What you carry is on the left: pick one to post it."] = "Слева — то, что у вас в сумках. Выберите предмет, чтобы выставить его."
ru["pcs"] = "шт."
ru["none listed"] = "лотов нет"
ru["in your bags: %s"] = "в сумках: %s"
ru["posted one at a time"] = "выставляется по одному"
ru["all your stacks in one posting"] = "все стопки — одним лотом"
ru["of %s"] = "из %s"
ru["Less than a vendor pays (%s each, no cut, no waiting)."] = "Дешевле, чем даст торговец (%s за шт. — без комиссии и ожидания)."
ru["%s under the fair price (%s)."] = "На %s ниже справедливой цены (%s)."
ru["Dearer than the cheapest listing (%s): yours sells after it."] = "Дороже самого дешёвого лота (%s): ваш продастся после него."
ru["A price jump right now (buyout?): the fair price is ~%s - it may not last."] = "Сейчас скачок цены (перекуп?): справедливая ~%s — может не продержаться."
ru["The price is falling fast: %s vs its fair price."] = "Цена быстро падает: %s к справедливой."
ru["Talk to an auctioneer to sell."] = "Чтобы продать, подойдите к аукционисту."
ru["The item isn't in that bag slot any more."] = "Предмета больше нет в этой ячейке сумки."
ru["The auction house doesn't take this item."] = "Аукцион не принимает этот предмет."
ru["Post %s x %s at %s each?"] = "Выставить %s x %s по %s за штуку?"
ru["For all: %s. For %d hours."] = "За весь лот: %s. На %d ч."
ru["You get %s when it all sells."] = "Вы получите %s, когда всё продастся."
ru["No answer from the server about the posting: look in the auction house window."] = "Сервер не ответил о выставлении — проверьте в окне аукциона."
ru["Not enough gold for the deposit: %s needed."] = "Не хватает золота на залог: нужно %s."
ru["The auction house warns: this price is far from the usual one. Post anyway?"] = "Аукцион предупреждает: цена сильно отличается от обычной. Всё равно выставить?"
ru["Posted: %s x %s at %s each."] = "Выставлено: %s x %s по %s за штуку."
ru["The posting didn't go through: check the auction house window."] = "Выставить не удалось — проверьте окно аукциона."
ru["Your bags changed: the posting is cancelled. Check it and press Post again."] = "Сумки изменились — выставление отменено. Проверьте и нажмите «Выставить» ещё раз."
ru["Finish the purchase or posting under way first."] = "Сначала завершите текущую покупку или выставление."
ru["The market prices are from %s: wait for the live update at the auction house."] = "Цены рынка — %s: дождитесь живого обновления у аукциониста."
ru["Gear: the prices are of its cheapest version listed - check yours (item level, \"of the ...\")."] = "Экипировка: цены — самой дешёвой выставленной версии. Сверьте со своей (уровень, суффикс «…»)."
ru["%dh"] = "%d ч"
ru["of the last days"] = "по последним дням"
ru["no cut, no waiting"] = "без комиссии и ожидания"

-- my auctions
ru["My auctions"] = "Мои лоты"
ru["Yours"] = "Ваша"
ru["Lowest"] = "Мин."
ru["Left"] = "Осталось"
ru["left"] = "осталось"
ru["sold"] = "продан"
ru["ended?"] = "истёк?"
ru["%dh %dm"] = "%d ч %d мин"
ru["%dm"] = "%d мин"
ru["under 30 min"] = "< 30 мин"
ru["30 min - 2 h"] = "30 мин – 2 ч"
ru["2 - 8 h"] = "2 – 8 ч"
ru["8 - 24 h"] = "8 – 24 ч"
ru["Refresh"] = "Обновить"
ru["Check the prices"] = "Проверить цены"
ru["Reads the order book of every item you have up: who undercut you, now. One search each."] =
    "Читает стакан каждого вашего выставленного предмета: кто вас перебил — прямо сейчас. По одному поиску на предмет."
ru["Talk to an auctioneer to see your auctions as they are now."] = "Чтобы увидеть лоты как сейчас, подойдите к аукционисту."
ru["No auctions of yours known. Post something, or open the auction house."] = "Ваших лотов не видно. Выставьте что-нибудь или откройте аукцион."
ru["%d up, worth %s"] = "%d лотов на %s"
ru["%d undercut"] = "перебито: %d"
ru["as of %s"] = "на момент: %s"
ru["Undercut: the lowest is %s, yours %s."] = "Перебили: самая низкая %s, ваша %s."
ru["Yours is the cheapest (as far as is known)."] = "Ваш лот самый дешёвый (насколько известно)."
ru["Your price"] = "Ваша цена"
ru["Cancel the auction"] = "Снять с аукциона"
ru["Keep it"] = "Оставить"
ru["It comes back by mail; the deposit isn't returned."] = "Предмет вернётся по почте, залог не возвращается."
ru["Pick an auction"] = "Выберите лот"
ru["Your auctions are on the left: undercut ones first."] = "Слева — ваши лоты, перебитые — первыми."
ru["sold: the gold comes by mail"] = "продан — золото придёт по почте"
ru["all: %s"] = "всего: %s"
ru["Sold."] = "Продан."
ru["Undercut by %s (%s)."] = "Вас перебили на %s (%s)."
ru["Yours is the cheapest."] = "Ваш лот самый дешёвый."
ru["As of %s: Check the prices for now."] = "Данные — %s: «Проверить цены», чтобы узнать, как сейчас."
ru["No market price known."] = "Цена рынка неизвестна."
ru["Check the prices: one search for each of your items."] = "«Проверить цены» — по одному поиску на каждый ваш предмет."
ru["Talk to an auctioneer to cancel."] = "Чтобы снять лот, подойдите к аукционисту."
ru["Take %s x %s off the auction house?"] = "Снять с аукциона %s x %s?"
ru["Cancelling costs %s."] = "Снятие стоит %s."
ru["The auction wasn't cancelled."] = "Лот не снят."
ru["Taken off: %s x %s (it comes by mail)."] = "Снято: %s x %s (придёт по почте)."
ru["Reading your auctions from the auction house: the question comes in a moment."] = "Читаю ваши лоты у аукциона — вопрос о снятии появится через мгновение."
ru["That auction isn't up any more (sold or ended)."] = "Этого лота уже нет на аукционе (продан или истёк)."
ru["The auction house asks to confirm the posting."] = "Аукцион просит подтвердить выставление."
ru["WoW Forever lets only its own auction house window cancel auctions: open its Auctions tab and cancel there."] =
    "WoW Forever разрешает снимать лоты только в своём окне аукциона: откройте в нём вкладку «Аукционы» и снимите там."
ru["WoW Forever lets only its own auction house window post auctions: use its Sell tab (the prices and warnings here still help)."] =
    "WoW Forever разрешает выставлять лоты только в своём окне аукциона: выставьте на его вкладке «Продажа» (цены и предупреждения здесь по-прежнему помогут)."
ru["WoW Forever lets only its own auction house window buy: buy there (the order book here shows what it costs)."] =
    "WoW Forever разрешает покупать только в своём окне аукциона: купите там (стакан здесь покажет, сколько это стоит)."
ru["Cancel in the game's window"] = "Снять в окне аукциона"

-- the price exchange test
ru["check which ways the exchange can use"] = "проверить, какими путями может идти обмен"
ru["Exchange test: which ways the game carries ForeverTrading's hidden messages (the realm restricts addon messages: %s)..."] =
    "Проверка обмена: какими путями игра пропускает скрытые сообщения ForeverTrading (сервер ограничивает сообщения аддонов: %s)..."
ru["the game refused to send it (code %s)"] = "игра отказалась отправить (код %s)"
ru["the game found no player named %s"] = "игра не нашла персонажа «%s»"
ru["works"] = "работает"
ru["sent, but it didn't come back: this way seems not to work here"] = "отправлено, но не вернулось — похоже, здесь этот путь не работает"
ru["works, but some characters come changed: the compact exchange can't go this way"] =
    "работает, но часть символов приходит изменённой — плотный обмен этим путём не пройдёт"
ru["The exchange: the compact data came changed on the way. From now on the old format is asked for - press Exchange again."] =
    "Обмен: плотные данные пришли искажёнными. Дальше будет запрашиваться старый формат — нажмите «Обмен» ещё раз."
ru["guild"] = "гильдия"
ru["group"] = "группа"
ru["whisper"] = "шёпот"
ru["yes"] = "да"
ru["no"] = "нет"
ru["unknown"] = "неизвестно"

-- risks: the competition, since the last check and against what is usual
ru["%s since the check %s"] = "%s с замера %s"
ru["Flooded: %s listed, usually ~%s"] = "Завал: выставлено %s, обычно ~%s"
ru["More sellers: %d, usually ~%d"] = "Больше продавцов: %d, обычно ~%d"
ru["flooded: %s listed (usually ~%s)"] = "завал: выставлено %s (обычно ~%s)"
ru["%d sellers (usually ~%d)"] = "продавцов: %d (обычно ~%d)"
ru["The price went %s since the check %s: others undercut."] = "Цена %s с замера %s: другие сбивают цену."
ru["Flooded: %s listed, usually ~%s - it may sell slowly, and undercuts come."] =
    "Завал: выставлено %s, обычно ~%s — может продаваться медленно, будут перебивать."
ru["More sellers than usual: %d, usually ~%d - expect undercuts."] =
    "Продавцов больше обычного: %d, обычно ~%d — скорее всего, вас перебьют."
ru["Flooded: more than usual by"] = "Завал: больше обычного на"
ru["More listed than usual, or more sellers than usual, by this much: competitors have come, and a price that holds now may not hold long. A craft of it gets RISKY and the Sell page warns. Usual: the average of the last days up to an hour ago (sellers are counted from the searches of an item: My items, live prices, the items you open). A price 10% lower than at the last check half an hour or more ago is RISKY too."] =
    "Выставлено больше обычного или продавцов больше обычного на столько: пришли конкуренты, и цена, которая держится сейчас, может скоро упасть. Крафт такого предмета получает РИСК, а страница продажи предупреждает. Обычное — среднее за последние дни, без последнего часа (продавцов видно только по поиску предмета: «Мои товары», живые цены, открытые предметы). Цена на 10% ниже, чем при замере полчаса и более назад, — тоже РИСК."

-- good deals
ru["TO VENDOR"] = "ТОРГОВЦУ"
ru["RESELL"] = "ПЕРЕПРОДАЖА"
ru["Good deals"] = "Сделки"
ru["To a vendor"] = "Торговцу"
ru["Resell"] = "Перепродать"
ru["Prices not older than"] = "Цены не старше"
ru["1 h"] = "1 ч"
ru["6 h"] = "6 ч"
ru["24 h"] = "24 ч"
ru["Check order books"] = "Проверить стаканы"
ru["Check order books (%d)"] = "Проверить стаканы (%d)"
ru["Searches the auction house for the deals seen without an order book: how many cheap lots there really are (one search each, like My items)."] =
    "Ищет на аукционе предметы сделок, у которых не загружен стакан: сколько дешёвых лотов там на самом деле (по одному поиску на предмет, как «Мои товары»)."
ru["To a vendor: a sure profit. Resell: the cheap lots of a steady market, listed again near the fair price. Between houses: cheaper at one auction house than the other sells it for."] =
    "Торговцу: прибыль без риска. Перепродать: дешёвые лоты спокойного рынка, выставить снова около справедливой цены. Между аукционами: на одном аукционе дешевле, чем продаётся на другом."
ru["%s each, a vendor pays %s: +%s each"] = "%s за шт., торговец даст %s: +%s за шт."
ru["%s each, fair ~%s: list at %s, +%s each after the cut"] = "%s за шт., справедливая ~%s: выставить по %s, +%s за шт. после комиссии"
ru["the cheapest lot"] = "самый дешёвый лот"
ru["%s pcs"] = "%s шт."
ru["Buy: %s for %s"] = "Купить: %s за %s"
ru["Sell them to a vendor for %s each: no cut, no waiting."] = "Продать торговцу по %s за шт.: без комиссии и ожидания."
ru["Profit: %s"] = "Прибыль: %s"
ru["Only the cheapest lot is sure: open the item (or Check order books) for its whole order book."] =
    "Точно известен только самый дешёвый лот: откройте предмет (или нажмите «Проверить стаканы»), чтобы увидеть весь стакан."
ru["Click: the item with its order book - buy there."] = "Клик: предмет со стаканом — покупать там."
ru["Looking for deals..."] = "Ищу сделки..."
ru["Blackwater"] = "Черноводье"
ru["CARRY OVER"] = "ПЕРЕВОЗ"
ru["Between houses"] = "Между аукционами"
ru["%s each at %s, %s at %s: +%s each after its cut"] = "купить за %s (%s) — продать за %s (%s): +%s за шт. после комиссии"
ru["sells there"] = "там продаётся"
ru["here %s, there %s"] = "здесь %s, там %s"
ru["Buy at %s: %s for %s (price of %s)"] = "Купить (%s): %s за %s, цена %s"
ru["in your list"] = "в списке"
ru["in your list since %s"] = "добавлено в список %s"
ru["Right click: out of your carry list."] = "Правый клик: убрать из списка закупки."
ru["Right click: into your carry list - at %s the Sell page shows what you brought and what it cost."] =
    "Правый клик: в список закупки — там, где продавать (%s), вкладка «Продажа» покажет, что вы привезли и почём купили."
ru["Carry list: %s - buy at %s for up to %s each, list at %s for ~%s."] =
    "Список закупки: %s — купить (%s) не дороже %s за шт., выставить (%s) около %s."
ru["Carry list: %s is out of it."] = "Список закупки: %s убран."
ru["brought"] = "привезено"
ru["bought at %s for %s each: list at ~%s"] = "куплено (%s) по %s: ставить около %s"
ru["Carry it to %s and list it at %s each: its cut there is %s (the deposit comes back when it sells; unsold, it is lost)."] =
    "Отвезти (%s) и выставить по %s за шт.: комиссия там %s (залог вернётся при продаже, а если не продастся — сгорит)."
ru["listed there: %s"] = "там выставлено: %s"
ru["usual there: %s"] = "обычно там: %s"
ru["price there: %s"] = "цена там: %s"
ru["%s pcs are this cheap: no more than %s - more doesn't sell there in two days."] =
    "Так дёшево %s шт., но берите не больше %s: больше там за два дня не продастся."
ru["Fewer than 3 days of prices there: look at its order book before buying much."] =
    "Там цены известны меньше 3 дней: посмотрите стакан, прежде чем покупать много."
ru["No prices of %s yet: scan there once - deals between the houses compare both."] =
    "Цен аукциона «%s» ещё нет: отсканируйте его хотя бы раз — сделки между аукционами сравнивают оба."
ru["The prices of %s are from %s: deals between the houses take them up to 3 days old."] =
    "Цены аукциона «%s» — %s: сделки между аукционами берут цены не старше 3 дней."
ru["Between the auction houses"] = "Торговля между аукционами"
ru["Signals > Deals > Between houses: cheaper at one auction house than the other sells it for - buy, carry it over, list it there; each house's cut counted, no more than sells there in two days."] =
    "«Сигналы > Сделки > Между аукционами»: что на одном аукционе дешевле, чем продаётся на другом, — купить, отвезти, выставить там; комиссия каждого аукциона учтена, и не больше, чем там продаётся за два дня."
ru["Your faction"] = "Ваша фракция"
ru["Not while scanning: the prices being read belong to the auction house they come from."] =
    "Не во время скана: читаемые цены принадлежат аукциону, с которого они пришли."
ru["Blackwater auction house: its prices, history and your auctions there are kept apart from your faction's."] =
    "Аукцион Черноводья: его цены, история и ваши лоты там хранятся отдельно от аукциона фракции."
ru["Auction house: %s."] = "Аукцион: %s."
ru["Auction house: %s"] = "Аукцион: %s"
ru["This is %s?"] = "Это аукцион «%s»?"
ru["The prices seen at this auctioneer go to %s from now on, and ForeverTrading remembers it for the auctioneers here."] =
    "Цены у этого аукциониста с этого момента пойдут в «%s», и ForeverTrading запомнит это для аукционистов здесь."
ru["You stand at %s: online while its prices are on, offline with the other's."] =
    "Вы стоите у аукциона «%s»: онлайн, пока выбраны его цены, и офлайн с ценами другого."
ru["You stand at %s, the prices of %s are on: nothing is read here, bought or posted. The chip next to it switches back."] =
    "Вы стоите у аукциона «%s», а выбраны цены «%s»: здесь ничего не читается, не покупается и не выставляется. Чип рядом переключит обратно."
ru["Wrong auction house?"] = "Не тот аукцион?"
ru["Whose prices this window shows, whatever the main window and the other windows show. Click: %s."] =
    "Чьи цены в этом окне — независимо от главного окна и других окон. Клик — «%s»."
ru["You stand at %s, the prices of %s are on: switch on the chip in the header first."] =
    "Вы стоите у аукциона «%s», а выбраны цены «%s»: сначала переключите чип в шапке."
ru["Click if this auctioneer is of %s, not %s: ForeverTrading puts it right and remembers it for the auctioneers here."] =
    "Клик, если этот аукционист от аукциона «%s», а не «%s»: ForeverTrading исправит это и запомнит для аукционистов здесь."
ru["Whose prices the pages show: your faction's auction house or Blackwater, the neutral one shared by both factions. Each keeps its own prices, history, deals and your auctions. Click: %s."] =
    "Чьи цены на страницах: аукцион вашей фракции или Черноводье — нейтральный, общий для обеих фракций. У каждого свои цены, история, сделки и ваши лоты. Клик — «%s»."
ru["Which auction house"] = "Какой аукцион"
ru["Your faction's or Blackwater, the neutral one: each keeps its own prices. Talking to an auctioneer picks its house; a click shows the other one's prices (at an auctioneer: offline there). The pencil: this auctioneer is of the other house."] =
    "Вашей фракции или Черноводье, нейтральный: у каждого свои цены. Аукционист сам выбирает свой аукцион; клик показывает цены другого (у аукциониста — офлайн там). Карандаш: этот аукционист от другого аукциона."
ru["Blackwater apart"] = "Черноводье отдельно"
ru["The neutral auction house keeps its own prices, history, deals and your auctions: a scan there doesn't touch your faction's. Talking to an auctioneer picks its house; the chip next to the auction house status switches whose prices you see, the pencil on it puts a wrong auction house right."] =
    "У нейтрального аукциона свои цены, история, сделки и ваши лоты: скан там не трогает аукцион фракции. Аукционист сам выбирает свой аукцион; чип рядом со статусом аукциона переключает, чьи цены вы смотрите, а карандаш на нём исправляет неверно определённый аукцион."
ru["Deals on any computer"] = "Сделки на любом компьютере"
ru["A faster exchange"] = "Обмен быстрее"
ru["Item windows"] = "Окна предметов"
ru["More: the item in a window of its own - up to four at once, two items side by side. Each window has its own auction house (its chip) and a compact mode with the charts alone."] =
    "«Подробнее»: товар в отдельном окне — до четырёх сразу, два товара рядом. У каждого окна свой аукцион (свой чип) и компактный режим только с графиками."
ru["A tidier look"] = "Аккуратнее вид"
ru["Hotfix"] = "Срочное исправление"
ru["Faster"] = "Быстрее"
ru["Saving a scan is three to four times as fast and far lighter on the game's memory: prices are written into the saved file once, when you log out. After a scan only the items that changed are counted again, a little each frame. /ft perf shows what each part took and the memory it takes."] =
    "Скан сохраняется в 3–4 раза быстрее и гораздо меньше нагружает память игры: цены пишутся в файл сохранений один раз — при выходе. После скана заново считаются только изменившиеся предметы, понемногу в каждом кадре. /ft perf показывает, сколько заняла каждая часть и сколько памяти у аддона."
ru["Without Auctionator"] = "Без Auctionator"
ru["ForeverTrading goes by its own scans: top gainers and losers, the market mood, an item's changes, signals, liquidity and reselling work from the first days of scanning - while an auction house has been scanned on fewer days, fewer days of prices are asked for. Auctionator and Mastercraft only fill in what is missing."] =
    "ForeverTrading опирается на свои сканы: лидеры роста и падения, настроение рынка, изменения цены, сигналы, ликвидность и перепродажа работают с первых дней сканирования — пока аукцион сканировали меньше дней, и истории требуется меньше. Auctionator и Mastercraft только дополняют то, чего не хватает."
ru["The carry list"] = "Список закупки"
ru["Signals > Deals > Between houses: a right click on a deal puts it on your carry list. It stays on the page (even when the deal is gone), and at the other auction house the Sell page marks what you brought and what it cost."] =
    "«Сигналы > Сделки > Между аукционами»: правый клик по сделке добавляет её в список закупки. Она остаётся на странице (даже когда сделки уже нет), а на другом аукционе вкладка «Продажа» помечает, что вы привезли и почём купили."
ru["A smaller saved file"] = "Файл сохранений меньше"
ru["Settings > Data: remove the history of items not seen on either auction house for 30 days - the ones that matter to you stay. Less for the game to load at login."] =
    "«Настройки > Данные»: убрать историю предметов, которых не было ни на одном аукционе 30 дней, — нужные вам остаются. Игре меньше загружать при входе."
ru["A lighter exchange"] = "Обмен легче"
ru["About a third fewer messages between two players with 1.1.4: prices come sooner. /ft share test also checks that every character comes through."] =
    "Между игроками с 1.1.4 примерно на треть меньше сообщений — цены приходят быстрее. /ft share test заодно проверяет, что все символы доходят."
ru["Our own font"] = "Свой шрифт"
ru["Sofia Sans Condensed: narrow, with Cyrillic, no Mastercraft needed for it (the classic style keeps the game's). After updating, restart the game once."] =
    "Sofia Sans Condensed: узкий, с кириллицей, Mastercraft для него больше не нужен (классическая тема — со шрифтом игры). После обновления один раз перезапустите игру."
ru["Cheaper at one auction house than the other sells it for. A right click on a deal puts it on your carry list: it stays here, and at the other auction house the Sell page shows what you brought and what it cost."] =
    "Что на одном аукционе дешевле, чем продаётся на другом. Правый клик по сделке — в список закупки: она остаётся здесь, а на другом аукционе вкладка «Продажа» покажет, что вы привезли и почём купили."
ru["The ForeverTrading tab on the auction house window works without Auctionator too."] =
    "Вкладка ForeverTrading на окне аукциона работает и без Auctionator."
ru["Choices are one framed switch, tinted buttons have an edge, corners are slightly rounded, rows and filters line up; the light style shows hovered and chosen rows."] =
    "Переключатели — единый элемент в рамке, у цветных кнопок контур, углы чуть скруглены, ряды и фильтры выровнены; в светлой теме видно наведённые и выбранные строки."
ru["The deals journal counts what was sold (Forever's letters say 0) and keeps up with Collect all; no exchange during your own scan; the Settings columns stay; the ticker shows the market's most valuable listings while there are no moves yet."] =
    "Журнал сделок считает проданное (письма Forever пишут 0) и успевает за «Собрать все»; обмен не идёт во время вашего скана; колонки настроек не пропадают; бегущая строка показывает самые дорогие лоты, пока нет движений цен."
ru["More opens up to four item windows at once - two items side by side. Each has a compact mode (the charts alone) and its own auction house."] =
    "«Подробнее» открывает до четырёх окон предметов сразу — два товара рядом. У каждого есть компактный режим (только графики) и свой аукцион."
ru["Prices go three times as fast between two players with 1.1.2 (three lanes at once). Exchange pressed again stops it; what has come stays."] =
    "Цены идут в три раза быстрее между игроками с 1.1.2 (три канала сразу). Повторное нажатие «Обмен» останавливает его, полученное остаётся."
ru["Signals > Deals asks the game for what vendors pay (a new computer or game knows hardly any), and says why there are none: old prices, too little history, the minimum profit."] =
    "«Сигналы > Сделки» сами узнают у игры цены торговцев (новый компьютер или игра их почти не знает) и объясняют, почему сделок нет: старые цены, мало истории, минимальная прибыль."
ru["No prices yet: deals are looked for in the auction house's prices - scan it at the auction house."] =
    "Цен ещё нет: сделки ищутся в ценах аукциона — отсканируйте его у аукциониста."
ru["No good deals right now."] = "Сейчас выгодных сделок нет."
ru["%d more with older prices: choose 24 h, or scan the auction house again."] =
    "Ещё %d — по ценам старше выбранного срока: выберите «24 ч» или отсканируйте аукцион заново."
ru["Newest prices: %s - scan the auction house again."] = "Самые свежие цены — %s: отсканируйте аукцион заново."
ru["Vendor prices are still loading: deals to a vendor follow."] = "Цены торговцев ещё загружаются — сделки «Торговцу» появятся следом."
ru["Reselling needs at least 3 days of prices: a full scan every day."] =
    "Для перепродажи нужны цены хотя бы за 3 дня: полный скан каждый день."
ru["%d smaller ones (under %s profit) are hidden: Settings > Signals."] =
    "Ещё %d с прибылью меньше %s скрыты: Настройки > Сигналы."
ru["Loading vendor prices: %s items left - deals to a vendor follow as they come."] =
    "Загружаю цены торговцев, осталось предметов: %s — сделки «Торговцу» появляются по ходу."
ru["No good deals right now. They are looked for in the latest prices: scan the auction house, or open items while it is open."] =
    "Сейчас выгодных сделок нет. Они ищутся по последним ценам: отсканируйте аукцион или открывайте предметы при открытом аукционе."
ru["%d deals, +%s in all"] = "сделок: %d, всего +%s"
ru["Talk to an auctioneer to check the order books."] = "Поговорите с аукционистом, чтобы проверить стаканы."
ru["Deals: resale %d%% or more under the fair price, from %s profit (Settings > Signals)."] =
    "Сделки: перепродажа от %d%% ниже справедливой цены, прибыль от %s (Настройки > Сигналы)."
ru["Deals: resale under the fair price by"] = "Сделки: ниже справедливой на"
ru["Signals > Good deals: a lot this far under its fair price, on a market that sells most days and isn't flooded, is worth buying to list again."] =
    "Сигналы > Сделки: лот настолько ниже справедливой цены на рынке, где товар выставляется почти каждый день и нет завала, стоит купить и выставить снова."
ru["Deals: minimum profit"] = "Сделки: минимальная прибыль"
ru["Deals that bring less are not shown (a vendor deal too)."] = "Сделки с меньшей прибылью не показываются (продажа торговцу тоже)."

-- sales seen from the listings
ru["~%s a day"] = "~%s в день"
ru["Sells"] = "Продаётся"
ru["sells"] = "продаётся"
ru["not seen yet"] = "пока не видно"
ru["(%d h watched)"] = "(за %d ч наблюдений)"
ru["Hardly bought: %s with ~%s usually listed"] = "Покупают мало: %s при ~%s выставленных обычно"

-- undercut
ru["UNDERCUT"] = "ПЕРЕБИЛИ"
ru["post again"] = "перевыставить"
ru["wait"] = "ждать"
ru["not worth following"] = "не гнаться"
ru["check the prices"] = "проверить цены"
ru["yours %s, now %s"] = "ваш %s, теперь %s"
ru["%d h"] = "%d ч"
ru["%d min"] = "%d мин"
ru["%s cheaper than yours"] = "дешевле вашего: %s шт."
ru["Under the lowest would be %s: far under its fair price (or the vendor's). Rather wait for the cheap lots to go, or let yours run out."] =
    "Ниже самой низкой — это %s: сильно ниже справедливой цены (или цены торговца). Лучше подождать, пока уйдут дешёвые лоты, или дать вашему истечь."
ru["%s; at %s, about %s sell in the %s yours has left - yours too, likely. Waiting costs nothing; posting again costs a deposit."] =
    "%s; при продажах %s уйдёт около %s шт. за %s, что осталось вашему лоту, — скорее всего, и ваш. Ждать — бесплатно, перевыставить — новый залог."
ru["%s; at %s, only about %s sell in the %s yours has left - yours likely won't. Take it off and post it again at %s (the deposit is lost, a new one is paid)."] =
    "%s; при продажах %s уйдёт только около %s шт. за %s, что осталось вашему лоту, — ваш, скорее всего, не успеет. Снимите и выставьте снова по %s (залог сгорит, нужен новый)."
ru["%s cheaper than yours. To sell first: take it off and post it again at %s (the deposit is lost) - or wait if they are few and go fast."] =
    "Дешевле вашего: %s шт. Чтобы продать первым — снимите и выставьте снова по %s (залог сгорит), или подождите, если их мало и они быстро уходят."
ru["Check the prices first: how many are listed under yours, now."] = "Сначала проверьте цены: сколько сейчас выставлено дешевле вашего."
ru["Take it from your mailbox: back in your bags, the Sell page has it first, at a copper under the lowest."] =
    "Заберите предмет с почты: в сумках на странице «Продажа» он будет первым, с ценой на 1 медь ниже самой низкой."
ru["%s is back in your bags: the Sell page has it first, at a copper under the lowest."] =
    "%s снова в сумках: на странице «Продажа» он первый, с ценой на 1 медь ниже самой низкой."
ru["Undercut: %s - yours %s, now %s."] = "Вас перебили: %s — ваш %s, теперь %s."
ru["...and %d more: Sell > My auctions."] = "...и ещё %d: Продажа > Мои лоты."
ru["Take off to post cheaper"] = "Снять и выставить дешевле"
ru["The auction is taken off (the deposit is lost) and the item comes back by mail; back in your bags, the Sell page has it first, at a copper under the lowest. Posting again needs your click there."] =
    "Лот снимается (залог сгорает), предмет приходит по почте; когда он вернётся в сумки, страница «Продажа» покажет его первым с ценой на 1 медь ниже самой низкой. Выставить снова — вашим кликом там."
ru["Say in chat when you are undercut"] = "Сообщать в чат, когда вас перебили"
ru["At the auction house: when an auction of yours is no longer the cheapest (your own other lots aside) - once per auction and price. Sell > My auctions tells whether to wait or post it again."] =
    "У аукциониста: когда ваш лот перестал быть самым дешёвым (ваши другие лоты не в счёт) — один раз на лот и цену. Продажа > Мои лоты подскажет, ждать или перевыставить."

-- the deals journal
ru["Deals journal"] = "Журнал сделок"
ru["What you bought and sold at the auction house, and what it brought"] = "Что вы купили и продали на аукционе и что это принесло"
ru["Sold"] = "Продано"
ru["Bought"] = "Куплено"
ru["Deposits lost"] = "Залоги сгорели"
ru["Result"] = "Итог"
ru["Today"] = "Сегодня"
ru["90d"] = "90д"
ru["From the auction house's letters, read when you open your mailbox; deposits of what you post here. The cut is taken off what sold."] =
    "По письмам аукциона (читаются, когда вы открываете почтовый ящик) и залогам выставленного здесь. Комиссия вычтена из проданного."
ru["Bought / sold at"] = "Покупка / продажа"
ru["Back unsold"] = "Не продано"
ru["an item not known by name"] = "предмет без известного названия"
ru["Sold, not bought at the auction house (crafted, farmed): its result is what it brought."] =
    "Продано, но куплено не на аукционе (скрафчено, добыто): итог — всё, что принесло."
ru["Deposits lost: %s"] = "Сгоревшие залоги: %s"
ru["Came back unsold: %s expired, %s taken off"] = "Вернулось непроданным: истекло %s, снято %s"
ru["%s pcs, the cut %s"] = "%s шт., комиссия %s"
ru["paid %s, back %s"] = "внесено %s, вернулось %s"
ru["back unsold: %s expired, %s taken off"] = "не продано: истекло %s, снято %s"
ru["The journal fills from the auction house's letters: open your mailbox. What you post here writes its deposit."] =
    "Журнал заполняется из писем аукциона: откройте почтовый ящик. Выставления через ForeverTrading записывают свой залог."
ru["Nothing in this period."] = "За этот период ничего нет."

-- the craft queue
ru["Craft queue"] = "Очередь"
ru["Queue it"] = "В очередь"
ru["Queued: %d"] = "В очереди: %d"
ru["Click: one craft more in the craft queue, Shift-click: five. The queue (Craft queue, above) adds up the materials to buy for all of it."] =
    "Клик: ещё один крафт в очередь, Shift+клик: пять. Очередь (переключатель сверху) складывает материалы, которые нужно купить для всего сразу."
ru["auction house"] = "аукцион"
ru["craft it"] = "скрафтить"
ru["~%s d"] = "~%s дн."
ru["Crafts"] = "Крафтов"
ru["Makes"] = "Выйдет"
ru["To sell"] = "Продать"
ru["How long what the crafts make takes to sell at what really sells a day (seen from the listings)."] =
    "Сколько дней займёт продажа того, что выйдет, при реальных продажах в день (по наблюдениям за стаканом)."
ru["Sells %s: the %s it makes take about %s."] = "Продаётся %s: %s шт. уйдут примерно за %s."
ru["Click: the recipe. -/+ : one craft (Shift: five)."] = "Клик: рецепт. -/+ : один крафт (Shift: пять)."
ru["The queue is empty: pick a recipe and press Queue it."] = "Очередь пуста: выберите рецепт и нажмите «В очередь»."
ru["Material"] = "Материал"
ru["Need"] = "Нужно"
ru["Have"] = "Есть"
ru["Costs"] = "Стоит"
ru["enough"] = "хватает"
ru["Need %s, have %s (bags and bank of this character): buy %s."] = "Нужно %s, есть %s (сумки и банк этого персонажа): купить %s."
ru["At %s each: %s"] = "По %s за шт.: %s"
ru["Click: its order book - buy there."] = "Клик: стакан — покупать там."
ru["Nothing to buy."] = "Покупать ничего не нужно."
ru["Search materials on AH"] = "Найти материалы на АХ"
ru["Searches what is left to buy: fresh prices and order books, so the costs above are of now. The auction house must be open."] =
    "Ищет то, что осталось купить: свежие цены и стаканы, чтобы стоимость выше была на сейчас. Аукцион должен быть открыт."
ru["Clear the queue"] = "Очистить очередь"
ru["Take every recipe out of the craft queue?"] = "Убрать все рецепты из очереди крафта?"
ru["%d crafts"] = "крафтов: %d"
ru["to buy"] = "купить на"
ru["(%d without a price)"] = "(без цены: %d)"
ru["brings"] = "выручка"
ru["profit"] = "прибыль"
ru["%d recipes in the queue"] = "рецептов в очереди: %d"

-- the cut, as the auction house's letters say it is
ru["Take the auction house cut off profits"] = "Вычитать комиссию аукциона из прибыли"
ru["The cut is learned from the auction house's letters about your sales (it isn't the same everywhere); 5% until one is read."] =
    "Комиссия берётся из писем аукциона о ваших продажах (она сейчас не везде одинакова); пока писем не было — 5%."
ru["Deposit %s (back when it sells), the auction house's cut: %s."] = "Залог %s (вернётся при продаже), комиссия аукциона: %s."
ru["What one craft brings in at the auction house after its cut (or at a vendor, when that pays more)."] =
    "Сколько приносит один крафт на аукционе после комиссии (или у торговца, если тот платит больше)."
ru["List them again at %s each (the auction house's cut is counted; the deposit comes back when they sell)."] =
    "Выставить снова по %s за шт. (комиссия аукциона учтена; залог вернётся при продаже)."
ru["Auction house cut"] = "Комиссия аукциона"

-- About
ru["version %s"] = "версия %s"

-- What's new
ru["What's new"] = "Что нового"
ru["what's new"] = "что нового"
ru["What's new in ForeverTrading %s"] = "Что нового в ForeverTrading %s"
ru["Press Show to go there."] = "«Показать» — перейти туда."
ru["Show"] = "Показать"
ru["Got it"] = "Понятно"
ru["Take the tour"] = "Пройти экскурсию"
ru["Take the tour again"] = "Пройти обучение заново"
ru["Nothing new written for %s."] = "Для %s нет списка нового."
ru["Welcome to ForeverTrading"] = "Добро пожаловать в ForeverTrading"
ru["A short tour: where everything is and how to use it (a couple of minutes). It can be taken again any time: Settings > About, /ft tour."] =
    "Короткая экскурсия: где что находится и как этим пользоваться (пара минут). Повторить можно в любой момент: Настройки > Об аддоне, /ft tour."
ru["Signals > Deals: what to buy right now for a profit - under what a vendor pays, or far under the fair price on a steady market."] =
    "Сигналы > Сделки: что выгодно купить прямо сейчас — дешевле, чем даст торговец, или сильно ниже справедливой цены на спокойном рынке."
ru["What really sells"] = "Что реально продаётся"
ru["How much really sells a day, on the Craft page, the Market and the item window (told from the listings); and risks: a flooded market, more sellers, hardly bought."] =
    "Сколько реально продаётся в день — в Крафте, на Рынке и в «Подробнее» (по наблюдениям за стаканом); и риски: завал рынка, наплыв продавцов, «покупают мало»."
ru["Undercut"] = "Вас перебили"
ru["A line in chat when an auction of yours is undercut; Sell > My auctions tells whether to wait or post it again."] =
    "Сообщение в чат, когда ваш лот перебили; Продажа > Мои лоты подскажет, ждать или перевыставить."
ru["Portfolio > Deals journal: what you really earned - from the auction house's letters."] =
    "Портфель > Журнал сделок: сколько вы реально заработали — по письмам аукциона."
ru["The craft queue"] = "Очередь крафта"
ru["Craft > Queue: the materials to buy for several crafts at once, at their cheapest, and how long it all takes to sell."] =
    "Крафт > Очередь: что купить сразу на несколько крафтов по самым выгодным ценам и сколько дней займёт продажа."
ru["Fixes"] = "Исправления"
ru["The price exchange works (it didn't know your name), poisons are back on the Craft page, vendor prices of materials count, searching finds Russian names in any case."] =
    "Обмен ценами работает (аддон не узнавал своё имя), яды вернулись в Крафт, цены торговцев на материалы учитываются, поиск находит русские названия в любом регистре."

-- the tour
ru["the tour of ForeverTrading"] = "экскурсия по ForeverTrading"
ru["The pages"] = "Разделы"
ru["Market: the prices and charts of every item. Craft: what your recipes cost and bring. Signals: what to do now. Portfolio: what all you own is worth. Selling: post from your bags and watch your auctions."] =
    "Рынок — цены и графики всех предметов. Крафт — себестоимость и прибыль ваших рецептов. Сигналы — что делать сейчас. Портфель — сколько стоит всё, что у вас есть. Продажа — выставить из сумок и следить за своими лотами."
ru["The auction house"] = "Аукцион"
ru["Green while you are at an auctioneer: the item you have open is searched again every few seconds, and you can buy, post and cancel right here. Click: the game's own auction house window."] =
    "Горит зелёным, пока вы у аукциониста: открытый предмет обновляется каждые несколько секунд, а покупать, выставлять и снимать лоты можно прямо здесь. Клик — окно аукциона игры."
ru["Scan and exchange"] = "Скан и обмен"
ru["Full scan: the prices of the whole market in a couple of minutes (at an auctioneer). Exchange: fresh prices from ForeverTrading users in your guild and group, anywhere."] =
    "«Полный скан» — цены всего рынка за пару минут (у аукциониста). «Обмен» — свежие цены от пользователей ForeverTrading в гильдии и группе, где угодно."
ru["Search by name (in quotes: that name exactly), categories, filters as at the auction house. Click an item: its chart, signals and order book; right-click: watchlist."] =
    "Поиск по названию (в кавычках — точное имя), категории и фильтры как на аукционе. Клик по предмету — график, сигналы и стакан; ПКМ — в избранное."
ru["The order book"] = "Стакан"
ru["Every listing by price, how many, by how many sellers. Click a price: how many to buy; Buy: at an auctioneer, at the server's exact price."] =
    "Все лоты по ценам: сколько и у скольких продавцов. Клик по цене — сколько купить, «Купить» — у аукциониста, по точной цене сервера."
ru["What each recipe costs with its cheapest materials (auction house, vendor or crafting it yourself), what it brings, its risks. Queue: the materials to buy for several crafts at once."] =
    "Себестоимость каждого рецепта по самым выгодным материалам (аукцион, торговец или свой крафт), выручка и риски. «Очередь» — что купить сразу на несколько крафтов."
ru["Signals and deals"] = "Сигналы и сделки"
ru["What to sell, craft and buy now, your auctions undercut, risky recipes. Deals: what to buy right now for a profit - under what a vendor pays, far under the fair price, or cheaper than the other auction house sells it for."] =
    "Что продавать, крафтить и закупать сейчас, перебитые лоты, рискованные рецепты. Сделки: что выгодно купить прямо сейчас — дешевле, чем даст торговец, сильно ниже справедливой цены или дешевле, чем продаётся на другом аукционе."
ru["Your bags at market prices: a copper under the lowest, the deposit, the cut, and warnings. My auctions: who undercut you, and whether to wait or post again."] =
    "Ваши сумки по ценам рынка: цена на 1 медь ниже самой низкой, залог, комиссия и предупреждения. «Мои лоты» — кто вас перебил и стоит ли перевыставлять."
ru["Portfolio and journal"] = "Портфель и журнал"
ru["What everything your characters own is worth. Deals journal: what you really earned, from the auction house's letters."] =
    "Сколько стоит всё, что есть у ваших персонажей. «Журнал сделок» — сколько вы реально заработали, по письмам аукциона."
ru["Signal thresholds, the exchange, alerts, your data. In About: What's new, and this tour again (/ft tour)."] =
    "Пороги сигналов, обмен, оповещения, данные. В «Об аддоне» — «Что нового» и эта экскурсия ещё раз (/ft tour)."
ru["Next"] = "Далее"
ru["Back"] = "Назад"
ru["Done"] = "Готово"
ru["End the tour"] = "Закончить"
ru["The tour is over. Again: Settings > About, or /ft tour."] = "Экскурсия окончена. Повторить: Настройки > Об аддоне или /ft tour."
ru["After the fight: the tour opens the pages of the window."] = "После боя: экскурсия открывает разделы окна."

-- /ft perf
ru["how fast it works and the memory it takes"] = "скорость работы и занятая память"
ru["Performance (this session):"] = "Замеры (эта сессия):"
ru["%.1f MB"] = "%.1f МБ"
ru["Memory: ForeverTrading %s, all addons %s"] = "Память: ForeverTrading %s, все аддоны вместе %s"
ru["Saved prices: %s items, %s characters; %s waiting to be written (at logout or /reload)"] =
    "Сохранённые цены: %s предметов, %s символов; ждут записи (при выходе или /reload): %s"
ru["Writing them at the last logout: %s ms (%s records)"] = "Запись при прошлом выходе: %s мс (%s записей)"
ru["%s: %s - %s ms of work in %s frames (the longest %s ms), %s s in all, %s"] =
    "%s: %s шт. — %s мс работы за %s кадров (самый долгий %s мс), всего %s с, %s"
ru["Nothing measured yet this session: make a scan or open the Market."] =
    "В этой сессии ещё нечего показать: сделайте скан или откройте «Рынок»."
ru["Reading every auction (deep scan)"] = "Чтение всех лотов (глубокий скан)"
ru["Reading a scan of Auctionator"] = "Чтение скана Auctionator"
ru["Saving a scan"] = "Сохранение скана"
ru["Marking what is no longer listed"] = "Отметка снятого с аукциона"
ru["Market: every item"] = "«Рынок»: все предметы"
ru["Market: the changed items"] = "«Рынок»: изменившиеся предметы"
ru["Deals: every item"] = "«Сделки»: все предметы"
ru["Deals: the changed items"] = "«Сделки»: изменившиеся предметы"
ru["Pruning old history"] = "Чистка старой истории"
ru["Market: %s items, %s with prices on 3+ days of the last two weeks, %s can be top gainers or losers"] =
    "«Рынок»: %s предметов, из них с ценами за 3+ дня из последних двух недель: %s, могут попасть в лидеры роста и падения: %s"
ru["(Auctionator is off: only the days ForeverTrading saw itself count)"] =
    "(Auctionator выключен: считаются только дни, которые ForeverTrading видел сам)"

-- TradeSkillMaster
ru["Reading TSM's prices"] = "Чтение цен TSM"
ru["At each login (and /reload) the latest prices TSM's desktop app downloaded for your realm go into ForeverTrading's history - a whole auction house at a time, without scanning (your own newer scans stand). While an item's own history is short, TSM's market value stands in for its average, and the region's sales for its liquidity. Your faction's auction house only."] =
    "При каждом входе (и /reload) последние цены, которые приложение TSM скачало для вашего реалма, попадают в историю ForeverTrading — весь аукцион разом, без сканирования (ваши более свежие сканы остаются). Пока у предмета мало своей истории, рыночная цена TSM заменяет среднюю, а продажи по региону — ликвидность. Только аукцион вашей фракции."
ru["%s above TSM's market value"] = "%s выше рыночной цены TSM"
ru["%s below TSM's market value"] = "%s ниже рыночной цены TSM"
ru["%s below TSM's market value: wait"] = "%s ниже рыночной цены TSM — лучше подождать"
ru["TSM: ~%s a day in the region"] = "TSM: ~%s в день по региону"
ru[", %d%% of auctions sell"] = ", продаётся %d%% лотов"
ru["TSM ~%s/day"] = "TSM ~%s/день"
ru["Lowest buyout"] = "Минимальный выкуп"
ru["Recent value"] = "Недавняя цена"
ru["Market value (14 days)"] = "Рыночная цена (14 дн.)"
ru["Historical price (60 days)"] = "Историческая цена (60 дн.)"
ru["Region market value"] = "Рыночная цена региона"
ru["Region historical price"] = "Историческая цена региона"
ru["Region sale price"] = "Средняя цена продажи (регион)"
ru["Region sold a day"] = "Продаётся в день (регион)"
ru["Region sale rate"] = "Доля продаж (регион)"
ru["TSM knows your faction's auction house only: here just the region's."] =
    "TSM знает только аукцион вашей фракции: здесь — лишь данные региона."
