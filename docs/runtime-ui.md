# Runtime UI

phase-4 将 phase-3 的虚拟化后端能力接到应用表面，当前运行期入口分为两层：

- 首页详情区：展示单 VM 的状态、资源、启动源、安装镜像、bundle 路径、日志路径和最近错误摘要
- 独立运行窗口：承载 `VZVirtualMachineView`，并把生命周期按钮和详情侧栏放到同一个产品表面

## 入口

- 当仓库中还没有 VM 记录时，首页主按钮仍然是 `Create Virtual Machine`
- 当唯一 VM 已存在时，首页主按钮切换为 `Open Runtime Window`
- 首页详情卡和独立运行窗口都会暴露相同的生命周期动作，避免用户必须记忆不同入口

## 生命周期按钮语义

- `Start`：确保当前记录先通过 phase-3 的配置工厂生成运行会话，然后调用 `VirtualMachineSession.start()`；Draft 会进入安装启动路径，Stopped/Error 会进入系统盘启动路径
- `Request Stop`：调用 guest 侧的优雅关机请求，只在底层会话报告 `canRequestStop` 时启用
- `Force Stop`：调用宿主侧强制停止，只在底层会话报告 `canStop` 时启用
- `Open VM Storage`：打开固定 bundle 根路径
- `Open Logs`：优先打开 `logs/runtime.log`，如果日志文件尚未生成，则打开 `logs/` 目录

## 当前边界

- 当前仍然是单 VM MVP，不做多窗口/多 VM 编排
- 应用 relaunch 后的会话恢复不在本阶段实现，phase-5 再补
- 当前只提供最小错误提示和本地日志入口，不做日志导出、恢复向导或诊断面板
- 视图层只绑定产品状态、详情快照和会话动作，不直接解释 `VZVirtualMachine` delegate 事件
