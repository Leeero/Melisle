# QueueSheet 快速参考指南

## 🎯 核心问题一览

### 1. 设计不一致 (🔴 高优先级)

| 组件 | 问题 | 影响 |
|------|------|------|
| **顶部圆角** | 34dp（应为 24dp） | 视觉不协调 |
| **拖动条宽度** | 52dp（应为 40-48dp） | 视觉混乱 |
| **背景透明度** | 0.96（应为 1.0） | 半透明显示背景 |
| **内间距** | 缺失（应为 16-20） | 文字贴边 |

### 2. 配置不一致 (🟡 中优先级)

- **迷你播放条**: 缺少 `isScrollControlled: true`
  - 影响: 键盘弹出时 Sheet 显示不正确
  
- **缺少 `show()` 方法**
  - 影响: 调用方式不统一，代码冗长

### 3. Mobile 交互问题 (🟠 中优先级)

- **固定宽度 Trailing 区域** (112dp)
  - 在 < 360dp 屏幕上显示不恰当
  - 需要响应式设计

- **没有键盘安全边距处理**
  - 需要添加 `viewInsets.bottom`

---

## 📋 所有调用位置

### 1. player_page.dart (✅ 正确)
```dart
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,  // ✅
  useSafeArea: true,
  backgroundColor: Colors.transparent,
  builder: (_) => BlocProvider.value(
    value: context.read<PlayerCubit>(),
    child: const QueueSheet(),
  ),
);
```

### 2. mini_player_bar.dart (❌ 缺配置)
```dart
void _showMiniQueueSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    // ❌ 缺少 isScrollControlled: true
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const QueueSheet(),
    ),
  );
}
```

---

## 🔍 PlayerCubit 关键方法

### 队列操作

```dart
playIndex(int index)          // 播放指定索引的歌曲
moveQueueItem(old, new)       // 拖拽排序
removeQueueItem(index)        // 删除单首歌曲
clearQueue()                  // 清空整个队列
```

### 状态（PlayerViewState）

```dart
queue: List<MusicTrack>       // 当前队列
currentIndex: int             // 当前播放位置
isPlaying: bool               // 是否播放中
isLoading: bool               // 是否加载中
currentTrack: MusicTrack?     // 当前歌曲
```

---

## 📐 设计规范对应关系

### AppRadiusTokens
```dart
shellContainer: 24  // ← 应该用这个（不是 34）
card: 20
```

### AppSpacingTokens
```dart
pageHorizontalCompact: 16    // ← padding 应该用这个
cardPadding: 16
headerPadding: 22
```

### AppBreakpoints
```dart
compact:   width < 860dp      // ← Mobile
medium:    860dp ≤ width < 1280dp
expanded:  width ≥ 1280dp    // ← 桌面
```

---

## 💡 改进建议

### 第一步：修复基础样式

```dart
// 在 queue_sheet.dart 中改动

// 1. 修改顶部圆角
- borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
+ borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),

// 2. 修改背景透明度
- color: colorScheme.surface.withValues(alpha: 0.96),
+ color: colorScheme.surface,

// 3. 修改拖动条宽度
- width: 52,
+ width: 48,

// 4. 添加内间距和键盘处理
+ Padding(
+   padding: EdgeInsets.only(
+     bottom: MediaQuery.of(context).viewInsets.bottom,
+   ),
+   child: Padding(
+     padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
+     child: /* 现有的 DecoratedBox 内容 */
+   ),
+ )
```

### 第二步：修复配置不一致

```dart
// 在 mini_player_bar.dart 中改动

void _showMiniQueueSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,  // ← 添加这一行
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: context.read<PlayerCubit>(),
      child: const QueueSheet(),
    ),
  );
}
```

### 第三步：添加 show() 方法

```dart
// 在 QueueSheet 类中添加

class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<PlayerCubit>(),
        child: const QueueSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ... 现有代码
  }
}

// 然后在调用方改为:
QueueSheet.show(context);
```

### 第四步（可选）：响应式 Trailing

```dart
// 在 queue_sheet.dart 中改动 trailing

trailing: _buildTrailingActions(
  context: context,
  isCurrent: isCurrent,
  isPlaying: state.isPlaying,
  index: index,
)

// 新增方法
Widget _buildTrailingActions({
  required BuildContext context,
  required bool isCurrent,
  required bool isPlaying,
  required int index,
}) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  final isSmallScreen = screenWidth < 360;
  final trailingWidth = isSmallScreen ? 90.0 : 112.0;
  
  return SizedBox(
    width: trailingWidth,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isCurrent)
          Icon(
            isPlaying
                ? Icons.graphic_eq_rounded
                : Icons.pause_circle_outline_rounded,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          )
        else
          const SizedBox(width: 24),
        IconButton(
          onPressed: () => context
              .read<PlayerCubit>()
              .removeQueueItem(index),
          tooltip: '移出队列',
          icon: const Icon(Icons.close_rounded),
          iconSize: isSmallScreen ? 18 : 20,
        ),
        Tooltip(
          message: '拖拽排序',
          child: ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.drag_handle_rounded,
                color: Theme.of(context)
                    .colorScheme.onSurfaceVariant,
                size: isSmallScreen ? 18 : 20,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
```

---

## 📊 DraggableScrollableSheet 参数解释

```dart
DraggableScrollableSheet(
  expand: false,          // 不填满屏幕，让用户能通过拖拽调整大小
  initialChildSize: 0.82, // 初始占屏幕高度 82%
  minChildSize: 0.42,     // 用户最小能缩小到 42%
  maxChildSize: 0.94,     // 用户最大能放大到 94%
  builder: (context, scrollController) {
    // scrollController 用于与 ReorderableListView 绑定
  }
)
```

### 改进建议
```dart
// 当前比较激进，可以调整为:
initialChildSize: 0.8,   // 微调为 80%（减少初始占屏高度）
minChildSize: 0.45,      // 微调为 45%（给系统控件更多空间）
maxChildSize: 0.92,      // 微调为 92%（保留状态栏空间）
```

---

## 🧪 测试检查清单

### 视觉检查
- [ ] 顶部圆角与其他 Sheet 一致
- [ ] 拖动条大小合理
- [ ] 背景完全不透明
- [ ] 文字间距适当
- [ ] 列表项卡片样式一致

### 功能检查
- [ ] 从播放页打开 Sheet 正常
- [ ] 从迷你播放条打开 Sheet 正常
- [ ] 键盘弹出时 Sheet 显示正确
- [ ] 拖拽排序工作正常
- [ ] 删除歌曲工作正常
- [ ] 清空队列工作正常

### Mobile 检查
- [ ] 在 320dp 宽屏幕上显示正常
- [ ] 在 360dp 屏幕上显示正常
- [ ] 在 412dp 屏幕上显示正常
- [ ] Trailing 按钮在所有尺寸上易点击

---

## 📖 相关文档

| 文档 | 内容 |
|------|------|
| `QUEUE_SHEET_ANALYSIS.md` | 完整技术分析 |
| `QUEUE_SHEET_COMPARISON.md` | 与其他 Sheet 的对比 |
| `QUEUE_SHEET_QUICK_REFERENCE.md` | 本文件 |

---

## ⏱️ 估计工作量

| 任务 | 复杂度 | 时间 |
|------|-------|------|
| 修复基础样式 | ⭐ | 15 min |
| 修复配置不一致 | ⭐ | 5 min |
| 添加 show() 方法 | ⭐⭐ | 15 min |
| 响应式设计 | ⭐⭐⭐ | 30 min |
| 测试和调整 | ⭐⭐ | 20 min |
| **总计** | | **~85 min** |

