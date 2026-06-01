# Melisle Visual Restoration Plan

> Last updated: 2026-06-01
> Status: Planned
> Scope: Restore the Flutter UI to the current Open Design sources in `design/` while preserving all existing product functions.

## 1. Purpose

This file is the single progress tracker for the visual restoration work.

The restoration target is to match the current Open Design prototypes as closely as the production Flutter app allows, without hardcoding prototype demo data or breaking existing login, browsing, playback, queue, lyrics, favorite, download, settings, and routing behavior.

## 2. Source Of Truth

Use these files as the visual source of truth, in this order:

1. `design/desktop.html`
   - Desktop layout and interactions.
   - Sidebar, main content, desktop mini player, immersive player overlay, desktop queue panel, search, library, detail pages, settings, and downloads.
2. `design/mobile-ios.html`
   - Mobile iOS layout and interactions.
   - Mobile login, bottom tabs, floating mini player, fullscreen player, bottom sheets, library, search, favorites, detail pages, and settings.
3. `design/index.html`
   - Design entry page and high-level design system reference.
4. `design/assets/artwork/`
   - Prototype-only visual assets for screenshots and comparison.
   - Do not replace real app media data with these assets.

Historical references:

- `design.md` should be updated to point to this source order.
- `design-system/melisle/` is historical reference only unless a task explicitly asks to use it.

## 3. Non-Negotiable Rules

- Preserve Clean Architecture boundaries.
- Focus changes in `lib/presentation/` and `lib/shared/theme/`.
- Do not change `MusicRepository` semantics for visual work.
- Do not hardcode prototype sample songs, albums, artists, or playlists into production logic.
- Keep all user-facing text in Simplified Chinese.
- Keep real playback, search, favorites, downloads, lyrics, and settings working after every phase.
- Run relevant tests first, then `flutter analyze`, then a small manual smoke test.
- Record any intentional difference from the prototype in the phase notes.

## 4. Core Design Mapping

### 4.1 Color Tokens

The current `design/desktop.html` OKLCH tokens convert to these practical Flutter color values:

| Role | Light | Dark |
|---|---:|---:|
| Background | `#F7FCFC` | `#0C1315` |
| Surface | `#FFFFFF` | `#141C1E` |
| Surface Raised | `#FAFEFE` | `#1B2325` |
| Sidebar Surface | `#F1F9F8` | `#101719` |
| Foreground | `#070F11` | `#E3E9E9` |
| Foreground Secondary | `#444F52` | `#96A1A1` |
| Muted | `#6E7A7B` | `#697475` |
| Border | `#D8DEDD` | `#2B3233` |
| Border Light | `#E8ECEC` | `#222829` |
| Accent | `#1A9480` | `#46B49E` |
| Accent Hover | `#00856F` | `#41C7AE` |
| Accent Soft | `#D4F1E9` | `#062D26` |
| Music Warm | `#D6A771` | `#CEA26F` |
| Music Warm Soft | `#FDEDDC` | `#312313` |
| Music Rose | `#DC937C` | `#D6917B` |
| Music Rose Soft | `#FFE8E0` | `#362019` |
| Music Teal | `#45A592` | `#5FB7A5` |
| Music Teal Soft | `#D9F4ED` | `#122C26` |
| Music Ink | `#20373B` | `#BECECF` |

### 4.2 Size Tokens

| Token | Desktop | Mobile |
|---|---:|---:|
| Sidebar width | `220` | Not used |
| Desktop mini player height | `72` | Not used |
| Mobile page horizontal padding | Not used | `24` |
| Mobile mini player height | Not used | `58-60` |
| Mobile tab content height | Not used | `54` |
| Mobile safe bottom | Platform safe area | Platform safe area |

### 4.3 Radius Tokens

| Design Token | Value | Flutter Use |
|---|---:|---|
| `radius-sm` | `6` desktop, `8` mobile | Sidebar nav, compact rows, cover thumbnails |
| `radius-md` | `10` desktop, `12` mobile | Search fields, small surfaces |
| `radius-lg` | `14` desktop, `16` mobile | Album cards, normal cards |
| `radius-xl` | `20` desktop, `24` mobile | Hero cards, sheets, large covers |
| `radius-full` | `9999` | Pills, primary buttons, round controls |

