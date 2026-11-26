# ForeverTrading

**English** · [Русский](#русский)

An exchange-style trading terminal for the **WoW Forever** auction house, with its own scanner: price and profit
charts, order books, craft profitability and "sell / craft / buy" signals. It also reads **Auctionator** and
**Mastercraft** when they are installed, and **TradeSkillMaster** (each source can be turned off in Settings) - none is
required: it goes by its own scans, and the signals and deals work from the first days of scanning. With TSM, the latest
prices its desktop app downloaded for your realm go into the history at each login (a whole auction house, without
scanning), and the region's real sales help judge liquidity.

- **Market** - every item seen on the auction house: price, 24h change, 7-day sparkline, filters, a price line
  and a profitability line (zero in the middle) per item, RSI and other indicators, price alerts, and the
  item's order book with a "what does buying N cost" calculator.
- **Craft** - every recipe your characters know: cost (each material at the cheapest of auction house, vendor or
  crafting it yourself), revenue after the auction house's cut, profit, margin, risks and a signal. The **craft
  queue** adds up what to buy for several crafts at once and how long it all takes to sell.
- **Signals** - sell now / worth crafting / worth buying / hold or avoid, your auctions undercut, risky recipes;
  **Good deals** - what to buy right now for a profit (under what a vendor pays, or far under the fair price).
- **Portfolio** - what your characters own (bags, banks, mail) at market prices; the **deals journal** - what
  you really bought, sold and earned, from the auction house's letters.
- **What really sells** - an estimate from the listings seen go (bought, not relisted or expired), shown as
  "sells ~N a day"; risks see a flooded market, more sellers than usual and a price falling since the last check.
- **Scanning** - *Full scan* (the whole auction house in seconds, any time; an optional deep scan reads every
  auction once every 15 minutes) and *My items* (order books of your recipe items, materials, watchlist and
  holdings). Whatever you look at yourself on the auction house is recorded too.
- **Live prices** - with the auction house open, the item you have open is searched again every 8 seconds.
  **More** on any chart opens the item in its own window with large charts and its order book.
- **Price exchange** - ForeverTrading users in a guild or group share their scans: when your prices are more
  than an hour old, the freshest scan around comes to you in the background (or press **Exchange**).
- **Two auction houses** - your faction's and Blackwater (the neutral one, shared by both factions) each keep
  their own prices, history, deals and your auctions: talking to an auctioneer picks its house, and the chip in
  the header switches whose prices you see. **Deals between the houses**: cheaper at one than the other sells it
  for - buy, carry it over, list it there, both cuts counted. A right click puts a deal on your **carry list**: at
  the other house the Sell page shows what you brought and what it cost.
- **Trading** - at the auction house: buy from the order book, post from your bags (a suggested price, the
  deposit, the cut, warnings) and watch **My auctions** (who undercut you, cancel) - every action confirmed with
  the exact numbers first; when you are undercut it says whether to wait or post again. Optionally ForeverTrading
  opens in place of the game's auction house window.
- **What's new** once a version and a **tour** of the window (Settings > About, `/ft news`, `/ft tour`).

Install: download the latest release (or this repository) into `Interface/AddOns/ForeverTrading`.
Open the auction house and press **Full scan** in the ForeverTrading window (`/ft`). The UI is in Russian and
English (Settings > Language).

---

## Русский

Биржевой терминал для аукциона **WoW Forever** со **своим сканером**: графики цены и прибыльности, стаканы, прибыльность крафта и сигналы «продавать / крафтить / закупать». В связке с **Auctionator**, **Mastercraft** и **TradeSkillMaster** — их данные тоже попадают в историю (каждый источник отключается в настройках), но ни один из них не обязателен: аддон опирается на свои сканы, а они лишь дополняют недостающее.

## Откуда данные

| Источник | Что даёт |
|---|---|
| **Полный скан** (свой) | Весь аукцион за несколько секунд: лучшая цена и количество каждого предмета, в любое время. Опция «глубокий скан» в настройках — каждый лот и стаканы всех предметов, раз в 15 минут. |
| **Мои товары** (свой) | Результаты и материалы ваших рецептов, избранное и ваши запасы — поиск по каждому, от дешёвых лотов (до 250 лотов): стакан и цена. Встаёт на паузу, пока вы ищете сами. |
| **Что вы смотрите сами** | Любой ваш поиск и открытый товар на аукционе тоже попадает в историю и стаканы. |
| **Живые цены** (свой) | Пока открыт аукцион, открытый в аддоне предмет запрашивается заново каждые 8 секунд: цена и стакан всегда свежие. Пауза, пока вы сами ищете, покупаете или продаёте. |
| **Обмен** (с гильдией и группой) | Если вашим ценам рынка больше часа, аддон спрашивает пользователей ForeverTrading в гильдии (затем в группе), у кого свежее, — и самый свежий присылает свой полный скан в фоне, по одному скрытому сообщению в секунду. Кнопка **Обмен** в шапке — спросить сразу, аукцион не нужен. |
| **Два аукциона** | У аукциона вашей фракции и у Черноводья (нейтрального, общего для обеих фракций) свои цены, история, сделки и ваши лоты. Аукционист сам выбирает свой аукцион; чип в шапке переключает, чьи цены вы смотрите. «Сделки > Между аукционами» — что на одном дешевле, чем продаётся на другом; правый клик по сделке — в **список закупки**, и на другом аукционе вкладка «Продажа» покажет, что вы привезли и почём купили. |
| **Auctionator** | Его полный скан и поиски пишутся в нашу историю; дни, которые вы сами не сканировали, берутся из его базы. |
| **Mastercraft** | Его сканы цен пишутся в историю; рецепты и запасы альтов, на которых вы ещё не заходили с ForeverTrading. |
| **TradeSkillMaster** | При каждом входе в игру (и `/reload`) последняя загрузка приложения TSM для вашего реалма (минимальный выкуп и число лотов каждого предмета, весь аукцион) пишется в историю — без сканирования; ваши более свежие сканы не перебиваются. Пока у предмета мало своей истории, рыночная цена TSM (14 дней) заменяет среднюю, недавняя — справедливую цену, а реальные продажи по региону (сколько продаётся в день, доля проданных лотов) — ликвидность. Значения TSM — во всплывающей подсказке карточки «Индикаторы». Только аукцион фракции, не Черноводье. |
| **Игра** | Окна профессий (рецепты), сумки, банк, почта, золото каждого персонажа, цены у торговцев. |

## Первые шаги

1. Откройте аукцион → `/ft` (или кнопка **ForeverTrading** на окне аукциона) → **Полный скан**.
2. Откройте окно каждой профессии хотя бы раз на каждом персонаже (или пусть Mastercraft их знает).
3. Кнопка **Мои товары** — стаканы всех ваших предметов (по одному поиску на каждый, несколько минут); перед началом аддон спросит подтверждение.

Изменения цены, лидеры роста и падения, сигналы и сделки появляются уже в первый день, со второго скана: пока аукцион сканировали мало дней, аддон требует меньше истории (в первый день вместо средней — цена последних часов). RSI — через 3+ дня цен. Если включён Auctionator, его прошлая история сразу заполняет графики.

## Вкладки

- **Рынок** — все предметы: цена, изменение 24ч, спарклайн 7 дней, сортировка по стоимости предложения, фильтры. Для предмета — два графика: **линия цены** (1ч / 4ч / 1д / 1н, по желанию скользящие средние MA7/MA25) и **линия прибыльности с нулём посередине** — для ваших рецептов это прибыль за один крафт, для остальных предметов — на сколько золота продажа сейчас выше (+, выгодно продавать) или ниже (−) средней за 14 дней. Выше нуля линия зелёная, ниже — красная. Кнопка **Подробнее** на графике открывает предмет в отдельном окне: большие графики, цифры и стакан. Ниже — индикаторы (RSI, отклонение от средней, волатильность, ликвидность), сигналы и ценовые алерты. Справа — **стакан** с глубиной и калькулятором «сколько стоит купить N шт»; у аукциониста из него можно **купить**: клик по цене (всё до неё) или своё количество → «Купить» → подтверждение с точной ценой сервера. Без выбранного предмета — обзор рынка: настроение, стоимость всех лотов по сканам, лидеры роста и падения.
- **Крафт** — себестоимость (каждый материал по самой низкой цене: аукцион, торговец или свой крафт), выручка после комиссии аукциона, прибыль, маржа, риски, сигнал, сколько реально продаётся в день; графики цены предмета и прибыли за крафт (ноль посередине) за 30 дней и разбор материалов. **Очередь** — что купить сразу на несколько крафтов по самым выгодным ценам и сколько дней займёт продажа.
- **Сигналы** — продавать сейчас / выгодно крафтить / выгодно закупать / держать и не крафтить, перебитые лоты и рискованные рецепты. **Сделки** — что выгодно купить прямо сейчас: дешевле, чем даст торговец, или сильно ниже справедливой цены на спокойном рынке.
- **Портфель** — запасы всех персонажей сервера по рыночным ценам и их стоимость по дням. **Журнал сделок** — что вы реально купили, продали и заработали, по письмам аукциона.
- **Продажа** — что у вас в сумках можно выставить: цена рынка и сигнал; форма выставления с подсказанной ценой (на 1 медь дешевле самой низкой), сроком, залогом, комиссией, итогом и предупреждениями; выставление — только после подтверждения, у аукциониста. Переключатель «Мои лоты» — ваши лоты: где вас перебили и стоит ли перевыставлять, сколько осталось, снять с аукциона.
- **Настройки** — сканирование, живые цены, источники, обмен, пороги сигналов, хранение данных; «Убрать» — история предметов, которых не было на аукционе 30+ дней.

Три размера окна в шапке: компактное (только графики — без стакана и карточек), стандартное и на весь экран.

## Как считаются сигналы

| Сигнал | Условие (пороги меняются в настройках) |
|---|---|
| ПРОДАВАТЬ | цена выше средней за 14 дн. на 10%+ или RSI ≥ 70 |
| ДЕРЖАТЬ | цена ниже средней на 10%+ — лучше подождать |
| ПОКУПАТЬ | цена ниже средней на 15%+ или RSI ≤ 30 |
| КРАФТИТЬ | прибыль ≥ 20s и маржа ≥ 10%, предмет регулярно бывает на аукционе, цена не падает >10% за неделю |
| СЛЕДИТЬ / РИСК / УБЫТОК | малая прибыль / редко продаётся или цена падает / крафт в минус |
| Скачок / быстрое падение | цена выше справедливой на 50%+ (дешёвое скупили и перевыставили): прибыль и сигналы считаются по справедливой цене; ниже на 20%+ (конкуренты сбивают цену): крафт получает РИСК. Справедливая цена — медиана цен за последние дни без последнего часа, взвешенная по числу лотов, времени и свежести |

## Данные

- **История по дням** — у каждого встреченного предмета: цена на открытии и закрытии дня, минимум, максимум, предложение и лоты. Хранится 90 дней (настройка).
- **Почасовая история (1ч / 4ч)** — для важных вам предметов (рецепты и материалы, избранное, запасы, всё, что вы открывали); для всех — отдельная настройка.
- **Предложение** — сколько выставлено, а не сделки: игра не сообщает о продажах. На аукционе есть только продажи, поэтому стакан односторонний.
- **Что реально продаётся** — оценка: два замера стакана сравниваются по продавцам и ценам (купили, перевыставили или истекло), отсюда «продаётся ~N в день». Риски видят завал рынка, наплыв продавцов и падение цены с прошлого замера.

## Команды

`/ft` — окно · `/ft scan` — полный скан · `/ft scan mine` — мои товары · `/ft stop` — остановить скан · `/ft share` — запросить цены у гильдии и группы · `/ft market | craft | signals | portfolio | settings` · `/ft lang ru | en | auto` · `/ft reset` · `/ft debug` · `/ft perf` — скорость и память.

Shift-клик по предмету в любом списке — ссылка в чат; ПКМ по строке рынка — в избранное.

## Шрифт

Sofia Sans Condensed Medium (Lettersoup, https://github.com/lettersoup/Sofia-Sans) — лежит в `media/`, лицензия SIL Open Font License 1.1 (`media/SofiaSansCondensed-OFL.txt`).

