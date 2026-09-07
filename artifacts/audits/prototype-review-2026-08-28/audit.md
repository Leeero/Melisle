# Melisle prototype review

Date: 2026-08-28
Target: http://localhost:4173/
Viewport coverage: desktop default (1280×720), mobile (390×844)

## Verdict

The prototype substantially matches the proposed direction, especially in global information architecture, music-first hierarchy, restrained visual language, and the immersive desktop player. It is not yet complete: mobile home/player responsibilities overlap, the mobile player overflows at 390×844, and the library lacks sorting/filtering/view controls for a large collection.

Estimated alignment: 78%.

## Steps

1. Desktop home — Healthy
   - Strong cover-led hero and current-listening emphasis.
   - Sidebar groups listening, library, and system tasks clearly.
   - The home hero still consumes enough space that discovery content is partially below the fold at 720 px height.

2. Desktop albums — Needs improvement
   - Content-first grid is cleaner and less card-heavy.
   - 126 albums are presented with only random play; sorting, filtering, and view-density controls are missing.

3. Desktop player — Healthy
   - Cover, ambient background, synchronized lyrics, and persistent controls create a distinct brand moment.
   - Track identity is relegated to the bottom control strip; the main content has no title/artist anchor.

4. Desktop settings — Healthy
   - Clear sections, restrained surfaces, and an explicit reduce-motion preference.
   - Secondary text and divider contrast should be measured rather than judged from screenshots alone.

5. Mobile home — Needs improvement
   - Strong visual continuity with desktop.
   - The current-playing hero fills nearly the whole first viewport, duplicating the dedicated player and hiding discovery content below the fold.

6. Mobile player — At risk
   - The immersive direction is strong and controls remain understandable.
   - At 390×844 the queue control is clipped below the viewport and the page scrolls vertically; the player should adapt artwork and lyric heights so primary controls fit without scrolling.

## Accessibility evidence

- Confirmed from the current DOM: landmark structure, headings, navigation labels, button names, slider names, artwork alt text, and a reduce-motion setting.
- Not verified in this screenshot review: keyboard focus order/visibility, screen-reader behavior, exact contrast ratios, zoom/reflow beyond the tested viewport, and reduced-motion runtime behavior.

## Highest-impact changes

1. Separate mobile home and player responsibilities: compress the home hero and expose recent/discovery content in the first viewport.
2. Make the mobile player viewport-contained at 390×844 by adapting artwork, lyric, and control spacing.
3. Add library sort, filter, and density/view controls before scaling the grid to real collections.
4. Restore a small track identity anchor in the desktop player's main content without weakening the lyric focus.
