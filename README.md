# 乐岛（Melisle）

> 听见每一份热爱。

乐岛（Melisle）是一个使用 Flutter 构建的跨平台自托管音乐播放器，面向 Android、iOS、macOS 和 Windows。当前应用以统一的 `MusicRepository` 抽象接入远端音乐服务，并在本地维护设置、播放历史、搜索历史和离线下载记录。

## 当前状态

| 项目 | 状态 |
| --- | --- |
| 可运行平台 | Android / iOS / macOS / Windows |
| 当前可用后端 | Emby API、Navidrome / Subsonic API 兼容服务 |
| 登录方式 | 同一登录入口输入服务器、用户名、密码或 API Token，应用自动探测后端类型 |
| 未完成后端 | WebDAV / NAS 目前只有仓库骨架，尚未接入启动流程 |
| UI 语言 | 简体中文 |
| 许可证 | PolyForm Noncommercial 1.0.0，源码可见但禁止商用 |

## 已实现功能

- 账号登录、会话安全存储、启动时自动恢复登录态。
- 首页推荐，包括最新专辑、随机专辑、最近播放和常听内容。
- 媒体库浏览：歌曲、专辑、艺术家、歌单、收藏。
- 专辑详情、艺术家详情、歌单详情。
- 全局搜索，覆盖歌曲、专辑、艺术家和歌单，并记录本地搜索历史。
- 播放器：播放 / 暂停、上一曲 / 下一曲、进度拖动、音量、播放队列、队列重排、移除和清空。
- 播放模式：顺序播放、列表循环、单曲循环、随机播放。
- 在线音质：自动、无损、高品质 320K、标准 192K、省流 128K。
- 歌词：同步歌词展示、当前行高亮、歌词点击跳转、歌词偏移调节、自定义歌词来源。
- 封面：服务端封面展示、自定义封面来源、封面调色背景。
- 收藏歌曲 / 专辑 / 艺术家 / 歌单。
- 播放历史本地记录，并向后端汇报播放开始、进度和结束；Subsonic API 使用 scrobble。
- 离线下载：串行下载队列、进度展示、取消、删除、本地文件优先播放、自定义下载目录。
- 睡眠定时器：倒计时停止或本曲结束后停止。
- 设置：主题模式、默认音质、曲间间隔、自定义歌词与封面来源、下载管理。
- 系统播放能力：基于 `audio_service` 支持通知、锁屏和系统媒体控制。
- 桌面集成：macOS / Windows 窗口初始化、托盘菜单；Windows 支持全局快捷键和关闭后最小化到托盘。
- 应用内键盘快捷键：空格播放 / 暂停，方向键切歌和调音量，`S` 随机，`R` 循环，`L` 切换播放模式，`Ctrl+J/K` 调整歌词偏移。

## 技术栈

- Flutter / Dart
- `flutter_bloc`：页面和业务状态管理
- `go_router`：路由与登录态重定向
- `just_audio` + `audio_service`：播放内核、后台播放和系统媒体能力
- `dio`：Emby / Subsonic API 请求与离线文件下载
- `drift` + SQLite：播放历史、搜索历史、应用设置、下载记录
- `flutter_secure_storage`：登录会话安全存储
- `window_manager`、`tray_manager`、`hotkey_manager`：桌面窗口、托盘和快捷键
- `cached_network_image`、`palette_generator`：封面缓存与颜色提取

## 架构

项目按 Clean Architecture 风格分层：

```text
lib/
├── bootstrap/        # 应用启动、依赖组装、路由、桌面集成
├── domain/           # 领域实体、播放队列、歌词同步、仓库契约
├── application/      # 用例层
├── infrastructure/   # Emby / Subsonic 适配、缓存、数据库、音频、持久化
├── presentation/     # 页面、Cubit、组件
└── shared/           # 主题、常量、设计 token
```

核心约束：

- `MusicRepository` 保持后端无关。
- `presentation → application → domain ← infrastructure`，领域层不依赖 Flutter。
- 新后端应通过 infrastructure 适配 `MusicRepository`，不要把后端专有逻辑泄漏到 domain 或 presentation。

## 本地开发

环境要求：

- Flutter Stable，Dart SDK 需满足 `pubspec.yaml` 中的 `^3.11.5` 约束。
- macOS / Windows 桌面开发需要安装对应平台工具链。
- iOS 构建需要 Xcode；Android 构建需要 Android SDK。

安装依赖：

```bash
flutter pub get
```

运行：

```bash
flutter run
```

指定平台：

```bash
flutter run -d macos
flutter run -d windows
flutter run -d ios
flutter run -d android
```

## 开发登录

Debug 模式下可以用 dart-define 注入开发登录信息。先复制示例文件：

```bash
cp .env/dev_login.example.json .env/dev_login.json
```

填写 `.env/dev_login.json` 后运行：

```bash
flutter run -d macos --dart-define-from-file=.env/dev_login.json
```

支持的字段：

```json
{
  "MELISLE_DEV_LOGIN_ENABLED": true,
  "MELISLE_DEV_LOGIN_SERVER_URL": "https://music.example.com",
  "MELISLE_DEV_LOGIN_USERNAME": "your-username",
  "MELISLE_DEV_LOGIN_PASSWORD": "your-password-or-token"
}
```

`.env/*` 默认被 Git 忽略，`.env/*.example.json` 除外。不要提交真实服务器地址、账号、密码或 Token。

## 常用命令

```bash
# 静态分析
flutter analyze

# 全量测试
flutter test

# 单个测试文件
flutter test test/domain/entities/play_queue_test.dart

# 代码生成：修改 Drift 表或其他生成源后运行
dart run build_runner build --delete-conflicting-outputs

# 平台构建
flutter build apk
flutter build ios
flutter build macos
flutter build windows
```

## 发布流程

仓库包含 `.github/workflows/master-release.yml`，会在推送任意 tag 时触发发布构建，并校验该 tag 对应提交属于 `master` 历史。

当前工作流：

- 使用 Flutter `3.41.7`。
- 构建 Android `.apk`。
- 构建 iOS 无签名 `.ipa`，使用 `flutter build ios --release --no-codesign`。
- 构建 macOS `.dmg`。
- 构建 Windows `.exe` 安装包。
- 将产物发布到 GitHub Releases。

产物命名示例：

```text
melisle-android-v1.0.0.apk
melisle-ios-v1.0.0.ipa
melisle-macos-v1.0.0.dmg
melisle-windows-v1.0.0.exe
```

推荐发布方式：

```bash
git checkout master
git tag v1.0.0
git push origin v1.0.0
```

iOS 产物未签名，不能直接作为已签名发行包安装。若需要正式上架或企业分发，需要额外配置证书、描述文件和对应的 GitHub Secrets。

## 设计文档

- `design.md`：当前 UI 设计规范。

## 许可证

本项目采用 PolyForm Noncommercial 1.0.0，并附带 `NOTICE` 声明。

允许：

- 个人学习、研究、非商用使用。
- 非商用修改和非商用再分发。

禁止：

- 商业销售、商业 SaaS、企业营利性集成、付费部署等商业用途。

基于本项目修改或再分发时，必须保留 `LICENSE` 与 `NOTICE`，并明确注明来源于乐岛（Melisle）项目。

带有“禁止商用”限制的许可不属于 OSI 定义下的开源许可证。更准确地说，本项目是源码可见 / 源码可用（source-available）项目。
