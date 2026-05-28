# Design

## Design goals

乐岛（Melisle）的界面服务于自托管音乐库的日常聆听：连接服务、浏览媒体库、管理收藏与歌单、开始播放、沉浸听歌。设计应保持精致、克制、有音乐感；让封面、曲目信息、歌词和播放状态成为主角。

默认 register 为 product。设计语言需要有成熟工具的可信度，也要保留音乐播放器的情绪温度。避免把乐岛做成后台管理系统、模板化 SaaS、强刺激霓虹播放器或过度拟物的视觉实验。

## Theme strategy

双模式均衡。深色适合夜间聆听、播放页和长时间沉浸；浅色适合白天管理音乐库、桌面整理和通勤环境。任何界面都不应只在一个主题下成立。

物理场景：用户在桌面端整理 NAS 音乐库，也会在夜间低光环境打开播放页听完整张专辑；界面需要在日间清晰、夜间安静。

色彩策略为 Restrained：带品牌倾向的中性层级 + 一个主强调色 + 少量音乐氛围色。封面可以为详情页和播放页提供情绪色，但情绪色应像环境光，不应覆盖内容可读性。

## Color system

当前代码使用 Material 3 `ColorScheme.fromSeed`，并通过 `AppColorTokens` 覆写关键色值。文档中的色值记录实现现状；后续可迁移为 OKLCH token，但视觉意图应保持低饱和、偏冷、柔和。

### Core tokens

| Role | Dark | Light | Use |
|---|---:|---:|---|
| Scaffold | `#090C12` | `#F6F8FC` | 页面底层背景 |
| Surface | `#121723` | `#FBFCFF` | 内容容器、卡片基底 |
| Surface High | `#171E2B` | `#F0F3F9` | 输入框、提升一级容器 |
| Surface Highest | `#212A3B` | `#E4EAF3` | SnackBar、最高层级容器 |
| Primary | `#9CA6FF` | `#6172E3` | 主操作、选中态、播放焦点 |
| Primary Container | `#2B3150` | `#E0E4FF` | 当前播放、选中背景 |
| Secondary | `#86D3D0` | `#4BA9A4` | 辅助强调、轻量状态 |
| Secondary Container | `#1D333C` | `#D4F3F0` | 辅助容器 |
| On Surface | `#E8ECF4` | Material 默认 | 主文本 |
| On Surface Variant | `#ACB6C7` | `#5E687C` | 次要文本、图标 |
| Outline | `#5A6478` | `#8A93A7` | 明确分隔线 |
| Outline Variant | `#2A3342` | `#D8DFEA` | 轻边框、卡片描边 |
| Lyric Highlight | `#ECA35B` | `#ECA35B` | 当前歌词行 |

### Color rules

- Primary 用于主要操作、当前选择、播放相关焦点，不用于纯装饰。
- Secondary 用于辅助信息或轻量状态，不与 Primary 同时大面积竞争。
- 深色模式靠 1px 低透明边框建立层级，少用阴影。
- 浅色模式允许极轻阴影，但仍以边框和背景层级为主。
- 不使用纯黑或纯白作为设计意图；当前浅色 Surface 为代码现状，新增设计应优先使用轻微染色的中性背景。
- 封面取色只用于详情页和播放页氛围背景，必须叠加模糊和暗化以保护文字对比度。

## Typography

当前代码使用平台系统字体作为产品 UI 主字体，保留 `Righteous` 仅用于 display 层级和少量品牌/播放页时刻。这个策略优先保证中文界面、列表、按钮、设置项和桌面工具界面的稳定可信度。

### Current implementation

| Level | Font | Weight | Letter spacing | Use |
|---|---|---:|---:|---|
| Display Large/Medium/Small | Righteous | 400 | 0 | 播放页歌名、品牌性标题 |
| Headline Large/Medium | System UI | 700 | 0 | 专辑、艺术家、页面强标题 |
| Headline Small | System UI | 700 | 0 | 区块标题 |
| Title Large | System UI | 700 | 0 | AppBar、重要标题 |
| Title Medium/Small | System UI | 600 | 0 | 列表项、卡片标题 |
| Body Large/Medium | System UI | 400 | 0 | 正文、副标题 |
| Body Small | System UI | 400 | 0 | 时间、说明、次要信息 |
| Label Large | System UI | 600 | 0 | 按钮、Tab、Chip |
| Label Medium/Small | System UI | 500 | 0 | 导航、MetaPill |

