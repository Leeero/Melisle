# 下载管理页面 Design QA

## Evidence

- Source visual truth: `/Users/lero/.codex/generated_images/01a0339e-4c9d-71e0-b86f-fdc14b01789d/exec-661036d9-9d86-4c99-896d-f1320a14c882.png`
- Implementation screenshot: `/Users/lero/Documents/MyData/Code/melisle/audit-output/downloads-page-implementation.jpeg`
- Side-by-side comparison: `/Users/lero/Documents/MyData/Code/melisle/audit-output/downloads-page-comparison.png`
- Source pixels: 1364 × 1153.
- Implementation pixels and app viewport: 1198 × 768 at device pixel ratio 1.
- Normalization: the source was proportionally resized to 909 × 768; the implementation remained 1198 × 768. Both full-window captures were placed side by side without cropping.
- State: downloaded view selected, download activity count zero, one local download in the live implementation. The source uses illustrative light-theme data; the implementation intentionally uses the user's current dark theme and live local records because the request limits reuse to layout and interaction.

## Findings

- No actionable P0, P1, or P2 differences remain within the requested scope.
- The implementation preserves the source hierarchy: two download scopes, directory action on the right, storage and quality controls below, and a lightweight downloaded-track table.
- Failed jobs are intentionally included under “下载中” so retry behavior remains available without reintroducing a third tab.
- The page uses the project's existing header, sidebar, theme tokens, text tabs, artwork, buttons, table spacing, error color, and mini-player instead of copying the source's visual style.

## Required Fidelity Surfaces

- Fonts and typography: passed. The source hierarchy is preserved while all type styles come from the project's `ThemeData`.
- Spacing and layout rhythm: passed. Tabs, actions, metadata row, divider, columns, and list rows follow the source composition and the project's spacing tokens.
- Colors and visual tokens: passed. Dark surfaces, green selection color, muted text, outlines, and error/delete colors come from the active project theme as explicitly requested.
- Image quality and asset fidelity: passed. Downloaded rows use the existing `CachedArtwork` component and real track artwork; no generated or placeholder UI art was introduced.
- Copy and content: passed. Labels are concise and capability-backed: “已下载”, “下载中”, “本地占用”, “下载音质”, “打开下载目录”, and existing retry/cancel/delete copy.

## Focused Region Comparison

- The top controls were checked at full resolution: the selected underline, count badges, directory action, storage summary, and closed quality selector are aligned and readable.
- The table region was checked separately: title, artwork, artist, album, size, missing-file state, and delete action retain clear column alignment.

## Primary Interactions Checked

- Switching between downloaded and download-activity views.
- Opening the download directory editor and exposing the folder picker.
- Opening the download-quality menu, changing quality, persisting it, and restoring it through `DownloadsCubit`.
- Retaining retry for failed jobs, cancel for active jobs, and delete confirmation for completed downloads.

## Comparison History

1. First implementation capture found a P2 layout mismatch: desktop rows showed legacy numeric indices instead of the reference's artwork-led title rows.
2. The row leading column was replaced with the project's existing `CachedArtwork` component, the header gutter was realigned, and the revised live app was captured again.
3. The final comparison shows no remaining P0/P1/P2 issue for the requested interaction-and-layout-only adaptation.

## Follow-up Polish

- P3: when more simultaneous downloads exist, capture the “下载中” view with progress, queued, failed, retry, and cancel states together for an additional visual pass.

final result: passed
