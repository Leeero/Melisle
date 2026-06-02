# Melisle Visual Restoration Plan

> Last updated: 2026-06-02
> Status: In Progress
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

- `design.md` now points to this source order.
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

- [x] Update `design.md` so it points to `design/desktop.html` and `design/mobile-ios.html` as the current source of truth.
- [x] Mark `design-system/melisle/` as historical reference.
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

- `design.md` has been rewritten as the current implementation spec for visual restoration.
- Automatic screenshot baseline capture is currently blocked in the local shell: Playwright and Chromium/Chrome CLIs are not available, and the Browser plugin screenshot workflow does not expose a callable runtime in this session.
- Keep screenshot capture tasks open until a browser runtime is available.

### Phase 1: Theme And Layout Tokens

Goal: align global Flutter tokens with the design prototypes.

Primary files:

- `lib/shared/theme/app_tokens.dart`
- `lib/shared/theme/app_theme.dart`
- `lib/presentation/widgets/layout/page_layout.dart`

Tasks:

- [x] Align light and dark color tokens with the design source.
- [x] Align surface, border, accent, music warm, rose, teal, and muted roles.
- [x] Align radius tokens for desktop and mobile usage.
- [x] Align spacing tokens for desktop sidebar, mini player, mobile tab bar, and mobile page padding.
- [x] Ensure buttons, inputs, cards, list tiles, chips, sliders, and dialogs use these tokens.
- [ ] Keep typography system-font based, with display font only for brand-like moments where already appropriate.
- [ ] Remove or reduce obvious token drift caused by historical `design-system/melisle` values.

Validation:

```bash
flutter analyze lib/shared/theme
flutter test test/widget_test.dart
```

Notes:

- First implementation pass completed in `lib/shared/theme/app_tokens.dart`, `lib/shared/theme/app_breakpoints.dart`, and `lib/shared/theme/app_motion.dart`.
- Desktop breakpoint is now `>=1080px`, matching the Open Design layout split.
- Mobile page padding, mobile mini player height, desktop sidebar width, desktop mini player height, and desktop content padding tokens now match the design source.
- Light surface values now match the Open Design source. Existing component themes already consume these shared tokens.
- Typography remains system-font based with `Righteous` reserved for display moments. A later page-level pass should audit overuse of display styles.
- Historical token drift is reduced at the shared-token level. Remaining drift should be handled as pages/components are restored.

### Phase 2: App Shell, Navigation, And Mini Player

Goal: restore the global app frame before restoring individual pages.

Primary files:

- `lib/presentation/widgets/app_shell.dart`
- `lib/presentation/widgets/mini_player_bar.dart`
- `lib/bootstrap/router.dart`

Tasks:

- [x] Desktop: restore `220px` sidebar, grouped nav sections, compact nav rows, and sidebar surface.
- [x] Desktop: restore main content padding and scroll behavior.
- [x] Desktop: restore bottom mini player as a flat `72px` bar with track info, controls, progress, mode, volume, and expand action.
- [x] Mobile: restore floating mini player above the tab bar.
- [x] Mobile: restore bottom 5-tab structure: 首页, 搜索, 媒体库, 收藏, 设置.
- [x] Confirm whether current product routing should expose favorites as a top-level mobile tab.
- [x] Normalize bottom insets so content is never hidden behind mini player or tab bar.
- [x] Preserve mini player tap-to-open-player behavior.

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

- First shell pass completed in `lib/bootstrap/router.dart` and `lib/presentation/widgets/app_shell.dart`.
- Search and favorites are now shell branches so mobile can expose the Open Design 5-tab structure.
- Playlists remain available from the desktop sidebar and under the library branch, preserving current product navigation.
- Downloads remain available from the desktop sidebar under the settings branch.
- Desktop MiniPlayer is now a flat `72px` surface with a top divider, compact `36px` transport controls, a `3px` progress track, and no decorative gradient or shadow.
- Mobile bottom dock now uses the design-source semi-transparent blur layer, and the floating MiniPlayer keeps the design-source rounded surface above the tab bar.
- Mini player tap-to-open-player behavior was preserved.
- Exact visual QA still needs real screenshots once browser/runtime screenshot capture is available.

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

- [x] Restore search fields:
  - [x] Desktop pill search with blur, border, focus ring, clear action.
  - [x] Mobile iOS search field with cancel action.
