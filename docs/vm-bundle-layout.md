# VM Bundle Layout

phase-1 固化单 VM 的本地持久化目录：

- 根目录固定为 `~/Library/Application Support/phas/VMs/<vm-id>.vmbundle/`
- `config.json` 保存产品层 VM 元数据，并包含 `schemaVersion`
- `Disk.img` 由代码以逻辑大小创建，依赖宿主机文件系统提供稀疏分配语义
- `MachineIdentifier` 保存 Apple Virtualization 机器标识的二进制表示
- `NVRAM` 路径为后续 EFI variable store 预留，phase-3 再完成真实引导装配
- `logs/` 用于后续 phase 写入启动与错误日志

phase-1 的持久化边界：

- 本阶段负责 bundle 根路径解析、目录创建、config.json 读写、MachineIdentifier 持久化、稀疏磁盘创建和安全删除
- 本阶段不负责 EFI/NVRAM 初始化、ISO 启动装配、网络设备配置或运行期日志采集

后续阶段应直接复用这套 bundle 约定，而不是重新定义路径或文件名。