import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';

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
    final isMetaPressed = keyboard.isMetaPressed;
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

    // Cmd/Ctrl + L — 跳转到播放页面
    if ((isMetaPressed || isControlPressed) && logical == LogicalKeyboardKey.keyL) {
      _navigateToPlayer();
      return;
    }

    // Cmd/Ctrl + , — 打开设置
    if ((isMetaPressed || isControlPressed) && logical == LogicalKeyboardKey.comma) {
      _navigateToSettings();
      return;
    }

    // Cmd/Ctrl + F — 打开搜索
    if ((isMetaPressed || isControlPressed) && logical == LogicalKeyboardKey.keyF) {
      _navigateToSearch();
      return;
    }

    // Cmd/Ctrl + M — 最小化窗口
    if ((isMetaPressed || isControlPressed) && logical == LogicalKeyboardKey.keyM) {
      _minimizeWindow();
      return;
    }

    // Cmd/Ctrl + Q — 退出应用
    if ((isMetaPressed || isControlPressed) && logical == LogicalKeyboardKey.keyQ) {
      _quitApp();
      return;
    }

    // 数字键 1-5 — 切换底部导航栏的 Tab
    if (!hasModifier) {
      final numKey = _getNumberKey(logical);
      if (numKey != null && numKey >= 1 && numKey <= 5) {
        _switchTab(numKey - 1);
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

  int? _getNumberKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.digit1) return 1;
    if (key == LogicalKeyboardKey.digit2) return 2;
    if (key == LogicalKeyboardKey.digit3) return 3;
    if (key == LogicalKeyboardKey.digit4) return 4;
    if (key == LogicalKeyboardKey.digit5) return 5;
    return null;
  }

  void _navigateToPlayer() {
    final context = _focusNode.context;
    if (context != null) {
      context.push('/player');
    }
  }

  void _navigateToSettings() {
    final context = _focusNode.context;
    if (context != null) {
      context.go('/settings');
    }
  }

  void _navigateToSearch() {
    final context = _focusNode.context;
    if (context != null) {
      context.go('/search');
    }
  }

  void _switchTab(int index) {
    final context = _focusNode.context;
    if (context == null) return;

    // 通过 GoRouter 切换 Tab
    final router = GoRouter.of(context);
    switch (index) {
      case 0:
        router.go('/home');
        break;
      case 1:
        router.go('/search');
        break;
      case 2:
        router.go('/library');
        break;
      case 3:
        router.go('/favorites');
        break;
      case 4:
        router.go('/settings');
        break;
    }
  }

  void _minimizeWindow() async {
    if (Platform.isMacOS || Platform.isWindows) {
      await windowManager.minimize();
    }
  }

  void _quitApp() async {
    if (Platform.isMacOS || Platform.isWindows) {
      await windowManager.setPreventClose(false);
      await windowManager.destroy();
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
