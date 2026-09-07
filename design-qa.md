# Media Library Songs Design QA

## Comparison Target

- Selected revised visual: `/Users/lero/.codex/generated_images/01a056b4-c39c-74d0-aa12-983a69b9e061/exec-8178f2af-6b86-4375-9356-4579a639e776.png`
- Native macOS implementation: `/Users/lero/Documents/MyData/Code/melisle/artifacts/design/ambient-listening-stage/library/library-implementation-macos-1200x768.jpg`
- Side-by-side comparison: `/Users/lero/Documents/MyData/Code/melisle/artifacts/design/ambient-listening-stage/library/library-design-qa-comparison.png`

## Normalization

- Source pixels: 1487 x 1058.
- Native implementation pixels: 1199 x 768.
- The source was proportionally scaled to 1079 x 768 and placed beside the native capture without cropping.
- Both states use the desktop dark-theme Songs view. The implementation uses live library data and an idle player, so artwork, track count, row content, and current-playing state intentionally differ from the generated visual.

## Verified Structure

- The desktop page preserves the selected hierarchy: sidebar, title and playback actions, unified toolbar, table, and fixed bottom player.
- The toolbar provides working song search, favorite filtering, sorting, and compact/comfortable display density.
- Song identity combines artwork, title, and artist; album, quality, duration, favorite, and more actions remain independent columns.
- Only the left song identity region starts playback. Album and row actions no longer trigger playback.
- Hovering the song identity region replaces the index with a play icon; the current track uses an equalizer indicator.
- Each library row exposes one playback semantics action, avoiding nested duplicate play buttons.
- The generated visual's unsupported audio-quality filter was intentionally replaced with `全部歌曲 / 仅显示收藏`, matching the repository's real capabilities instead of presenting a non-functional control.

## Iteration History

1. Initial native QA found an unbounded-width exception caused by the legacy combined sort/filter control remaining in the title action area. The duplicate control was removed and title actions were reduced to shuffle and play-all.
2. Accessibility inspection found nested playback semantics on library rows. Outer-row playback semantics were disabled for library style, leaving the identity hotspot as the single playback action.
3. Compact and comfortable density states were exercised; the comfortable state was restored for the final capture.

## Validation

- Music track table and library filter widget tests: passed, 16 tests.
- Desktop Songs toolbar smoke test: passed.
- Playback hotspot and compact-density regression tests: passed.
- Single playback semantics action regression test: passed.
- Targeted Flutter analysis for the changed library files and tests: passed with no issues.
- `git diff --check`: passed.

## Residual Differences

- The generated source uses curated placeholder data while the native capture uses the connected user's media library.
- The source is a larger 1487 x 1058 composition; the native verification window is 1199 x 768, so the implementation shows fewer visible rows and slightly tighter horizontal spacing.
- These differences do not alter the layout hierarchy, interaction model, or responsive behavior.

final result: passed

---

# Login Redesign Design QA

## Comparison Target

- Source visual truth: `/var/folders/60/sjbc7jwx6q35_rb5vhh6_h3m0000gn/T/codex-clipboard-d56777e0-1e12-49fa-aa4e-c73c063c6400.png`
- Normalized source: `/Users/lero/Documents/MyData/Code/melisle/audit-output/2026-09-02-login-redesign/source-normalized.png`
- Rendered implementation: `/Users/lero/Documents/MyData/Code/melisle/design-reference/screenshots/actual/login-desktop-dark-1440x900-idle.png`
- Full-view comparison: `/Users/lero/Documents/MyData/Code/melisle/audit-output/2026-09-02-login-redesign/login-source-vs-implementation.png`
- Focused form comparison: `/Users/lero/Documents/MyData/Code/melisle/audit-output/2026-09-02-login-redesign/login-form-focused.png`
- Focused artwork comparison: `/Users/lero/Documents/MyData/Code/melisle/audit-output/2026-09-02-login-redesign/login-artwork-focused.png`

## Normalization

- Source pixels: 2556 × 1988.
- Source was center-cropped to a 16:10 content frame and scaled to 1440 × 900.
- Implementation pixels and logical viewport: 1440 × 900 at devicePixelRatio 1.
- State: desktop, dark theme, unauthenticated, idle form.
- The Flutter widget-test renderer substitutes deterministic Ahem glyphs for most product text. Typography hierarchy, wrapping, and occupied geometry are visible; production font family assignments and all Chinese copy are additionally covered by widget assertions.

## Findings

- No actionable P0/P1/P2 differences remain.
- Fonts and typography: brand wordmark uses the bundled Righteous face; product copy remains on the platform font stack. The hero/title/body hierarchy and line wrapping match the approved hybrid direction. The Ahem screenshot substitution is a capture-only limitation, not a production font change.
- Spacing and layout rhythm: the implementation preserves the approved 52/48 desktop split, wider brand panel, centered 460px form, restrained borders, and full-height surfaces. Tablet and mobile intentionally return to the existing single-card structure.
- Colors and tokens: both panels use existing semantic surface, primary, outline, error, and on-surface roles; no second color system or gradient was introduced.
- Image quality and asset fidelity: the three prototype cover sources were imported as local 512px assets and use cover cropping, rounded masks, borders, and restrained shadows. No placeholder or code-drawn replacement remains.
- Copy and content: the prototype's manual Navidrome/Subsonic/Emby selector was intentionally removed. The implementation states automatic recognition and keeps the generic `连接服务器` action, matching the repository's existing auto-detect behavior.

## Comparison History

1. Initial implementation used code-native decorative tiles in place of the reference cover artwork. This was treated as an asset-fidelity blocker.
2. The tiles were replaced with the original `dawn-river`, `forest-echo`, and `night-city` cover sources, resized to 512px for the packaged app.
3. Post-fix full-view and focused artwork comparisons confirm the source art direction, overlap, crop, and scale are preserved. No P0/P1/P2 findings remain.

## Responsive and State Validation

- 1440 × 900: split layout, idle/loading/failure, light/dark.
- 900 × 800: centered 480px single-card layout without overflow.
- 390 × 844 at text scale 1.3: 358px mobile card without overflow.
- Primary interactions tested: validation, submit loading state, disabled CTA, password visibility control, and failure recovery label.

## Follow-up Polish

- P3: a native-window screenshot can be added later for pixel-level platform font antialiasing comparison; this does not block the layout handoff.

final result: passed
