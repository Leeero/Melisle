import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/pages/album/album_detail_page.dart';
import 'package:cross_platform_music_player/presentation/pages/artist/artist_detail_page.dart';
import 'package:cross_platform_music_player/presentation/pages/downloads/downloads_page.dart';
import 'package:cross_platform_music_player/presentation/pages/favorites/favorites_page.dart';
import 'package:cross_platform_music_player/presentation/pages/history/history_page.dart';
import 'package:cross_platform_music_player/presentation/pages/home/home_page.dart';
import 'package:cross_platform_music_player/presentation/pages/library/library_page.dart';
import 'package:cross_platform_music_player/presentation/pages/login/login_page.dart';
import 'package:cross_platform_music_player/presentation/pages/player/player_page.dart';
import 'package:cross_platform_music_player/presentation/pages/playlists/playlist_detail_page.dart';
import 'package:cross_platform_music_player/presentation/pages/playlists/playlists_page.dart';
import 'package:cross_platform_music_player/presentation/pages/search/search_page.dart';
import 'package:cross_platform_music_player/presentation/pages/settings/settings_page.dart';
import 'package:cross_platform_music_player/presentation/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final isAuthenticated = authCubit.state.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isPending = authCubit.state.status == AuthStatus.unknown ||
          authCubit.state.status == AuthStatus.loading;

      if (isPending) {
        return null;
      }
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      if (isAuthenticated && isLoginRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _shellPage(state, const HomePage()),
              ),
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) =>
                    _shellPage(state, const FavoritesPage()),
              ),
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) =>
                    _shellPage(state, const HistoryPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) =>
                    _shellPage(state, const LibraryPage()),
              ),
              GoRoute(
                path: '/album/:albumId',
                pageBuilder: (context, state) => _shellPage(
                  state,
                  AlbumDetailPage(
                    albumId: state.pathParameters['albumId']!,
                    album: state.extra as MusicAlbum?,
                  ),
                ),
              ),
              GoRoute(
                path: '/artist/:artistId',
                pageBuilder: (context, state) => _shellPage(
                  state,
                  ArtistDetailPage(
                    artistId: state.pathParameters['artistId']!,
                    artist: state.extra as MusicArtist?,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/playlists',
                pageBuilder: (context, state) =>
                    _shellPage(state, const PlaylistsPage()),
              ),
              GoRoute(
                path: '/playlists/:playlistId',
                pageBuilder: (context, state) => _shellPage(
                  state,
                  PlaylistDetailPage(
                    playlistId: state.pathParameters['playlistId']!,
                    playlist: state.extra as MusicPlaylist?,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    _shellPage(state, const SettingsPage()),
              ),
              GoRoute(
                path: '/downloads',
                pageBuilder: (context, state) =>
                    _shellPage(state, const DownloadsPage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/player',
        pageBuilder: (context, state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const PlayerPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // iOS/Android: 从底部滑入的 Material 风格转场。
              final tween = Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              );
              return SlideTransition(
                position: tween.animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => SearchPage(
          initialQuery: state.uri.queryParameters['q'],
        ),
      ),
    ],
  );
}

NoTransitionPage<void> _shellPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