### 4.4 Motion

| Motion | Duration | Curve |
|---|---:|---|
| Tap / hover feedback | `150ms` | ease out |
| Normal transitions | `250ms` | ease out |
| Screen entrance | `300-320ms` | cubic `0.2, 0, 0.13, 1` |
| Player overlay | `380-420ms` | cubic `0.2, 0, 0.13, 1` |
| Sheet entrance | `240ms` | cubic `0.2, 0, 0.13, 1` |

## 5. Phase Plan

### Phase 0: Documentation And Baseline

Goal: make the design source explicit and capture comparison evidence before changing UI code.

Tasks:

- [ ] Update `design.md` so it points to `design/desktop.html` and `design/mobile-ios.html` as the current source of truth.
- [ ] Mark `design-system/melisle/` as historical reference.
- [ ] Capture prototype screenshots:
  - [ ] Desktop login
  - [ ] Desktop home
  - [ ] Desktop search
  - [ ] Desktop library
  - [ ] Desktop favorites
  - [ ] Desktop playlists
  - [ ] Desktop playlist detail
  - [ ] Desktop album detail
  - [ ] Desktop artist detail
  - [ ] Desktop downloads
  - [ ] Desktop settings
  - [ ] Desktop now playing
  - [ ] Desktop queue panel
  - [ ] Mobile login
  - [ ] Mobile home
  - [ ] Mobile search
  - [ ] Mobile library
  - [ ] Mobile favorites
  - [ ] Mobile playlist detail
  - [ ] Mobile album detail
  - [ ] Mobile artist detail
  - [ ] Mobile settings
  - [ ] Mobile now playing
  - [ ] Mobile queue sheet
  - [ ] Mobile player action sheet
- [ ] Capture current Flutter screenshots for the same surfaces where implemented.
- [ ] Add screenshot paths or comparison notes below.

Validation:

```bash
flutter analyze lib/shared/theme lib/presentation
```

Notes:

- Pending.

### Phase 1: Theme And Layout Tokens

Goal: align global Flutter tokens with the design prototypes.

Primary files:

- `lib/shared/theme/app_tokens.dart`
- `lib/shared/theme/app_theme.dart`
- `lib/presentation/widgets/layout/page_layout.dart`

Tasks:

- [ ] Align light and dark color tokens with the design source.
- [ ] Align surface, border, accent, music warm, rose, teal, and muted roles.
- [ ] Align radius tokens for desktop and mobile usage.
- [ ] Align spacing tokens for desktop sidebar, mini player, mobile tab bar, and mobile page padding.
- [ ] Ensure buttons, inputs, cards, list tiles, chips, sliders, and dialogs use these tokens.
- [ ] Keep typography system-font based, with display font only for brand-like moments where already appropriate.
- [ ] Remove or reduce obvious token drift caused by historical `design-system/melisle` values.

Validation:

```bash
flutter analyze lib/shared/theme
flutter test test/widget_test.dart
```

Notes:

- Pending.

### Phase 2: App Shell, Navigation, And Mini Player

Goal: restore the global app frame before restoring individual pages.

Primary files:

- `lib/presentation/widgets/app_shell.dart`
- `lib/presentation/widgets/mini_player_bar.dart`
- `lib/bootstrap/router.dart`

Tasks:

- [ ] Desktop: restore `220px` sidebar, grouped nav sections, compact nav rows, and sidebar surface.
- [ ] Desktop: restore main content padding and scroll behavior.
- [ ] Desktop: restore bottom mini player as a flat `72px` bar with track info, controls, progress, mode, volume, and expand action.
- [ ] Mobile: restore floating mini player above the tab bar.
- [ ] Mobile: restore bottom 5-tab structure: 首页, 搜索, 媒体库, 收藏, 设置.
- [ ] Confirm whether current product routing should expose favorites as a top-level mobile tab.
- [ ] Normalize bottom insets so content is never hidden behind mini player or tab bar.
- [ ] Preserve mini player tap-to-open-player behavior.

Validation:

```bash
flutter test test/presentation/pages/global_ui_smoke_test.dart
flutter analyze lib/presentation/widgets/app_shell.dart lib/presentation/widgets/mini_player_bar.dart lib/bootstrap/router.dart
```

Manual smoke:

