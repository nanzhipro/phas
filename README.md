## phas

phas 是一个基于 Apple 原生 Virtualization.framework 的本地 Linux VM MVP 项目，目标是在 Apple silicon 的 macOS 14+ 上交付单虚拟机创建、图形化安装、持久化启动、基础联网和错误恢复的完整闭环。

当前仓库处于 Phase-0 工程壳层阶段：已经锁定原生 macOS GUI 方向、entitlement 入口和首页空状态，后续 phase 会逐步补齐 VM 领域模型、创建流程、运行期能力和验证矩阵。

## 当前范围

- 单 VM MVP，不做多 VM 管理平台。
- 仅支持 Apple silicon + macOS 14+。
- 主验收镜像锁定 Ubuntu Desktop ARM64，Fedora Workstation ARM64 作为补充验证。

## 构建入口

详细命令见 [docs/build-run.md](docs/build-run.md)。

最短路径：

```bash
xcodegen generate
xcodebuild -project phas.xcodeproj -scheme phas -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## 规划入口

- 产品需求定义见 [PRD.md](PRD.md)
- Phase workflow 见 [plan/workflow.md](plan/workflow.md)
- 当前执行状态见 [plan/handoff.md](plan/handoff.md)