### Type rules

- 中文界面优先保证可读性，不为品牌感牺牲列表和按钮清晰度。
- 正文行长控制在 65-75ch，音乐列表可更紧凑。
- 普通产品 UI 不使用负字距；播放页 display 文本如需品牌感，可在局部组件内单独处理。
- 时间、进度和计数使用等宽数字，避免播放进度跳动。

## Layout and spacing

布局需要跨端一致，但不是同一套结构硬套所有屏幕。

### Breakpoints

| Width | Layout |
|---:|---|
| `<1080px` | 移动端模式：内容区 + MiniPlayerBar + 底部导航 |
| `>=1080px` | 桌面端模式：左侧边栏 + 内容容器 + MiniPlayerBar |

### Spacing tokens

| Token | Value | Use |
|---|---:|---|
| pageTop | 20 | 常规页面顶部 |
| pageTopCompact | 12 | 紧凑页面顶部 |
| headerBottomGap | 14 | Header 到内容 |
| contentBottom | 24 | 列表底部 |
| sectionGap | 24 | 区块间距 |
| sectionTitleBottomGap | 16 | 标题到内容 |
| cardPadding | 16 | 普通卡片内边距 |
| headerPadding | 22 | Header 卡片内边距 |
| pageHorizontalCompact | 16 | 移动端水平边距 |
| pageHorizontalMedium | 24 | 中宽水平边距 |
| shellOuterPadding | 14 | 桌面 Shell 外边距 |
| shellGap | 14 | 侧边栏与内容间距 |
| shellBottomInset | 10 | Shell 底部安全间距 |

### Layout rules

- 内容优先，不给每个元素都套容器。
- 大面积内容使用清晰的滚动结构，列表页避免嵌套卡片。
- 同一页面内间距应有节奏：Header、列表、底部状态不必使用完全相同 padding。
- 桌面端可以提高信息密度，移动端优先触控目标和单手可达性。

## Shape and elevation

### Radius tokens

| Token | Value | Use |
|---|---:|---|
| shellContainer | 22 | 桌面主内容容器 |
| card | 14 | 普通卡片、列表项、底部导航容器 |
| button | 999 | 胶囊主按钮 |
| input | 14 | 输入框 |
| iconButton | 12 | 图标按钮、TextButton 圆角 |
| coverGrid | 14 | 网格封面 |
| coverDetail | 22 | 详情页封面 |

### Elevation rules

- 深色模式默认 elevation 0，通过 `outlineVariant` 边框和 surface 层级表达深度。
- 浅色模式允许非常轻的 shadow，普通卡片默认接近平面，不使用强浮动感。
- 普通页面避免 20px 以上的大圆角，播放页、详情封面和 shell 容器例外。
- IconButton 默认无背景，仅在 hover、focus、pressed 时显示极轻 overlay。
- FilledButton、OutlinedButton 和 TextButton 默认高度为 44px，PC 端批量操作应优先使用轻量按钮。
- 当前播放项使用 primary container 与 primary 边框，而不是厚边条或高亮侧线。
- 禁止用彩色左/右粗边框作为列表或卡片强调。

## Components

### App shell

桌面端使用窄侧边栏，包含 Logo、首页、媒体库、歌单、设置。移动端使用底部导航，并与 MiniPlayerBar 共同形成底部 Dock。导航项保持四个一级入口，收藏入口位于媒体库 Tab 内，不再作为一级导航。

### Page header

页面 Header 用于标题、说明、搜索和局部筛选。Header 应保持轻量，不把所有统计都塞成指标区。

`AppPageHeader` 是页面标题区的统一入口，支持返回按钮、标题、说明、中心槽位和右侧操作。搜索页、媒体库、下载管理等常规页面不再各自手写 Header Row。

- 返回按钮使用 `AppBackButton`，44×44px，无常驻背景，仅在 hover、focus、pressed 时出现轻量 overlay。
- PC 端 Header 采用同一基线：标题在左，搜索或筛选作为中心任务，统计和次要操作在右。
- 移动端 Header 优先保留返回和主任务；当中心槽位是搜索框时，可以隐藏标题，避免横向拥挤。
- 媒体库这类需要保留页面身份的场景，移动端标题在上、搜索框在下。

