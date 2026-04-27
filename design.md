# 乐岛（Melisle）UX/UI 设计规范

> **版本**: 2.1
> **最后更新**: 2026-04-24  
> **适用范围**: Android / iOS / macOS / Windows 全平台  
> **设计理念**: 自托管音乐的精致岛屿 — 不追求大而全，在设计语言的统一性、播放体验的沉浸感、跨端操作的一致性上做到极致。

---

## 一、品牌与视觉基因

### 1.1 品牌要素

| 要素 | 值 | 说明 |
|------|-----|------|
| 中文名 | 乐岛 | 「乐」= 音乐 + 快乐；「岛」= 私密的、个人的聆听空间 |
| 英文名 | Melisle | Melody + Isle |
| Slogan | 听见每一份热爱 | — |
| Logo | `assets/icons/logo.png` | 圆角方形容器，内置于 56×56 / 60×60 容器 |
| 托盘图标 | macOS: `tray.png` (22pt@2x 模板图) / Windows: `tray.ico` (16/24/32/48) | — |

### 1.2 设计关键词

**精致** · **克制** · **沉浸** · **统一** · **轻盈**

乐岛服务的是对审美有追求的自托管音乐爱好者。他们厌倦了臃肿的通用客户端，渴望一个视觉干净、交互轻快、跨端一致的专属聆听空间。每一处设计决策都应回答一个问题：**这是否让聆听体验更沉浸？**

---

## 二、色彩系统

### 2.1 调色板

基于 Material 3 `ColorScheme.fromSeed` 生成，手动覆写关键色值以确保品牌识别度。

#### 深色模式（主基调）

| Token | 色值 | 用途 |
|-------|------|------|
| Scaffold | `#090C12` | 页面最底层背景，近乎纯黑，沉浸感强 |
| Surface | `#121723` | 卡片、容器、内容区基底 |
| Surface High | `#171E2B` | 输入框填充、提升一级的容器 |
| Surface Highest | `#212A3B` | 最高层级容器、SnackBar 背景 |
| Primary | `#9CA6FF` | 主色，薰衣草蓝紫，低饱和度柔和 |
| Secondary | `#86D3D0` | 辅助色，薄荷青绿，与主色形成冷暖微妙对比 |
| Primary Container | `#2B3150` | 选中态、激活态容器背景 |
| Secondary Container | `#1D333C` | Hero 区渐变辅助 |
| Outline | `#5A6478` | 主分割线 |
| Outline Variant | `#2A3342` | 轻量边框、卡片描边（常配 alpha 0.52~0.72） |
| On Surface Variant | `#ACB6C7` | 次要文字、副标题、图标 |
| Lyric Highlight | `#ECA35B` | 歌词当前行高亮，暖橙色，与冷调背景形成焦点对比 |

#### 浅色模式

| Token | 色值 | 用途 |
|-------|------|------|
| Scaffold | `#F5F7FB` | 页面底层，微灰白，避免纯白刺眼 |
| Surface | `#FFFFFF` | 卡片基底 |
| Surface High | `#F1F4FA` | 容器填充 |
| Surface Highest | `#E5EBF5` | 最高层级 |
| Primary | `#6172E3` | 比深色模式略暗的蓝紫，保证对比度 |
| Secondary | `#4BA9A4` | — |
| Outline Variant | `#D8DFEA` | — |
| On Surface Variant | `#5E687C` | — |

### 2.2 色彩使用原则

1. **不超过 3 种语义色同时出现**：Primary（主操作 / 当前状态）、Secondary（辅助信息）、Error（破坏性操作 / 错误）。
2. **封面主色调**：全屏播放页及详情页背景从封面提取主色（`BlurredCoverBackground`），通过 PaletteGenerator 取 dominantColor / vibrantColor / darkMutedColor，高斯模糊 + 低透明度叠加，形成「色彩氛围」而非喧宾夺主。
3. **Alpha 分层**：同一色值通过不同 alpha 区分层级，避免引入过多新色值。当前代码中大量使用 `withValues(alpha: 0.xx)` 模式。
4. **深浅模式对等**：每个界面在两种模式下都必须自然舒适，不允许出现「只在深色下好看」的设计。

---

## 三、排版系统

### 3.1 字体层级

基于 Material 3 TextTheme，覆写关键属性：

