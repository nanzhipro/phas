# Phase 6: Automate Smoke and Regression Verification Matrix

## 阶段定位

在 phase-5 已经具备运行、恢复和诊断的产品闭环之后，本阶段负责把“怎么验证这些东西没坏”自动化成可复跑矩阵，而不是继续靠人工拼命记命令。

## 必带上下文

- plan/common.md
- Phase 5 已完成
- PRD.md 中关于验收闭环、回归验证和开发者自助复跑验证路径的要求

## 阶段目标

- 交付一条可复跑的验证矩阵入口，覆盖单 VM MVP 的核心 smoke 与 regression 路径。
- 把 bundle/domain、创建向导、运行 UI、恢复诊断拆成清晰 lane，而不是只留一个笼统的 `xcodebuild test`。
- 让验证命令以非零退出码表达失败，并给出当前 lane 与失败上下文，便于后续 phase 和人工复跑。
- 用独立文档说明矩阵 lane、前置工具、常用命令和当前覆盖范围。

## 实施范围

- 验证矩阵脚本或命令入口。
- lane 定义、失败输出和最小使用文档。
- 与矩阵直接相关的测试选择策略与执行验证。

## 本阶段产出

- 一个默认可执行的验证矩阵入口。
- 至少包含 smoke lane 和 regression lane 的矩阵定义，覆盖运行、恢复和 bundle 工作流。
- 清晰的执行摘要输出，便于后续 release 阶段引用。
- 覆盖矩阵使用方式和 lane 范围的文档。

## 明确不做

- 不在本阶段编写 release notes、acceptance ledger 或发布清单。
- 不引入 CI 平台特有配置作为唯一运行方式；本地必须可直接复跑。
- 不为了“矩阵好看”去修改产品逻辑或跳过已有测试。

## 完成判定

- 存在一条单命令入口可跑 smoke/regression 矩阵，并在失败时返回非零退出码。
- 矩阵至少覆盖 bundle/domain、运行 UI 和恢复诊断相关测试路径。
- 实际执行过该入口，验证矩阵在当前仓库上通过。
- 文档明确说明 lane、命令和当前未覆盖范围。

## 依赖关系

- 依赖 Phase 5。
