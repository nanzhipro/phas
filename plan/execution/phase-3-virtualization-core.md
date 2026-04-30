# Phase 3 执行包

本文件不能单独使用。执行 Phase 3 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-3-virtualization-core.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-3-virtualization-core.md`

## 执行目标

- 把 phase-2 的 Draft VM 数据推进到真正可启动的 Apple Virtualization 配置层。
- 在不做完整运行期 UI 的前提下，先把后端虚拟化核心和启动状态逻辑定型。

## 本次允许改动

- `App/**`
- `Features/**`
- `Domain/**`
- `Infrastructure/**`
- `Tests/**`
- `docs/**`
- `README.md`
- `.gitignore`

## 本次不要做

- 不实现完整的运行窗口、详情页排版、生命周期按钮矩阵或删除确认 UI。
- 不实现应用 relaunch 恢复、日志导出、验证矩阵自动化或 release 文档收尾。
- 不把网络扩展到 bridged 模式，也不接入共享目录、剪贴板或音频设备。

## 交付检查

- 至少一组自动化测试覆盖安装介质启动与系统盘启动的配置差异。
- 至少一组自动化测试覆盖启动前状态转移、guest 停机后状态转移和错误状态映射。
- 配置工厂构造出的对象能在应用测试环境下通过 `VZVirtualMachineConfiguration.validate()`，或通过同等强度的可执行校验。
- 文档明确说明 EFI variable store、MachineIdentifier、磁盘与 ISO 在 bundle 中的装配方式。

## 执行裁决规则

- 如果系统盘启动路径仍然挂载安装介质，直接判定无效。
- 如果实现绕过 phase-1 的 bundle 文件命名约定，直接判定无效。
- 如果上层必须直接理解 `VZVirtualMachine` delegate 细节才能工作，说明包装层边界失效，直接判定无效。
- 如果本阶段把运行窗口和复杂 UI 提前混进来，直接回退到当前 phase 边界。
