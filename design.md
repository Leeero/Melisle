# Design

本文件是乐岛（Melisle）的 UI 设计规范入口。Flutter 代码实现、评审和验收都应优先对齐这里定义的设计原则、token、组件规则和验证方式。

## Source Of Truth

设计源优先级如下：

1. `lib/shared/theme/`
   - Flutter 主题、颜色、字体、间距和组件风格的代码实现。
2. `lib/presentation/widgets/`
   - 共享 UI 组件与跨页面交互模式。
3. `design.md`
   - 产品视觉原则、设计 token、布局规则和验收标准。

生产代码必须使用后端数据和现有 Cubit/Repository，不使用设计样例或假数据替代真实业务数据。

## Product Register

默认 register 为 product。乐岛是面向自托管音乐库用户的跨平台播放器，界面需要服务「连接服务、浏览媒体库、管理收藏与歌单、开始播放、沉浸聆听」这条路径。

设计气质：精致、克制、有音乐感，接近 Apple 生态的成熟产品界面。界面应让封面、曲目信息、歌词、播放状态成为主角，不做后台管理系统、模板化 SaaS、强刺激霓虹播放器或过度拟物实验。

## Theme Strategy

双模式均衡：

- 浅色用于桌面整理、白天浏览、媒体库管理。
- 深色用于夜间聆听、播放页、长时间沉浸。
- 任一页面都必须在浅色和深色下自然成立。

色彩策略为 Restrained：带青绿色品牌倾向的中性层级 + 一个主强调色 + 少量音乐氛围色。封面主色可影响播放页和详情页氛围，但不得牺牲文字对比度。

## Color Tokens

Flutter 中使用以下 sRGB 映射值作为当前实现基准：

| Role | Light | Dark | Use |
|---|---:|---:|---|
| Background | `#F7FCFC` | `#0C1315` | 页面底层背景 |
| Surface | `#FFFFFF` | `#141C1E` | 主内容、卡片、列表组 |
| Surface Raised | `#FAFEFE` | `#1B2325` | 输入框、提升容器 |
| Sidebar Surface | `#F1F9F8` | `#101719` | 桌面侧边栏 |
| Foreground | `#070F11` | `#E3E9E9` | 主文本 |
| Foreground Secondary | `#444F52` | `#96A1A1` | 次级文本 |
| Muted | `#647173` | `#7D898A` | 辅助文本、时间、弱图标 |
| Border | `#D8DEDD` | `#2B3233` | 明确分割线 |
| Border Light | `#E8ECEC` | `#222829` | 轻边框、列表分割线 |
| Accent | `#117E6E` | `#46B49E` | 主操作、选中、当前状态 |
| Accent Hover | `#0B695F` | `#5CC5AF` | Hover / pressed 强调 |
| Accent Soft | `#D4F1E9` | `#062D26` | 选中背景、轻强调底色 |
| Music Warm | `#D6A771` | `#CEA26F` | 音乐氛围暖色 |
| Music Warm Soft | `#FDEDDC` | `#312313` | 暖色柔和背景 |
| Music Rose | `#DC937C` | `#D6917B` | 播放页、封面氛围 |
| Music Rose Soft | `#FFE8E0` | `#362019` | 当前播放、柔和选中 |
| Music Teal | `#45A592` | `#5FB7A5` | 辅助音乐氛围 |
| Music Teal Soft | `#D9F4ED` | `#122C26` | Hover wash、背景光 |
| Music Ink | `#20373B` | `#BECECF` | 播放页歌词高亮 |
| Success | `#2E7D4F` | `#65C98A` | 成功状态 |
| Warning | `#9A6700` | `#E2B85B` | 警告状态 |
| Danger | `#B9383A` | `#F08B8D` | 破坏性操作、错误 |

### Color Rules

- Accent 只用于主操作、当前选择、播放相关焦点和链接，不用于纯装饰。
- 状态色与音乐氛围色职责分离，不使用 Music Warm、Music Rose 或品牌 Accent 表达成功、警告和错误。
- Hover wash 优先使用 `Music Teal Soft` 混合背景。
- Selected wash 优先使用 `Music Warm Soft` 或 `Music Rose Soft` 混合背景。
- 深色模式主要通过边框、表面层级和少量阴影建立深度。
- 浅色模式可使用轻阴影，但普通内容不应强浮动。
- 不使用纯黑或纯白作为暗色背景；设计稿中的白色 surface 是浅色主内容面。
- 封面取色只用于播放页和详情页氛围，必须叠加柔化或暗化以保护可读性。
- 封面遮罩上的固定浅色前景使用 `onArtworkScrim`，不随页面明暗模式翻转。
- 页面和组件不得维护独立静态调色板；固定颜色统一来自 `AppColorTokens`，界面通过 `ThemeData`、`ColorScheme` 或 `MelisleThemeX` 消费。
- 普通文字与背景对比度不低于 4.5:1，大字号文字和非文本控件不低于 3:1。

## Typography

当前设计稿使用 Apple 生态字体栈：

