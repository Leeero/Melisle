---
name: "source-command-push"
description: "将本地变更按功能分组自动提交并推送到远程"
---

# source-command-push

Use this skill when the user asks to run the migrated source command `push`.

## Command Template

执行 **自动化提交工作流**。分析当前所有本地变更，按功能领域分组后逐一提交，最后推送到远程。

## 分组提交规则

使用 `git diff --stat` 和 `git status` 分析变更，按以下分组逻辑归类。**每组变更独立 staging + commit**，全部提交完成后 `git push`。

### 分层分组顺序（按层级从低到高）

| 变更路径 | 类型(scope) | 说明 |
|---------|-------------|------|
| `lib/domain/entities/` 新增文件 | `feat(domain)` | 新实体 |
| `lib/domain/entities/entities.dart` 或 `lib/domain/repositories/` | `feat(repository)` | 接口变更 |
| `lib/application/usecases/` | 跟随对应功能层 | UseCase 变更随对应功能提交 |
| `lib/infrastructure/network/` | `feat(network)` | API 客户端 |
| `lib/infrastructure/adapters/` + `lib/application/usecases/` | `feat(repository)` | 适配器实现 |
| `lib/presentation/blocs/` | `feat(<scope>)` | 状态管理 |
| `lib/presentation/pages/` 或 `lib/presentation/widgets/` | `style(<scope>)` | UI 变更 |
| `lib/infrastructure/audio/` 或 `lib/bootstrap/` | `chore(player)` 等 | 基础设施变更 |
| `test/` | `chore(test)` | 测试适配 |

### 合组原则

- 同一功能跨层的变更（如 Genre 贯穿 domain→api→adapter→bloc→ui）按层拆分为多个提交
- UI 零散调整合并为一个 `style(ui)` 提交
- `dart format` 导致的纯格式化变更不单独提交，归入同组其他提交或 `style(ui)`

## 提交信息规范

严格遵循 Conventional Commits，参考 Angular 约定（https://www.ruanyifeng.com/blog/2016/01/commit_message_change_log.html）：

```
<type>(<scope>): <subject>

<body>
```

### type 可选值

| type | 何时使用 |
|------|---------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `style` | UI 调整、代码格式化（不影响运行逻辑） |
| `refactor` | 代码重构（既非功能也非修复） |
| `chore` | 测试、配置、工具链 |
| `docs` | 文档 |
| `perf` | 性能优化 |

### scope 可选值

`player` / `auth` / `library` / `ui` / `network` / `repository` / `settings` / `domain` / `api`

### subject 规则

- 中文简短描述，不超过 50 字
- 祈使句，不加句号
- 例如："添加 Genre 实体与 PaginatedResult 分页模型"

### body（可选）

- 列出关键变更点，每项用 - 开头
- 中文描述

## 提交流程

1. `git diff --stat` 查看所有变更
2. 识别文件分组，确定提交顺序
3. 每组执行：`git add <files>` → `git commit -m "<message>"`
4. 全部完成后 `git push`
5. 输出提交摘要供用户确认
