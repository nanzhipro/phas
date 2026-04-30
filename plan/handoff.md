# Phase-Contract Execution Handoff

本文件用于长流程执行时的压缩恢复。不要一次性重新加载全部 phase 文档；恢复时按本文档与 manifest 继续。

## 当前状态

- State file: `plan/state.yaml`
- Handoff file: `plan/handoff.md`
- Updated at: `2026-04-30T02:44:32Z`
- Completed phases: `phase-0-app-shell, phase-1-vm-domain, phase-2-create-wizard, phase-3-virtualization-core, phase-4-runtime-ui`

## 最近完成

- `phase-2-create-wizard` implement VM creation wizard and admission gates: Added a single-VM creation wizard, host capability snapshot, admission validator, draft bundle creation flow, and tests for blocking versus warning gating.
- next focus: Promote the phase-3 contract and wire Draft VM records into Virtualization.framework configuration, install-media boot, and runtime launch orchestration.
- `phase-3-virtualization-core` implement virtualization configuration and install boot path: Added lifecycle state policy, Virtualization configuration/session services, structured runtime logging, and tests for boot assembly plus error mapping.
- next focus: Implement the runtime window, VM detail surface, and lifecycle controls on top of the new session factory.
- `phase-4-runtime-ui` deliver runtime window, detail view, and lifecycle controls: Added a real runtime window, VM detail snapshots, lifecycle controls, and tests for button availability plus runtime detail presentation.
- next focus: Implement recovery flows, diagnostics, and relaunch-aware restoration on top of the runtime window and session service.

## 下一 Phase

- `phase-5-recovery-diagnostics` add recovery flows, diagnostics, and app relaunch restoration
- plan: `plan/phases/phase-5-recovery-diagnostics.md`
- execution: `plan/execution/phase-5-recovery-diagnostics.md`
- status: `placeholder contracts need upgrade first (plan/phases/phase-5-recovery-diagnostics.md, plan/execution/phase-5-recovery-diagnostics.md)`

下一步读取顺序：
1. `plan/common.md`
2. `plan/phases/phase-5-recovery-diagnostics.md`
3. `plan/execution/phase-5-recovery-diagnostics.md`

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
