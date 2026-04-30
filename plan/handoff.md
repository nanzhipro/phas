# Phase-Contract Execution Handoff

本文件用于长流程执行时的压缩恢复。不要一次性重新加载全部 phase 文档；恢复时按本文档与 manifest 继续。

## 当前状态

- State file: `plan/state.yaml`
- Handoff file: `plan/handoff.md`
- Updated at: `2026-04-30T02:09:25Z`
- Completed phases: `phase-0-app-shell`

## 最近完成

- `phase-0-app-shell` bootstrap native app shell and build pipeline: Bootstrapped the native macOS app shell with a generated Xcode project, virtualization entitlement, SwiftUI empty state, and a reproducible build/test path.
- next focus: Promote phase-1 contracts and implement the VM domain model, bundle metadata, and persistent storage scaffolding.

## 下一 Phase

- `phase-1-vm-domain` establish VM domain model and bundle persistence
- plan: `plan/phases/phase-1-vm-domain.md`
- execution: `plan/execution/phase-1-vm-domain.md`
- status: `placeholder contracts need upgrade first (plan/phases/phase-1-vm-domain.md, plan/execution/phase-1-vm-domain.md)`

下一步读取顺序：
1. `plan/common.md`
2. `plan/phases/phase-1-vm-domain.md`
3. `plan/execution/phase-1-vm-domain.md`

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
