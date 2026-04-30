# Phase-Contract Execution Handoff

本文件用于长流程执行时的压缩恢复。不要一次性重新加载全部 phase 文档；恢复时按本文档与 manifest 继续。

## 当前状态

- State file: `plan/state.yaml`
- Handoff file: `plan/handoff.md`
- Updated at: `2026-04-30T02:51:55Z`
- Completed phases: `phase-0-app-shell, phase-1-vm-domain, phase-2-create-wizard, phase-3-virtualization-core, phase-4-runtime-ui, phase-5-recovery-diagnostics, phase-6-verification-matrix`

## 最近完成

- `phase-4-runtime-ui` deliver runtime window, detail view, and lifecycle controls: Added a real runtime window, VM detail snapshots, lifecycle controls, and tests for button availability plus runtime detail presentation.
- next focus: Implement recovery flows, diagnostics, and relaunch-aware restoration on top of the runtime window and session service.
- `phase-5-recovery-diagnostics` add recovery flows, diagnostics, and app relaunch restoration: Added relaunch recovery evaluation, diagnostics surfaces, runtime-window restoration gating, and tests for transient-state mapping plus recovery actions.
- next focus: Automate the smoke and regression verification matrix for the runtime, recovery, and bundle workflows.
- `phase-6-verification-matrix` automate smoke and regression verification matrix: Added a Ruby verification matrix with smoke/full defaults, targeted bundle-runtime-recovery lanes, and documentation for local replay.
- next focus: Finalize the release surface, refresh high-level docs, and produce the acceptance ledger for the completed MVP.

## 下一 Phase

- `phase-7-release-readiness` finalize release surface, operator docs, and acceptance ledger
- plan: `plan/phases/phase-7-release-readiness.md`
- execution: `plan/execution/phase-7-release-readiness.md`
- status: `placeholder contracts need upgrade first (plan/phases/phase-7-release-readiness.md, plan/execution/phase-7-release-readiness.md)`

下一步读取顺序：
1. `plan/common.md`
2. `plan/phases/phase-7-release-readiness.md`
3. `plan/execution/phase-7-release-readiness.md`

## 压缩恢复顺序

1. `plan/manifest.yaml`
2. `plan/handoff.md`
3. `next.phase.required_context`

## 压缩控制规则

- 永远不要一次性加载所有 phase 文档。
- 只在当前 phase 读取 plan/common.md、当前 phase plan 和当前 phase execution。
- 每完成一个 phase 后更新 handoff，再进入下一 phase。

## 连续执行命令

- next: `ruby scripts/planctl advance --strict`
- complete: `ruby scripts/planctl complete <phase-id> --summary "<summary>" --next-focus "<next-focus>" --continue`
- handoff-repair (manual recovery only): `ruby scripts/planctl handoff --write`