媒体库 Header 当前包含：标题、搜索框、Tab（歌曲 / 专辑 / 艺术家 / 收藏）。搜索为手动提交，不随输入实时触发。

### Search field

`AppSearchField` 是全局搜索输入组件，适用于搜索页、媒体库和后续歌单内搜索。

- PC 端 dense 模式默认高度约 46px，与轻量操作按钮和 Header 基线协调。
- 清空按钮使用极简关闭图标，不使用白色圆底或额外容器。
- Focus 状态通过细边框、轻微表面层级和低透明阴影表达，不引入强发光。
- 组件内部管理可选 `FocusNode`、语义标签、清空动作和提交动作；页面只保留业务行为。

### Tabs and pills

媒体库分类、搜索结果分类和同类页面筛选使用 `AppScopeTabs`。移动端使用 pill 形态，桌面端使用 underline 形态，文字始终居中，不再由页面各自实现 hover 和 selected 状态。

- `AppScopeTabsVariant.underline` 用于 PC 端主内容分类，例如搜索结果、媒体库 Tab。
- `AppScopeTabsVariant.pill` 用于移动端或局部横向筛选，例如搜索结果分类、艺术家流派筛选。
- MetaPill 只用于轻量统计，例如歌曲数、已加载数、播放时间，不承担主要导航。

### Action buttons

`AppActionButton` 用于 PC 端批量和次级操作，例如播放全部、加入队列、重试、清空。它默认无常驻背景，通过 hover、focus、pressed overlay 表达反馈。

- Primary tone 只用于当前页面最重要的轻量动作，例如播放全部、重试。
- Neutral tone 用于加入队列、清空、次要跳转。
- 重要提交仍可使用 Material `FilledButton`，但列表页和工具栏中的批量动作优先用 `AppActionButton` 或 `PlayAllButton`。

### Track list item

歌曲项应突出封面、标题、艺术家和专辑。当前播放项可更明显，但不能破坏列表节奏。

- 封面：48-58px，圆角 14-20。
- 标题：Title Medium，单行省略。
- 副标题：Body Medium，使用 onSurfaceVariant。
- 当前播放：primaryContainer 背景、primary 细边框、`graphic_eq_rounded`。
- 普通项：surface 低透明背景、outlineVariant 细边框。

### Track table

`MusicTrackTable` 是 PC 端歌曲列表的统一表格组件，适用于搜索、媒体库、专辑详情、艺术家详情和歌单详情。移动端仍使用 `MusicTrackTile` 触控列表。

- 列结构：序号、封面、歌曲 / 歌手、歌手、专辑、时长、行内操作。
- hover 只影响当前行，不能污染相邻行。
- 当前播放使用 `graphic_eq_rounded` 和 primaryContainer，不使用粗边条。
- 行内操作保持极简图标视觉，图标可为 18px，但实际按钮命中区必须为 44×44px。页面通过回调提供收藏、加入队列等业务动作。
- 表格可关闭 action bar，用于详情页中已有 hero 主操作的场景。

### Album and playlist grid

网格以封面为主，文字为辅。避免相同尺寸的图标卡片网格。专辑、歌单卡片可以 hover 轻微缩放，但不做复杂进场动画。

- `MusicAlbumGridCard` 是专辑网格默认组件，首页、搜索、媒体库和艺术家详情中的专辑入口应优先复用它。
- `MusicPlaylistGridCard` 和 `MusicPlaylistListTile` 是歌单列表默认组件。PC 端优先网格，移动端优先列表。
- 网格封面使用 `AppRadiusTokens.coverGrid`，普通容器使用 `AppRadiusTokens.card`。不要在页面内重新手写 20px 以上普通卡片圆角。
- 卡片 hover 只允许轻微 scale、低透明遮罩或极轻阴影；不要叠加装饰性渐变、毛玻璃或强光效。
- 封面角标只用于对象本身的轻量 meta，例如歌单歌曲数，不承担主要导航或营销文案。

### Detail hero

`AppDetailHeroFrame` 是专辑、艺术家和歌单详情页的统一身份展示容器。详情页可以使用封面氛围背景，但 hero 内部结构应保持一致。

