# Phase 1 执行包

本文件不能单独使用。执行 Phase 1 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-1-vm-domain.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-1-vm-domain.md`

## 执行目标

- 把单 VM MVP 的领域元数据和本地 bundle 持久化契约一次性定型。
- 让后续创建向导、虚拟化配置和恢复流程都能复用同一套 bundle 读写和删除保护能力。

## 本次允许改动

- `Domain/**`
- `Infrastructure/**`
- `Tests/**`
- `docs/**`
- `README.md`
- `.gitignore`

## 本次不要做

- 不修改 `App/**`、`Features/**`、`Resources/**` 或任何首页/运行期 UI。
- 不写宿主机资源检查、ISO 文件校验、发行版软警告或创建向导交互。
- 不写 `VZVirtualMachine`、`VZVirtualMachineConfiguration`、`VZVirtualMachineView`、NAT 设备或运行状态驱动逻辑。
- 不把本阶段扩大成日志导出、应用重启恢复、删除确认 UI 或验证矩阵自动化。

## 交付检查

- 至少一组自动化测试覆盖 config.json 序列化 round-trip、bundle 路径解析和删除保护。
- 至少一组自动化测试覆盖 bundle bootstrap 后的 `logs/`、`MachineIdentifier` 与 `Disk.img` 创建结果。
- 稀疏磁盘创建逻辑由仓库内代码完成，并在测试里验证逻辑文件大小与请求值一致。
- 文档中明确说明 bundle 目录结构、schema version 与后续 phase 的复用边界。

## 执行裁决规则

- 如果持久化契约没有通过自动化测试验证，直接判定无效并继续修同一切片，不得带病进入 phase-2。
- 如果实现依赖 shell 命令黑盒创建磁盘或 MachineIdentifier，而仓库代码本身无法复用该能力，直接判定无效。
- 如果删除逻辑没有明确的 bundle 根路径保护，直接判定无效。
- 如果改动扩散到创建向导、虚拟化运行、运行窗口或恢复 UI，直接回退到本 phase 边界。
