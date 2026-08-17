import 'dart:async';
import 'dart:io';

import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_view_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面端集成：全局媒体快捷键 + 系统托盘菜单 + 窗口行为 + macOS 菜单栏歌词。
///
/// 仅在 macOS / Windows 上启用；Linux 暂未适配，Android / iOS 跳过。
/// 生命周期：[attach] 时绑定；[dispose] 时解绑。
///
/// 关闭按钮行为（macOS + Windows）：点击关闭按钮 → 隐藏窗口，
/// 播放继续后台运行。通过托盘菜单"退出"或 Cmd+Q / Alt+F4 才真正退出。
class DesktopIntegration
    with TrayListener, WindowListener, WidgetsBindingObserver {
  DesktopIntegration({
    required this.playerCubit,
    bool menuBarLyricsEnabled = true,
  }) : _menuBarLyricsEnabled = menuBarLyricsEnabled;

  final PlayerCubit playerCubit;

  StreamSubscription<PlayerViewState>? _stateSub;
  bool _attached = false;
  bool _trayReady = false;
  bool _menuBarReady = false;
  bool _menuBarLyricsEnabled;
  String? _lastTrackId;
  String? _lastTitle;
  String? _lastArtistName;
  bool? _lastPlaying;
  String? _lastDesktopStatusText;

  /// macOS 菜单栏 MethodChannel。
  static const _menuBarChannel = MethodChannel('com.melisle/menu_bar');

  static bool get _isSupported => Platform.isMacOS || Platform.isWindows;

  void setMenuBarLyricsEnabled(bool enabled) {
    if (_menuBarLyricsEnabled == enabled) return;
    _menuBarLyricsEnabled = enabled;
    _lastDesktopStatusText = null;

    if (!enabled) {
      if (Platform.isMacOS) {
        _ignoreDesktopUpdate(_disposeMenuBar());
      } else if (Platform.isWindows) {
        final text = _trackStatusText(playerCubit.state) ?? '乐岛';
        _ignoreDesktopUpdate(trayManager.setToolTip(text));
        _ignoreDesktopUpdate(_rebuildMenu());
      }
      return;
    }

    _updateDesktopStatusFromState(playerCubit.state);
    _ignoreDesktopUpdate(_rebuildMenu());
  }

  /// 接入桌面集成。首帧渲染后调用，保证窗口句柄已就绪。
  Future<void> attach() async {
    if (!_isSupported || _attached) return;
    _attached = true;

    // macOS / Windows: 拦截关闭事件，改为隐藏窗口而非退出。
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

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

    if (Platform.isMacOS && _menuBarLyricsEnabled) {
      try {
        await _initMenuBar();
      } catch (error, stack) {
        debugPrint('DesktopIntegration: 菜单栏初始化失败：$error\n$stack');
      }
    }

    WidgetsBinding.instance.addObserver(this);
    _stateSub = playerCubit.stream.listen(_onPlayerState);
    _onPlayerState(playerCubit.state);
  }

  Future<void> dispose() async {
    if (!_isSupported) return;
    WidgetsBinding.instance.removeObserver(this);
    await _stateSub?.cancel();
    _stateSub = null;

    windowManager.removeListener(this);

    try {
      trayManager.removeListener(this);
      await trayManager.destroy();
      _trayReady = false;
    } catch (_) {
      // ignore
    }

    try {
      await hotKeyManager.unregisterAll();
    } catch (_) {
      // ignore
    }

    if (Platform.isMacOS) {
      try {
        await _disposeMenuBar();
      } catch (_) {
        // ignore
      }
    }

    _attached = false;
  }

  // --- Menu Bar (macOS) ---

  Future<void> _initMenuBar() async {
    if (_menuBarReady) return;
    await _menuBarChannel.invokeMethod('init');
    _menuBarReady = true;

    // 监听菜单栏点击事件。
    _menuBarChannel.setMethodCallHandler((call) async {
      if (call.method == 'onMenuBarClicked') {
        windowManager.show();
        windowManager.focus();
      }
    });
  }

  Future<void> _updateMenuBarTrackInfo(String title, String? artist) async {
    if (!_menuBarReady) await _initMenuBar();
    await _menuBarChannel.invokeMethod('updateTrackInfo', {
      'title': title,
      'artist': artist,
    });
  }

  Future<void> _updateMenuBarLyric(String text) async {
    if (!_menuBarReady) await _initMenuBar();
    await _menuBarChannel.invokeMethod('updateLyric', {'text': text});
  }

  Future<void> _clearMenuBar() async {
    if (!_menuBarReady) return;
    await _menuBarChannel.invokeMethod('clear');
  }

  Future<void> _disposeMenuBar() async {
    if (!_menuBarReady) return;
    await _menuBarChannel.invokeMethod('dispose');
    _menuBarReady = false;
    _lastDesktopStatusText = null;
  }

  // --- Hotkeys ---

  Future<void> _registerHotkeys() async {
    // macOS: hotkey_manager 的 Swift 层在注册任意普通键时触发 NSNull/NSArray 崩溃，
    // 连 try/catch 都无法拦截；媒体键走 audio_service → MPRemoteCommandCenter。
    // Linux: hotkey_manager 暂未适配。完全跳过这两个平台。
    if (!Platform.isWindows) return;

    // 仅注册系统媒体键。普通输入键会和 Flutter 的文本输入事件流竞争，
    // 使 HardwareKeyboard 的按键状态失同步；应用内快捷键由
    // LocalKeyboardShortcuts 在非输入焦点时处理。
    final bindings = <HotKey, Future<void> Function()>{
      // --- Windows 专用媒体键 ---
      HotKey(key: PhysicalKeyboardKey.mediaPlayPause):
          playerCubit.togglePlayback,
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
    _trayReady = true;
    await trayManager.setToolTip('跨平台音乐播放器');
    await _rebuildMenu();
  }

  Future<void> _rebuildMenu() async {
    if (!_trayReady) return;

    final state = playerCubit.state;
    final titleLabel =
        (_menuBarLyricsEnabled
            ? _desktopStatusText(state)
            : _trackStatusText(state)) ??
        '当前没有播放';

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
    final track = state.currentTrack;
    final trackChanged =
        track?.id != _lastTrackId ||
        track?.title != _lastTitle ||
        track?.artistName != _lastArtistName;
    final playingChanged = state.isPlaying != _lastPlaying;

    if (trackChanged || playingChanged) {
      _lastTrackId = track?.id;
      _lastTitle = track?.title;
      _lastArtistName = track?.artistName;
      _lastPlaying = state.isPlaying;
      _ignoreDesktopUpdate(_rebuildMenu());
    }

    if (_menuBarLyricsEnabled && (Platform.isMacOS || Platform.isWindows)) {
      _updateDesktopStatusFromState(state);
    }
  }

  /// Updates the desktop now-playing surface from the player state.
  void _updateDesktopStatusFromState(PlayerViewState state) {
    final text = _desktopStatusText(state);
    if (text == _lastDesktopStatusText) return;
    _lastDesktopStatusText = text;

    if (text == null) {
      if (Platform.isMacOS) {
        _ignoreDesktopUpdate(_clearMenuBar());
      } else if (Platform.isWindows) {
        _ignoreDesktopUpdate(trayManager.setToolTip('乐岛'));
        _ignoreDesktopUpdate(_rebuildMenu());
      }
      return;
    }

    if (Platform.isMacOS) {
      final lyricText = _currentLyricText(state);
      if (lyricText != null) {
        _ignoreDesktopUpdate(_updateMenuBarLyric(lyricText));
      } else {
        final track = state.currentTrack;
        if (track != null) {
          _ignoreDesktopUpdate(
            _updateMenuBarTrackInfo(track.title, track.artistName),
          );
        }
      }
    } else if (Platform.isWindows) {
      _ignoreDesktopUpdate(trayManager.setToolTip(text));
      _ignoreDesktopUpdate(_rebuildMenu());
    }
  }

  String? _desktopStatusText(PlayerViewState state) {
    final track = state.currentTrack;
    if (track == null) return null;

    final lyricText = _currentLyricText(state);
    if (lyricText != null) return lyricText;

    return _trackStatusText(state);
  }

  String? _trackStatusText(PlayerViewState state) {
    final track = state.currentTrack;
    if (track == null) return null;

    final artist = track.artistName.trim();
    return artist.isEmpty ? track.title : '${track.title} — $artist';
  }

  String? _currentLyricText(PlayerViewState state) {
    final currentLyricIndex = state.currentLyricIndex;
    final lyrics = state.lyrics;
    if (currentLyricIndex != null &&
        currentLyricIndex >= 0 &&
        currentLyricIndex < lyrics.length) {
      final text = lyrics[currentLyricIndex].text.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  void _ignoreDesktopUpdate(Future<void> future) {
    unawaited(
      future.catchError((Object error, StackTrace stack) {
        debugPrint('DesktopIntegration: 桌面状态更新失败：$error\n$stack');
      }),
    );
  }

  @override
  void onTrayIconMouseDown() {
    // 点击菜单栏托盘图标 → 显示主窗口。
    windowManager.show();
    windowManager.focus();
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

  // --- App lifecycle: show window on resume ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      windowManager.show();
    }
  }

  // --- Window close interception: hide to background ---

  @override
  void onWindowClose() async {
    // 点击关闭按钮 → 隐藏窗口而非退出，播放继续后台运行。
    await windowManager.hide();
  }

  /// 真正退出应用。解除关闭拦截后执行 destroy。
  Future<void> _forceQuit() async {
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }
}