- PC 端使用横向结构：封面/头像在左，标题、meta 和主操作在右。
- 移动端使用纵向结构：封面/头像居中，标题、meta 和播放入口位于下方。
- 专辑和歌单封面使用 `AppRadiusTokens.coverDetail`；艺术家头像保持圆形，但仍放在同一 hero 框架里。
- 主操作使用 `PlayAllButton`，次操作使用 `AppActionButton`。不要在详情页单独手写圆形播放按钮或自定义大按钮。
- PC 端曲目列表复用 `MusicTrackTable`，移动端曲目列表复用 `MusicTrackTile`。

### Player page

播放页是情绪最强的界面。允许使用封面模糊背景、唱片旋转、歌词高亮和更大的视觉焦点，但必须保持控制区清晰可用。

- PC 端采用稳定工作区，而不是移动页横向拉伸。默认结构为封面舞台、歌词舞台、播放工具三列，底部只保留进度和核心播放控制。
- 封面区承载当前曲目信息和收藏动作；歌词区直接展示歌词内容，不再在歌词内部嵌套额外卡片。
- 播放工具在 PC 端使用右侧工具面板，下载、睡眠定时、队列、音质和音量保持同一行式工具语言。
- 移动端必须提供显式「封面 / 歌词」分段切换入口，手势只能作为辅助，不作为发现模式的唯一入口。
- 播放页弹层使用实底 surface、轻边框和少量阴影。除队列等复杂操作外，桌面端优先使用靠近工具栏的轻量弹层，不套用移动端底部抽屉。
- 控制区不承担过多信息。歌名、专辑、收藏等上下文信息应位于封面舞台或移动端曲目信息区，底部控制只服务播放。

### Bottom sheets

底部抽屉用于播放队列、音质选择、睡眠定时和曲目操作。移动端使用平台习惯，桌面端避免把简单操作都变成移动式抽屉。

- 移动端底部抽屉统一使用 `AppSheetScaffold`：实底 surface、22px 顶部圆角、细顶边框、统一拖拽把手和标题说明区。
- Sheet 内选择项优先使用 `AppOptionTile`，选中态用 primaryContainer、细边框和 radio/check，不使用装饰渐变或大面积高饱和色。
- 高风险动作不能在 Sheet 或列表中即时执行。清空队列、删除下载、退出登录、清理缓存等必须先进入确认弹窗。
- 桌面端优先使用靠近触发点的轻量弹层；只有复杂队列管理或需要长列表时才使用较大的浮层。

### Dialogs

确认弹窗使用 `showAppConfirmationDialog`。弹窗应短文案、明确后果、按钮右对齐，危险动作使用 error 色但保持 TextButton 极简风格。

### State views

`AppBodyStateView` 和 `AppSliverStateView` 用于加载、空状态和错误状态。状态文案应说明原因和下一步，而不是只显示「暂无内容」。

- 基础调用仍可只传 `message`，兼容旧页面。
- 新页面优先传入 `icon`、`title`、`description` 和操作按钮，形成更完整的空状态。
- 加载态可继续使用居中 spinner；列表密集页面后续可逐步替换为 skeleton。

## Motion

动效服务于反馈、状态变化和播放氛围。

| Motion | Duration | Curve | Use |
|---|---:|---|---|
| Tap feedback | 140ms | ease out | 按钮按压 |
| Hover / selected state | 180ms | ease out | 背景、边框、颜色 |
| Text/content switch | 220-260ms | ease out | 歌曲信息切换 |
| Lyric scroll | 320ms | easeOutCubic | 当前歌词定位 |
| Tonearm | 500ms | easeInOut | 播放/暂停唱针 |
| Volume fade | 600ms | linear | 淡入淡出 |

Rules:

- 不做装饰性页面加载编舞。
- 列表滚动中避免复杂动画和大面积 blur。
- 不动画 layout 属性，优先使用 opacity、transform、color。
- 播放状态动画可有仪式感，但不能拖慢控制响应。

## Copy and language

- 用户可见文案使用简体中文。
- 文案短、明确、直接服务任务。
- 空状态说明下一步，而不是只说「暂无内容」。
- 不使用夸张营销语，不把播放器写成 SaaS 产品介绍。
- 不使用破折号式堆砌；用逗号、冒号、句号或括号。

