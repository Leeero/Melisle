---
description: 执行代码审查工作流（检查当前分支变更的代码质量、架构、测试、安全）
argument-hint: "<可选：审查范围说明，默认审查当前分支所有未合并变更>"
---

执行**代码审查工作流**。$ARGUMENTS

## 准备工作

1. 运行 `git diff main...HEAD` 或 `git diff master...HEAD` 获取待审查变更
2. 如果无差异，运行 `git diff --cached` 和 `git diff` 获取暂存/未暂存变更
3. 读取规则文件：
   - `.codebuddy/rules/architecture.md`
   - `.codebuddy/rules/coding-style.md`
   - `.codebuddy/rules/testing.md`

## 阶段 1：代码检查

角色：**开发者**

### 格式检查
- 运行 `dart format --set-exit-if-changed lib/` 检查格式
- 检查行长度（建议不超过 80 字符）

### 静态分析
- 运行 `flutter analyze` 检查 error / warning / info

### 命名检查
- 文件命名：`snake_case`（`^[a-z][a-z0-9_]*\.dart$`）
- 类命名：`PascalCase`
- 变量/方法命名：`camelCase`

### 代码风格
- 领域实体使用 `const` 构造函数
- 不可变对象实现 `copyWith`
- 所有字段使用 `final`
- 正确处理空值（无不必要的 `!` 断言）
- 不使用 `print` 做日志（使用 talker_flutter）

## 阶段 2：架构验证

角色：**架构师**

### 分层检查
- 依赖方向：`presentation → application → domain ← infrastructure`（无反向依赖）
- `domain/` 层不 import Flutter 包
- `infrastructure/adapters/` 正确实现 `MusicRepository` 接口

### MusicRepository 检查
- 无后端特定方法添加到 `MusicRepository`
- 新后端能力通过新 adapter 实现

### 状态管理检查
- 使用 Cubit（非 Bloc events）
- 状态使用 `copyWith` 不可变更新
- 状态枚举定义合理

### 路由检查
- 主要页面在 ShellRoute 内（home/library/settings/album/playlists/artist 等）
- `/login`、`/player`、`/search` 在 ShellRoute 外
- 认证重定向逻辑正确

## 阶段 3：测试验证

角色：**测试者**

### 测试存在性
- 新功能/修复是否有对应测试
- 相关实体/usecase 是否有测试文件

### 测试质量
- 运行 `flutter test` 确认全量通过
- 检查覆盖率（`flutter test --coverage`）

### 测试规范
- 命名：`[被测对象]_[场景]_[预期结果]`
- 使用 Fake 实现 Repository
- 测试独立，setUp/tearDown 正确
- AAA 模式

## 阶段 4：文档检查

角色：**文档员**

- 公开类/方法是否有 `///` 文档注释
- 复杂逻辑是否有行内注释
- barrel 文件（`entities.dart`、`repositories.dart`、`usecases.dart` 等）是否已更新
- `CLAUDE.md` / `CODEBUDDY.md` 是否需要更新

## 阶段 5：安全检查

角色：**开发者/审查员**

- 无硬编码密钥、密码、Token
- 日志不打印敏感信息（如 accessToken）
- Drift 使用参数化查询（无字符串拼接 SQL）
- 用户输入有适当验证
- 依赖版本无已知安全漏洞

## 阶段 6：生成审查报告

角色：**审查员**

输出以下格式的审查报告：

```
# 代码审查报告

## 总评
**评分**: X/100
**结论**: 可合并 / 需修改后合并 / 需重新设计

## 阻断问题 (Critical) — 必须修复
- [问题描述] `file:line`

## 重要建议 (Major) — 强烈建议修复
- [问题描述] `file:line`

## 次要问题 (Minor) — 建议修复
- [问题描述] `file:line`

## 优化建议 (Suggestion)
- [建议描述]

## 通过项
- [已通过的检查项列表]

## 验证命令
- [需要运行的验证命令及结果]
```

**严重程度定义**：
- **Critical**：必须修复，阻止合并（架构违规、安全漏洞、崩溃风险）
- **Major**：强烈建议修复，需要讨论（性能问题、设计问题、缺少测试）
- **Minor**：建议修复，可选（命名、注释、代码风格）
- **Suggestion**：优化建议，可选

## 参考知识库

- `.codebuddy/rules/architecture.md` — 架构规则
- `.codebuddy/rules/coding-style.md` — 编码风格
- `.codebuddy/rules/testing.md` — 测试规范
- `.codebuddy/rules/commit.md` — 提交规范
- `.codebuddy/knowledge/architecture.md` — 架构知识
- `.codebuddy/knowledge/conventions.md` — 约定知识
