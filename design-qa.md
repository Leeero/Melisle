**Findings**

- [P1] 无法获取运行中的 Flutter 界面
  Location: 媒体库 / 歌曲 / 排序与筛选。
  Evidence: 本机环境未提供 `flutter` 命令，无法捕获已实现界面并与方案 1 的参考图进行同视口比较。
  Impact: 无法确认菜单锚点、弹层尺寸、键盘导航与交互态的视觉一致性。
  Fix: 在具备 Flutter SDK 的环境执行 `flutter test test/presentation/blocs/library_cubit_test.dart`、`flutter analyze`，启动桌面应用后于歌曲页打开“排序与筛选”菜单，再重新截图比较。

**Open Questions**

- 参考图中的“已下载”和“音质”筛选尚未纳入实现，因为当前协议能力层未声明它们可由服务端过滤；Emby 与 Navidrome 都明确接入“仅显示收藏”。

**Implementation Checklist**

1. 以可选 `TrackFilteringRepository` 声明并获取当前协议支持的筛选项。
2. Emby 将收藏筛选编码为 `Filters=IsFavorite`，并与服务端排序一起请求。
3. Navidrome 通过 Subsonic 的 `getStarred2` 获取收藏歌曲，并在客户端对该服务端结果应用搜索和分页。
4. 缓存与自动检测仓库透传活动协议的能力与请求；其他协议返回空能力集合。
5. 菜单仅渲染当前协议返回的排序和筛选项。

**Follow-up Polish**

- [P3] 获得桌面截图后，可微调弹层最小宽度、菜单行高和激活筛选徽标的位置。

## Comparison evidence

- Source visual truth: `/Users/lero/.codex/generated_images/01a0236e-353c-7e70-b361-9e426733cd7f/exec-745dda7a-b976-4783-b9c7-7aaec146708e.png`
- Intended viewport: 2560 × 1640, desktop light theme, songs page with the anchored menu open.
- Implementation screenshot: unavailable; Flutter SDK is not installed or on `PATH` in this workspace environment.
- Focused region comparison: blocked because no implementation capture exists.

## Required fidelity surfaces

- Fonts and typography: blocked pending rendered capture.
- Spacing and layout rhythm: blocked pending rendered capture.
- Colors and visual tokens: implemented with existing `ThemeData` and Tidal Blue tokens; visual verification blocked.
- Image quality and asset fidelity: no new raster assets are required for this menu; visual verification blocked.
- Copy and content: menu copy uses “排序与筛选”、“排序方式”、“筛选”、“清除” and only capability-backed choices.

## Comparison history

- No visual comparison iteration was possible. `flutter test` could not run because the `flutter` command is unavailable.

final result: blocked
