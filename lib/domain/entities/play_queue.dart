import 'dart:math';

import 'package:cross_platform_music_player/domain/entities/music_track.dart';

/// 播放循环模式。与 just_audio 的 LoopMode 语义一致，但独立建模，
/// 便于 Dart 层完全掌控 next/previous 策略。
enum QueueLoopMode { off, all, one }

/// 不可变的播放队列快照。
///
/// 只描述"逻辑"队列：一串 [MusicTrack] + 当前所在索引 + 循环/随机模式。
/// 不包含任何 AudioSource / URL 信息；解析与实际播放由更底层的组件负责。
///
/// 随机播放用一个稳定的 "shuffle order"（真实索引数组）实现：
/// - `shuffleEnabled = true` 时，下一首 / 上一首在 shuffleOrder 里前进 / 后退。
/// - 关闭 shuffle 时还原为顺序播放（但 currentIndex 仍指向真实位置）。
final class PlayQueue {
  const PlayQueue._({
    required this.tracks,
    required this.currentIndex,
    required this.loopMode,
    required this.shuffleEnabled,
    required this.shuffleOrder,
  });

  /// 空队列。
  const PlayQueue.empty()
    : tracks = const [],
      currentIndex = 0,
      loopMode = QueueLoopMode.off,
      shuffleEnabled = false,
      shuffleOrder = const [];

  final List<MusicTrack> tracks;

  /// 当前播放的真实索引（指向 [tracks]）。空队列时为 0。
  final int currentIndex;

  final QueueLoopMode loopMode;
  final bool shuffleEnabled;

  /// shuffle 顺序：长度等于 tracks.length，每个元素是 tracks 中的一个真实索引，
  /// 且互不重复。关闭 shuffle 时为空列表。
  final List<int> shuffleOrder;

  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;

  MusicTrack? get currentTrack {
    if (tracks.isEmpty || currentIndex < 0 || currentIndex >= tracks.length) {
      return null;
    }
    return tracks[currentIndex];
  }

  /// 用一组新的 tracks 替换队列，重置到 [startIndex]。
  /// 若 shuffle 原本开启，会基于新队列重新生成 shuffleOrder。
  PlayQueue replaceAll(
    List<MusicTrack> newTracks, {
    int startIndex = 0,
    int? seed,
  }) {
    if (newTracks.isEmpty) {
      return PlayQueue._(
        tracks: const [],
        currentIndex: 0,
        loopMode: loopMode,
        shuffleEnabled: shuffleEnabled,
        shuffleOrder: const [],
      );
    }
    final safeIndex = startIndex.clamp(0, newTracks.length - 1);
    final order = shuffleEnabled
        ? _buildShuffleOrder(newTracks.length, startAt: safeIndex, seed: seed)
        : const <int>[];
    return PlayQueue._(
      tracks: List.unmodifiable(newTracks),
      currentIndex: safeIndex,
      loopMode: loopMode,
      shuffleEnabled: shuffleEnabled,
      shuffleOrder: order,
    );
  }

  /// 跳到指定真实索引。
  ///
  /// 注意：**shuffle 模式下不会改写 [shuffleOrder]**。
  /// `shuffleOrder` 代表本轮随机播放的稳定顺序；`moveTo` 只是把“当前播放指针”
  /// 切到目标曲目。如果在这里交换 / 重排 `shuffleOrder`，就会导致：
  /// - 点一次“下一曲”后，随机顺序本身被篡改；
  /// - 再点一次“下一曲”可能跳回上一首或来回循环；
  /// - 点击队列中的任意歌曲后，后续上一曲 / 下一曲行为变得不可预测。
  ///
  /// 正确语义应该是：随机顺序稳定，当前播放位置可跳转。
  PlayQueue moveTo(int index) {
    if (tracks.isEmpty) return this;
    final safe = index.clamp(0, tracks.length - 1);
    return _copyWith(currentIndex: safe);
  }

