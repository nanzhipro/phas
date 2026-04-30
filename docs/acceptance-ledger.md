# Acceptance Ledger

| Capability | Status | Verification | Current Limit |
| --- | --- | --- | --- |
| Xcode project generation and local build path | Done | `xcodegen generate` and `xcodebuild -project phas.xcodeproj -scheme phas -configuration Debug build CODE_SIGNING_ALLOWED=NO` | Local macOS build path only |
| Single-VM bundle persistence and domain model | Done | `ruby scripts/verify_matrix bundle` | Fixed single-VM bundle layout |
| Create wizard and admission gates | Done | `ruby scripts/verify_matrix smoke` | No multi-VM flow |
| Virtualization configuration assembly | Done | `ruby scripts/verify_matrix runtime` | No bridged networking or advanced devices |
| Runtime window and lifecycle controls | Done | `ruby scripts/verify_matrix runtime` | No end-to-end guest UI automation |
| Relaunch recovery and diagnostics | Done | `ruby scripts/verify_matrix recovery` | No remote diagnostics or silent auto-repair |
| Smoke and regression matrix automation | Done | `ruby scripts/verify_matrix` | Local replay only, no CI integration in this phase |

## Notes

- 当前主验收镜像是 Ubuntu Desktop ARM64。
- Fedora Workstation ARM64 只作为补充验证目标，不扩大首发承诺。
- 当前仓库已完成单 VM MVP 的功能闭环，但仍保留非目标边界：多 VM、桥接网络、共享目录、剪贴板、音频、Rosetta、快照和 release 自动化。