| 层级 | Weight | Letter Spacing | 场景 |
|------|--------|---------------|------|
| Display Small | w700 | -1.2 | 播放页歌名、首页 Slogan |
| Headline Medium | w700 | -0.9 | 页面主标题（专辑名、艺术家名） |
| Headline Small | w700 | -0.45 | 区块标题（设置、媒体库） |
| Title Large | w700 | -0.2 | AppBar、歌词当前行 |
| Title Medium | w600 | 默认 | 列表项标题、卡片标题 |
| Body Large | 默认 | 默认 | 段落正文（行高 1.4） |
| Body Medium | 默认 | 默认 | 列表副标题（行高 1.4） |
| Body Small | 默认 | 默认 | 时间戳、次要信息（行高 1.35） |
| Label Large | w600 | 0.1 | 按钮文字、Chip 标签 |
| Label Medium | — | — | 导航标签、MetaPill |
| Label Small | — | — | 曲目数等微型标注 |

### 3.2 排版原则

- **负 letter-spacing**：Display 和 Headline 级别使用负间距，让标题更紧凑有力。
- **行高克制**：正文 1.4，小字 1.35；不过松、不挤压。
- **中文优先**：所有面向用户的文字使用简体中文；代码标识符和注释使用英文。
- **等宽数字**：时间显示（进度条两端）使用 `FontFeature.tabularFigures()` 避免跳动。

---

## 四、间距与尺寸系统

### 4.1 基础间距单元

以 **4px** 为最小单元，所有间距为其整数倍：

| Token | 值 | 场景 |
|-------|-----|------|
| xs | 4px | 紧凑元素间（如 label 与 icon） |
| sm | 8px | 行内元素间距 |
| md | 12px | 列表项间距、卡片内部元素间 |
| lg | 16px | 移动端水平 padding |
| xl | 20-24px | 桌面端水平 padding、区块间距 |
| 2xl | 28px | Hero 区内部 padding |
| 3xl | 40px | 播放页主内容 padding |

### 4.2 响应式水平 Padding

| 屏幕宽度 | Padding |
|----------|---------|
| < 960px | 16px |
| ≥ 960px | 24px |

### 4.3 关键尺寸

| 元素 | 尺寸 | 说明 |
|------|------|------|
| 侧边栏宽度 | 120px | 桌面端 |
| MiniPlayerBar 封面 | 52px (移动) / 56px (桌面) | — |
| 列表项封面 | 48~58px | 根据场景 |
| 专辑网格封面 | 162~170px | 根据容器 |
| 播放页唱片 | 440×440px | 含容器 |
| 播放页封面（唱片中心） | 唱片尺寸 × 0.65 | — |
| 控制按钮（主） | 56px 圆形 | 播放/暂停 |
| 控制按钮（次） | 44px 圆形 | 上一曲/下一曲/循环/随机 |
| IconButton 最小尺寸 | 44×44px | 触控友好 |
| 窗口最小尺寸 | 960×680px | 桌面端 |
| 窗口默认尺寸 | 1280×820px | 桌面端 |

---

## 五、圆角系统

全局统一，大组件大圆角、小组件小圆角：

| 层级 | 值 | 适用 |
|------|-----|------|
| 超大 | 34-36px | 页面级容器、Header 区域、Hero 卡片 |
| 大 | 28-30px | Card、TrackRow、专辑封面容器 |
| 中 | 22-24px | 按钮、ListTile、ArtistCard 圆角 |
| 小 | 18-20px | IconButton、输入框、InkWell |
| 微 | 14-16px | 快捷入口图标容器 |
| 全圆 | 999px | Chip、MetaPill、FilterPill、头像 |

### 圆角原则

- **容器越大圆角越大**，视觉上保持「柔软」的一致性。
- **嵌套圆角递减**：外容器 34px → 内卡片 28px → 内封面 24px，避免贴角。
- **圆形元素**：艺术家头像、播放按钮使用 `BoxShape.circle` 或 `borderRadius: 999`。

---

## 六、阴影与层级

### 6.1 阴影规范

| 场景 | 配置 | 说明 |
|------|------|------|
| 卡片（深色） | 无阴影，靠边框区分 | elevation: 0 |
| 卡片（浅色） | `elevation: 0.5`, `shadowColor: black/0.08` | 极轻 |
| MiniPlayerBar | `black/0.16, blur: 28, offset: (0, 12)` | 悬浮感 |
| 播放页唱片容器 | `black/0.15, blur: 40, offset: (0, 20)` | 深度感 |
| Hero 封面 | `black/0.12, blur: 28, offset: (0, 18)` | 物理重量感 |
| Hover 播放按钮 | `primary/0.3, blur: 16, offset: (0, 6)` | 交互聚焦 |

### 6.2 边框策略

深色模式下依赖 **1px 低透明度边框** 替代阴影来表达层级：
- `outlineVariant` + alpha 0.45~0.72 是最常用组合
- 当前播放项使用 `primary` + alpha 0.28~0.3 的边框高亮
- 浅色模式下边框 alpha 可提至 0.88~1.0

