# Phase 7 执行包

本文件不能单独使用。执行 Phase 7 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-7-release-readiness.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-7-release-readiness.md`

## 执行目标

- 收束当前仓库的对外说明面，让 README、operator docs 和 acceptance ledger 与实际代码/脚本状态一致。
- 在不执行发布动作的前提下，为最终 finalize 准备完整的文档和验收台账。

## 本次允许改动

- `App/**`
- `Features/**`
- `Domain/**`
- `Infrastructure/**`
- `Resources/**`
- `Tests/**`
- `docs/**`
- `README.md`
- `.gitignore`

## 本次不要做

- 不打 tag，不创建 release，不归档 `plan/`，不替 finalize 做决策。
- 不为了让文档更好看而新增超出 MVP 的功能。
- 不把 README 写成实现细节堆栈。

## 交付检查

- README 保持高层概览，并准确反映当前 MVP 功能与限制。
- docs 中存在 operator-facing 页面，覆盖 build/run、runtime/recovery、verification matrix、acceptance ledger。
- 文档中的命令至少抽样执行或已在前序 phase 真实执行过，不能写失效命令。
- phase 完成后可以直接执行 `ruby scripts/planctl finalize`，无缺失文档 blocker。

## 执行裁决规则

- 如果 README 仍然停留在 phase-0/phase-1 描述，直接判定无效。
- 如果 acceptance ledger 只写“完成”而没有验证方式和限制，直接判定无效。
- 如果本阶段擅自执行 tag/release/archive 动作，直接判定越界。
- 如果文档与当前脚本/代码入口不一致，直接判定无效。