  /// 计算"下一首"的真实索引；若无（且不循环）返回 null。
  ///
  /// 产品语义：单曲循环（[QueueLoopMode.one]）下，手动点击"下一曲"也不切歌，
  /// 因此直接返回当前索引。上层可据此重播当前曲或保持当前曲不变。
  int? nextIndex() {
    if (tracks.isEmpty) return null;
    if (loopMode == QueueLoopMode.one) return currentIndex;

    if (shuffleEnabled && shuffleOrder.isNotEmpty) {
      final pos = shuffleOrder.indexOf(currentIndex);
      if (pos < 0) return shuffleOrder.first;
      if (pos < shuffleOrder.length - 1) {
        return shuffleOrder[pos + 1];
      }
      return loopMode == QueueLoopMode.off ? null : shuffleOrder.first;
    }

    if (currentIndex < tracks.length - 1) {
      return currentIndex + 1;
    }
    return loopMode == QueueLoopMode.off ? null : 0;
  }

  /// 计算"上一首"的真实索引；若无返回 null。
  ///
  /// 与 [nextIndex] 一致：单曲循环下手动点击"上一曲"也不切歌。
  int? previousIndex() {
    if (tracks.isEmpty) return null;
    if (loopMode == QueueLoopMode.one) return currentIndex;

    if (shuffleEnabled && shuffleOrder.isNotEmpty) {
      final pos = shuffleOrder.indexOf(currentIndex);
      if (pos < 0) return shuffleOrder.first;
      if (pos > 0) {
        return shuffleOrder[pos - 1];
      }
      return loopMode == QueueLoopMode.off ? null : shuffleOrder.last;
    }

    if (currentIndex > 0) {
      return currentIndex - 1;
    }
    return loopMode == QueueLoopMode.off ? null : tracks.length - 1;
  }

  /// 自然播放结束后应该切到的真实索引；若无返回 null（代表应停止）。
  /// 与 [nextIndex] 的区别仅在于 [QueueLoopMode.one] 时返回当前索引（触发重播）。
  int? autoAdvanceIndex() {
    if (loopMode == QueueLoopMode.one) return currentIndex;
    return nextIndex();
  }

  PlayQueue withLoopMode(QueueLoopMode mode) => _copyWith(loopMode: mode);

  /// 切换 shuffle。开启时基于当前 tracks 生成 shuffleOrder（currentIndex 放在首位）。
  PlayQueue withShuffle(bool enabled, {int? seed}) {
    if (enabled == shuffleEnabled) return this;
    final newOrder = enabled
        ? _buildShuffleOrder(tracks.length, startAt: currentIndex, seed: seed)
        : const <int>[];
    return _copyWith(shuffleEnabled: enabled, shuffleOrder: newOrder);
  }

  /// 追加若干曲目到末尾（不改变 currentIndex）。若 shuffle 开启，追加部分会随机接到
  /// shuffleOrder 末尾，保持已播过的顺序不变。
  PlayQueue append(List<MusicTrack> more, {int? seed}) {
    if (more.isEmpty) return this;
    final newTracks = <MusicTrack>[...tracks, ...more];
    final newOrder = shuffleEnabled
        ? _appendShuffleOrder(more.length, seed)
        : const <int>[];
    return PlayQueue._(
      tracks: List.unmodifiable(newTracks),
      currentIndex: currentIndex,
      loopMode: loopMode,
      shuffleEnabled: shuffleEnabled,
      shuffleOrder: newOrder,
    );
  }

  List<int> _appendShuffleOrder(int count, int? seed) {
    final appended = [
      for (var i = tracks.length; i < tracks.length + count; i++) i,
    ];
    appended.shuffle(Random(seed ?? DateTime.now().microsecondsSinceEpoch));
    return [...shuffleOrder, ...appended];
  }

  PlayQueue insertAt(int index, MusicTrack track, {bool makeCurrent = false}) {
    final safeIndex = index.clamp(0, tracks.length);
    final newTracks = List<MusicTrack>.of(tracks)..insert(safeIndex, track);
    final newCurrent = makeCurrent
        ? safeIndex
        : (safeIndex <= currentIndex ? currentIndex + 1 : currentIndex);
    return PlayQueue._(
      tracks: List.unmodifiable(newTracks),
      currentIndex: newCurrent.clamp(0, newTracks.length - 1),
      loopMode: loopMode,
      shuffleEnabled: shuffleEnabled,
      shuffleOrder: shuffleEnabled
          ? _buildShuffleOrder(newTracks.length, startAt: newCurrent)
          : const [],
    );
  }

