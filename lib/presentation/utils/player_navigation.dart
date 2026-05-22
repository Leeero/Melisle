import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/music_track.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

final class PlayerNavigation {
  PlayerNavigation._();

  static bool _playerRoutePushInFlight = false;

  static Future<void> playTracksAndOpenPlayer(
    BuildContext context, {
    required List<MusicTrack> tracks,
    required int startIndex,
  }) async {
    if (tracks.isEmpty) {
      return;
    }

    final playbackFuture = context.read<PlayerCubit>().playTracks(
      tracks,
      startIndex: startIndex,
    );

    openPlayerPage(context);

    await playbackFuture;
  }

  /// "播放全部"专用入口。
  ///
  /// [loadedTracks] 是当前已分页加载到内存中的歌曲列表，用于**立即开始播放**，
  /// 避免等待全量列表拉取完毕。[fetchAll] 是一个异步回调，用于在后台获取
  /// 全量歌曲列表（上限 500 首）；获取完成后会替换播放队列。
  ///
  /// 如果列表已经全量加载（[allLoaded] = true），直接使用 [loadedTracks]。
  static Future<void> playAllAndOpenPlayer(
    BuildContext context, {
    required List<MusicTrack> loadedTracks,
    required bool allLoaded,
    required Future<List<MusicTrack>> Function() fetchAll,
    int startIndex = 0,
  }) async {
    if (loadedTracks.isEmpty) return;

    final cubit = context.read<PlayerCubit>();
    // 预测 playTracks 后的 revision：playTracks 内部会把 playbackRevision +1。
    // 在这里 +1 取得即将使用的值；若期间其他播放操作覆盖，appendTracks* 会因
    // 值不匹配自动放弃。
    final safeStart = startIndex.clamp(0, loadedTracks.length - 1).toInt();
    final expectedRevision = cubit.playbackRevision + 1;
    final playbackFuture = cubit.playTracks(
      loadedTracks,
      startIndex: safeStart,
    );

    openPlayerPage(context);
    await playbackFuture;

    if (allLoaded) return;

    unawaited(() async {
      try {
        final allTracks = await fetchAll();
        await cubit.appendTracksIfRevisionMatches(
          expectedRevision: expectedRevision,
          initialTracks: loadedTracks,
          allTracks: allTracks,
        );
      } catch (_) {
        // 拉取失败不影响已经在播放的内容
      }
    }());
  }

  static void openPlayerPage(BuildContext context) {
    if (!context.mounted || _isPlayerRoute(context)) {
      return;
    }
    _openPlayerIfNeeded(context);
  }

  static void _openPlayerIfNeeded(BuildContext context) {
    if (_playerRoutePushInFlight) {
      return;
    }

    _playerRoutePushInFlight = true;
    unawaited(context.push('/player'));
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        _playerRoutePushInFlight = false;
      }),
    );
  }

  static bool _isPlayerRoute(BuildContext context) {
    try {
      return GoRouterState.of(context).matchedLocation == '/player';
    } catch (_) {
      return false;
    }
  }
}