- Display: `SF Pro Display`, fallback to platform system UI.
- Body: `SF Pro Text`, fallback to platform system UI.
- Mono: `SF Mono`, fallback to platform monospace.

Flutter 实现以平台系统字体为主，中文环境优先保证可读性。`Righteous` 可保留在品牌性或播放页展示文本中，但普通产品 UI 标签、按钮、列表、设置项不应使用 display 字体。

### Type Rules

- 桌面页面标题约 26px，移动页面标题约 31px。
- Section title 桌面约 17px，移动约 18px。
- 列表正文桌面约 13-14px，移动约 15px。
- 时间、进度、大小等数字使用等宽数字。
- 中文文案短、明确、服务任务，不使用夸张营销语。
- 避免负字距成为 Flutter 全局规则；若需要紧凑标题，只在局部组件中处理。

## Layout And Spacing

### Breakpoints

| Width | Layout |
|---:|---|
| `<768px` | 移动端模式：内容区 + 浮动 MiniPlayer + 底部 Tab |
| `768-1079px` | 中等模式：紧凑侧边栏 + 内容区 + 浮动 MiniPlayer |
| `1080-1439px` | 桌面端模式：左侧 Sidebar + 主内容区 + 底部 MiniPlayer |
| `>=1440px` | 大桌面模式：提高内容网格密度 |

### Desktop Layout Tokens

| Token | Value | Use |
|---|---:|---|
| sidebarWidth | 220 | 桌面左侧导航 |
| miniPlayerHeight | 72 | 桌面底部 MiniPlayer |
| mainContentPaddingX | 36 | 桌面主内容水平边距 |
| mainContentPaddingY | 28 | 桌面主内容顶部边距 |
| cardGridMinWidth | 160 | 桌面专辑/歌单网格最小宽度 |
| cardGridGapX | 18 | 桌面卡片横向间距 |
| cardGridGapY | 22 | 桌面卡片纵向间距 |

### Mobile Layout Tokens

| Token | Value | Use |
|---|---:|---|
| pageX | 24 | 移动端内容水平边距 |
| tabContentHeight | 54 | 底部 Tab 内容高度 |
| miniPlayerHeight | 58-60 | 移动端浮动 MiniPlayer |
| safeBottom | platform safe area | 底部系统安全区 |
| cardScrollGap | 12 | 横向卡片间距 |
| libraryGridGap | 14 / 12 | 移动媒体库网格纵横间距 |

### Layout Rules

- 桌面端使用固定侧边栏和底部播放器，不把移动端底部抽屉模式直接搬到桌面。
- 移动端使用底部 5 Tab：首页、搜索、媒体库、收藏、设置。
- 内容区底部必须预留 MiniPlayer + Tab + SafeArea 空间，避免遮挡列表末尾。
- 设计稿中的 iPhone 外框、Dynamic Island、模拟状态栏属于展示 chrome，不进入生产 App。
- 页面内容优先，不给所有内容套重型卡片。

## Shape And Elevation

| Design Token | Desktop | Mobile | Use |
|---|---:|---:|---|
| radiusSm | 6 | 8 | 导航项、缩略封面、紧凑行 |
| radiusMd | 10 | 12 | 搜索框、小容器 |
| radiusLg | 14 | 16 | 卡片、普通封面 |
| radiusXl | 20 | 24 | 大封面、Sheet、Hero |
| radiusFull | 9999 | 9999 | 胶囊按钮、圆形按钮 |

### Elevation Rules

- 桌面侧边栏和 MiniPlayer 以边框为主，不使用重阴影。
- 移动 MiniPlayer 和底部 Tab 使用半透明 surface、轻边框、blur 和轻阴影。
- 专辑/歌单卡片以封面为视觉主体，hover 或 press 反馈应轻。
- 当前播放项使用柔和选中背景和 accent 文本，不使用粗侧边条。

## Components

### App Shell

桌面端：

- 左侧 Sidebar 宽 220px。
- 1080px 以上 Sidebar 可折叠为 72px 图标栏；折叠态必须保留 tooltip。
- Sidebar 分组：主入口、资料库、管理。
- 主内容顶部使用 54px 页面工具栏，提供返回、页面位置和全局搜索入口。
- 主内容区独立滚动，padding 约 `28px 36px`。
- 底部 MiniPlayer 高 72px，位于主内容列底部。
- 播放队列为右侧滑出面板。

移动端：

- 内容区从顶部安全区下方开始滚动。
- 底部有浮动 MiniPlayer，位于 Tab Bar 上方。
- Tab Bar 包含首页、搜索、媒体库、收藏、设置。
- 播放队列和播放设置使用底部 Sheet。

### Search

桌面搜索框：

- 胶囊形。
- 背景接近 surface，带轻边框和 blur。
- Focus 时 accent 边框和低透明 focus ring。
- 清除按钮仅在有输入时显示。

移动搜索框：

- iOS 风格圆角矩形，高约 40px。
- Focus 时显示「取消」。
- 最近搜索/分类使用轻量 chip。

