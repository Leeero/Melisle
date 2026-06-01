---
target: lib/presentation/pages/library/library_page.dart
total_score: 36
p0_count: 0
p1_count: 1
timestamp: 2026-05-19T07-19-59Z
slug: lib-presentation-pages-library-library-page-dart
---
#### Design Health Score
| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 4 | Solid handling of empty, loading, and error states. |
| 2 | Match System / Real World | 4 | Standard music player table columns and icons used correctly. |
| 3 | User Control and Freedom | 3 | Easy tab switching, but custom tab implementation may lack standard native behavior. |
| 4 | Consistency and Standards | 3 | Follows DESIGN.md perfectly, but custom tabs instead of Flutter's `TabBar` drift from framework standards. |
| 5 | Error Prevention | 4 | Clean separation of row-tap and favorite-tap targets. |
| 6 | Recognition Rather Than Recall | 4 | Persistent table headers make column data obvious. |
| 7 | Flexibility and Efficiency | 3 | Hover actions on PC are great, but lacking explicit keyboard shortcut hints in the list. |
| 8 | Aesthetic and Minimalist Design | 4 | Adheres strictly to the "refined, restrained, immersive" brand personality. |
| 9 | Error Recovery | 4 | Explicit inline error messages and reload actions provided. |
| 10 | Help and Documentation | 3 | UI is self-explanatory, no explicit documentation needed. |
| **Total** | | **36/40** | **Excellent** |

#### Anti-Patterns Verdict
**LLM assessment**: The implementation successfully avoids common "AI slop" traps. It doesn't rely on overly generic cards, heavy glassmorphism, or gratuitous gradients. Instead, it closely adheres to the `DESIGN.md` guidelines, utilizing precise alpha channels (`surfaceContainerHighest.withValues(alpha: 0.4)`) and `colorScheme` tokens for a refined, native desktop feel. The table layout avoids the "identical card grid" anti-pattern.

**Deterministic scan**: N/A (Flutter/Dart code; CLI html detector skipped).

#### Overall Impression
The Media Library PC layout is exceptionally clean and aligns perfectly with the brand's "private music island" aesthetic. The transition from mobile cards to a dense, hover-enabled desktop table significantly improves the experience. The biggest opportunity is hardening the underlying semantics and responsiveness of the custom-built components.

#### What's Working
- **Adaptive Hover States**: The row transitions (index to play button, duration to more options) are elegant, maintain layout stability, and match desktop conventions perfectly.
- **Visual Hierarchy**: The use of alpha layers and bolding for the currently playing track makes it stand out without relying on loud, disruptive colors.
- **Target Separation**: Extracting the favorite button into a distinct `IconButton` resolves previous usability issues.

#### Priority Issues
- **[P1] Custom Tab Implementation (Consistency)**: 
  - **Why it matters**: `_LibraryPCFilterTabs` is manually built with `InkWell` and `Container` borders. It lacks the built-in keyboard navigation, focus rings, and semantics of Flutter's native `TabBar` or `SegmentedButton`, impacting accessibility and power users.
  - **Fix**: Refactor `_LibraryPCFilterTabs` to use Flutter's native `TabBar` with custom styling (using the app's theme), or ensure full semantic wrapping.
  - **Suggested command**: `/impeccable harden`

- **[P2] Fixed Flex Ratios in Table (Responsive Layout)**:
  - **Why it matters**: The `_TrackTableRow` uses fixed `Expanded(flex: N)` ratios. While functional, on extremely ultrawide monitors, columns may stretch uncomfortably far apart, and on narrower desktop views, text might truncate too aggressively.
  - **Fix**: Consider max-width constraints on the overall list or using a more robust `Table` layout that respects intrinsic content widths better.
  - **Suggested command**: `/impeccable adapt`

- **[P3] Missing Semantic Labels for Table Data (Accessibility)**:
  - **Why it matters**: Screen readers parsing the `Row` will read it as a continuous string of text without table context.
  - **Fix**: Wrap critical data points or the row itself in `Semantics` to announce the role (e.g., "Row 2, Song Title, Artist").
  - **Suggested command**: `/impeccable audit`

#### Persona Red Flags
- **Alex (Power User)**: The custom tabs can't be navigated natively with arrow keys out-of-the-box. There are no visual focus rings for keyboard tab-navigation in the table rows.
- **Jordan (First-Timer)**: No major red flags. The interface is intuitive and closely mimics familiar desktop media players.

#### Minor Observations
- The `indexText` uses `.padLeft(2, '0')`. If a user's library has over 100 tracks in a view, it becomes 3 digits. Ensure the `44px` width for the index column won't clip "100" or "999".

#### Questions to Consider
- Does the PC layout need a "Select All" or "Batch Edit" mode (e.g., checkboxes next to the index)?
- How should the table scale if the window is resized from 1280px down to 800px? Does it swap to the mobile list view early enough?
