import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:cross_platform_music_player/application/usecases/fetch_playlists.dart';
import 'package:cross_platform_music_player/application/usecases/login_with_emby.dart';
import 'package:cross_platform_music_player/application/usecases/logout.dart';
import 'package:cross_platform_music_player/application/usecases/restore_session.dart';
import 'package:cross_platform_music_player/bootstrap/bloc_observer.dart';
import 'package:cross_platform_music_player/bootstrap/desktop_integration.dart';
import 'package:cross_platform_music_player/bootstrap/dev_login_environment.dart';
import 'package:cross_platform_music_player/bootstrap/router.dart';
import 'package:cross_platform_music_player/domain/repositories/music_repository.dart';
import 'package:cross_platform_music_player/domain/repositories/settings_repository.dart';
import 'package:cross_platform_music_player/presentation/widgets/local_keyboard_shortcuts.dart';
import 'package:cross_platform_music_player/infrastructure/adapters/adapters.dart';
import 'package:cross_platform_music_player/infrastructure/audio/audio_player_handler.dart';
import 'package:cross_platform_music_player/infrastructure/cache/audio_cache_manager.dart';
import 'package:cross_platform_music_player/infrastructure/database/app_database.dart';
import 'package:cross_platform_music_player/infrastructure/media/custom_media_source_resolver.dart';
import 'package:cross_platform_music_player/infrastructure/network/dio_debug_logging_interceptor.dart';
import 'package:cross_platform_music_player/infrastructure/network/emby_api_client.dart';
import 'package:cross_platform_music_player/infrastructure/network/subsonic_api_client.dart';
import 'package:cross_platform_music_player/infrastructure/persistence/auth_session_store.dart';
import 'package:cross_platform_music_player/infrastructure/persistence/drift_settings_repository.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/downloads/downloads_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/favorites/favorites_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/player/player_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/settings/app_settings_state.dart';
import 'package:cross_platform_music_player/shared/constants/app_constants.dart';
import 'package:cross_platform_music_player/shared/theme/app_theme.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

final class AppBootstrap {
  const AppBootstrap._();

  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _configureDesktopWindow();

    // Android / iOS: 全局 Edge-to-edge，让状态栏和导航栏透明。
    if (Platform.isAndroid || Platform.isIOS) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarContrastEnforced: false,
        ),
      );
    }

    Bloc.observer = const AppBlocObserver();

    final mediaSourceResolver = CustomMediaSourceResolver();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(const DioDebugLoggingInterceptor());
    }

    final sessionStore = AuthSessionStore(const FlutterSecureStorage());
    final remoteRepository = AutoDetectMusicRepository(
      embyRepository: EmbyMusicRepository(
        client: EmbyApiClient(dio),
        sessionStore: sessionStore,
        mediaSourceResolver: mediaSourceResolver,
      ),
      navidromeRepository: SubsonicMusicRepository(
        client: SubsonicApiClient(dio),
        sessionStore: sessionStore,
        mediaSourceResolver: mediaSourceResolver,
      ),
    );
    final repository = CachedMusicRepository(delegate: remoteRepository);

    // 本地数据库（播放历史、设置、搜索历史、下载记录）。
    final database = AppDatabase();
    final settingsRepository = DriftSettingsRepository(database);
    final settingsCubit = AppSettingsCubit(
      settingsRepository,
      mediaSourceResolver,
      clearTemporaryCache: repository.clearTemporaryCache,
    );
    // 先把设置读出来，让首帧就能用正确的主题 / 默认音质渲染。
    await settingsCubit.load();

    // 先声明应用播放的是持续性音乐，让系统建立正确的媒体音频会话和输出路由。
    // 必须早于 AudioPlayer 创建；否则 Darwin 平台可能出现时间轴推进但无声。
    final audioSession = await AudioSession.instance;
    await audioSession.configure(const AudioSessionConfiguration.music());

    // 初始化 audio_service —— 负责锁屏 / 通知 / NowPlaying / SMTC。
    final audioHandler = await AudioService.init(
      builder: () =>
          AudioPlayerHandler(mediaSourceResolver: mediaSourceResolver),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.leeero.melisle.audio',
        androidNotificationChannelName: '音乐播放',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );

    final playerCubit =
        PlayerCubit(
            repository: repository,
            controller: audioHandler,
            database: database,
          )
          ..setDefaultQuality(settingsCubit.state.defaultQuality)
          ..setGapBetweenTracks(settingsCubit.state.gapBetweenTracks)
          ..setLyricSyncOffset(settingsCubit.state.lyricSyncOffset);

    // 桌面端媒体键、托盘与菜单栏歌词（非桌面平台内部会 no-op）。
    final desktopIntegration = DesktopIntegration(
      playerCubit: playerCubit,
      menuBarLyricsEnabled: settingsCubit.state.menuBarLyricsEnabled,
    );

    // 设置变更时同步推到 PlayerCubit / DesktopIntegration。
    var previousSettings = settingsCubit.state;
    settingsCubit.stream.listen((s) {
      final lyricsSourceChanged =
          previousSettings.customLyricsSourceEnabled !=
              s.customLyricsSourceEnabled ||
          previousSettings.customLyricsSourceUrl != s.customLyricsSourceUrl;
      final defaultQualityChanged =
          previousSettings.defaultQuality != s.defaultQuality;

      if (defaultQualityChanged) {
        playerCubit.applyUserDefaultQuality(s.defaultQuality);
      } else {
        playerCubit.setDefaultQuality(s.defaultQuality);
      }
      playerCubit.setGapBetweenTracks(s.gapBetweenTracks);
      playerCubit.setLyricSyncOffset(s.lyricSyncOffset);
      desktopIntegration.setMenuBarLyricsEnabled(s.menuBarLyricsEnabled);
      if (lyricsSourceChanged) {
        unawaited(playerCubit.reloadLyricsForCurrent());
      }
      previousSettings = s;
    });

    final favoritesCubit = FavoritesCubit(repository);

    final downloadsCubit = DownloadsCubit(
      repository: repository,
      database: database,
      cacheManager: AudioCacheManager(),
    );
    await downloadsCubit.load();

    final authCubit = AuthCubit(
      loginWithEmby: LoginWithEmby(repository),
      restoreSession: RestoreSession(repository),
      logout: Logout(repository),
      fetchPlaylists: FetchPlaylists(repository),
      devLoginCredentials: DevLoginEnvironment.credentials(),
      clearSessionData: () async {
        Object? firstError;
        StackTrace? firstStackTrace;

        try {
          await playerCubit.clearQueue();
        } catch (error, stackTrace) {
          firstError = error;
          firstStackTrace = stackTrace;
        }

        favoritesCubit.reset();
        try {
          await database.clearSessionHistory();
        } catch (error, stackTrace) {
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        }

        if (firstError case final error?) {
          Error.throwWithStackTrace(error, firstStackTrace!);
        }
      },
    );

    unawaited(desktopIntegration.attach());

    runApp(
      MusicPlayerApp(
        repository: repository,
        settingsRepository: settingsRepository,
        mediaSourceResolver: mediaSourceResolver,
        database: database,
        authCubit: authCubit,
        playerCubit: playerCubit,
        settingsCubit: settingsCubit,
        favoritesCubit: favoritesCubit,
        downloadsCubit: downloadsCubit,
        desktopIntegration: desktopIntegration,
      ),
    );
  }

  static Future<void> _configureDesktopWindow() async {
    if (!Platform.isMacOS && !Platform.isWindows) {
      return;
    }

    await windowManager.ensureInitialized();
    final options = WindowOptions(
      size: const Size(1280, 820),
      minimumSize: const Size(1080, 680),
      center: true,
      title: AppConstants.appName,
      titleBarStyle: Platform.isMacOS
          ? TitleBarStyle.hidden
          : TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      if (Platform.isMacOS) {
        // 让 Flutter 内容延伸到标题栏区域，交通灯按钮叠在内容之上。
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: true,
        );
      }
      await windowManager.show();
      await windowManager.focus();
    });
  }
}

