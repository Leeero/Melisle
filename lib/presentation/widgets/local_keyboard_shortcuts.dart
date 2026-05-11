import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';

/// 在 App 窗口活跃期间捕获键盘快捷键.
///
/// 与平台原生全局热键不同，这里完全在 Dart 层实现，依赖 [KeyboardListener]，
/// 无第三方插件，没有 macOS 上的崩溃风险.
///
/// 限制：App 窗口不在前台或未聚焦时无法捕获。
class LocalKeyboardShortcuts extends StatefulWidget {
  const LocalKeyboardShortcuts({
    super.key,
    required this.playerCubit,
    required this.child,
  });

  final PlayerCubit playerCubit;
  final Widget child;

  @override
  State<LocalKeyboardShortcuts> createState() => _LocalKeyboardShortcutsState();
}

class _LocalKeyboardShortcutsState extends State<LocalKeyboardShortcuts> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handle(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final player = widget.playerCubit;
    final logical = event.logicalKey;
    final keyboard = HardwareKeyboard.instance;
    final isControlPressed = keyboard.isControlPressed;
    final hasModifier =
        isControlPressed || keyboard.isMetaPressed || keyboard.isAltPressed;

    // Ctrl+J / Ctrl+K — 歌词偏移
    if (isControlPressed) {
      if (logical == LogicalKeyboardKey.keyJ) {
        final offset = player.state.lyricSyncOffset;
        player.setLyricSyncOffset(offset - const Duration(milliseconds: 100));
        return;
      }
      if (logical == LogicalKeyboardKey.keyK) {
        final offset = player.state.lyricSyncOffset;
        player.setLyricSyncOffset(offset + const Duration(milliseconds: 100));
        return;
      }
    }

    // 无修饰键的基本播放控制
    if (!hasModifier) {
      if (logical == LogicalKeyboardKey.space) {
        player.togglePlayback();
        return;
      }
      if (logical == LogicalKeyboardKey.arrowRight) {
        player.next();
        return;
      }
      if (logical == LogicalKeyboardKey.arrowLeft) {
        player.previous();
        return;
      }
      if (logical == LogicalKeyboardKey.arrowUp) {
        final vol = (player.state.volume + 0.1).clamp(0.0, 1.0);
        player.setVolume(vol);
        return;
      }
      if (logical == LogicalKeyboardKey.arrowDown) {
        final vol = (player.state.volume - 0.1).clamp(0.0, 1.0);
        player.setVolume(vol);
        return;
      }
      if (logical == LogicalKeyboardKey.keyS) {
        player.toggleShuffle();
        return;
      }
      if (logical == LogicalKeyboardKey.keyR) {
        player.toggleLoopMode();
        return;
      }
      if (logical == LogicalKeyboardKey.keyL) {
        final modes = PlaybackModeOption.values;
        final idx =
            (modes.indexOf(player.state.playbackMode) + 1) % modes.length;
        player.setPlaybackMode(modes[idx]);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handle,
      child: widget.child,
    );
  }
}