  /// 移除指定位置的曲目。若删掉的是当前曲，[currentIndex] 会被 clamp 到新边界，
  /// 调用方应自行判断是否需要立即切歌。
  PlayQueue removeAt(int index) {
    if (index < 0 || index >= tracks.length) return this;
    final newTracks = List<MusicTrack>.of(tracks)..removeAt(index);
    if (newTracks.isEmpty) {
      return const PlayQueue.empty();
    }
    int newCurrent;
    if (index < currentIndex) {
      newCurrent = currentIndex - 1;
    } else if (index == currentIndex) {
      newCurrent = currentIndex.clamp(0, newTracks.length - 1);
    } else {
      newCurrent = currentIndex;
    }
    final newOrder = shuffleEnabled
        ? _rebuildShuffleOrderAfterRemove(index)
        : const <int>[];
    return PlayQueue._(
      tracks: List.unmodifiable(newTracks),
      currentIndex: newCurrent,
      loopMode: loopMode,
      shuffleEnabled: shuffleEnabled,
      shuffleOrder: newOrder,
    );
  }

  /// 把 [from] 处的曲目移动到 [to]。currentIndex 会相应跟随。
  PlayQueue move(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= tracks.length ||
        to >= tracks.length ||
        from == to) {
      return this;
    }
    final newTracks = List<MusicTrack>.of(tracks);
    final moved = newTracks.removeAt(from);
    newTracks.insert(to, moved);
    int newCurrent;
    if (from == currentIndex) {
      newCurrent = to;
    } else if (from < currentIndex && to >= currentIndex) {
      newCurrent = currentIndex - 1;
    } else if (from > currentIndex && to <= currentIndex) {
      newCurrent = currentIndex + 1;
    } else {
      newCurrent = currentIndex;
    }
    // move 不重排 shuffleOrder 元素值——shuffleOrder 存的是"真实索引"，
    // 数组被重排后真实索引会平移，这里最简单安全的做法是：若启用 shuffle，
    // 重新构建 shuffleOrder，把新 currentIndex 放在其内部第一个位置，其他按
    // 原有 shuffle 的相对顺序保留。
    if (!shuffleEnabled) {
      return PlayQueue._(
        tracks: List.unmodifiable(newTracks),
        currentIndex: newCurrent,
        loopMode: loopMode,
        shuffleEnabled: shuffleEnabled,
        shuffleOrder: const [],
      );
    }
    return PlayQueue._(
      tracks: List.unmodifiable(newTracks),
      currentIndex: newCurrent,
      loopMode: loopMode,
      shuffleEnabled: shuffleEnabled,
      shuffleOrder: _buildShuffleOrder(newTracks.length, startAt: newCurrent),
    );
  }

  PlayQueue _copyWith({
    List<MusicTrack>? tracks,
    int? currentIndex,
    QueueLoopMode? loopMode,
    bool? shuffleEnabled,
    List<int>? shuffleOrder,
  }) {
    return PlayQueue._(
      tracks: tracks ?? this.tracks,
      currentIndex: currentIndex ?? this.currentIndex,
      loopMode: loopMode ?? this.loopMode,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      shuffleOrder: shuffleOrder ?? this.shuffleOrder,
    );
  }

  List<int> _rebuildShuffleOrderAfterRemove(int removedIndex) {
    // 删除 removedIndex 后，所有 > removedIndex 的真实索引要 -1；
    // 等于 removedIndex 的条目从 shuffleOrder 里拿掉。
    final remapped = <int>[];
    for (final raw in shuffleOrder) {
      if (raw == removedIndex) continue;
      remapped.add(raw > removedIndex ? raw - 1 : raw);
    }
    return remapped;
  }

  static List<int> _buildShuffleOrder(
    int length, {
    required int startAt,
    int? seed,
  }) {
    if (length <= 0) return const [];
    final indices = [for (var i = 0; i < length; i++) i];
    final rng = Random(seed ?? DateTime.now().microsecondsSinceEpoch);
    // Fisher-Yates
    for (var i = indices.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = indices[i];
      indices[i] = indices[j];
      indices[j] = tmp;
    }
    // 确保 startAt 在 order 的第一位
    final anchor = startAt.clamp(0, length - 1);
    final pos = indices.indexOf(anchor);
    if (pos > 0) {
      final tmp = indices[0];
      indices[0] = indices[pos];
      indices[pos] = tmp;
    }
    return indices;
  }
}