- [ ] Switch every shell tab.
- [ ] Open player from mini player.
- [ ] Verify layout with and without current track.
- [ ] Verify mobile safe area behavior.

Notes:

- Pending.

### Phase 3: Shared Component Vocabulary

Goal: create the visual language once and reuse it across pages.

Primary component groups:

- Search field
- Section title
- Album / playlist cards
- Artist round cards
- Desktop track table rows
- Mobile track items
- Primary and ghost buttons
- Settings group, row, toggle
- Queue panel and mobile sheets
- Player popovers

Tasks:

- [ ] Restore search fields:
  - [ ] Desktop pill search with blur, border, focus ring, clear action.
  - [ ] Mobile iOS search field with cancel action.
- [ ] Restore section titles and "查看全部" action style.
- [ ] Restore album and playlist cards with cover-first layout, hover or press states.
- [ ] Restore artist cards as circular covers with centered text.
- [ ] Restore desktop track table:
  - [ ] Columns: number, title/artist, album, duration, actions.
  - [ ] Compact row height.
  - [ ] Hover background.
  - [ ] Current row accent treatment.
- [ ] Restore mobile track item:
  - [ ] Border-bottom list language.
  - [ ] Press wash.
  - [ ] Current row selected wash.
- [ ] Restore buttons:
  - [ ] Primary pill button.
  - [ ] Ghost pill button.
  - [ ] Round player control button.
- [ ] Restore settings group, settings row, and toggle visuals.
- [ ] Restore desktop player popovers.
- [ ] Restore mobile player action sheet and option tile visuals.

Validation:

```bash
flutter test test/presentation/widgets/music_track_table_test.dart
flutter test test/presentation/widgets/app_modal_test.dart
flutter analyze
```

Notes:

- Pending.

### Phase 4: Login And Home

Goal: restore the first impression and primary listening entry.

Primary files:

- `lib/presentation/pages/login/login_page.dart`
- `lib/presentation/pages/home/home_page.dart`

Tasks:

- [ ] Desktop login:
  - [ ] Restore centered connect card.
  - [ ] Restore service selector with disc visual.
  - [ ] Restore input field spacing and status pill.
  - [ ] Preserve login validation and error handling.
- [ ] Mobile login:
  - [ ] Restore brand hero.
  - [ ] Restore service pills.
  - [ ] Restore settings-group-like input rows.
  - [ ] Preserve login validation and error handling.
- [ ] Desktop home:
  - [ ] Restore recommendation hero with stacked covers.
  - [ ] Restore "继续播放", "最近添加", and "推荐艺术家" sections.
- [ ] Mobile home:
  - [ ] Restore horizontal recommendation cards.
  - [ ] Restore horizontal album and artist scrollers.
- [ ] Use real repository data where available.
- [ ] Keep empty, loading, and error states clear.

Validation:

```bash
flutter test test/presentation/blocs/home_cubit_test.dart
flutter analyze lib/presentation/pages/login/login_page.dart lib/presentation/pages/home/home_page.dart
```

Manual smoke:

- [ ] Login loading, success, and failure.
- [ ] Home loading and empty states.
- [ ] Play recommendation or first available track.
- [ ] Open album and artist details from cards.

Notes:

- Pending.

### Phase 5: Search And Library

Goal: restore core discovery and browsing flows.

Primary files:

- `lib/presentation/pages/search/search_page.dart`
- `lib/presentation/pages/library/library_page.dart`

Tasks:

- [ ] Desktop search:
  - [ ] Restore pill search field.
  - [ ] Restore underline result tabs.
  - [ ] Restore track table and result grids.
- [ ] Mobile search:
  - [ ] Restore search field with cancel action.
  - [ ] Restore chips.
  - [ ] Restore track list and horizontal result cards.
- [ ] Desktop library:
  - [ ] Restore tabs and table or grids by scope.
  - [ ] Restore play-all toolbar.
- [ ] Mobile library:
  - [ ] Restore segmented tabs.
  - [ ] Restore song list, album grid, and artist grid.
- [ ] Confirm favorite scope placement against the new mobile top-level 收藏 tab.
- [ ] Preserve search debouncing, submission, recent searches, and navigation.

Validation:

