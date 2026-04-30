# Phase 0 执行包

本文件不能单独使用。执行 Phase 0 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-0-app-shell.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-0-app-shell.md`

## 执行目标

- 建立一个可构建、可启动的 macOS 原生应用壳层，并锁定后续阶段沿用的工程结构。
- 让 entitlement、首页空状态、构建命令和目录组织在本阶段一次性站稳，为后续业务相位提供稳定地基。

## 本次允许改动

- `README.md`
- `.gitignore`
- `App/**`
- `Features/**`
- `Domain/**`
- `Infrastructure/**`
- `Resources/**`
- `Tests/**`
- `docs/**`
- `phas.entitlements`
- `phas.xcodeproj/**`
- `project.yml`
- `Package.swift`

## 本次不要做

- 不写 VM bundle 持久化、配置 schema、磁盘镜像创建、MachineIdentifier/NVRAM 逻辑。
- 不写创建向导、ISO 重新选择入口、资源准入检查或任何安装状态机。
- 不写 Virtualization.framework 的运行配置、VM 生命周期控制、诊断导出和错误恢复 UI。
- 不把工程壳层扩张成多窗口或多 VM 管理平台。

## 交付检查

- 应用工程能在当前本地工具链下完成至少一次真实构建。
- entitlement 文件或工程配置中已显式包含 `com.apple.security.virtualization`。
- 应用启动后能稳定展示首页或空状态页面，且该页面不依赖未实现的 VM 逻辑。
- README 或 docs 中存在一条可复跑的 build/run 入口说明。

## 执行裁决规则

- 如果工程壳层没有通过真实构建命令验证，直接判定无效并回退到可构建状态。
- 如果为图省事引入第三方虚拟化底座、跨平台壳层或任何超出 Apple 原生框架边界的方案，直接判定无效。
- 如果工程生成方式导致产物与当前本地 Xcode 工具链不兼容，直接判定无效并改用兼容方案。
- 如果改动范围漂移到 VM 创建、运行、恢复、验证矩阵等后续 phase，直接回退到本 phase 边界。