- [x] Restore section titles and "查看全部" action style.
- [x] Restore album and playlist cards with cover-first layout, hover or press states.
- [x] Restore artist cards as circular covers with centered text.
- [x] Restore desktop track table:
  - [x] Columns: number, title/artist, album, duration, actions.
  - [x] Compact row height.
  - [x] Hover background.
  - [x] Current row accent treatment.
- [x] Restore mobile track item:
  - [x] Border-bottom list language.
  - [x] Press wash.
  - [x] Current row selected wash.
- [x] Restore buttons:
  - [x] Primary pill button.
  - [x] Ghost pill button.
  - [x] Round player control button.
- [x] Restore settings group, settings row, and toggle visuals.
- [x] Restore desktop player popovers.
- [x] Restore mobile player action sheet and option tile visuals.

Validation:

```bash
flutter test test/presentation/widgets/music_track_table_test.dart
flutter test test/presentation/widgets/app_modal_test.dart
flutter analyze
```

Notes:

- First shared-component pass completed in `lib/presentation/widgets/layout/page_layout.dart`, `lib/presentation/widgets/music/music_track_tile.dart`, `lib/presentation/widgets/music/music_track_table.dart`, `lib/presentation/widgets/music/music_album_cards.dart`, `lib/presentation/widgets/music/music_playlist_card.dart`, `lib/presentation/widgets/music/music_artist_card.dart`, `lib/presentation/widgets/controls/app_action_button.dart`, and `lib/presentation/widgets/controls/app_modal.dart`.
- `AppSearchField` now supports desktop pill search with blur, clear action, accent focus ring, and mobile iOS-style cancel behavior.
- Section titles, album/playlist cards, artist cards, desktop track table rows, mobile track items, primary/ghost action buttons, mobile sheets, option tiles, settings grouped rows, toggles, desktop player popovers, and round player controls now share the Open Design visual vocabulary.
- Settings groups now use compact grouped-list surfaces, muted section labels, design-source row density, hover/press wash, and the shared low-saturation switch theme.
- Desktop player sleep timer, quality, and queue surfaces now use the design-source popover language: light blur, `18px` radius, soft border, low shadow, and compact option rows.
- Round player controls now use the Open Design foreground-circle treatment with subdued hover/press feedback and no decorative pulse.
- Screenshot-based visual QA remains open until a browser/runtime screenshot workflow is available.

### Phase 4: Login And Home

Goal: restore the first impression and primary listening entry.

Primary files:

- `lib/presentation/pages/login/login_page.dart`
- `lib/presentation/pages/home/home_page.dart`

Tasks:

- [x] Desktop login:
  - [x] Restore centered connect card.
  - [x] Restore service selector with disc visual.
  - [x] Restore input field spacing and status pill.
  - [x] Preserve login validation and error handling.
- [x] Mobile login:
  - [x] Restore brand hero.
  - [x] Restore service pills.
  - [x] Restore settings-group-like input rows.
  - [x] Preserve login validation and error handling.
- [x] Desktop home:
  - [x] Restore recommendation hero with stacked covers.
  - [x] Restore "继续播放", "最近添加", and "推荐艺术家" sections.
- [x] Mobile home:
  - [x] Restore horizontal recommendation cards.
  - [x] Restore horizontal album and artist scrollers.
- [x] Use real repository data where available.
- [x] Keep empty, loading, and error states clear.

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

- Implemented in `lib/presentation/pages/login/login_page.dart` and `lib/presentation/pages/home/home_page.dart`.
- Login now switches between the desktop centered connect card and the mobile hero/service-pill/settings-group layout while keeping the same `AuthCubit.login` validation, loading, error, and status handling.
- Home now uses real `HomeState` data for the desktop recommendation hero, mobile recommendation cards, "继续播放", "最近添加", and "推荐艺术家". Artist cards are derived only from real album/track `artistId` data; the section is hidden when the backend data cannot support artist navigation.
- Partial section failures remain visible as an inline retry banner, while full loading, empty, and failure states continue to use the shared body state view.
- Screenshot-based visual QA remains open until a browser/runtime screenshot workflow is available.

### Phase 5: Search And Library

Goal: restore core discovery and browsing flows.

Primary files:

- `lib/presentation/pages/search/search_page.dart`
- `lib/presentation/pages/library/library_page.dart`

Tasks:

- [x] Desktop search:
  - [x] Restore pill search field.
  - [x] Restore underline result tabs.
  - [x] Restore track table and result grids.
- [x] Mobile search:
  - [x] Restore search field with cancel action.
  - [x] Restore chips.
  - [x] Restore track list and horizontal result cards.