```bash
flutter test test/presentation/pages/search/search_page_test.dart
flutter test test/presentation/blocs/search/search_cubit_test.dart
flutter analyze lib/presentation/pages/search/search_page.dart lib/presentation/pages/library/library_page.dart
```

Manual smoke:

- [ ] Submit search.
- [ ] Clear search.
- [ ] Open track, album, artist, and playlist result.
- [ ] Switch library tabs.
- [ ] Play all songs from library.

Notes:

- Pending.

### Phase 6: Details, Favorites, History, And Playlists

Goal: restore object pages and saved collection surfaces.

Primary files:

- `lib/presentation/pages/album/album_detail_page.dart`
- `lib/presentation/pages/artist/artist_detail_page.dart`
- `lib/presentation/pages/playlists/playlists_page.dart`
- `lib/presentation/pages/playlists/playlist_detail_page.dart`
- `lib/presentation/pages/favorites/favorites_page.dart`
- `lib/presentation/pages/history/history_page.dart`

Tasks:

- [ ] Desktop album detail:
  - [ ] Restore left cover, right metadata, action row, track table.
- [ ] Desktop artist detail:
  - [ ] Restore round artist image, metadata, action row, popular tracks, albums.
- [ ] Desktop playlist list and detail:
  - [ ] Restore card grid.
  - [ ] Restore detail hero and track table.
- [ ] Mobile detail pages:
  - [ ] Restore back nav.
  - [ ] Restore centered cover or avatar.
  - [ ] Restore action buttons.
  - [ ] Restore mobile track list.
- [ ] Favorites:
  - [ ] Restore mobile top-level favorite page.
  - [ ] Preserve favorite toggling and removal behavior.
- [ ] History:
  - [ ] Match the same mobile track list and desktop table vocabulary.
- [ ] Keep large playlist pagination and loading feedback.

Validation:

```bash
flutter test test/presentation/blocs/playlist_detail_cubit_test.dart
flutter analyze lib/presentation/pages/album lib/presentation/pages/artist lib/presentation/pages/playlists lib/presentation/pages/favorites lib/presentation/pages/history
```

Manual smoke:

- [ ] Open album, artist, playlist detail.
- [ ] Play all from details.
- [ ] Play an individual track.
- [ ] Toggle favorites.
- [ ] Load more playlist tracks.
- [ ] Navigate back on desktop and mobile.

Notes:

- Pending.

### Phase 7: Player, Lyrics, Queue, And Playback Sheets

Goal: restore the core immersive playback experience.

Primary files:

- `lib/presentation/pages/player/player_page.dart`
- `lib/presentation/widgets/lyric_view.dart`
- `lib/presentation/widgets/queue_sheet.dart`
- `lib/presentation/widgets/quality_picker_sheet.dart`
- `lib/presentation/widgets/sleep_timer_sheet.dart`
- `lib/presentation/widgets/track_actions_sheet.dart`

Tasks:

- [ ] Desktop player:
  - [ ] Restore fullscreen overlay layout.
  - [ ] Restore three-column body: cover/track info, lyrics, queue.
  - [ ] Restore bottom progress and playback controls.
  - [ ] Restore desktop player popovers for volume, settings, and more actions.
- [ ] Mobile player:
  - [ ] Restore fullscreen player overlay layout.
  - [ ] Restore large cover, track info, lyric scroll, progress, controls, and extras.
  - [ ] Preserve explicit lyrics or artwork mode if production UX still needs it.
- [ ] Lyrics:
  - [ ] Restore current-line scale, color, mask fade, and scrolling feel.
  - [ ] Preserve seek, lyric sync offset, loading, no-lyrics, and error states.
- [ ] Queue:
  - [ ] Desktop: right slide-in queue panel.
  - [ ] Mobile: bottom queue sheet with handle and "完成" action.
- [ ] Playback sheets:
  - [ ] Mobile action sheet for more, settings, and volume.
  - [ ] Preserve quality, sleep timer, download, favorite, and queue actions.

Validation:

```bash
flutter test test/presentation/widgets/lyric_view_test.dart
flutter test test/domain/entities/lyric_sync_engine_test.dart
flutter test test/domain/entities/play_queue_test.dart
flutter analyze lib/presentation/pages/player lib/presentation/widgets/lyric_view.dart lib/presentation/widgets/queue_sheet.dart
```

