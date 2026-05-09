import 'dart:async';
import 'dart:io';

import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面端集成：全局媒体快捷键 + 系统托盘菜单 + 窗口行为。
///
/// 仅在 macOS / Windows 上启用；Linux 暂未适配，Android / iOS 跳过。
/// 生命周期：[attach] 时绑定；[dispose] 时解绑。
///
/// Windows 特殊行为：点击关闭按钮默认最小化到托盘而非退出应用，
/// 通过托盘菜单"退出"才真正退出。
class DesktopIntegration with TrayListener, WindowListener {
  DesktopIntegration({required this.playerCubit});

  final PlayerCubit playerCubit;

  StreamSubscription<PlayerViewState>? _stateSub;
  bool _attached = false;
  String? _lastTitle;
  bool? _lastPlaying;

  static bool get _isSupported => Platform.isMacOS || Platform.isWindows;

  /// 接入桌面集成。首帧渲染后调用，保证窗口句柄已就绪。
  Future<void> attach() async {
    if (!_isSupported || _attached) return;
    _attached = true;

    // Windows: 拦截关闭事件，改为隐藏到托盘。
    if (Platform.isWindows) {
      windowManager.addListener(this);
      await windowManager.setPreventClose(true);
    }

    try {
      await _registerHotkeys();
    } catch (error, stack) {
      debugPrint('DesktopIntegration: 快捷键注册失败：$error\n$stack');
    }

    try {
      await _setupTray();
      trayManager.addListener(this);
    } catch (error, stack) {
      debugPrint('DesktopIntegration: 托盘初始化失败：$error\n$stack');
    }

    _stateSub = playerCubit.stream.listen(_onPlayerState);
    _onPlayerState(playerCubit.state);
  }

  Future<void> dispose() async {
    if (!_isSupported) return;
    await _stateSub?.cancel();
    _stateSub = null;

    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }

    try {
      trayManager.removeListener(this);
      await trayManager.destroy();
    } catch (_) {
      // ignore
    }

    try {
      await hotKeyManager.unregisterAll();
    } catch (_) {
      // ignore
    }

