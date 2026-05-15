# Visual Design Patterns Analysis: Melisle Bottom Sheets & Components

## Executive Summary

**QueueSheet has visual inconsistencies** compared to other bottom sheets in the app. This analysis identifies the patterns used across existing sheets and provides a comparison.

---

## 1. Bottom Sheet Implementation Patterns

### Overview: Three Approaches

The app uses **three distinct bottom sheet implementations**, each with different visual characteristics:

#### A. `showModalBottomSheet()` + `showDragHandle: true`
- **Files**: `track_actions_sheet.dart`
- **Features**: 
  - Uses Flutter's native `showModalBottomSheet` with `showDragHandle: true`
  - Drag handle automatically positioned at top
  - Simple shape configuration
- **Visual Style**:
  ```dart
  backgroundColor: colorScheme.surface
  showDragHandle: true
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  )
  ```

#### B. `showModalBottomSheet()` + Custom Container
- **Files**: `quality_picker_sheet.dart`, `sleep_timer_sheet.dart`
- **Features**:
  - Uses `backgroundColor: Colors.transparent`
  - Custom `Container` with `BoxDecoration` for styling
  - Custom-drawn drag handle (40-48px width × 4px height)
- **Visual Style**:
  ```dart
  backgroundColor: Colors.transparent
  
  Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(24 or 28)),
    ),
    padding: EdgeInsets.fromLTRB(8 or 20, 12, 8 or 20, 24),
    child: ...,
  )
  ```

#### C. `DraggableScrollableSheet` (QUEUE SHEET)
- **File**: `queue_sheet.dart`
- **Features**:
  - Uses `DraggableScrollableSheet` instead of `showModalBottomSheet`
  - Draggable and resizable content
  - Reorderable list view inside
  - Border applied to container
- **Visual Style**:
  ```dart
  DecoratedBox(
    decoration: BoxDecoration(
      color: colorScheme.surface.withValues(alpha: 0.96),
      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.72),
      ),
    ),
    child: Column(...),
  )
  ```

---

## 2. Visual Comparison Chart

| Aspect | TrackActionsSheet | QualityPickerSheet | SleepTimerSheet | QueueSheet |
|--------|------|------|------|------|
| **Implementation** | `showModalBottomSheet` + `showDragHandle: true` | Custom Container | Custom Container | `DraggableScrollableSheet` |
| **Background Color** | `surface` | `transparent` | `transparent` | `surface.alpha(0.96)` |
| **Top Radius** | 28px | 24px | 28px | 34px ⚠️ |
| **Drag Handle** | Automatic | Manual (40px×4px) | Manual (48px×4px) | Manual (52px×4px) |
| **Handle Color** | (Auto) | `outlineVariant` | `outlineVariant` | `onSurfaceVariant.alpha(0.4)` |
| **Outer Padding Top** | Auto | 12px | 12px | 12px |
| **Outer Padding Horizontal** | Auto | 8px | 20px | N/A (full) |
| **Outer Padding Bottom** | Auto | 24px | 24px | 24px |
| **Border** | None (card shape) | None | None | Yes (1px, outlineVariant.alpha(0.72)) ⚠️ |
| **Interior Padding** | Auto | 16px horizontal | 20px horizontal | 20px horizontal |
| **Inner Spacing** | Tight (4-12px gaps) | Moderate (4-12px gaps) | Moderate (6-18px gaps) | Tight (4-12px gaps) |
| **Content Typography** | titleMedium/bodySmall | titleLarge/bodyMedium | titleLarge/bodyMedium | titleLarge/bodyMedium |
| **Divider** | Yes (Divider widget) | No | No | No |

---

## 3. Key Visual Inconsistencies in QueueSheet

### Issue 1: Top Border Radius (34px)
- **Other sheets**: 24-28px
- **QueueSheet**: 34px ⚠️
- **Design.md spec**: "Bottom sheets: 24-34px top" (but other sheets use 24-28)
- **Issue**: Appears visually larger/rounder than peers

### Issue 2: Border Applied to Sheet
```dart
border: Border.all(
  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
)
```
- **Other sheets**: No border (relying on shape only)
- **QueueSheet**: Has border frame around entire container
- **Issue**: Extra visual weight, inconsistent with design.md which specifies shape but not perimeter border