### Cards

专辑和歌单：

- 封面优先，文字为辅。
- 桌面网格 `minmax(160px, 1fr)`。
- 移动端横向滚动卡片宽约 150px，媒体库网格最小宽约 118px。
- Hover 显示低透明播放 overlay；移动端 press 轻微缩放。

艺术家：

- 圆形封面。
- 标题居中。
- 不使用图标卡片替代真实头像或封面。

### Track Lists

桌面：

- 使用紧凑表格语言。
- 列结构：序号、标题/艺术家、专辑、时长、操作。
- Hover 时显示行操作。
- 当前播放使用 accent 与柔和背景。

移动：

- 使用 iOS 列表语言，默认底部分割线。
- 行高不小于 52px。
- 当前播放使用柔和选中背景、圆角和 accent 标题。
- 操作按钮触控区域不小于 44px。

### Detail Pages

桌面：

- Hero 为横向布局：左封面/头像，右标题、meta、操作。
- 专辑/歌单封面为圆角矩形；艺术家头像为圆形。
- 下方曲目列表使用桌面 track table。

移动：

- 顶部返回入口。
- 封面/头像居中。
- 标题、meta、主操作居中。
- 曲目使用移动 track item。

### Player Page

桌面：

- 全屏沉浸层。
- 三列主体：封面与曲目信息、歌词、播放队列。
- 底部仅承载进度和核心控制。
- 音量、播放设置、更多操作使用靠近控制区的小浮层。

移动：

- 全屏播放页。
- 顶部关闭、标题、更多。
- 主体包含大封面、歌曲信息、歌词滚动。
- 底部为进度、核心控制、扩展操作。
- 更多、音量、播放设置使用底部 Sheet。

### Queue

桌面：

- 右侧滑出队列面板，宽约 360px。
- 当前播放项使用 accent soft 背景。

移动：

- 底部 Sheet，左右 pageX 缩进，顶部圆角 24px。
- 顶部拖拽把手和「完成」操作。
- 列表行使用封面、标题、艺术家、时长。

### Settings

设置页使用分组列表语言：

- 分组标题为小号 muted 文本。
- 设置行包含标题、说明、右侧值、chevron 或 toggle。
- 移动端保留 iOS 风格圆角 group。
- 高风险动作如退出登录必须确认。

### Downloads

下载管理使用工具页语言：

- 顶部可展示存储/音质信息分组。
- 下载项与歌曲列表共享视觉语言。
- 删除下载必须确认并反馈结果。

## Motion

| Motion | Duration | Curve | Use |
|---|---:|---|---|
| Tap / hover | 150ms | ease out | 按钮、列表、卡片反馈 |
| Normal transition | 250ms | ease out | 背景、边框、颜色 |
| Screen entrance | 300-320ms | cubic-bezier(0.2, 0, 0.13, 1) | 页面切换 |
| Player overlay | 380-420ms | cubic-bezier(0.2, 0, 0.13, 1) | 播放页打开 |
| Sheet entrance | 240ms | cubic-bezier(0.2, 0, 0.13, 1) | 移动底部 Sheet |
| Lyric current line | 420-450ms | same music curve | 当前歌词高亮与缩放 |

动效只服务于反馈、状态切换和播放氛围。不做装饰性页面加载编舞，不动画昂贵 layout 属性。

## Accessibility

- 所有播放、暂停、上一首、下一首、队列、收藏、下载、关闭、返回、更多操作都需要 tooltip 或语义标签。
- 触控目标不小于 44x44px。
- Slider 需要提供语义格式化，播放进度读作时间，音量读作百分比。
- 当前播放和当前歌词行需要可读屏理解。
- 深浅主题均需满足 WCAG AA 对比度。
- 长标题、长艺术家名、长专辑名必须省略或换行，不能溢出。
- 支持系统字体缩放，关键布局至少检查 1.0 到 1.3。

## Implementation Policy

- 优先更新共享 token 和共享组件，再更新页面。
- 真实 App 使用后端数据和现有 Cubit/Repository，不使用设计稿假数据替代业务数据。
- 保留现有功能：登录、会话恢复、搜索、播放、切歌、歌词、收藏、队列、音质、睡眠定时、下载、设置保存、路由跳转。
- 每阶段先跑相关测试，再跑 `flutter analyze`，最后做桌面/移动手动 smoke test。

## Validation

常用验证命令：

```bash
flutter test test/widget_test.dart
flutter test test/presentation/pages/global_ui_smoke_test.dart
flutter test test/presentation/widgets/music_track_table_test.dart
flutter test test/presentation/widgets/app_modal_test.dart
flutter test test/presentation/widgets/lyric_view_test.dart
flutter test test/presentation/blocs/search/search_cubit_test.dart
flutter test test/presentation/pages/search/search_page_test.dart
flutter test test/presentation/blocs/playlist_detail_cubit_test.dart
flutter analyze
```

完整验收：

```bash
flutter test
flutter analyze
```