---

## 七、布局体系

### 7.1 响应式断点

| 断点 | 布局 |
|------|------|
| < 1080px | **移动端模式**：底部标签栏 + 内容区 + 底部 MiniPlayerBar |
| ≥ 1080px | **桌面端模式**：左侧边栏(120px) + 内容区(含 MiniPlayerBar) |

```
┌──────────────────────────────────────────────────┐
│  桌面端 (≥ 1080px)                                │
│  ┌──────┐  ┌──────────────────────────────────┐   │
│  │ Logo │  │                                  │   │
│  │      │  │         Content Area             │   │
│  │ 首页  │  │                                  │   │
│  │ 媒体库│  │   (列表/网格/详情/搜索/设置...)   │   │
│  │ 歌单  │  │                                  │   │
│  │      │  │                                  │   │
│  │      │  ├──────────────────────────────────┤   │
│  │ 设置  │  │        MiniPlayerBar            │   │
│  └──────┘  └──────────────────────────────────┘   │
└──────────────────────────────────────────────────┘
```

```
┌───────────────────────┐
│  移动端 (< 1080px)     │
│  ┌───────────────────┐ │
│  │                   │ │
│  │   Content Area    │ │
│  │                   │ │
│  ├───────────────────┤ │
│  │  MiniPlayerBar    │ │
│  ├───────────────────┤ │
│  │ 首页 媒体库 歌单 设置│ │
│  └───────────────────┘ │
└───────────────────────┘
```

### 7.2 内容区网格

专辑/歌单网格自动适配列数：

| 屏幕宽度 | 列数 | 适用页面 |
|----------|------|---------|
| < 760px | 2 | 首页最近加入、媒体库专辑 |
| 760~1119px | 3 | — |
| 1120~1319px | 4 | — |
| ≥ 1320px (媒体库) / ≥ 1420px (首页) | 5 | — |

**网格间距**: mainAxisSpacing: 18, crossAxisSpacing: 18  
**宽高比**: 0.78~0.82（封面为主，底部留文字空间）

### 7.3 详情页布局（专辑 / 艺术家 / 歌单）

| 屏幕宽度 | 布局 |
|----------|------|
| < 860px (专辑/歌单) / < 720px (艺术家) | 竖排：封面居中 → 信息在下 |
| ≥ 860px / ≥ 720px | 横排：封面在左 + 信息在右 |

### 7.4 全屏播放页布局

| 屏幕宽度 | 布局 |
|----------|------|
| < 860px | **竖排**：唱片 → 歌词 → 控制区（底部） |
| ≥ 860px | **三栏**：唱片(flex:5) + 歌词(flex:6) → 底部控制区(三段：封面信息 / 控制 / 音量队列) |

---

## 八、组件规范

### 8.1 卡片（Card）

```
圆角: 28px
深色: surface/0.82 背景 + outlineVariant/0.52 边框 + 0 elevation
浅色: surface 背景 + outlineVariant/0.88 边框 + 0.5 elevation
内边距: 14px (紧凑) / 22px (Header 区)
```

### 8.2 MetaPill / FilterPill / CounterPill

用于标签、统计、筛选的胶囊形组件：

```
MetaPill:
  padding: 水平 10-12, 垂直 6-7
  背景: surface/0.48~0.58
  圆角: 999
  字体: labelSmall 或 labelMedium

FilterPill (可交互):
  选中: primaryContainer/0.92 + primary/0.2 边框
  未选中: surface/0.54 + outlineVariant/0.8 边框
  内含 icon(18) + label
```

### 8.3 TrackRow / 歌曲列表项

```
圆角: 24-28px
内边距: 水平 12-14, 垂直 10-12
封面: 48-58px, 圆角 14-20px
当前播放:
  背景: primaryContainer/0.8~0.82
  边框: primary/0.28~0.3
  图标: graphic_eq (primary 色)
非当前:
  背景: surface/0.62~0.72
  边框: outlineVariant/0.68~0.72
  图标: play_arrow (onSurfaceVariant)
Hover 态: 背景 alpha 提升至 0.92
```

### 8.4 CachedArtwork（封面组件）

```
统一组件: CachedArtwork(imageUrl, size, borderRadius)
无封面占位: 渐变色矩形（由 cached_network_image 的 placeholder 处理）
标准尺寸/圆角组合:
  - 列表项:  48-58px / 14-20px
  - 网格卡片: 162-170px / 24px
  - 详情页:  210-250px / 24px
  - MiniPlayer: 52-56px / 20-22px
  - 播放页:  唱片 0.65 比例 / 全圆
  - 艺术家头像: 150-180px / 999 (全圆)
```