class MusicPlayerApp extends StatefulWidget {
  const MusicPlayerApp({
    super.key,
    required this.repository,
    required this.settingsRepository,
    required this.mediaSourceResolver,
    required this.database,
    required this.authCubit,
    required this.playerCubit,
    required this.settingsCubit,
    required this.favoritesCubit,
    required this.downloadsCubit,
    this.desktopIntegration,
  });

  final MusicRepository repository;
  final SettingsRepository settingsRepository;
  final CustomMediaSourceResolver mediaSourceResolver;
  final AppDatabase database;
  final AuthCubit authCubit;
  final PlayerCubit playerCubit;
  final AppSettingsCubit settingsCubit;
  final FavoritesCubit favoritesCubit;
  final DownloadsCubit downloadsCubit;
  final DesktopIntegration? desktopIntegration;

  @override
  State<MusicPlayerApp> createState() => _MusicPlayerAppState();
}

class _MusicPlayerAppState extends State<MusicPlayerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createRouter(widget.authCubit);
  }

  @override
  void dispose() {
    _router.dispose();
    widget.desktopIntegration?.dispose();
    widget.authCubit.close();
    widget.playerCubit.close();
    widget.settingsCubit.close();
    widget.favoritesCubit.close();
    widget.downloadsCubit.close();
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MusicRepository>.value(value: widget.repository),
        RepositoryProvider<SettingsRepository>.value(
          value: widget.settingsRepository,
        ),
        RepositoryProvider<CustomMediaSourceResolver>.value(
          value: widget.mediaSourceResolver,
        ),
        RepositoryProvider<AppDatabase>.value(value: widget.database),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: widget.authCubit),
          BlocProvider<PlayerCubit>.value(value: widget.playerCubit),
          BlocProvider<AppSettingsCubit>.value(value: widget.settingsCubit),
          BlocProvider<FavoritesCubit>.value(value: widget.favoritesCubit),
          BlocProvider<DownloadsCubit>.value(value: widget.downloadsCubit),
        ],
        child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
          buildWhen: (a, b) => a.themeMode != b.themeMode,
          builder: (context, settings) {
            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              themeMode: settings.themeMode,
              routerConfig: _router,
              builder: (context, child) => LocalKeyboardShortcuts(
                key: const ValueKey('global-keyboard-shortcuts-v2'),
                playerCubit: widget.playerCubit,
                router: _router,
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        ),
      ),
    );
  }
}
