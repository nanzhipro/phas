# Phase 4: Deliver Runtime Window, Detail View, and Lifecycle Controls

## 阶段定位

在 phase-3 已经具备 Virtualization 配置工厂、运行会话包装层和最小日志入口之后，本阶段负责把这些后端能力接到真实 GUI：用户能在应用内看到单台 VM 的详情，打开运行窗口，并通过明确的按钮驱动启动、请求关机和强制停止。

## 必带上下文

- plan/common.md
- Phase 3 已完成
- PRD.md 中关于运行窗口、生命周期控制、单 VM 详情展示和错误可恢复动作的要求

## 阶段目标

- 交付单 VM 的详情视图，展示名称、状态、资源、启动源、安装介质路径、bundle 路径和最近错误摘要。
- 交付真实运行窗口，把 `VZVirtualMachineView` 嵌入原生 macOS 界面并绑定 phase-3 的运行会话。
- 提供清晰的生命周期控制：Start、Request Stop、Force Stop、Open VM Storage、Open Logs。
- 让 UI 只依赖产品层状态与会话接口，不直接理解 `VZVirtualMachine` delegate 细节。

## 实施范围

- 首页到 VM 详情页/运行窗口的导航与状态展示。
- 运行会话的 UI 绑定层、生命周期按钮 enable/disable 规则与错误提示。
- `VZVirtualMachineView` 的宿主窗口、会话注入和单 VM 运行编排。
- 与本阶段行为直接对应的测试与文档。

## 本阶段产出

- 可从现有首页进入的 VM 详情区域与运行窗口。
- 一组基于 VM 状态和运行会话能力的生命周期控制按钮。
- 运行中可见的错误/状态提示，以及打开 bundle/log 路径的辅助动作。
- 覆盖按钮策略、详情展示模型和运行窗口绑定边界的自动化测试。

## 明确不做

- 不实现应用 relaunch 恢复、损坏 bundle 修复、日志导出、验证矩阵自动化或 release 收尾。
- 不扩展到多 VM 列表、多窗口编排器、桥接网络、共享目录、剪贴板或音频设备。
- 不在本阶段实现复杂诊断页面、健康检查仪表盘或批量运维动作。

## 完成判定

- 用户能从应用内打开唯一 VM 的详情视图，并看到与当前记录一致的状态、资源和路径信息。
- 运行窗口能够承载 `VZVirtualMachineView`，且 Start/Request Stop/Force Stop 等动作通过 phase-3 会话对象驱动。
- 按钮的 enable/disable 与错误提示遵守当前运行状态，不出现明显的非法动作入口。
- 自动化测试覆盖详情模型、生命周期按钮规则或会话绑定边界；`xcodebuild test` 通过。

## 依赖关系

- 依赖 Phase 3。
