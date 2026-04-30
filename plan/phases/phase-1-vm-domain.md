# Phase 1: Establish VM Domain Model and Bundle Persistence

## 阶段定位

在创建向导和虚拟化配置落地之前，先把单 VM 的稳定领域模型、固定 bundle 结构和可复用的本地持久化能力建好，避免后续 phase 一边写 UI 一边返工底层数据契约。

## 必带上下文

- plan/common.md
- Phase 0 已完成
- PRD.md 中的 8.1.3、8.2、8.3、8.4、9.5 与 15.2/15.3/15.4 决策锁定

## 阶段目标

- 定义单 VM 所需的稳定领域类型，至少覆盖 VM ID、资源规格、启动源、网络模式、发行版验证结果与产品状态。
- 固化 `~/Library/Application Support/phas/VMs/<vm-id>.vmbundle/` 的 bundle 路径解析、元数据读写和目录布局。
- 提供可复用的 bundle bootstrap 能力，能够创建 config.json、logs 目录、MachineIdentifier 数据和稀疏磁盘文件，为后续创建与运行阶段复用。
- 提供安全删除和重载入口，确保后续 phase 可以在不误删宿主机其他路径的前提下读取、删除或恢复 VM bundle。

## 实施范围

- 领域模型：单 VM 元数据、状态枚举、资源规格和值对象。
- 持久化基础设施：bundle 路径、配置仓储、MachineIdentifier 仓储、稀疏磁盘创建、删除保护。
- 领域层测试与 bundle 结构说明文档。

## 本阶段产出

- 一组可序列化、可测试的 VM 领域模型与状态类型。
- 一套 bundle 存储基础设施，支持创建、加载、保存和删除单个 VM bundle。
- 覆盖领域序列化、bundle 结构和磁盘创建的单元测试。
- 一份说明 bundle 目录结构和持久化契约的文档。

## 明确不做

- 不实现创建向导 UI、宿主机资源准入检查或 ISO 架构判定。
- 不实现 `VZVirtualMachineConfiguration`、EFI 启动装配、安装流程控制或 NAT 网络设备。
- 不实现 VM 运行窗口、生命周期动作按钮、日志导出界面或应用重启恢复 UI。

## 完成判定

- 仓库内存在覆盖 VM ID、状态、启动源、网络模式、资源规格与配置 schema version 的领域模型，且 config.json 可完成一次写入再读回。
- bundle 根目录严格落在 `~/Library/Application Support/phas/VMs/<vm-id>.vmbundle/`，并由自动化测试验证目录结构与关键文件路径。
- bundle bootstrap 逻辑能创建 `config.json`、`logs/`、`MachineIdentifier` 和逻辑大小正确的 `Disk.img`，其中磁盘文件通过代码路径创建而非 shell 临时命令。
- 删除逻辑带有路径保护，自动化测试证明它不会删除超出 bundle 根目录的路径。

## 依赖关系

- 依赖 Phase 0。
