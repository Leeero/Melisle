import 'dart:async';

import 'package:cross_platform_music_player/domain/entities/music_album.dart';
import 'package:cross_platform_music_player/domain/entities/music_artist.dart';
import 'package:cross_platform_music_player/domain/entities/music_playlist.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_cubit.dart';
import 'package:cross_platform_music_player/presentation/blocs/auth/auth_state.dart';
import 'package:cross_platform_music_player/presentation/blocs/library/library_state.dart';
import 'package:cross_platform_music_player/presentation/navigation/popup_route_coordinator.dart';
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
import 'package:cross_platform_music_player/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(AuthCubit authCubit) {
  final popupRouteCoordinator = PopupRouteCoordinator();
  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final isAuthenticated =
          authCubit.state.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';
      final isPending =
          authCubit.state.status == AuthStatus.unknown ||
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
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/history', redirect: (_, _) => '/home/history'),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(
          navigationShell: navigationShell,
          popupRouteCoordinator: popupRouteCoordinator,
        ),
        branches: [
          StatefulShellBranch(
            observers: [popupRouteCoordinator.createObserver()],
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    _shellPage(authCubit, state, const HomePage()),
                routes: [
                  GoRoute(
                    path: 'history',
                    pageBuilder: (context, state) =>
                        _shellPage(authCubit, state, const HistoryPage()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [popupRouteCoordinator.createObserver()],
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => _shellPage(
                  authCubit,
                  state,
                  SearchPage(initialQuery: state.uri.queryParameters['q']),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [popupRouteCoordinator.createObserver()],
            routes: [
              GoRoute(
                path: '/library',
                pageBuilder: (context, state) => _shellPage(
                  authCubit,
                  state,
                  LibraryPage(
                    initialFilter: _libraryFilterFromQuery(
                      state.uri.queryParameters['tab'],
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/album/:albumId',
                pageBuilder: (context, state) => _shellPage(
                  authCubit,
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
                  authCubit,
                  state,
                  ArtistDetailPage(
                    artistId: state.pathParameters['artistId']!,
                    artist: state.extra as MusicArtist?,
                  ),
                ),
              ),
              GoRoute(
                path: '/playlists',
                pageBuilder: (context, state) =>
                    _shellPage(authCubit, state, const PlaylistsPage()),
              ),
              GoRoute(
                path: '/playlists/:playlistId',
                pageBuilder: (context, state) => _shellPage(
                  authCubit,
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
            observers: [popupRouteCoordinator.createObserver()],
            routes: [
              GoRoute(
                path: '/favorites',
                pageBuilder: (context, state) =>
                    _shellPage(authCubit, state, const FavoritesPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            observers: [popupRouteCoordinator.createObserver()],
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) =>
                    _shellPage(authCubit, state, const SettingsPage()),
              ),
              GoRoute(
                path: '/settings/media-sources',
                pageBuilder: (context, state) => _shellPage(
                  authCubit,
                  state,
                  const CustomMediaSourcesPage(),
                ),
              ),
              GoRoute(
                path: '/downloads',
                pageBuilder: (context, state) =>
                    _shellPage(authCubit, state, const DownloadsPage()),
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
            transitionDuration: const Duration(milliseconds: 380),
            reverseTransitionDuration: const Duration(milliseconds: 260),
            child: const PlayerPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  final compact = AppBreakpoints.isCompactWidth(
                    MediaQuery.sizeOf(context).width,
                  );

                  if (!compact) {
                    return FadeTransition(
                      opacity: curved,
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.985,
                          end: 1,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  }

                  // 移动端：从底部滑入的全屏播放页转场。
                  final tween = Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  );
                  return SlideTransition(
                    position: tween.animate(curved),
                    child: child,
                  );
                },
          );
        },
      ),
    ],
  );
}

NoTransitionPage<void> _shellPage(
  AuthCubit authCubit,
  GoRouterState state,
  Widget child,
) {
  final sessionIdentity = identityHashCode(authCubit.state.session);
  return NoTransitionPage<void>(
    key: ValueKey('${state.pageKey.value}#$sessionIdentity'),
    child: child,
  );
}

LibraryFilter _libraryFilterFromQuery(String? tab) {
  return switch (tab) {
    'albums' => LibraryFilter.albums,
    'artists' => LibraryFilter.artists,
    'playlists' => LibraryFilter.playlists,
    _ => LibraryFilter.tracks,
  };
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
