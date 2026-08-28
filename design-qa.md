# Settings Page Design QA

## Comparison Target

- Mobile source visual truth: `/Users/lero/.codex/generated_images/01a04122-f574-7500-afce-5dd24af5daae/exec-70a326c4-de4a-463d-a90f-195d1078cbdd.png`
- Desktop source visual truth: `/Users/lero/.codex/generated_images/01a04122-f574-7500-afce-5dd24af5daae/exec-605cb9ab-f922-4050-a8cc-9444bde54529.png`, overridden by the user's explicit request to replace its two-column content layout with a single column.
- Mobile implementation screenshot: `/Users/lero/Documents/MyData/Code/melisle/design-reference/screenshots/actual/settings-390x844-dark-scale-1.0.png`
- Desktop implementation screenshot: `/Users/lero/Documents/MyData/Code/melisle/design-reference/screenshots/actual/settings-1440x1024-dark-scale-1.0.png`
- Desktop preference-menu screenshot: `/Users/lero/Documents/MyData/Code/melisle/design-reference/screenshots/actual/settings-desktop-quality-menu-dark.png`
- Mobile combined evidence: `/Users/lero/Documents/MyData/Code/melisle/design-reference/screenshots/diff/settings-mobile-source-vs-actual.png`
- Desktop combined evidence: `/Users/lero/Documents/MyData/Code/melisle/design-reference/screenshots/diff/settings-desktop-content-source-vs-actual.png`

## Normalization

- Mobile source: 853 x 1844 px, normalized to 390 x 844 px.
- Mobile implementation: 390 x 844 CSS px at DPR 1.0.
- Desktop source: 1487 x 1058 px, normalized to 1440 x 1024 px. The 236 px shell sidebar was cropped so the comparison covers the app-owned settings content.
- Desktop implementation: 1440 x 1024 CSS px at DPR 1.0. The page was rendered standalone by the widget harness; the production shell continues to own the sidebar and bottom player.
- State: authenticated Emby session, dark theme, default quality `auto`, zero track gap, custom media sources disabled, menu-bar lyrics enabled on desktop.

## Full-view Comparison Evidence

- Mobile keeps the selected single-column treatment while following the revised order: current server, common preferences, media and devices, storage, then about; logout remains a separate danger action.
- Desktop intentionally replaces the reference's two-column content area with one 820 px left-aligned column. The section order is current server, common preferences, media and devices, storage, then about; grouped rows and restrained outlines remain aligned with the source.
- Responsive tests cover 375 x 812, 390 x 844, 768 x 900, 1080 x 900, 1440 x 900, and 1440 x 1024 in light/dark themes at 1.0 and 1.3 text scale.

## Required Fidelity Surfaces

- Fonts and typography: production continues to use the shared platform-font theme and existing type scale. The Flutter screenshot runner cannot resolve Chinese system glyphs, so its PNGs show tofu boxes; widget-tree copy assertions and 1.0/1.3 text-scale layout tests verify content, wrapping constraints, and hierarchy. This is a screenshot-harness limitation, not a production font change.
- Spacing and layout rhythm: mobile and desktop margins, section gaps, the 820 px desktop content measure, grouped row heights, icon spacing, radii, and dividers match the selected direction with no overflow.
- Colors and visual tokens: implementation uses the existing Melisle theme tokens for ink surfaces, mint primary, muted text, outlines, success, and danger. No page-private palette was added.
- Image quality and asset fidelity: the target contains no raster content required by the settings page. Existing Material icons are used consistently; no placeholder or handcrafted image assets were introduced.
- Copy and content: all visible rows map to implemented capabilities. No subscription, equalizer, cache-size estimate, download-path editor, account editor, or other fake entry was added.

## Focused Region Comparison

- Common preferences: three rows, mint icon emphasis, current values, chevrons, separators, and the same neutral surface as other groups were checked in both mobile and desktop captures.
- Desktop preference interaction: each row opens a compact 280 px anchored menu below its current-value area, with icons and a mint selected check. The menu remains visually attached to the invoking row and avoids mobile-style full-width sheet motion.
- Server/account: user, server URL, backend type, connected status, and logout were checked against the authenticated source state.
- Secondary settings: custom lyrics/artwork, desktop menu-bar lyrics, downloads, cache clearing, about, and version placement were checked independently.

## Findings

- No actionable P0, P1, or P2 visual differences remain.
- P3: the standalone Flutter screenshot harness does not render Chinese system glyphs. Production uses the unchanged platform font stack; a future golden harness can bundle a test-only CJK font for more readable PNG evidence.

## Comparison History

1. Pre-comparison responsive validation found a P2 mobile header overflow caused by a 420 px title constraint. It was reduced to 300 px, then re-rendered at 390 x 844 with no overflow.
2. Post-fix mobile and desktop combined comparisons found no remaining P0/P1/P2 issues.
3. The desktop layout was changed from a 6:5 two-column grid to one 820 px column per user feedback. The 1440 x 1024 screenshot confirms the sections remain aligned, readable, and free of horizontal overflow.
4. The common-preferences accent wash was removed, and both responsive layouts were reordered to current server, common preferences, media and devices, storage, then about. Fresh 390 x 844 and 1440 x 1024 captures confirm the groups use a consistent neutral surface.
5. Desktop common-preference controls were changed from bottom sheets to anchored menus. The first pass was too tall with two-line option descriptions; the final 280 px single-line menu fits below the row without viewport overflow. Mobile bottom sheets remain unchanged.

## Primary Interactions Tested

- Online-quality picker opens from the common-preferences surface.
- Desktop online quality, track gap, and theme use anchored menus; mobile continues to use bottom sheets.
- Cache-clear confirmation opens after scrolling on mobile.
- Theme, gap, media-source, downloads, menu-bar lyrics, and logout retain their existing handlers and routes.

## Console and Runtime Errors

- No Flutter exceptions were reported across the final 27 settings-page tests.
- Targeted static analysis for the settings page and its test reports no issues.

final result: passed