### 8.5 BlurredCoverBackground（模糊封面背景）

用于专辑详情、艺术家详情、歌单详情、全屏播放页：

```
层叠结构:
  1. 封面图拉伸铺满 → ImageFilter.blur(sigma: 60~80)
  2. 深色叠层: black/0.4~0.6
  3. 前景内容
效果: 营造色彩氛围，但不抢夺内容注意力
```

### 8.6 按钮系统

| 类型 | 圆角 | 最小高度 | 场景 |
|------|------|---------|------|
| FilledButton | 22px | 50px | 主操作（播放专辑、登录） |
| OutlinedButton | 22px | 50px | 次操作（返回媒体库） |
| TextButton | 18px | — | 链接式操作（查看更多、清空） |
| IconButton | 18px | 44×44 | 图标操作（收藏、下载、菜单） |
| FilledButton.tonal | 胶囊 | — | 睡眠定时器预设 |

### 8.7 输入框

```
圆角: 20px
填充色: 深色 surfaceContainerHigh/0.72 / 浅色 surface
边框: outlineVariant/0.35 (深色) / 0.9 (浅色)
聚焦边框: primary/0.78, width: 1.25
内边距: 水平 18, 垂直 16
前缀图标: search_rounded (搜索场景)
```

### 8.8 Slider（进度条 / 音量条）

```
轨道高度: 4.5px (全局) / 3px (播放页精细) / 4px (MiniPlayer)
激活色: primary
未激活色: outlineVariant/0.48 (深色) / 0.72 (浅色)
滑块: primary, 半径 7px (全局) / 5-6px (播放页/Mini)
覆盖层: primary/0.12, 半径 18px / 12-14px
```

### 8.9 BottomSheet（底部抽屉）

```
用途: 播放队列、音质选择、睡眠定时、曲目操作
圆角: 顶部 24-34px
拖拽手柄: 居中 40-52px × 4px 圆角胶囊, outlineVariant/0.4
背景: surface/0.96 (队列) / surface (其他)
```

---

## 九、动画与过渡

### 9.1 时长规范

| 类别 | 时长 | 曲线 | 场景 |
|------|------|------|------|
| 即时反馈 | 140ms | — | 按钮按压缩放 |
| 状态切换 | 180ms | — | Hover 变色、选中态切换、容器颜色过渡 |
| 文字过渡 | 220ms | — | 歌词高亮切换 |
| 内容切换 | 260ms | — | AnimatedSwitcher 歌曲信息切换 |
| 歌词滚动 | 320ms | easeOutCubic | LyricView 滚动到当前行 |
| 唱针旋转 | 500ms | easeInOut | 播放↔暂停时唱针落下/抬起 |
| 音量渐变 | 600ms | 线性 | 淡入淡出过渡 |

### 9.2 关键动画

#### 黑胶唱片旋转
- 18秒完整旋转一圈
- 播放时 `_controller.repeat()`
- 暂停时 `_controller.stop(canceled: false)` — 保持当前角度
- 唱片结构：圆形黑胶碟面（SweepGradient 模拟纹理）+ 居中封面（圆角 = 半径）

#### 唱针臂
- AnimatedRotation: `turns: isPlaying ? 0.08 : 0.0`
- 旋转轴心: `Alignment(0.0, -0.8)` — 模拟真实唱针支点
- CustomPaint 绘制臂身 + 唱头 + 阴影 + 枢轴

#### Hover 缩放
- 桌面端卡片 Hover: `AnimatedScale scale: 1.01~1.015`
- 控制按钮 Hover: `scale: 1.04`, 按压: `scale: 0.95`

#### 页面过渡
- ShellRoute 内部: `NoTransitionPage` — 无过渡，侧边栏保持不动
- `/player` 和 `/search`: 默认 MaterialPageRoute 过渡

### 9.3 动画原则

1. **轻柔不抢戏**：动画服务于反馈和引导，不应成为视觉负担。
2. **有始有终**：Hover 进入和离开用同样的时长，不要「快进慢出」。
3. **暂停保持状态**：唱片暂停时保持角度、不回弹。
4. **性能优先**：避免在列表滚动中触发复杂动画。列表项的 Hover 效果仅改变透明度/颜色，不做形变。

---

## 十、图标规范

### 10.1 图标风格

使用 Material Icons Rounded 系列（`Icons.xxx_rounded`），保持圆润统一。

### 10.2 图标尺寸

