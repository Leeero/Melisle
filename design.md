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
| Scaffold | `#090C12` | `#F5F7FB` | 页面底层背景 |
| Surface | `#121723` | `#FFFFFF` | 内容容器、卡片基底 |
| Surface High | `#171E2B` | `#F1F4FA` | 输入框、提升一级容器 |
| Surface Highest | `#212A3B` | `#E5EBF5` | SnackBar、最高层级容器 |
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

当前代码使用 `Righteous` 作为 display/headline 字体，`Poppins` 作为正文和 UI 字体。后续建议逐步评估回到系统字体栈或更接近平台原生的 sans，以提升跨平台产品 UI 的可信度和中文排版稳定性；在未改代码前，设计稿和实现仍按现状记录。

### Current implementation

| Level | Font | Weight | Letter spacing | Use |
|---|---|---:|---:|---|
| Display Large/Medium/Small | Righteous | 400 | -1.5 to -1.0 | 播放页歌名、品牌性标题 |
| Headline Large/Medium | Righteous | 400 | -0.9 to -0.6 | 专辑、艺术家、页面强标题 |
| Headline Small | Poppins | 700 | -0.45 | 区块标题 |
| Title Large | Poppins | 700 | -0.2 | AppBar、重要标题 |
| Title Medium/Small | Poppins | 600 | 0 | 列表项、卡片标题 |
| Body Large/Medium | Poppins | 400 | 0 | 正文、副标题 |
| Body Small | Poppins | 400 | 0 | 时间、说明、次要信息 |
| Label Large | Poppins | 600 | 0.1 | 按钮、Tab、Chip |
| Label Medium/Small | Poppins | 500 | 0 | 导航、MetaPill |

### Type rules

- 中文界面优先保证可读性，不为品牌感牺牲列表和按钮清晰度。
- 正文行长控制在 65-75ch，音乐列表可更紧凑。
- 标题可有轻微负字距，正文和标签不追求装饰性字距。
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
| shellContainer | 24 | 桌面主内容容器 |
| card | 20 | 卡片、列表项、底部导航容器 |
| button | 999 | 胶囊主按钮 |
| input | 16 | 输入框 |
| iconButton | 18 | 图标按钮、TextButton 圆角 |
| coverGrid | 16 | 网格封面 |
| coverDetail | 24 | 详情页封面 |

### Elevation rules

- 深色模式默认 elevation 0，通过 `outlineVariant` 边框和 surface 层级表达深度。
- 浅色模式允许非常轻的 shadow，避免浮夸卡片感。
- 当前播放项使用 primary container 与 primary 边框，而不是厚边条或高亮侧线。
- 禁止用彩色左/右粗边框作为列表或卡片强调。

## Components

### App shell

桌面端使用窄侧边栏，包含 Logo、首页、媒体库、歌单、设置。移动端使用底部导航，并与 MiniPlayerBar 共同形成底部 Dock。导航项保持四个一级入口，收藏入口位于媒体库 Tab 内，不再作为一级导航。

### Page header

页面 Header 用于标题、说明、搜索和局部筛选。Header 应保持轻量，不把所有统计都塞成指标区。

媒体库 Header 当前包含：标题、说明、搜索框、Tab（歌曲 / 专辑 / 艺术家 / 收藏）。搜索为手动提交，不随输入实时触发。

### Tabs and pills

媒体库分类使用一致的 Tab 交互，移动端和桌面端保持同一视觉词汇。MetaPill 只用于轻量统计，例如歌曲数、已加载数、播放时间。

### Track list item

歌曲项应突出封面、标题、艺术家和专辑。当前播放项可更明显，但不能破坏列表节奏。

- 封面：48-58px，圆角 14-20。
- 标题：Title Medium，单行省略。
- 副标题：Body Medium，使用 onSurfaceVariant。
- 当前播放：primaryContainer 背景、primary 细边框、`graphic_eq_rounded`。
- 普通项：surface 低透明背景、outlineVariant 细边框。

### Album and playlist grid

网格以封面为主，文字为辅。避免相同尺寸的图标卡片网格。专辑、歌单卡片可以 hover 轻微缩放，但不做复杂进场动画。

### Player page

播放页是情绪最强的界面。允许使用封面模糊背景、唱片旋转、歌词高亮和更大的视觉焦点，但必须保持控制区清晰可用。

### Bottom sheets

底部抽屉用于播放队列、音质选择、睡眠定时和曲目操作。移动端使用平台习惯，桌面端避免把简单操作都变成移动式抽屉。

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
- 深浅主题都需满足 WCAG AA 对比度。
- 空状态、错误状态和加载状态不能只依赖颜色表达。
- 支持字体缩放，标题和列表项需要合理截断而不是溢出。
- 后续动效应兼容减少动态效果偏好。

## Page patterns

### Login

品牌首印象 + 快速连接。宽屏分栏，窄屏上下排列。登录表单清晰优先，品牌装饰保持低噪声。

### Home

快速开始聆听。包含搜索入口、推荐内容、最近播放、常听内容和最近加入。避免把首页做成指标面板。

### Library

媒体库承载歌曲、专辑、艺术家、收藏四个 Tab。搜索手动提交。歌曲与收藏都应提供歌曲数和播放全部入口，视觉和交互保持一致。

### Playlists

歌单列表用于浏览和进入详情。歌单详情移动端将播放全部入口放在歌单标题下方，列表本身保持紧凑、低圆角、适合连续浏览。

### Details

专辑、艺术家、歌单详情可以使用封面氛围背景。Hero 展示身份信息和主操作，列表继续承担播放入口。

### Player

沉浸式聆听核心。封面、唱片、歌词和控制区建立音乐感。控制必须始终清晰、可触达、响应快。

### Settings and downloads

设置、下载管理更偏工具界面。使用更清晰的分组和更低情绪强度，不引入多余装饰。

## Design debt and recommendations

- 字体系统建议后续评估从 Righteous + Poppins 迁移到更原生的系统字体栈，尤其为了中文和跨平台 UI 的一致性。
- 颜色 token 可逐步补充 OKLCH 表达，减少十六进制在极亮或极暗场景下的不可控偏色。
- 收藏已并入媒体库，旧的独立收藏页规范应视为历史，不再作为新设计入口。
- 组件状态需要持续补齐 hover、focus、active、disabled、loading、error，尤其是自定义列表项和卡片。
