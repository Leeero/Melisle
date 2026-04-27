# CODEBUDDY.md

This file provides guidance to CodeBuddy Code when working with code in this repository.

## Project Overview

A Flutter cross-platform music player for self-hosted music libraries, targeting Android, iOS, macOS, and Windows. UI-facing text is in Simplified Chinese, and the visual direction is dark-first and minimalist (see `design.md`).

The repository is structured so the app can support multiple backends behind one domain contract. `AppBootstrap` currently wires Emby and Subsonic/OpenSubsonic repositories behind auto-detection and caching. A WebDAV adapter exists in `lib/infrastructure/adapters/webdav/` but is not currently wired into the bootstrap path.

## Common Commands

```bash
# Install dependencies
flutter pub get

# Run locally
flutter run
flutter run -d macos
flutter run -d windows
flutter run -d ios
flutter run -d android

# Static analysis
flutter analyze

# Run tests
flutter test
flutter test test/widget_test.dart
flutter test --plain-name "renders login page when session is missing"

# Code generation (drift and other generators)
dart run build_runner build --delete-conflicting-outputs
dart run build_runner watch --delete-conflicting-outputs

# Platform builds
flutter build apk
flutter build ios
flutter build macos
flutter build windows
```

Dart SDK constraint: `^3.11.5` (see `pubspec.yaml`). Use a Flutter stable version compatible with that SDK.

## High-Level Architecture

The app follows a Clean-Architecture-style dependency flow under `lib/`:

```text
presentation → application → domain ← infrastructure
```

Do not reverse those arrows. In particular, do not import Flutter into `domain/`, and do not add backend-specific methods to `MusicRepository`.

```text
lib/
├── main.dart                         # Thin entrypoint; calls AppBootstrap.run()
├── bootstrap/                        # Composition root, router, bloc observer, desktop integration
├── domain/                           # Pure Dart entities and repository contracts
├── application/usecases/             # One use case class per operation
├── infrastructure/
│   ├── adapters/                     # Emby/Subsonic/WebDAV adapters + auto-detect + cache wrapper
│   ├── network/                      # Dio API clients
│   ├── audio/                        # audio_service + just_audio bridge, track resolving, sleep timer
│   ├── persistence/                  # Secure session storage, drift-backed settings repository
│   ├── database/                     # Drift database for local state such as history/download metadata
│   ├── cache/                        # Audio cache manager
│   └── media/                        # Custom media source / artwork / lyric resolving
├── presentation/
│   ├── blocs/                        # Cubits and immutable state per feature
│   ├── pages/                        # Route-level pages
│   ├── widgets/                      # Shared UI building blocks
│   └── utils/                        # UI/navigation helpers
└── shared/                           # App constants and theme
```

### Composition root and lifecycle

`lib/bootstrap/app.dart` is the one place that assembles long-lived dependencies. `AppBootstrap.run()` creates, in order:

1. `Dio`
2. `AuthSessionStore`
3. Backend repositories (`EmbyMusicRepository`, `SubsonicMusicRepository`)
4. `AutoDetectMusicRepository`
5. `CachedMusicRepository`
6. `AppDatabase`
7. `DriftSettingsRepository`
8. Global cubits such as `AppSettingsCubit`, `AuthCubit`, `PlayerCubit`, `FavoritesCubit`, and `DownloadsCubit`
9. `AudioPlayerHandler` through `AudioService.init()`
10. `DesktopIntegration`

`MusicPlayerApp` receives these instances via constructor injection, exposes them with `MultiRepositoryProvider` / `MultiBlocProvider`, and disposes the long-lived objects in `_MusicPlayerAppState.dispose()`.

### Repository chain and backend model

All app data goes through the domain-level `MusicRepository` contract in `lib/domain/repositories/music_repository.dart`.

The runtime repository chain is:

```text
CachedMusicRepository
  └── AutoDetectMusicRepository
        ├── EmbyMusicRepository
        └── SubsonicMusicRepository
```

Key implications:

- `AutoDetectMusicRepository` tries Subsonic/OpenSubsonic first, then Emby, on login and session restore.
- `CachedMusicRepository` adds in-memory caching on top of the active backend; login, logout, and favorite changes clear cache state.
- `MusicRepository` is intentionally backend-agnostic. New backend support should come from another adapter implementation, not new backend-specific domain methods.