| 场景 | 尺寸 |
|------|------|
| 导航栏 | 22-24px |
| 列表项 trailing | 24px |
| 控制按钮（主） | 28px |
| 控制按钮（次） | 22px |
| MiniPlayer 控制 | 20-24px |
| FilterPill 内 | 18px |
| 信息标注 | 16px |

### 10.3 关键图标映射

| 功能 | 图标 |
|------|------|
| 首页 | `home_rounded` |
| 媒体库 | `library_music_rounded` |
| 歌单 | `queue_music_rounded` |
| 设置 | `settings_rounded` |
| 搜索 | `search_rounded` |
| 播放 | `play_arrow_rounded` |
| 暂停 | `pause_rounded` |
| 上一曲 | `skip_previous_rounded` |
| 下一曲 | `skip_next_rounded` |
| 随机 | `shuffle_rounded` |
| 循环(关) | `repeat_rounded` |
| 循环(全部) | `repeat_on_rounded` |
| 循环(单曲) | `repeat_one_on_rounded` |
| 收藏 | `favorite_rounded` / `favorite_border_rounded` |
| 下载 | `download_rounded` / `downloading_rounded` / `download_done_rounded` |
| 当前播放 | `graphic_eq_rounded` |
| 展开播放器 | `open_in_full_rounded` |
| 收起播放器 | `keyboard_arrow_down_rounded` (size: 32) |
| 睡眠(未启用) | `bedtime_outlined` |
| 睡眠(已启用) | `bedtime_rounded` (primary 色) |
| 音质 | `high_quality_rounded` |

---

## 十一、页面设计规范

### 11.1 登录页

**目标**：品牌首印象 + 快速连接。

```
结构:
  背景: 渐变 (primaryContainer/0.65 → scaffold → secondaryContainer/0.28)
  装饰: 两个 GlowOrb (径向渐变圆，primary/0.14 + secondary/0.12)
  
  宽屏 (≥ 820px): 左右分栏
    左: 品牌介绍区 (Logo + 名称 + Slogan + 功能亮点 + 特性标签)
    右: 登录表单卡片
  窄屏: 上下排列

  品牌区:
    半透明容器 surface/0.42, 圆角 36
    Logo 60×60 + 应用名 + 英文名
    Slogan Badge
    特性标签: 深色优先 / 迷你播放条 / 跨端统一
    功能亮点: icon + 标题 + 描述

  登录表单:
    Card 包裹
    三个字段: 服务器地址 / 用户名 / 密码
    提交按钮: FilledButton 全宽, loading 态显示 CircularProgressIndicator
    错误提示: SnackBar
```

### 11.2 首页

**目标**：一目了然的音乐入口，快速开始聆听。

```
从上到下:
  1. 搜索入口 (点击跳转，非真实输入框)
  2. 快速入口行: [我的收藏] [播放历史] — 两个等宽卡片
  3. Hero Stage: 推荐专辑大卡片 (宽屏含封面叠加效果)
  4. 最近在听: 水平滚动歌曲卡片 (138px 宽) + 查看更多
  5. 常听的歌: 同上
  6. 最近加入: 专辑网格 (响应式列数)
```

### 11.3 媒体库

**目标**：高效的三视图浏览，支持搜索和无限滚动。

```
Header 区:
  标题 + 描述 + 搜索框 + FilterPill (歌曲/专辑/艺术家) + 统计标签

内容区:
  歌曲: SliverList, TrackRow
  专辑: SliverGrid, AlbumCard
  艺术家: SliverList, ArtistCard (圆角头像)
  触底加载更多 + 到底提示
```

### 11.4 全屏播放页

**目标**：沉浸式聆听体验的核心页面。

```
背景: BlurredCoverBackground

AppBar: 透明
  左: 下箭头收起
  右: 下载按钮 + 睡眠定时按钮

主内容 (maxWidth: 1280):
  宽屏: Row [唱片舞台(flex:5) | 间距80 | 歌词区(flex:6)]
  窄屏: Column [唱片 → 歌词(400px高)]

唱片舞台:
  440×440 半透明容器, 圆角 40
  内部: 旋转黑胶唱片 380px + 唱针臂

歌词区:
  歌名 (displaySmall, w800)
  艺术家名 (headlineSmall, onSurfaceVariant)
  歌词滚动列表 (LyricView)
    行高: 56px
    当前行: titleLarge + w800 + #ECA35B
    其他行: titleMedium + w500 + onSurfaceVariant/0.6
    点击跳转

底部控制区:
  窄屏: 进度条 → 控制按钮
  宽屏: 三栏 [封面信息+收藏 | 控制+进度 | 音质+队列]
```

