# Virtualization Core

phase-3 把 VM bundle 数据装配成真正的 Apple Virtualization 配置，并固定以下规则：

- 平台配置使用 `VZGenericPlatformConfiguration`
- EFI 启动使用 `VZEFIBootLoader`
- `NVRAM` 由 `VZEFIVariableStore` 管理，并绑定在 `VZEFIBootLoader.variableStore`
- 系统盘使用 `VZVirtioBlockDeviceConfiguration`
- 安装介质使用只读 `VZUSBMassStorageDeviceConfiguration`
- 网络固定为 `VZVirtioNetworkDeviceConfiguration` + `VZNATNetworkDeviceAttachment`
- 图形、键盘、鼠标分别使用 Virtio graphics、USB keyboard、USB pointing device

bundle 装配约定：

- `MachineIdentifier` 固定保存在 VM bundle 根目录的 `MachineIdentifier`
- `NVRAM` 固定保存在 VM bundle 根目录的 `NVRAM`
- 持久系统盘固定保存在 VM bundle 根目录的 `Disk.img`
- 安装介质仍然引用 `VirtualMachineRecord.installImagePath` 指向的外部镜像，不复制进 bundle

启动源策略：

- `bootSource = installationImage` 时，配置会挂载 ISO，并把产品状态推进到 `Installing`
- `bootSource = diskImage` 时，配置只挂载持久磁盘，并把产品状态推进到 `Running`
- guest 正常停机后，如果此前仍在安装介质路径，会把后续启动源切换为 `diskImage`
- 运行错误和网络附着断开都会把产品状态推进到 `Error`

日志入口：

- 运行会话会向 `logs/runtime.log` 追加一行一个 JSON 事件
- 每条日志包含时间戳、事件名、VM ID、产品状态、启动源、摘要、应用版本和宿主机系统版本

phase-4 将直接复用这里的配置工厂和运行会话对象，只补运行窗口与控制面板，不再重复拼装 Virtualization.framework 细节。
