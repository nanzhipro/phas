# Phase 0: Bootstrap Native App Shell and Build Pipeline

## 阶段定位

为后续 VM 领域建模和虚拟化实现建立一个可实际构建、可实际启动的 macOS 原生应用骨架，先把工程入口、entitlement、目录边界和基础页面站稳。

## 必带上下文

- plan/common.md
- PRD.md

## 阶段目标

- 建立一个面向 macOS 14+ 的原生应用工程，能够在当前本地工具链下完成至少一次真实构建。
- 固化后续实现使用的顶层目录与组合根，避免后续 phase 在工程结构上反复返工。
- 交付一个最小可运行的首页或空状态页面，为单 VM 流程预留入口和状态承载位置。

## 实施范围

- 工程与 target 基础设施：应用 target、entitlement、资源入口、基础目录布局。
- 应用入口与首屏：App 生命周期、基础导航或空状态承载页。
- 基础构建/运行文档：最小 build/run 命令与当前限制说明。

## 本阶段产出

- 可被当前本地工具链构建的 macOS 应用工程骨架。
- 已配置 `com.apple.security.virtualization` entitlement 的应用 target。
- 一个可启动并展示空状态或首页占位的应用入口。
- 一份简明的构建/运行入口说明，便于后续 phase 复用。

## 明确不做

- 不实现 VM 创建向导、ISO 校验、资源准入或磁盘创建逻辑。
- 不实现任何 `VZVirtualMachineConfiguration`、启动源切换、NAT 设备或安装流程控制。
- 不实现 VM 持久化、日志导出、状态恢复、多窗口运行期能力。

## 完成判定

- 仓库内存在可被当前本地工具链识别的 macOS 应用工程与 entitlement 配置，且 entitlement 包含 `com.apple.security.virtualization`。
- 至少一条真实构建命令在当前环境可执行并成功完成，且命令入口被记录在仓库文档中。
- 应用启动后可展示首页或空状态页面，不依赖任何 VM 领域数据即可进入稳定 UI。
- 顶层目录边界已经固定，后续 VM 领域代码、基础设施代码和测试代码有明确落位。

## 依赖关系

- 无前置依赖。