    _attached = false;
  }

  // --- Hotkeys ---

  Future<void> _registerHotkeys() async {
    // macOS: hotkey_manager 的 Swift 层在注册任意普通键时触发 NSNull/NSArray 崩溃，
    // 连 try/catch 都无法拦截；媒体键走 audio_service → MPRemoteCommandCenter。
    // Linux: hotkey_manager 暂未适配。完全跳过这两个平台。
    if (!Platform.isWindows) return;

    // Windows: media keys + 普通键均可走 hotkey_manager。
    final bindings = <HotKey, Future<void> Function()>{
      // --- 播放控制 ---
      HotKey(key: PhysicalKeyboardKey.mediaPlayPause):
          playerCubit.togglePlayback,
      HotKey(key: PhysicalKeyboardKey.space): playerCubit.togglePlayback,

      // --- 切歌 ---
      HotKey(key: PhysicalKeyboardKey.arrowRight): playerCubit.next,
      HotKey(key: PhysicalKeyboardKey.arrowLeft): playerCubit.previous,

      // --- 音量调节（步进 10%） ---
      HotKey(key: PhysicalKeyboardKey.arrowUp): () async {
        final vol = (playerCubit.state.volume + 0.1).clamp(0.0, 1.0);
        await playerCubit.setVolume(vol);
      },
      HotKey(key: PhysicalKeyboardKey.arrowDown): () async {
        final vol = (playerCubit.state.volume - 0.1).clamp(0.0, 1.0);
        await playerCubit.setVolume(vol);
      },

      // --- 随机 / 循环 ---
      HotKey(key: PhysicalKeyboardKey.keyS): playerCubit.toggleShuffle,
      HotKey(key: PhysicalKeyboardKey.keyR): playerCubit.toggleLoopMode,
      HotKey(key: PhysicalKeyboardKey.keyL): () async {
        final modes = PlaybackModeOption.values;
        final idx = (modes.indexOf(playerCubit.state.playbackMode) + 1) %
            modes.length;
        await playerCubit.setPlaybackMode(modes[idx]);
      },

      // --- 歌词偏移微调（每次 ±100ms） ---
      HotKey(
        key: PhysicalKeyboardKey.keyK,
        modifiers: [HotKeyModifier.control],
      ): () async {
        final current = playerCubit.state.lyricSyncOffset;
        playerCubit.setLyricSyncOffset(
          current + const Duration(milliseconds: 100),
        );
      },
      HotKey(
        key: PhysicalKeyboardKey.keyJ,
        modifiers: [HotKeyModifier.control],
      ): () async {
        final current = playerCubit.state.lyricSyncOffset;
        playerCubit.setLyricSyncOffset(
          current - const Duration(milliseconds: 100),
        );
      },

      // --- Windows 专用媒体键 ---
      HotKey(key: PhysicalKeyboardKey.mediaTrackNext): playerCubit.next,
      HotKey(key: PhysicalKeyboardKey.mediaTrackPrevious): playerCubit.previous,
    };

    for (final entry in bindings.entries) {
      try {
        await hotKeyManager.register(
          entry.key,
          keyDownHandler: (_) {
            entry.value();
          },
        );
      } catch (error) {
        debugPrint('DesktopIntegration: 跳过快捷键 ${entry.key.key}：$error');
      }
    }
  }

  // --- Tray ---

  Future<void> _setupTray() async {
    // 托盘图标：
    //   - macOS: tray.png 为 22pt @2x 模板图（黑色 + 透明），系统会根据菜单栏主题自动反色。
    //   - Windows: tray.ico 内嵌 16/24/32/48 多尺寸白色图标，适配深色任务栏。
    // 若资源意外缺失（例如 flutter clean 后未重新 build），降级跳过托盘以免阻塞启动。
    try {
      await trayManager.setIcon(
        Platform.isWindows ? 'assets/icons/tray.ico' : 'assets/icons/tray.png',
        isTemplate: !Platform.isWindows,
      );
    } catch (error) {
      debugPrint('DesktopIntegration: 托盘图标加载失败，跳过托盘 —— $error');
      return;
    }
    await trayManager.setToolTip('跨平台音乐播放器');
    await _rebuildMenu();
  }

  Future<void> _rebuildMenu() async {
    final state = playerCubit.state;
    final track = state.currentTrack;
    final titleLabel = track == null
        ? '当前没有播放'
        : '${track.title} — ${track.artistName}';

    final menu = Menu(
      items: [
        MenuItem(key: 'now_playing', label: titleLabel, disabled: true),
        MenuItem.separator(),
        MenuItem(key: 'play_pause', label: state.isPlaying ? '暂停' : '播放'),
        MenuItem(key: 'next', label: '下一曲'),
        MenuItem(key: 'previous', label: '上一曲'),
        MenuItem.separator(),
        MenuItem(key: 'show', label: '显示主窗口'),
        MenuItem(key: 'quit', label: '退出'),
      ],
    );
    await trayManager.setContextMenu(menu);
  }

  void _onPlayerState(PlayerViewState state) {
    final titleChanged = state.currentTrack?.title != _lastTitle;
    final playingChanged = state.isPlaying != _lastPlaying;
    if (!titleChanged && !playingChanged) return;

    _lastTitle = state.currentTrack?.title;
    _lastPlaying = state.isPlaying;
    _rebuildMenu();
  }

  @override
  void onTrayIconMouseDown() {
    // 点击托盘图标：macOS 为右键出菜单，Windows 通常左键打开。
    if (Platform.isWindows) {
      windowManager.show();
      windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'play_pause':
        playerCubit.togglePlayback();
        break;
      case 'next':
        playerCubit.next();
        break;
      case 'previous':
        playerCubit.previous();
        break;
      case 'show':
        windowManager.show();
        windowManager.focus();
        break;
      case 'quit':
        _forceQuit();
        break;
    }
  }

  // --- Window close interception (Windows: minimize to tray) ---

  @override
  void onWindowClose() async {
    // Windows: 点击关闭按钮 → 隐藏到托盘而非退出。
    if (Platform.isWindows) {
      await windowManager.hide();
    }
  }

  /// 真正退出应用。解除关闭拦截后执行 destroy。
  Future<void> _forceQuit() async {
    if (Platform.isWindows) {
      await windowManager.setPreventClose(false);
    }
    await windowManager.destroy();
  }
}
