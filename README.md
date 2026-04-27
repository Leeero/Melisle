# 乐岛（Melisle）

> 听见每一份热爱。

`乐岛（Melisle）` 是一个面向 **自托管音乐库** 的 Flutter 跨平台播放器，目标平台包括 **Android、iOS、macOS、Windows**。项目聚焦于统一、克制、沉浸的音乐体验，目前以 **Emby** 为首个正式接入的后端，并为后续 **Subsonic / OpenSubsonic**、**WebDAV / NAS** 适配预留了完整架构扩展点。

## 项目状态

- **当前可用后端**：Emby
- **预留 / 开发中后端**：Subsonic / OpenSubsonic、WebDAV / NAS
- **UI 语言**：简体中文
- **设计方向**：暗色优先、极简、跨端统一

## 当前已实现能力

- Emby 账号登录与会话恢复
- 首页推荐、最近播放、常听内容
- 媒体库浏览：歌曲 / 专辑 / 艺术家 / 歌单
- 专辑、艺术家、歌单详情页
- 全局搜索
- 收藏、播放历史、下载记录
- 歌词获取与展示
- 播放队列、循环 / 随机、音质切换
- 基于 `audio_service` 的后台播放能力
- 桌面端窗口管理、托盘 / 热键扩展基础设施

## 技术栈

- **Flutter**
- **flutter_bloc**：状态管理
- **go_router**：路由
- **just_audio + audio_service**：播放内核与系统媒体能力
- **Dio**：网络请求
- **Drift**：本地数据库（设置、历史、搜索历史、下载记录等）
- **flutter_secure_storage**：安全存储登录会话

## 目录结构

```text
lib/
├── bootstrap/        # 应用启动、依赖组装、路由、桌面集成
├── domain/           # 领域实体与仓库契约
├── application/      # 用例层
├── infrastructure/   # Emby / 缓存 / 数据库 / 音频 / 持久化等实现
└── presentation/     # 页面、Cubit、组件
```

项目整体采用 **Clean Architecture 风格分层**，核心数据访问统一收敛到 `MusicRepository` 抽象，方便后续增加新的音乐服务后端而不撕裂 UI 和业务层。

## 开发环境

- Flutter Stable（需匹配 `pubspec.yaml` 中的 Dart SDK 约束）
- Dart SDK：`^3.11.5`
- macOS / Windows 桌面开发建议安装对应平台工具链

## 本地运行

```bash
flutter pub get
flutter run
```

按平台运行示例：

```bash
flutter run -d macos
flutter run -d windows
flutter run -d ios
flutter run -d android
```

## 常用命令

```bash
# 静态分析
flutter analyze

# 测试
flutter test

# 代码生成（项目已预留 drift / freezed / json_serializable）
dart run build_runner build --delete-conflicting-outputs

# 桌面 / 移动平台构建
flutter build macos
flutter build windows
flutter build apk
flutter build ios
```

## 自动构建与发布

仓库新增了基于 **`master` 分支 tag** 的 GitHub Actions 发布流程：

- **触发条件**：给 `master` 上的提交打 tag 并推送；工作流会校验该 tag 对应提交是否属于 `master` 历史
- **构建产物**：Android `.apk`、iOS 无签名 `.ipa`、macOS `.dmg`、Windows `.exe`
- **发布位置**：GitHub `Releases`
- **产物命名规则**：`melisle-平台-tag.后缀`
- **产物命名示例**：`melisle-android-v1.0.0.apk`、`melisle-ios-v1.0.0.ipa`

说明：

- 推荐发布方式：`git checkout master` 后执行 `git tag v1.0.0 && git push origin v1.0.0`。
- 如果 tag 名里包含 `/` 或其他不适合文件名的字符，工作流会自动替换为 `-` 后再生成产物文件名。
- iOS 产物会先执行 `flutter build ios --release --no-codesign`，再封装为 **无签名** `.ipa`，适合归档和后续再签名，不可直接作为已签名发行包使用。
- macOS 产物会封装为 `.dmg`，Windows 产物会封装为 `.exe` 安装包。
- 如果后续需要发布 **已签名 Android / iOS** 安装包，需要再补充证书、描述文件和 GitHub Secrets。

## 使用说明

当前默认登录入口为 **Emby**。你需要准备：

- 一个可访问的 Emby 服务地址
- 对应账号和密码

应用会将登录会话保存在本地安全存储中，以便下次启动时自动恢复。

## 设计文档

界面与视觉规范见：

- `design.md`

## 许可证

本项目采用 **PolyForm Noncommercial 1.0.0** 许可，并附带 `NOTICE` 声明。

这意味着：

- **允许**：个人学习、研究、非商用使用、非商用修改、非商用再分发
- **禁止**：任何商业用途（包括但不限于商业销售、商业 SaaS、企业营利性集成、付费部署）
- **二次改版要求**：基于本项目修改或再分发时，必须保留 `LICENSE` 与 `NOTICE`，并明确注明来源于 `乐岛（Melisle）` 项目

> 严格来说，带“禁止商用”限制的许可**不属于 OSI 定义下的开源许可证**，更准确地说，这是一个 **源码可见 / 源码可用（source-available）** 项目。

如果你需要商业使用，请联系项目维护者另行获得授权。
