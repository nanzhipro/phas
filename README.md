# phas

phas 是一个基于 Apple 原生 Virtualization.framework 的本地 Linux VM MVP，面向 Apple silicon 的 macOS 14+。当前仓库已经具备单 VM 创建、运行窗口、持久化启动路径、基础恢复/诊断和本地可复跑验证矩阵。

## 当前能力

- 单 VM 创建向导与 admission gates
- 基于 EFI/NVRAM/MachineIdentifier 的 Virtualization 配置装配
- 独立运行窗口、详情视图和 Start / Request Stop / Force Stop 控制
- 应用 relaunch 后的状态恢复、脏状态显式错误化和最小诊断面板
- 本地 smoke / regression verification matrix

## 当前限制

- 只做单 VM MVP，不扩展到多 VM 管理
- 只支持 Apple silicon + macOS 14+
- 主验收镜像锁定 Ubuntu Desktop ARM64；Fedora Workstation ARM64 仅作补充验证
- 不包含桥接网络、共享目录、剪贴板、音频、Rosetta、快照或 release 自动化

## 快速入口

构建与运行见 [docs/build-run.md](docs/build-run.md)。

验证矩阵入口：

```bash
ruby scripts/verify_matrix
```

## 文档入口

- 操作指引见 [docs/operator-guide.md](docs/operator-guide.md)
- 运行窗口与生命周期控制见 [docs/runtime-ui.md](docs/runtime-ui.md)
- 恢复与诊断见 [docs/recovery-diagnostics.md](docs/recovery-diagnostics.md)
- 验证矩阵见 [docs/verification-matrix.md](docs/verification-matrix.md)
- 验收台账见 [docs/acceptance-ledger.md](docs/acceptance-ledger.md)

## 规划入口

- 产品需求定义见 [PRD.md](PRD.md)
- Phase workflow 见 [plan/workflow.md](plan/workflow.md)
- 当前执行状态见 [plan/handoff.md](plan/handoff.md)