### Routing model

`lib/bootstrap/router.dart` uses `GoRouter` with auth-gated redirects driven by `AuthCubit`.

Routes outside the shell:

- `/login`
- `/player`
- `/search`

Routes inside the shell (`AppShell`):

- `/home`
- `/favorites`
- `/history`
- `/library`
- `/album/:albumId`
- `/artist/:artistId`
- `/playlists`
- `/playlists/:playlistId`
- `/settings`
- `/downloads`

The router deliberately does **not** redirect while auth state is `unknown` or `loading`, so startup session restoration does not flash the login page.

### State management

This codebase uses `Cubit`, not event-based `Bloc` classes. Each feature keeps its cubit and state nearby under `lib/presentation/blocs/<feature>/`.

Global, app-wide cubits are created in the bootstrap layer and injected once. Route/page-specific cubits are created closer to the page that needs them.

Notable feature areas under `presentation/blocs/` include:

- `auth`
- `player`
- `home`
- `library`
- `album`
- `artist`
- `playlists`
- `favorites`
- `search`
- `history`
- `downloads`
- `settings`

### Playback architecture

Playback behavior is split across three layers:

- `PlayerCubit` in `lib/presentation/blocs/player/` owns the logical queue (`PlayQueue`), current index, loop/shuffle state, gap-between-tracks behavior, sleep timer, lyrics state, and playback reporting.
- `AudioPlayerHandler` in `lib/infrastructure/audio/audio_player_handler.dart` is the only system-facing playback bridge. It wraps `just_audio`, integrates with `audio_service`, and handles lock screen / notification / system media controls.
- `TrackResolver` resolves a `MusicTrack` into an `AudioSource`, preferring local downloaded media when available and otherwise asking `MusicRepository.getStreamUrl()` for a remote stream.

Important behavior: the handler loads one track at a time. Queue progression, next/previous, repeat, shuffle, and auto-advance policy all live in `PlayerCubit`, not in `just_audio` playlist primitives.

### Auth and persistence flow

Authentication state is managed by `AuthCubit` and persisted by `AuthSessionStore` using `flutter_secure_storage`.

Startup flow:

1. `AppBootstrap` creates `AuthCubit`.
2. `AuthCubit` immediately attempts `restore()`.
3. Repository restore chooses the active backend and returns an `AuthSession` when available.
4. The router reacts to auth state changes via `GoRouterRefreshStream`.

Local persistence is split by responsibility:

- `flutter_secure_storage` stores login session data.
- Drift (`lib/infrastructure/database/` and `lib/infrastructure/persistence/`) stores app settings and local playback/download-related state.

### Settings synchronization

`AppSettingsCubit` is loaded before the first frame so theme and default playback settings are ready at startup.

Settings updates are pushed into runtime systems from the bootstrap layer:

- default audio quality -> `PlayerCubit.setQuality(...)`
- gap between tracks -> `PlayerCubit.setGapBetweenTracks(...)`
- media-source-related settings -> `CustomMediaSourceResolver.updateSettings(...)`

### Desktop integration

Desktop-specific behavior lives in `lib/bootstrap/desktop_integration.dart` and is only active on macOS / Windows.

Current responsibilities include:

- tray menu integration
- media-key / hotkey integration
- Windows close-to-tray behavior
- syncing tray state with current playback state

### Testing notes

Current tests live in `test/widget_test.dart`.

Patterns worth following:

- Skip `AppBootstrap` in widget tests because it performs platform-specific setup.
- Construct `MusicPlayerApp` directly, or pump feature pages with the repositories/cubits they need.
- Use fake implementations of `MusicRepository` and `SettingsRepository`.
- Use `AppDatabase.forTesting(NativeDatabase.memory())` for local database state.
- UI assertions should use the real Simplified Chinese copy rendered by the app.

If you add methods to `MusicRepository` or `SettingsRepository`, update the test fakes in `test/widget_test.dart` so the test target still compiles.

## Working Conventions

- User-facing strings and error messages are Chinese.
- Code identifiers and most comments are English.
- Barrel exports are used heavily (`entities.dart`, `repositories.dart`, `adapters.dart`, `audio.dart`, `network.dart`, `blocs.dart`, `usecases.dart`); update the relevant barrel when adding a new file in those folders.
- Prefer extending existing layers and feature folders instead of creating parallel patterns.
