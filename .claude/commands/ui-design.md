---
description: UI/UX 设计指导（基于 design.md 视觉规范和 Flutter 最佳实践）
argument-hint: "<UI任务描述，例如：设计下载管理页面 / 优化播放页布局>"
---

执行 **UI/UX 设计任务**：$ARGUMENTS

## 执行步骤

### 1. 读取设计规范

**必须先读取以下文件**：
- `design.md` — 完整视觉规范（色彩、排版、间距、组件、动画、跨端规则）
- `lib/shared/theme/app_theme.dart` — 当前主题实现
- `lib/shared/theme/app_tokens.dart` — 设计 token 定义
- `lib/shared/theme/app_breakpoints.dart` — 响应式断点
- `lib/shared/theme/app_motion.dart` — 动画规范

按需读取：
- `.codebuddy/skills/ui-ux-pro-max/data/stacks/flutter.csv` — Flutter UI 参考数据
- `lib/presentation/widgets/` — 现有可复用组件

### 2. 设计原则

- **精致 · 克制 · 沉浸 · 统一 · 轻盈** — 每处设计决策回答：这是否让聆听体验更沉浸？
- **暗色优先**：深色模式为主基调，浅色模式同等支持
- **极简风格**：不超过 3 种语义色同时出现（Primary/Secondary/Error）
- **中文优先**：用户文案简体中文，代码标识符英文
- **Alpha 分层**：同一色值通过不同 alpha 区分层级

### 3. 跨端布局规则

| 布局 | 条件 | 结构 |
|------|------|------|
| 桌面端 | 宽度 > 1080px | 侧边栏 + 内容区 + 播放栏 |
| 移动端 | 宽度 ≤ 1080px | 底部导航 + 内容 + 迷你播放栏 |

- 使用 `AppShell` 统一处理布局切换
- 专辑详情等页面在宽屏时封面与信息水平排列
- 列表网格响应式列数（2~5列）

### 4. 色彩系统

深色模式核心色值：
- Scaffold: `#090C12` — 页面底层背景
- Surface: `#121723` — 卡片/容器基底
- Primary: `#9CA6FF` — 薰衣草蓝紫
- Secondary: `#86D3D0` — 薄荷青绿
- Lyric Highlight: `#ECA35B` — 歌词当前行高亮

使用 `AppColorTokens` 和 `AppTheme` 中定义的 token，不硬编码色值。

### 5. 排版规范

- Display/Headline 使用负 letter-spacing（紧凑有力）
- 正文行高 1.4，小字 1.35
- 时间显示使用 `FontFeature.tabularFigures()` 避免跳动
- 字体家族：Righteous（品牌）、Poppins（正文）

### 6. 组件复用

优先使用现有 Widget：
- `CachedArtwork` — 封面图片
- `BlurredCoverBackground` — 模糊封面背景
- `MusicTrackTile` — 歌曲列表项
- `MusicAlbumCards` — 专辑卡片网格
- `SectionHeader` — 区块标题
- `MetaPill` — 标签药丸
- `MiniPlayerBar` — 迷你播放条
- `QueueSheet` — 播放队列面板
- `TrackActionsSheet` — 曲目操作菜单
- `PageLayout` — 页面布局模板

## 输出要求

设计方案须包含：
- **布局结构**：桌面端和移动端的布局描述
- **组件选择**：复用的现有组件 + 需要新建的组件
- **交互说明**：用户操作流程、状态转换
- **动画规格**：参考 `AppMotion` 定义
- **实现建议**：涉及的文件和 Cubit/State 变更

## 约束

- 不引入新的设计系统或 UI 库
- 复用现有 Widget 和 Theme token
- 任何布局变更须兼顾桌面和移动端
- 遵循 Clean Architecture，UI 逻辑通过 Cubit 管理
