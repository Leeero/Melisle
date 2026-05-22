# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

**Melisle (乐岛)** — a Flutter cross-platform music player for self-hosted music libraries. Targets Android, iOS, macOS, and Windows. Currently supports **Emby** and **Subsonic/Navidrome** backends, with WebDAV/NAS reserved for future implementation. UI language is **Simplified Chinese**.

## Common Commands

```bash
flutter pub get                # Install dependencies
flutter run -d <platform>     # Run on macos/windows/ios/android
flutter analyze                # Static analysis
flutter test                   # Run all tests
flutter test test/domain/entities/play_queue_test.dart  # Run single test file
flutter test --plain-name "test name"                   # Run single test by name
dart run build_runner build --delete-conflicting-outputs # Code generation (drift/freezed/json_serializable)
dart format lib/               # Format code
```

### Build for release

```bash
flutter build macos
flutter build windows
flutter build apk
flutter build ios
```

Release is automated via GitHub Actions on `master` branch tags (`git tag v1.0.0 && git push origin v1.0.0`).

## Architecture

Clean Architecture with strict layer separation. Dependency flow: `presentation → application → domain ← infrastructure`.

```
lib/
├── main.dart                  # Entry: delegates to AppBootstrap.run()
├── bootstrap/                 # Composition root (DI, routing, desktop integration)
├── domain/                    # Pure Dart — entities + repository contracts
│   ├── entities/              # MusicTrack, MusicAlbum, MusicArtist, MusicPlaylist, AuthSession, etc.
│   └── repositories/          # MusicRepository (abstract), SettingsRepository (abstract)
├── application/usecases/      # One class per business operation (LoginWithEmby, RestoreSession, etc.)
├── infrastructure/            # Concrete implementations
│   ├── adapters/              # MusicRepository implementations (see below)
│   ├── network/               # EmbyApiClient, SubsonicApiClient (Dio-based)
│   ├── persistence/           # AuthSessionStore (flutter_secure_storage), DriftSettingsRepository
│   ├── database/              # Drift database (history, settings, search history, downloads)
│   ├── audio/                 # AudioPlayerHandler (just_audio + audio_service), SleepTimer
│   ├── cache/                 # AudioCacheManager
│   └── media/                 # CustomMediaSourceResolver
├── presentation/
│   ├── blocs/                 # Cubit + State per feature (auth, player, settings, home, library, etc.)
│   ├── pages/                 # One directory per route
│   └── widgets/               # Shared UI components (AppShell, MiniPlayerBar, QueueSheet, etc.)
└── shared/
    ├── constants/             # AppConstants
    └── theme/                 # AppTheme, AppTokens, AppBreakpoints, AppMotion
```

### Key Architectural Patterns

**Repository chain (adapters):** `CachedMusicRepository` → `AutoDetectMusicRepository` → `EmbyMusicRepository` | `SubsonicMusicRepository`. `AutoDetectMusicRepository` probes Navidrome first, then Emby during login, and remembers the active backend for the session.

**Composition root:** `AppBootstrap.run()` in `lib/bootstrap/app.dart` creates all dependencies, wires Cubits, initializes audio_service, and calls `runApp()`. Lifecycle cleanup happens in `_MusicPlayerAppState.dispose()`.

**State management:** Cubit-only (no Bloc events). States are immutable with `copyWith`. Cubits are created in `AppBootstrap` and injected via `MultiBlocProvider`/`MultiRepositoryProvider`.

**Routing:** `go_router` with `ShellRoute` for the main layout. Auth-gated redirect via `GoRouterRefreshStream` listening to `AuthCubit`. Layout switches between desktop sidebar (>1080px) and mobile bottom nav (≤1080px) in `AppShell`.

**Settings sync:** `AppSettingsCubit` stream is listened to in bootstrap to push quality/gap/lyric-offset changes to `PlayerCubit`.

## Critical Constraints

- **MusicRepository is backend-agnostic.** Never add backend-specific methods to the abstract interface. Backend-specific logic stays inside the adapter.
- **Domain layer has zero Flutter imports.** Entities are pure Dart with `const` constructors and `copyWith`.
- **No reverse dependencies.** Domain must not import infrastructure or presentation. Infrastructure must not import presentation.
- **No `print()`.** Use `talker_flutter` for logging.
- **Comments in English, user-facing strings in Chinese.**

## Naming Conventions

| Type | Pattern | Example |
|------|---------|---------|
| Entity | `Music<Type>` | `MusicTrack`, `MusicAlbum` |
| Repository interface | `<Domain>Repository` | `MusicRepository` |
| Use case | `<Action>` or `<ActionWithTarget>` | `LoginWithEmby`, `FetchAlbumTracks` |
| State | `<Feature>State` | `PlayerState`, `AuthState` |
| Cubit | `<Feature>Cubit` | `PlayerCubit`, `AuthCubit` |
| Test file | `<module>_test.dart` | `play_queue_test.dart` |

## Commits

Conventional Commits format: `<type>(<scope>): <subject>`. Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `perf`. Scopes: `player`, `auth`, `library`, `ui`, `network`, `repository`, `settings`.

## Testing

