---
description: 执行功能开发工作流（需求分析→架构设计→实现→测试→审查→提交）
argument-hint: "<功能描述，例如：实现歌词同步显示 / 添加均衡器功能>"
---

执行**功能开发工作流**，任务：$ARGUMENTS

使用 TaskCreate 为每个阶段创建任务，完成后标记 completed。

## 阶段 1：需求分析

角色：**产品经理**

- 分析用户需求，提取功能要点
- 确定功能边界和依赖项
- 定义可测试的验收标准
- 参考 `.codebuddy/knowledge/prd.md` 了解现有功能全景

**检查清单**:
- [ ] 功能目标明确
- [ ] 用户场景清晰
- [ ] 边界条件已识别
- [ ] 依赖项已列出
- [ ] 验收标准可测试

**输出格式**：功能概述 / 用户场景 / 验收标准 / 依赖项

## 阶段 2：架构设计

角色：**架构师**

- 读取 `.codebuddy/knowledge/architecture.md` 和 `.codebuddy/rules/architecture.md`
- 评估对现有架构的影响
- 定义新实体和接口（如需要）
- 设计数据流和状态管理
- **非平凡变更须进入 Plan Mode 等待用户批准**

**检查清单**:
- [ ] 遵循 Clean Architecture 分层
- [ ] 无后端特定方法添加到 MusicRepository
- [ ] 接口定义清晰
- [ ] 数据流设计合理
- [ ] 考虑扩展性

**输出格式**：影响范围 / 领域模型 / 接口定义 / 数据流

## 阶段 3：代码实现

角色：**开发者**

- 按层实现：domain → application → infrastructure → presentation
- 遵循编码规范（`.codebuddy/rules/coding-style.md`）
- 读取 `.codebuddy/knowledge/conventions.md` 了解项目约定
- 按需读取 `.codebuddy/knowledge/entities.md` 和 `.codebuddy/knowledge/api-contracts.md`

**检查清单**:
- [ ] 分层正确，无反向依赖
- [ ] 使用 const 构造函数和 copyWith
- [ ] 错误处理完善（使用类型化异常）
- [ ] 添加必要注释（英文）
- [ ] 用户可见文案使用简体中文
- [ ] 通过 `flutter analyze`
- [ ] 更新相关 barrel export 文件

## 阶段 4：测试验证

角色：**测试者**

- 读取 `.codebuddy/rules/testing.md` 了解测试规范
- 设计测试用例覆盖关键路径
- 使用 Fake 实现（非真实网络请求）
- AAA 模式（Arrange-Act-Assert）
- Widget 测试断言使用真实简体中文文案
- 运行 `flutter test`

**检查清单**:
- [ ] 覆盖关键路径
- [ ] 测试命名规范：`[被测对象]_[场景]_[预期结果]`
- [ ] 使用 Fake/Mock
- [ ] 测试独立运行
- [ ] 覆盖率达标（domain/entities 100%、usecases 100%、blocs ≥ 80%）

## 阶段 5：代码审查（自审）

角色：**审查员**

- 检查代码风格和架构合规
- 验证无安全问题（无硬编码密钥、日志不泄露敏感信息）
- 更新相关文档和 barrel exports
- 检查 `CLAUDE.md` / `CODEBUDDY.md` 是否需要更新

**检查清单**:
- [ ] 代码风格符合规范
- [ ] 架构符合 Clean Architecture
- [ ] 文档已更新
- [ ] 注释完整
- [ ] 无安全问题

## 阶段 6：提交合并

角色：**开发者**

依次执行：
1. `dart format lib/`
2. `flutter analyze`
3. `flutter test`
4. 提交代码：`feat(<scope>): <subject>`

Scope 选项：player / auth / library / ui / network / repository / settings

**检查清单**:
- [ ] 代码已格式化
- [ ] 无 lint 错误
- [ ] 所有测试通过
- [ ] 提交信息规范（Conventional Commits）
- [ ] 分支命名正确（`feature/<feature-name>`）

## 参考知识库

按需读取（路径前缀 `.codebuddy/knowledge/`）：
- `architecture.md` — 架构设计参考
- `entities.md` — 实体设计参考
- `api-contracts.md` — 接口设计参考
- `conventions.md` — 编码约定参考
- `prd.md` — 功能清单和优先级

规则文件（路径前缀 `.codebuddy/rules/`）：
- `architecture.md` — 架构规则验证
- `coding-style.md` — 编码风格验证
- `testing.md` — 测试规范验证
- `commit.md` — 提交规范验证