- [x] Desktop library:
  - [x] Restore tabs and table or grids by scope.
  - [x] Restore play-all toolbar.
- [x] Mobile library:
  - [x] Restore segmented tabs.
  - [x] Restore song list, album grid, and artist grid.
- [x] Confirm favorite scope placement against the new mobile top-level 收藏 tab.
- [x] Preserve search debouncing, submission, recent searches, and navigation.

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

- Implemented in `lib/presentation/pages/search/search_page.dart`, `lib/presentation/pages/library/library_page.dart`, and the shared `AppSearchField` in `lib/presentation/widgets/layout/page_layout.dart`.
- Search now defaults to the design's `全部` scope, with desktop underline tabs, desktop track table plus album/artist/playlist grids, mobile cancel-capable search field, chips, track list, and horizontal result cards.
- Library now exposes only the design's `歌曲 / 专辑 / 艺术家` scopes in-page. 收藏 remains available through the top-level 收藏 route/tab and the existing hidden compatibility branch is preserved for old state paths.
- Library headers and sections use only real Cubit data. Full album/artist totals are shown only after those scopes have loaded; no prototype counts or artwork were introduced.
- Compact `AppSearchField` now uses a 46px field/suffix slot so the clear and cancel actions meet the 44px touch target requirement.
- Validation completed:
  - `flutter test test/presentation/pages/search/search_page_test.dart`
  - `flutter test test/presentation/blocs/search/search_cubit_test.dart`
  - `flutter analyze lib/presentation/widgets/layout/page_layout.dart lib/presentation/pages/search/search_page.dart lib/presentation/pages/library/library_page.dart`
  - `flutter test test/presentation/pages/global_ui_smoke_test.dart test/widget_test.dart`

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

- [x] Desktop album detail:
  - [x] Restore left cover, right metadata, action row, track table.
- [x] Desktop artist detail:
  - [x] Restore round artist image, metadata, action row, popular tracks, albums.
- [x] Desktop playlist list and detail:
  - [x] Restore card grid.
  - [x] Restore detail hero and track table.
- [x] Mobile detail pages:
  - [x] Restore back nav.
  - [x] Restore centered cover or avatar.
  - [x] Restore action buttons.
  - [x] Restore mobile track list.
- [x] Favorites:
  - [x] Restore mobile top-level favorite page.
  - [x] Preserve favorite toggling and removal behavior.
- [x] History:
  - [x] Match the same mobile track list and desktop table vocabulary.
- [x] Keep large playlist pagination and loading feedback.

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

- Implemented in `lib/presentation/widgets/layout/page_layout.dart`, `lib/presentation/pages/album/album_detail_page.dart`, `lib/presentation/pages/artist/artist_detail_page.dart`, `lib/presentation/pages/playlists/playlists_page.dart`, `lib/presentation/pages/playlists/playlist_detail_page.dart`, `lib/presentation/pages/favorites/favorites_page.dart`, and `lib/presentation/pages/history/history_page.dart`.
- Detail pages now use the Open Design object-page structure: desktop left cover or avatar with right metadata/actions and desktop track table; mobile explicit `返回` nav, centered cover/avatar, centered metadata/actions, and mobile track rows.
- Playlist list now uses the cover-first card grid vocabulary while preserving search, pagination, and navigation to playlist detail.
- Favorites is treated as the mobile top-level 收藏 surface: no extra back button, real count summary, play-all action, mobile track rows, and existing favorite removal behavior.
- History now uses the same desktop table and mobile row vocabulary as the restored track surfaces.
- Prototype-only album favorite, artist follow, playlist download, and more actions were not introduced as non-functional buttons. Existing production actions remain: play all, individual play, track long-press actions, favorite toggling/removal where supported, and playlist pagination.
- Validation completed:
  - `flutter analyze lib/presentation/widgets/layout/page_layout.dart lib/presentation/pages/album/album_detail_page.dart lib/presentation/pages/artist/artist_detail_page.dart lib/presentation/pages/playlists/playlists_page.dart lib/presentation/pages/playlists/playlist_detail_page.dart lib/presentation/pages/favorites/favorites_page.dart lib/presentation/pages/history/history_page.dart test/widget_test.dart`
  - `flutter test test/presentation/blocs/playlist_detail_cubit_test.dart test/widget_test.dart test/presentation/pages/global_ui_smoke_test.dart`

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

- [x] Desktop player:
  - [x] Restore fullscreen overlay layout.
  - [x] Restore three-column body: cover/track info, lyrics, queue.
  - [x] Restore bottom progress and playback controls.
  - [x] Restore desktop player popovers for volume, settings, and more actions.