Tests use Fake implementations of `MusicRepository` (not mocks). Test structure follows AAA pattern (Arrange-Act-Assert). UI tests wrap widgets with `BlocProvider` and `MaterialApp`.

```bash
flutter test                              # All tests
flutter test test/<path>_test.dart        # Single file
flutter test --plain-name "test name"     # Single test
flutter test --coverage                   # With coverage
```

## Adding a New Backend

1. Create adapter directory: `lib/infrastructure/adapters/<backend>/`
2. Implement `MusicRepository` interface
3. Create corresponding API client in `lib/infrastructure/network/`
4. Register in `AutoDetectMusicRepository` and `AppBootstrap`

## Language & Interaction

- 回复和用户可见输出使用**简体中文**。
- Code identifiers, commit messages, and code comments in English.
- UI 改动须先读取 `design.md` 设计规范。
- 当用户要求执行功能开发、Bug 修复或代码审查时，使用项目工作流命令：`/project:harness`、`/project:feature`、`/project:bugfix`、`/project:review`。

## Knowledge Base (Reference on Demand)

以下知识库文档包含详细的项目知识，**按需读取**，不要一次性全部加载：

| 文档 | 何时读取 | 路径 |
|------|---------|------|
| 架构详情 | 设计新功能、跨模块变更 | `.codebuddy/knowledge/architecture.md` |
| 编码约定 | 实现代码、风格问题 | `.codebuddy/knowledge/conventions.md` |
| 实体定义 | 修改领域模型 | `.codebuddy/knowledge/entities.md` |
| API 契约 | 修改 MusicRepository 或 adapter | `.codebuddy/knowledge/api-contracts.md` |
| PRD 功能清单 | 需求分析、范围决策 | `.codebuddy/knowledge/prd.md` |
| 版本路线图 | 版本规划、优先级 | `.codebuddy/knowledge/roadmap.md` |
| 设计规范 | UI/UX 变更 | `design.md` |

更深层的架构、播放、认证、路由和测试实现细节见 `CODEBUDDY.md`。

## Workflow System

本项目配备完整的工作流系统，通过自定义命令触发：

| 命令 | 用途 |
|------|------|
| `/project:harness <任务>` | 主入口 — 自动识别任务类型并路由到对应工作流 |
| `/project:feature <功能>` | 功能开发（6阶段：需求→架构→实现→测试→审查→提交） |
| `/project:bugfix <问题>` | Bug 修复（6阶段：分析→定位→修复→回归→审查→提交） |
| `/project:review [范围]` | 代码审查（6阶段：检查→架构→测试→文档→安全→报告） |
| `/project:ui-design <任务>` | UI/UX 设计指导（基于 design.md 规范） |
| `/project:prd <需求>` | 产品需求分析与 PRD 编写 |

### Workflow Execution Rules

执行非平凡任务（功能开发、Bug 修复、重构、代码审查）时遵循：

1. **计划先行**：多文件或架构变更，先展示计划等待批准
2. **阶段推进**：按工作流阶段顺序执行，不跳过阶段
3. **验证后提交**：实施后运行 `flutter analyze` 和相关 `flutter test`
4. **最小改动**：只做任务需要的改动，不额外重构
5. **任务追踪**：使用 TaskCreate/TaskUpdate 显示阶段进度

## Role Behaviors

执行工作流阶段时，采用对应角色的思维模式：

- **架构师**：关注 Clean Architecture 合规、接口契约、依赖流向、影响分析。参考 `.codebuddy/rules/architecture.md`。
- **开发者**：最小必要改动，先读相关文件再改，遵循编码风格，analyze/test 验证。
- **测试者**：设计覆盖关键路径的测试，使用 Fake 实现，AAA 模式，验证覆盖率。参考 `.codebuddy/rules/testing.md`。
- **审查员**：检查架构边界、MusicRepository 纯净、安全问题、测试覆盖、文档完整。按严重程度分级输出（Critical → Major → Minor → Suggestion）。
- **产品经理**：从用户目标和现有代码倒推需求，定义验收标准，结合自托管场景（不照搬竞品）。

## Extended Coding Rules

（补充 Critical Constraints 部分）

### Import Order
1. Dart core (`dart:async`, `dart:io`)
2. Flutter SDK (`package:flutter/...`)
3. Third-party packages (`package:dio/...`, `package:flutter_bloc/...`)
4. Project internal (`package:cross_platform_music_player/...`)

### State Classes
- Cubit（非 Bloc events），状态使用 `copyWith` 不可变更新
- 所有字段 `final`
- 状态枚举定义加载状态：`idle`, `loading`, `loaded`/`playing`, `error`

### Error Handling
- 使用类型化异常：`AuthError`, `NetworkError`, `NotFoundError`
- Cubit 中 catch 具体异常类型，emit 带中文错误信息的 error 状态
- 不静默吞掉异常

### Barrel Files
- 在以下目录添加新文件时更新对应 barrel export：`entities/`, `repositories/`, `usecases/`, `blocs/`, `adapters/`, `network/`, `audio/`

### Pre-commit Checklist
提交前验证：
- `dart format lib/` 通过
- `flutter analyze` 无 error
- 相关测试通过
- 无反向依赖引入
- MusicRepository 未被后端特定方法污染
- 提交信息遵循 `<type>(<scope>): <subject>` 格式
