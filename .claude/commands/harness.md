---
description: 按项目 Harness Engineering 工作流执行任务（功能开发/Bug修复/代码审查/重构）
argument-hint: "<任务描述，例如：实现播放页优化 / 修复登录失败 / review当前分支>"
---

请按以下 Harness Engineering 工作流执行任务：**$ARGUMENTS**

## 执行流程

### 1. 判断任务类型

- 包含"实现/开发/添加/新功能/feature"关键词 → **功能开发流程**
- 包含"修复/fix/bug/错误/崩溃/issue"关键词 → **Bug 修复流程**
- 包含"审查/review/PR/检查"关键词 → **代码审查流程**
- 包含"重构/refactor"关键词 → 按功能开发流程（跳过需求分析）
- 不确定 → 向用户提出最多 2 个澄清问题

### 2. 读取参考资料

- 读取 `.codebuddy/knowledge/architecture.md` 了解架构
- 读取 `.codebuddy/knowledge/conventions.md` 了解约定
- 按需读取 `entities.md`、`api-contracts.md`
- UI 改动须先读取 `design.md`

### 3. 按类型执行对应流程

使用 TaskCreate 追踪每个阶段。

#### 功能开发流程（6阶段）

1. **需求分析**：明确功能目标、用户场景、验收标准、依赖项
2. **架构设计**：影响范围、领域模型、接口定义、数据流（遵守 Clean Architecture）
3. **代码实现**：按层实现（domain → application → infrastructure → presentation）
4. **测试验证**：设计用例、编写测试（Fake实现、AAA模式）、运行验证
5. **代码审查**：代码风格、架构合规、安全检查
6. **提交**：`dart format` → `flutter analyze` → `flutter test` → git commit

#### Bug 修复流程（6阶段）

1. **问题分析**：收集错误信息、复现步骤、影响范围
2. **根因定位**：找到代码位置、分析逻辑、识别根因
3. **修复实现**：最小化修改、添加防护、保持风格
4. **回归测试**：验证修复、回归测试、边界条件
5. **代码审查**：修复方案合理性、代码质量
6. **提交修复**：格式化 → 分析 → 测试 → commit

#### 代码审查流程（6阶段）

1. **代码检查**：格式、静态分析、命名、代码风格
2. **架构验证**：分层正确性、MusicRepository 纯净、状态管理、路由
3. **测试验证**：测试存在性、通过率、覆盖率、规范
4. **文档检查**：注释完整性、barrel 文件、外部文档
5. **安全检查**：硬编码密钥、日志安全、输入验证
6. **生成报告**：总评分、问题列表（Critical/Major/Minor/Suggestion）、修复建议

## 执行约束

- 修改代码前先读取相关文件，不基于猜测改动
- 非平凡实现先展示计划并等待用户批准
- 只做任务需要的最小必要改动，不额外重构
- UI 改动须先读取 `design.md`
- 用户可见文案使用简体中文
- 不破坏 Clean Architecture 依赖方向：`presentation → application → domain ← infrastructure`
- 不向 `MusicRepository` 添加后端特定方法
- 需要改 Drift 表或生成代码时，运行 `dart run build_runner build --delete-conflicting-outputs`

## 输出格式

完成后用简洁中文报告：

- 执行的 workflow 类型
- 完成的阶段及结果
- 修改的关键文件（使用 `file:line` 格式引用）
- 验证命令和结果
- 剩余风险或需要用户确认的事项