### Issue 3: Surface Alpha (0.96)
```dart
color: colorScheme.surface.withValues(alpha: 0.96)
```
- **Other sheets**: Full opacity `colorScheme.surface` or `Colors.transparent`
- **QueueSheet**: 96% opacity (4% transparent)
- **Issue**: Subtle but creates slight visual separation inconsistent with others

### Issue 4: Implementation Method
- **TrackActionsSheet**: `showModalBottomSheet()` + `showDragHandle: true` (simplest, most Material)
- **Quality/SleepTimer**: `showModalBottomSheet()` + Custom Container (mid-level control)
- **QueueSheet**: `DraggableScrollableSheet` (fully custom, adds complexity)
- **Issue**: Different sheet types use different base implementations, harder to maintain

### Issue 5: Handle Color and Alpha
| Sheet | Handle Color | Alpha |
|-------|------|------|
| QualityPicker | `outlineVariant` | default (1.0) |
| SleepTimer | `outlineVariant` | default (1.0) |
| QueueSheet | `onSurfaceVariant` | 0.4 ⚠️ |

- **Issue**: Inconsistent color choice and alpha application

---

## 4. Design.md Specifications for Bottom Sheets

### Section 8.9 - BottomSheet (Design.md lines 360-367)

```
用途: 播放队列、音质选择、睡眠定时、曲目操作
圆角: 顶部 24-34px
拖拽手柄: 居中 40-52px × 4px 圆角胶囊, outlineVariant/0.4
背景: surface/0.96 (队列) / surface (其他)
```

**Translation & Analysis**:
- **Purpose**: Queue, quality selection, sleep timer, track actions
- **Border radius**: Top 24-34px (QueueSheet at 34px is max)
- **Drag handle**: Centered, 40-52px wide × 4px tall, rounded capsule, `outlineVariant` with 0.4 alpha
- **Background**: `surface/0.96` for queue / `surface` for others

### Inference from Design.md

✅ **Supported by design.md**:
- Surface alpha 0.96 for QueueSheet
- Top radius 34px is at upper bound (acceptable)
- Drag handle at 52px width (QueueSheet uses this)

❓ **Ambiguous**:
- Should all sheets use surface/0.96? (Currently only Queue does)
- Border specification not mentioned — should there be one?

⚠️ **Implementation Gap**:
- Other sheets (Quality, Sleep) don't follow the `outlineVariant/0.4` handle color spec!
- They use full opacity `outlineVariant` instead

---

## 5. Pattern Recommendations

### 5.1 Standardize on One Approach

**Option A: Use `showModalBottomSheet()` for all** (Recommended)
```dart
// Clean, Material-compliant, easier maintenance
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => Container(
    decoration: BoxDecoration(
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: ...,
  ),
);
```

**Option B: Use `DraggableScrollableSheet` only for resizable sheets** (QueueSheet)
- Keep this for Queue because it's genuinely draggable/resizable
- Standardize QualityPicker + SleepTimer to approach Option A

### 5.2 Visual Standardization

| Property | Recommendation | Rationale |
|----------|---|---|
| **Top Radius** | 28px (most sheets) | Balances roundness; 34px feels too rounded |
| **Background** | `surface` (no alpha) | Simpler; only use alpha if genuinely needed |
| **Drag Handle** | `outlineVariant.alpha(0.4)` | Per design.md; currently inconsistent |
| **Handle Size** | 44-48px wide × 4px tall | Current range; use 44px for consistency |
| **Border** | None on standard sheets | Only QueueSheet needs visual framing |
| **Padding** | Horizontal 16px, Top 12px, Bottom 24px | Consistent with tokens |

### 5.3 Implementation Consistency

**Non-queue sheets** (TrackActions, QualityPicker, SleepTimer):
- Use `showModalBottomSheet()` with `backgroundColor: Colors.transparent`
- Custom Container with BoxDecoration
- No border
- Standard radius 28px

**Queue sheet** (QueueSheet):
- Continue using `DraggableScrollableSheet`
- Apply border if needed for visual separation
- Radius can be 30-34px (larger is acceptable for this special case)
- Surface alpha 0.96 acceptable (per design.md)

---

## 6. Theme Token Usage Analysis

### From `app_tokens.dart`:

```dart
// Border Radii
static const double shellContainer = 24;    // Shell (tab bar)
static const double card = 20;              // Cards
static const double button = 999;           // Buttons (capsule)
static const double input = 16;             // Input fields
static const double iconButton = 18;        // Icon buttons
```

