# 贡献指南

感谢你愿意参与乐岛（Melisle）。这个项目面向自托管音乐库用户，欢迎反馈问题、补充后端适配、改进播放体验和完善跨端 UI。

## 反馈问题

提交 issue 前，建议先确认：

- 你使用的客户端版本、平台和系统版本。
- 你的音乐服务类型，例如 Emby、Navidrome 或其他 Subsonic API 兼容服务。
- 问题是否可以稳定复现。
- 是否存在相关日志、截图或录屏。

请不要在 issue 中公开真实服务器地址、账号、密码、API Token、访问令牌或私有音乐库内容。

## 开发环境

```bash
flutter pub get
flutter run
```

指定平台运行：

```bash
flutter run -d macos
flutter run -d android
flutter run -d ios
flutter run -d windows
```

Debug 模式可参考 `.env/dev_login.example.json` 使用 `--dart-define-from-file` 注入开发登录信息。真实配置应放在 `.env/dev_login.json`，不要提交到仓库。

## 提交前检查

请尽量运行与变更相关的测试：

```bash
flutter test
flutter analyze
```

如果修改了 Drift 表或生成相关代码，请运行：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 架构约束

项目遵循 Clean Architecture 风格：

```text
presentation -> application -> domain <- infrastructure
```

关键约束：

- `domain/` 不依赖 Flutter。
- `MusicRepository` 保持后端无关。
- 新音乐源应在 `infrastructure/adapters/` 中适配 `MusicRepository`。
- 不要把某个后端的专有字段或接口泄漏到 UI 和 domain 层。

## 提交信息

建议使用 Conventional Commits：

```text
feat(player): 添加睡眠定时器
fix(network): 修复 Subsonic 歌词解析
docs(repository): 更新 README
```

常用 scope：`player`、`auth`、`library`、`ui`、`network`、`repository`、`settings`、`domain`、`api`。