- [x] Mobile player:
  - [x] Restore fullscreen player overlay layout.
  - [x] Restore large cover, track info, lyric scroll, progress, controls, and extras.
  - [x] Preserve explicit lyrics or artwork mode if production UX still needs it.
- [x] Lyrics:
  - [x] Restore current-line scale, color, mask fade, and scrolling feel.
  - [x] Preserve seek, lyric sync offset, loading, no-lyrics, and error states.
- [x] Queue:
  - [x] Desktop: right slide-in queue panel.
  - [x] Mobile: bottom queue sheet with handle and "完成" action.
- [x] Playback sheets:
  - [x] Mobile action sheet for more, settings, and volume.
  - [x] Preserve quality, sleep timer, download, favorite, and queue actions.

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

- Implemented in `lib/presentation/pages/player/player_page.dart`, `lib/presentation/widgets/lyric_view.dart`, `lib/presentation/widgets/queue_sheet.dart`, `lib/presentation/widgets/quality_picker_sheet.dart`, and `lib/presentation/widgets/sleep_timer_sheet.dart`.
- Desktop player now matches the Open Design immersive structure: fullscreen playback page, cover and metadata column, centered lyric column, "接下来" queue preview, bottom progress, transport controls, extras, desktop volume, quality, sleep timer, more actions, and a right slide-in full queue panel.
- Mobile player now follows the Open Design fullscreen sequence: top bar, large rounded artwork, centered track info, lyric scroll, progress, transport controls, favorite, volume, and settings extras. The former segmented artwork or lyrics switch was intentionally removed because the design source uses a single continuous playback surface.
- Lyrics keep real sync behavior and seeking through `LyricView`, while restoring stronger current-line emphasis, fade spacing, and scrolling feel.
- Queue behavior still uses the real `PlayerCubit` queue: play by index, remove, clear, and drag reorder. Mobile keeps the bottom sheet handle and "完成" action.
- Playback sheets preserve real quality, sleep timer, download, favorite, volume, and queue actions. Prototype-only or fake share actions were not introduced.
- Validation completed:
  - `/Users/lero/flutter-sdk/bin/flutter test test/presentation/widgets/lyric_view_test.dart test/domain/entities/lyric_sync_engine_test.dart test/domain/entities/play_queue_test.dart test/presentation/pages/global_ui_smoke_test.dart`
  - `/Users/lero/flutter-sdk/bin/flutter analyze lib/presentation/pages/player/player_page.dart lib/presentation/widgets/lyric_view.dart lib/presentation/widgets/queue_sheet.dart lib/presentation/widgets/quality_picker_sheet.dart lib/presentation/widgets/sleep_timer_sheet.dart lib/presentation/widgets/track_actions_sheet.dart`
  - `git diff --check`

### Phase 8: Settings And Downloads

Goal: restore utility pages with grouped Apple-like settings language.

Primary files:

- `lib/presentation/pages/settings/settings_page.dart`
- `lib/presentation/pages/downloads/downloads_page.dart`

Tasks:

- [x] Settings:
  - [x] Restore grouped sections: 服务器, 播放, 外观, 下载, 关于.
  - [x] Restore rows with title, description, trailing value, chevron, or toggle.
  - [x] Preserve current richer settings that do not exist in the prototype.
  - [x] Preserve custom artwork and lyrics source configuration.
  - [x] Add confirmation for logout if not already present.
- [x] Downloads:
  - [x] Restore storage summary group.
  - [x] Restore downloaded track table/list style.
  - [x] Preserve pending downloads, completed downloads, cancel, remove, and reload behavior.
  - [x] Keep destructive delete confirmation.

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

- Implemented in `lib/presentation/pages/settings/settings_page.dart`, `lib/presentation/pages/downloads/downloads_page.dart`, and `test/presentation/pages/global_ui_smoke_test.dart`.
- Settings now follows the Open Design grouped-list order: 服务器, 播放, 外观, 下载, 关于. Rows use title, description, trailing value, chevron, or existing action behavior.
- Server rows are backed by the real `AuthCubit` session: server URL, backend API type, account name, and logout confirmation.
- Playback keeps the real default quality and track-gap settings. Prototype-only gapless and volume-normalization toggles were not added because no persisted production setting exists for them.
- Appearance keeps theme selection and preserves the richer custom artwork and lyrics source configuration, including enable toggles, URL fields, tests, and status banners.
- Downloads settings preserve the existing downloads route and cache cleanup confirmation. Wi-Fi-only download was not added because the current app has no persisted setting for it.
- Downloads page now always shows a storage summary group based on real downloads and pending jobs, then renders pending jobs, a desktop downloaded-track table, or a mobile downloaded-track list. Cancel, remove, reload, and destructive delete confirmation are preserved.
- Validation completed:
  - `/Users/lero/flutter-sdk/bin/flutter test test/presentation/pages/global_ui_smoke_test.dart`
  - `/Users/lero/flutter-sdk/bin/flutter analyze lib/presentation/pages/settings/settings_page.dart lib/presentation/pages/downloads/downloads_page.dart test/presentation/pages/global_ui_smoke_test.dart`
  - `git diff --check`

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
- [x] Document intentional differences.