Manual smoke:

- [ ] Play and pause.
- [ ] Previous and next.
- [ ] Drag progress.
- [ ] Seek via lyrics where supported.
- [ ] Open and close queue.
- [ ] Reorder queue if supported.
- [ ] Switch quality.
- [ ] Set and cancel sleep timer.
- [ ] Toggle favorite.
- [ ] Download current track.
- [ ] Confirm player works with missing artwork and missing lyrics.

Notes:

- Pending.

### Phase 8: Settings And Downloads

Goal: restore utility pages with grouped Apple-like settings language.

Primary files:

- `lib/presentation/pages/settings/settings_page.dart`
- `lib/presentation/pages/downloads/downloads_page.dart`

Tasks:

- [ ] Settings:
  - [ ] Restore grouped sections: 服务器, 播放, 外观, 下载, 关于.
  - [ ] Restore rows with title, description, trailing value, chevron, or toggle.
  - [ ] Preserve current richer settings that do not exist in the prototype.
  - [ ] Preserve custom artwork and lyrics source configuration.
  - [ ] Add confirmation for logout if not already present.
- [ ] Downloads:
  - [ ] Restore storage summary group.
  - [ ] Restore downloaded track table/list style.
  - [ ] Preserve pending downloads, completed downloads, cancel, remove, and reload behavior.
  - [ ] Keep destructive delete confirmation.

Validation:

```bash
flutter test test/presentation/pages/global_ui_smoke_test.dart
flutter analyze lib/presentation/pages/settings/settings_page.dart lib/presentation/pages/downloads/downloads_page.dart
```

Manual smoke:

- [ ] Change theme mode.
- [ ] Change default quality.
- [ ] Change gap between tracks.
- [ ] Test custom artwork source.
- [ ] Test custom lyrics source.
- [ ] Open downloads page.
- [ ] Cancel a pending download if available.
- [ ] Remove a downloaded track with confirmation.
- [ ] Logout flow.

Notes:

- Pending.

### Phase 9: Final Visual QA

Goal: close the remaining gap between the Flutter implementation and the design prototypes.

Tasks:

- [ ] Compare desktop screenshots against `design/desktop.html`:
  - [ ] Login
  - [ ] Home
  - [ ] Search
  - [ ] Library
  - [ ] Favorites
  - [ ] Playlists
  - [ ] Playlist detail
  - [ ] Album detail
  - [ ] Artist detail
  - [ ] Downloads
  - [ ] Settings
  - [ ] Now playing
  - [ ] Queue panel
- [ ] Compare mobile screenshots against `design/mobile-ios.html`:
  - [ ] Login
  - [ ] Home
  - [ ] Search
  - [ ] Library
  - [ ] Favorites
  - [ ] Playlist detail
  - [ ] Album detail
  - [ ] Artist detail
  - [ ] Settings
  - [ ] Now playing
  - [ ] Queue sheet
  - [ ] Player action sheet
- [ ] Test light and dark themes.
- [ ] Test long Chinese titles, long artist names, long album names.
- [ ] Test text scale from `1.0` to `1.3`.
- [ ] Test missing artwork and failed artwork load.
- [ ] Test empty, loading, failure, and pagination states.
- [ ] Check hover, focus, pressed, selected, disabled, and loading states.
- [ ] Remove obsolete one-off styling where shared components now cover the design.
- [ ] Document intentional differences.

Final validation:

```bash
flutter test
flutter analyze
```

Notes:

- Pending.

## 6. Iteration Log

| Date | Phase | Summary | Validation | Remaining Risk |
|---|---|---|---|---|
| 2026-06-01 | Planning | Created this restoration tracker from `design/` source files. | Not run, documentation only. | `design.md` still needs source alignment. |

## 7. Intentional Difference Log

Record any deviation from the prototype here. Each entry must explain why the Flutter app should differ.

| Surface | Difference | Reason | Approved |
|---|---|---|---|
| Mobile prototype frame | Do not render iPhone frame, Dynamic Island, or fake status bar in production app. | These are prototype presentation chrome, not app UI. | Yes |

## 8. Useful Commands

Run focused tests as each phase changes:

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

Run full validation before considering the restoration complete:

```bash
flutter test
flutter analyze
```