**Bottom Sheets**: Not defined as a token!
- Use either `card (20)` or custom values (24-34px)
- Design.md says 24-34px, but no dedicated token

### From `app_motion.dart`:

```dart
static const Duration micro = Duration(milliseconds: 150);
static const Duration short = Duration(milliseconds: 220);
static const Duration medium = Duration(milliseconds: 300);
static const Duration long = Duration(milliseconds: 420);

static const Curve standard = Curves.easeInOut;
static const Curve enter = Curves.easeOut;
static const Curve exit = Curves.easeIn;
```

**Bottom Sheet Animation**: None currently used
- Should use `Duration.short` (220ms) for entry/exit
- Curve: `enter` (easeOut) for entering, `exit` (easeIn) for leaving

---

## 7. Mini Player Bar Reference

### Visual Approach (from `mini_player_bar.dart`):

```dart
// Frosted glass + gradient background
BackdropFilter(
  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
  child: DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          colorScheme.surface.withValues(alpha: 0.88),
          colorScheme.surfaceContainerHigh.withValues(alpha: 0.76),
        ],
      ),
      borderRadius: BorderRadius.circular(isWide ? 24 : 22),
      border: Border.all(
        color: colorScheme.outlineVariant.withValues(alpha: 0.58),
      ),
      boxShadow: [...],
    ),
  ),
)
```

**Takeaway for Sheets**:
- Borders are used with low alpha (0.58) for layering
- Gradients + blur create premium feel
- Mini player uses 22-24px radius
- Could apply similar glassmorphism to sheets for elevation

---

## 8. Design.md Color Specifications

### Section 2.1 - Color Palette (Dark Mode - where most sheets live):

| Token | Value | Usage |
|-------|-------|-------|
| Surface | `#121723` | Base containers |
| Surface High | `#171E2B` | Elevated containers |
| Primary Container | `#2B3150` | Active/selected states |
| Outline Variant | `#2A3342` | Borders, inactive states |
| On Surface Variant | `#ACB6C7` | Secondary text, icons |

**For Bottom Sheets**:
- **Background**: Should be `surface` or `surface/0.96`
- **Drag Handle**: Should be `outlineVariant` with alpha 0.4 (per section 8.9)
- **Border** (if used): `outlineVariant` with alpha 0.45-0.72

---

## 9. Animation / Transition Specifications

### From design.md (section 9.1 - Animation Durations):

| Category | Duration | Curve | Use Case |
|----------|----------|-------|----------|
| 상태 切换 | 180ms | — | Hover, selection, container color transition |
| 内容 切换 | 260ms | — | AnimatedSwitcher content swap |

**For Bottom Sheets**:
- **Entry animation**: 260ms (content reveal)
- **Exit animation**: 220ms (dismiss)
- **Curve**: `easeOut` for entry, `easeIn` for exit

Currently: No custom animation applied to sheets (uses Flutter's default bottom sheet animation ~250ms)

---

## 10. Summary of Findings

### What's Consistent ✅
1. All sheets use semi-transparent overlays (surface-based)
2. All sheets have top-rounded corners (24-34px)
3. All sheets have drag handles (40-52px wide × 4px tall)
4. Padding is generally consistent (12-20px)
5. All use design system colors (no arbitrary hex values)

### What's Inconsistent ⚠️
1. **Top radius**: 24px vs 28px vs 34px (mix of values)
2. **Handle color**: `outlineVariant` (full alpha) vs `onSurfaceVariant.alpha(0.4)`
3. **Border**: QueueSheet has it; others don't
4. **Background alpha**: 0.96 (Queue) vs 1.0 (others)
5. **Implementation method**: 2 different modal approaches + 1 DraggableScrollableSheet
6. **Interior padding**: 8px vs 16px vs 20px horizontal
7. **Drag handle styling**: Manual implementation inconsistent across sheets

### Recommendations 🎯
1. **Standardize radius to 28px** across all sheets (except Queue which can be 30-34px)
2. **Standardize drag handle** to `outlineVariant.alpha(0.4)` per design.md
3. **Remove border** from non-queue sheets (visual noise)
4. **Keep background**: `surface` (full opacity) except Queue (`surface.alpha(0.96)`)
5. **Consolidate** to 2 implementation patterns: standard modal + special DraggableScrollableSheet for Queue
6. **Document in design.md** or add token for "bottom sheet radius" and "drag handle style"

