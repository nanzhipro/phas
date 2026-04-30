# Phase 7: Finalize Release Surface, Operator Docs, and Acceptance Ledger

## 阶段定位

在 phase-6 已经具备功能闭环与可复跑验证矩阵之后，本阶段负责把仓库对外可读面收束到“可交付”状态：整理高层 README、补齐 operator-facing 文档、汇总 acceptance ledger，并明确当前 MVP 的已完成范围与未覆盖边界。

## 必带上下文

- plan/common.md
- Phase 6 已完成
- PRD.md 中关于验收目标、支持范围、操作说明和非目标边界的要求

## 阶段目标

- 把 README 刷新到当前 MVP 实际状态，但仍保持高层概览，不把实现细节灌进去。
- 提供 operator-facing 文档，覆盖构建、运行、验证矩阵、恢复/诊断入口和已知边界。
- 产出 acceptance ledger，总结每个核心能力是否已交付、如何验证、当前限制是什么。
- 为最终 `planctl finalize` 提供清晰、可审计的文档面，而不是让 finalize 只面对过时说明。

## 实施范围

- README 高层刷新。
- docs 目录中的 operator / release-readiness / acceptance ledger 文档。
- 与文档一致性直接相关的轻量脚本入口或链接修正。

## 本阶段产出

- 刷新后的高层 README。
- 一组可供操作者复用的文档入口。
- 一份明确列出能力、验证方式、限制和未覆盖范围的 acceptance ledger。

## 明确不做

- 不在本阶段打 tag、创建 release、推送 tag 或归档 `plan/`。
- 不新增产品功能来“补齐文档缺口”。
- 不把 finalize 本身替代成手写收尾结论。

## 完成判定

- README 与 docs 不再停留在早期 phase 描述，且保持高层概览风格。
- 存在清晰的 operator docs 与 acceptance ledger，可直接指向构建、运行、恢复和验证矩阵入口。
- 文档中的命令和入口与当前仓库实际一致。
- phase-7 自身完成后，可无 blocker 地进入 `planctl finalize`。

## 依赖关系

- 依赖 Phase 6。