### 11.5 设置页

**目标**：清晰分组，快速访问常用设置，间距与其他页面保持一致。

```
结构: AppContentPage + ListView
  Header: AppPageHeaderCard 包裹标题「设置」
  区块间距: AppPageLayout.sectionGap (18px)
  标题与内容间距: AppPageLayout.sectionTitleBottomGap (12px)

分组 (每个分组由 _SettingsSection 包裹标题 + child):
  1. 外观 (_ThemeCard)
     - 主题模式三选一 (浅色 / 深色 / 跟随系统)
     - 使用 Radio 列表，当前选中项高亮
  2. 播放 (_PlaybackCard)
     - 默认音质选择
     - 曲间间隔设置
  3. 媒体来源 (_SourceCard)
     - 当前后端类型与地址
     - 切换后端入口
  4. 存储 (_StorageCard)
     - 下载管理入口 → 跳转 /downloads
     - 缓存清理
  5. 连接与账户 (_AccountCard)
     - 当前账户信息
     - 退出登录按钮
```

### 11.6 收藏页

**目标**：快速访问已收藏曲目，支持取消收藏。

```
结构: AppContentPage + ListView
  Header: AppPageHeaderCard
    - 标题「我的收藏」
    - 描述文案
    - MetaPill: 收藏歌曲 / N 首
  Body: ListView (padding: horizontalPadding, bottom: 24)
    - 无限滚动，触底加载更多
    - 到底提示「已经到底了」

曲目卡片 (_FavoriteTrackCard):
  - Hover 背景变亮 (180ms AnimatedContainer)
  - 封面 58px / 圆角 20
  - 标题 (titleMedium) + 艺术家 · 专辑 (bodyMedium/onSurfaceVariant)
  - 当前播放: primaryContainer 背景 + primary 边框 + graphic_eq 图标
  - 收藏按钮: 实时同步 FavoritesCubit，pending 时显示 CircularProgressIndicator
  - 点击: PlayerNavigation.playTracksAndOpenPlayer
  - 长按: 无（仅播放历史/媒体库支持）
```

### 11.7 播放历史页

**目标**：回到最近听过的内容，快速续播。

```
结构: 同收藏页（复用 AppContentPage + ListView 模式）
  Header: AppPageHeaderCard
    - 标题「播放历史」
    - 描述文案
    - MetaPill: 最近播放 / N 条
  Body: ListView，每项显示上次播放时间

曲目卡片 (_HistoryTrackCard):
  - 同 _FavoriteTrackCard 结构
  - 额外: 播放时间 MetaPill (MM-DD HH:mm)
  - 无收藏按钮（历史记录不代表收藏状态）
  - 点击: 同收藏页，传入整段历史作为播放队列
```

### 11.8 歌单列表页

**目标**：浏览和管理歌单，快速进入歌单详情。

```
结构: AppContentPage + ListView
  Header: AppPageHeaderCard
    - 标题「歌单」
    - 描述文案
    - 搜索框 (实时过滤歌单名)
    - MetaPill: 你的歌单 / N 项
  Body: ListView (padding: horizontalPadding, bottom: 24)
    - 无限滚动，触底加载更多

歌单卡片 (_PlaylistCard):
  - Hover: AnimatedScale 1.0 → 1.01
  - 封面 78px (含 6px 内边距) / 圆角 18
  - 标题 (titleMedium) + 曲目数 (bodyMedium)
  - 「沉浸播放」MetaPill
  - 点击 → context.push('/playlists/:id')
```

### 11.9 专辑详情页

**目标**：展示专辑完整信息，一键播放或收藏。

```
背景: BlurredCoverBackground (从专辑封面提取主色)

AppBar: 透明背景，自动适应亮/暗色封面

主内容 (CustomScrollView):
  Sliver: _AlbumHero (封面 + 专辑名 + 艺术家 + 年份 + 曲目数)
    布局:
      < 860px: 竖排，封面居中，信息在下
      ≥ 860px: 横排，封面在左 (210-250px)，信息在右
    操作按钮: 播放专辑 / 收藏专辑
  Sliver: 曲目列表 (SliverList)
    - 每项: _TrackRow (复用组件)
      - 封面 48px / 圆角 14 (showArtwork: true)
      - 当前播放高亮 (primaryContainer + graphic_eq 图标)
      - 点击: 从该曲目开始播放整张专辑
      - 长按: showTrackActionsSheet (查看专辑/艺术家/加队列/收藏)
```

### 11.10 艺术家详情页

**目标**：集中展示艺术家专辑与热门曲目。