## Accessibility

- 所有播放、收藏、下载、队列、返回、关闭等图标操作需要 tooltip 或 Semantics。
- 触控目标不小于 44×44px。
- Slider 需要提供 `semanticFormatterCallback`，音量读作百分比，播放进度读作时间。
- 紧凑列表或桌面表格中的图标按钮可以视觉收窄，但实际可点击区域仍需保持 44×44px。
- 深浅主题都需满足 WCAG AA 对比度。
- 空状态、错误状态和加载状态不能只依赖颜色表达。
- 支持字体缩放，标题和列表项需要合理截断而不是溢出。
- 后续动效应兼容减少动态效果偏好。

## Page patterns

### Login

品牌首印象 + 快速连接。宽屏分栏，窄屏上下排列。登录表单清晰优先，品牌装饰保持低噪声。

### Home

快速开始聆听。包含搜索入口、推荐内容、最近播放、常听内容和最近加入。避免把首页做成指标面板。

- 搜索入口应贴近 `AppSearchField` 的形态，轻边框、低背景、无毛玻璃。
- 今日推荐和最近加入使用专辑网格语言，不再为首页单独设计大封面卡片。
- 最近播放可以保留当前播放标记和播放 hover，但只用低透明遮罩，不用渐变遮罩。
- 首页区块之间保持清楚节奏，但不引入额外 hero 或统计卡片。

### Library

媒体库承载歌曲、专辑、艺术家、收藏四个 Tab。搜索手动提交。歌曲与收藏都应提供歌曲数和播放全部入口，视觉和交互保持一致。

### Playlists

歌单列表用于浏览和进入详情。歌单详情移动端将播放全部入口放在歌单标题下方，列表本身保持紧凑、低圆角、适合连续浏览。

- 歌单列表 PC 端使用 `MusicPlaylistGridCard`，移动端使用 `MusicPlaylistListTile`。
- 歌单详情复用 `AppDetailHeroFrame`，曲目列表在 PC 端使用 `MusicTrackTable`。
- 歌单卡片与专辑卡片有亲缘关系，差异只通过歌曲数角标和文案表达。

### Details

专辑、艺术家、歌单详情可以使用封面氛围背景。Hero 展示身份信息和主操作，列表继续承担播放入口。

- 专辑、艺术家和歌单详情统一使用 `AppDetailHeroFrame`。
- 详情封面、hero 框和列表外观来自 token，不在页面内硬编码大圆角。
- 详情页允许比普通列表页更有音乐氛围，但操作按钮仍采用全局按钮系统。

### Player

沉浸式聆听核心。封面、唱片、歌词和控制区建立音乐感。控制必须始终清晰、可触达、响应快。

### Settings and downloads

设置、下载管理更偏工具界面。使用更清晰的分组和更低情绪强度，不引入多余装饰。

- 设置分组使用轻量 surface 列表，不使用额外渐变、玻璃或大阴影。设置项 hover 只显示低透明 surfaceContainerHigh。
- 设置项 hover 只能有一个状态源。若外层容器已经处理 hover/pressed 背景，内部不要再使用带默认 hover overlay 的 `ListTile`。
- 设置项 hover 背景不做淡入淡出动画，避免鼠标快速移动时上一项延迟淡出造成相邻两项同时高亮。
- 设置中的选择操作可以在移动端使用统一 Sheet；桌面端后续可逐步迁移为 popover，但同样复用 `AppOptionTile` 语义。
- 下载列表是文件管理场景。删除离线文件必须确认，并在完成后给出 SnackBar 反馈。
- 下载项视觉以封面、标题、状态、大小为主，删除和取消按钮保持 44px 点击区和 tooltip。

## Design debt and recommendations

- 字体系统已迁移为系统 UI 主字体，后续需要逐页检查 headline/display 的使用是否过度。
- 颜色 token 可逐步补充 OKLCH 表达，减少十六进制在极亮或极暗场景下的不可控偏色。
- 收藏已并入媒体库，旧的独立收藏页规范应视为历史，不再作为新设计入口。
- 组件状态需要持续补齐 hover、focus、active、disabled、loading、error，尤其是自定义列表项和卡片。