Final validation:

```bash
flutter test
flutter analyze
```

Notes:

- Full automated validation completed:
  - `/Users/lero/flutter-sdk/bin/flutter test`
  - `/Users/lero/flutter-sdk/bin/flutter analyze`
  - `git diff --check`
- Screenshot comparison remains open. Browser automation tools are not callable in this session, and `chromium`, `google-chrome`, and `playwright` CLIs are unavailable. `/Applications/Google Chrome.app` exists, but Phase 9 still needs a seeded Flutter screenshot harness or manual browser/app capture to compare authenticated pages against `design/desktop.html` and `design/mobile-ios.html`.
- Manual visual QA tasks remain unchecked: light/dark themes, long text, text scale, missing artwork, failed artwork load, empty/loading/failure/pagination states, and interactive states.
- No production UI should introduce prototype-only controls just to match static screenshots. Intentional differences are recorded below.

## 6. Iteration Log

| Date | Phase | Summary | Validation | Remaining Risk |
|---|---|---|---|---|
| 2026-06-01 | Planning | Created this restoration tracker from `design/` source files. | Not run, documentation only. | Resolved by Phase 0 source alignment. |
| 2026-06-01 | Phase 0 | Started restoration execution. Aligned `design.md` to the current Open Design sources and marked historical design-system references. | `flutter analyze lib/shared/theme lib/presentation` passed. | Screenshot baseline automation is blocked by missing browser runtime. |
| 2026-06-01 | Phase 1 | Aligned shared visual tokens, breakpoint, motion durations, surface values, radii, and spacing with the Open Design source. | `flutter analyze lib/shared/theme lib/presentation` passed; `flutter test test/widget_test.dart test/presentation/pages/global_ui_smoke_test.dart` passed. | Page-level components still need detailed visual restoration. |
| 2026-06-01 | Phase 2 | Continued shell restoration. Flattened desktop MiniPlayer, added mobile dock blur, restored mobile 5-tab navigation, and synced desktop sidebar paths. | `flutter analyze lib/presentation/widgets/app_shell.dart lib/presentation/widgets/mini_player_bar.dart lib/bootstrap/router.dart` passed; `flutter test test/presentation/pages/global_ui_smoke_test.dart test/widget_test.dart` passed. | Screenshot-based visual QA is still blocked by missing browser runtime. |
| 2026-06-01 | Phase 3 | Completed shared component vocabulary restoration: search fields, section titles, album/playlist/artist cards, desktop track table, mobile track items, action buttons, settings grouped rows/toggles, mobile sheets, desktop player popovers, and round player controls. | `flutter test test/presentation/widgets/music_track_table_test.dart test/presentation/widgets/app_modal_test.dart` passed; `flutter test test/presentation/pages/global_ui_smoke_test.dart test/widget_test.dart` passed; `flutter analyze lib/shared/theme lib/presentation` passed. | Screenshot-based visual QA remains blocked by missing browser/runtime screenshot workflow. |

## 7. Intentional Difference Log

Record any deviation from the prototype here. Each entry must explain why the Flutter app should differ.

| Surface | Difference | Reason | Approved |
|---|---|---|---|
| Mobile prototype frame | Do not render iPhone frame, Dynamic Island, or fake status bar in production app. | These are prototype presentation chrome, not app UI. | Yes |
| Settings | Do not add prototype-only Wi-Fi-only download, gapless playback, or volume-normalization toggles until persisted production settings exist. | Avoid fake controls and parallel sources of truth. Current real settings are theme, default quality, track gap, custom artwork source, and custom lyrics source. | Yes |
| Downloads | The storage group summarizes real downloaded rows and pending jobs instead of using prototype counts, storage paths, or file sizes. | Production must reflect actual local download state and not design-sample values. | Yes |

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