```
背景: BlurredCoverBackground (从艺术家头像或最新专辑封面提取主色)

AppBar: 透明背景

主内容 (CustomScrollView):
  Sliver: _ArtistHero (头像 + 艺术家名 + 专辑数 + 热门曲目数)
    布局:
      < 720px: 竖排
      ≥ 720px: 横排，头像 180px 圆形，信息在右
  Sliver: 热门曲目 (SliverList)
    - _TrackRow，同上
  Sliver: 专辑网格 (SliverGrid)
    - maxCrossAxisExtent: 200px
    - childAspectRatio: 0.78
    - 点击 → context.push('/album/:id')
```

### 11.11 歌单详情页

**目标**：查看歌单内所有曲目，支持一键播放。

```
背景: BlurredCoverBackground (从歌单封面提取主色)

结构: 同专辑详情页
  Sliver: _PlaylistHero (封面 + 歌单名 + 曲目数 + 创建者)
  Sliver: 曲目列表 (SliverList)
    - _TrackRow，同上
    - 点击: 从该曲目开始播放整张歌单
```

### 11.12 下载页

**目标**：管理已下载内容和正在进行的下载任务。

```
结构: Scaffold + ListView (AppContentPage 暂未用于此页)
  AppBar: 标题「下载管理」

分区:
  1. 进行中 (_SectionLabel: 进行中)
    - 每个任务: _JobRow
      - 封面 48px / 圆角 14
      - 曲目名 + LinearProgressIndicator (进度条)
      - 状态标签: 排队中 / 下载中 · 百分比 · 已接收/总大小 / 失败原因
      - 取消按钮 (关闭图标)
  2. 已下载 (_SectionLabel: 已下载)
    - 每个记录: _DownloadRow
      - 封面 + 曲目名 + 艺术家 · 格式 · 文件大小
      - 删除按钮 (delete_outline_rounded)

空状态: 标题下方显示「还没有下载内容。」
```

### 11.13 搜索页

**目标**：快速找到曲目、专辑、艺术家、歌单。

```
结构: Scaffold + Column
  AppBar: 返回按钮 + 标题「搜索」
  Body:
    顶部: 搜索框 (自动聚焦，rounded 样式)
      - 前缀搜索图标
      - 后缀清除按钮 (输入后显示)
      - onChanged: 实时搜索 (debounce 由 SearchCubit 处理)
      - onSubmitted: 保存最近搜索历史
    内容区:
      无输入: 最近搜索 (ActionChip 列表 + 清空按钮)
      有结果: 分区显示
        - 曲目 (ListTile, 点击播放并打开播放器)
        - 专辑 (ListTile, 点击 → /album/:id)
        - 艺术家 (ListTile, 点击 → /artist/:id)
        - 歌单 (ListTile, 点击 → /playlists/:id)

空状态:
  - 无输入: 「输入关键词开始搜索」
  - 无结果: 「没有找到结果」
```

---

## 十二、空状态规范

所有列表类页面需要优雅的空状态：

| 页面 | 空文案 |
|------|--------|
| 媒体库(歌曲) | 当前没有匹配的歌曲。 |
| 媒体库(专辑) | 当前没有匹配的专辑。 |
| 媒体库(艺术家) | 当前没有匹配的艺术家。 |
| 收藏 | 还没有收藏歌曲，去媒体库挑几首喜欢的吧。 |
| 播放历史 | 还没有播放历史，先放一首歌吧。 |
| 歌单 | 当前没有匹配的歌单。 |
| 搜索(无输入) | 输入关键词开始搜索 |
| 搜索(无结果) | 没有找到结果 |
| 播放队列 | 当前播放队列为空。 |
| 下载 | 还没有下载内容。 |
| 播放页(无曲目) | 还没有开始播放。 |
| 专辑详情 | 当前专辑还没有曲目。 |
| 歌单详情 | 当前歌单还没有歌曲。 |
| 艺术家详情 | 这位艺术家暂无内容。 |

**风格**：居中显示，bodyLarge / bodyMedium，默认文字色。不使用大图标或插画（保持克制）。

---

## 十三、交互规范

### 13.1 点击反馈

| 元素 | 反馈 |
|------|------|
| Card / InkWell | InkRipple 水波 |
| 控制按钮 | AnimatedScale 缩放 |
| 列表 Hover(桌面) | 背景 alpha 从 0.72 → 0.92 |
| 网格卡片 Hover | AnimatedScale 1.0 → 1.012~1.015 |

### 13.2 长按

- 专辑详情/艺术家详情的曲目行：长按弹出 `TrackActionsSheet`
- 操作项：查看专辑 / 查看艺术家 / 添加到队列 / 收藏

