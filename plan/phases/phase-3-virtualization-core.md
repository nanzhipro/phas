# Phase 3: Implement Virtualization Configuration and Install Boot Path

## 阶段定位

在 phase-2 已经能创建 Draft VM bundle 的基础上，本阶段负责把 bundle 元数据真正接到 Apple Virtualization.framework：基于现有记录生成有效的虚拟机配置，区分安装介质启动与系统盘启动，并提供可被后续 UI 复用的运行会话包装层。

## 必带上下文

- plan/common.md
- Phase 2 已完成
- PRD.md 中的 5.1.B、5.1.E、8.3、8.5、9.1、9.2、9.3、10.1、10.5

## 阶段目标

- 交付一套基于 `VirtualMachineRecord` + bundle layout 生成 `VZVirtualMachineConfiguration` 的工厂。
- 固化安装阶段与已安装阶段的启动源策略：安装介质启动挂载 ISO，系统盘启动只挂载持久磁盘。
- 提供 `VZVirtualMachine` 运行会话包装层，封装 start / stop / requestStop 和 delegate 事件到产品状态转移。
- 为后续 phase 的运行窗口和详情页预留稳定接口，而不是让 UI 直接拼装 Virtualization 配置细节。

## 实施范围

- Virtualization 配置工厂与 bundle boot artifacts 管理。
- 状态转移策略：启动前、guest 正常关机、运行错误、网络附着断开。
- 运行会话包装层与最小日志写入入口。
- 与上述逻辑直接对应的单元测试和说明文档。

## 本阶段产出

- 可生成并验证的 `VZVirtualMachineConfiguration`，覆盖 EFI、MachineIdentifier、NVRAM、Virtio 磁盘、USB 安装介质、图形、输入和 NAT 网络。
- 一套启动源与状态转移策略，支持 `Draft/Installing -> Installing` 与 `Stopped -> Running`，并在 guest 正常停止后切换到后续稳定状态。
- 一个可被 UI 注入的运行会话对象或服务，后续 phase 直接复用。
- 覆盖配置构建与状态策略的自动化测试。

## 明确不做

- 不交付 `VZVirtualMachineView` 运行窗口、详情页、按钮布局或多窗口编排。
- 不实现删除确认、错误恢复 UI、应用重启恢复和诊断导出界面。
- 不扩展到 bridged networking、共享目录、剪贴板、音频、Rosetta 或多 VM。

## 完成判定

- 对 Draft/Installing 记录生成的配置会挂载安装介质；对 Stopped/Running 记录生成的配置不会重复挂载 ISO。
- 配置工厂会复用 bundle 下的 `MachineIdentifier` 与 `NVRAM`，并在缺失时按当前 contract 创建所需引导文件。
- 运行会话包装层能够把 start / stop / requestStop 和 delegate 事件映射到产品层状态转移，而不是把 `VZVirtualMachine.State` 直接泄漏给上层 UI 逻辑。
- 自动化测试覆盖安装介质装配、系统盘启动、状态转移和错误映射；`xcodebuild test` 通过。

## 依赖关系

- 依赖 Phase 2。