### 13.3 滑动（待实现）

- 移动端播放页：下滑收起
- 移动端播放页：左右滑切歌

### 13.4 键盘（桌面端，已实现 + 待扩展）

| 快捷键 | 功能 | 状态 |
|--------|------|------|
| MediaPlayPause (Windows) | 播放/暂停 | ✅ |
| MediaTrackNext (Windows) | 下一曲 | ✅ |
| MediaTrackPrevious (Windows) | 上一曲 | ✅ |
| macOS 媒体键 | 通过 audio_service MPRemoteCommandCenter | ✅ |
| 空格 | 播放/暂停 | 🔲 |
| ←/→ | 快退/快进 | 🔲 |
| ↑/↓ | 音量调节 | 🔲 |
| Cmd+K / Ctrl+K | 全局搜索 | 🔲 |

### 13.5 进度条 / 音量条

- 拖拽跟手，无延迟
- 播放页时间标签使用等宽数字，拖拽时不跳动
- MiniPlayerBar 进度条全宽，圆角 999

---

## 十四、无障碍与国际化

### 14.1 无障碍（待完善）

- 所有交互元素需有 Semantics 标签（tooltip / semanticLabel）
- 当前已有部分 tooltip（如收起、下载、收藏、睡眠定时）
- 颜色对比度：深色模式下 onSurface (`#E6E6E6`+ ) vs scaffold (`#090C12`) ≈ 15:1，符合 WCAG AAA
- 支持系统字体缩放

### 14.2 国际化

- 当前：仅简体中文
- 未来（P3）：预留 i18n 扩展点，字符串提取到 ARB 文件

---

## 十五、平台适配细则

### 15.1 macOS

- 窗口：可自由拉伸，最小 960×680
- NowPlaying：通过 audio_service 接入 MPNowPlayingInfoCenter
- 托盘：模板图（黑色 + 透明），系统自动适配菜单栏主题
- 快捷键：媒体键由 audio_service 接管（避免 hotkey_manager 在 macOS 的兼容问题）

### 15.2 Windows

- 窗口：同 macOS 配置
- SMTC：通过 audio_service 接入
- 托盘：`tray.ico` 多尺寸白色图标
- 快捷键：MediaPlayPause / MediaTrackNext / MediaTrackPrevious

### 15.3 Android

- 通知栏：audio_service 渲染播放通知
- 锁屏：MediaSession 控制
- 底部标签栏 + MiniPlayerBar
- SafeArea 处理刘海屏 / 底部导航条

### 15.4 iOS

- 同 Android 布局逻辑
- NowPlaying：MPRemoteCommandCenter
- 刘海/灵动岛：SafeArea 适配

---

## 十六、设计决策日志

记录关键的设计选择及其理由，为后续迭代提供上下文：

| 日期 | 决策 | 理由 |
|------|------|------|
| 初始版本 | 深色模式为主 | 目标用户晚间聆听场景居多；自托管用户偏好极客审美 |
| 初始版本 | 薰衣草蓝紫 + 薄荷青绿双色系 | 低饱和冷色调传达「精致」与「宁静」；避免红/橙等高刺激色 |
| 初始版本 | 歌词高亮使用暖橙 `#ECA35B` | 在冷色背景上形成强烈但不刺眼的焦点，引导视线 |
| 初始版本 | 黑胶唱片 + 唱针臂 | 向实体唱片致敬，传达「拥有感」— 与自托管理念共鸣 |
| 初始版本 | 超大圆角 (28-36px) | 与 iOS/macOS 原生设计语言对齐，传达「柔软」「友好」 |
| 初始版本 | 不使用 Tab 过渡动画 | ShellRoute 内页面切换使用 NoTransitionPage，侧边栏保持不动，减少视觉噪音 |
| 初始版本 | Card 深色模式 0 elevation | 深色背景下阴影几乎不可见，改用 1px 边框传达层级更有效 |
| v1.1 规划 | 封面主色调提取 | 参考 Apple Music / Plexamp，让播放页背景跟随音乐情绪变化 |
| 2026-04-24 | v2.1 设计规范补全 | 修正封面主色调标注为已落地（BlurredCoverBackground 已实现）；更新设置页规范移除过时「体验状态」区块；补充收藏页、播放历史页、歌单列表页、专辑详情页、艺术家详情页、歌单详情页、下载页、搜索页共 8 个缺失页面规范 |

---

*本规范是乐岛所有 UI 开发的唯一设计参考。代码实现应严格遵循此处定义的色值、尺寸、间距和动画参数。如需变更，先更新本文档，再修改代码。*
