# Phase 2 执行包

本文件不能单独使用。执行 Phase 2 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-2-create-wizard.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-2-create-wizard.md`

## 执行目标

- 把“创建 VM”从静态占位文案升级成真实的产品入口。
- 在不触及虚拟化运行时的前提下，先把 UI 与准入规则闭环做好。

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

- 不实现 `VZVirtualMachineConfiguration`、`VZVirtualMachine`、`VZVirtualMachineView`、NAT 运行装配或安装状态驱动。
- 不实现删除确认、日志查看、错误恢复 UI 或应用重启恢复。
- 不把 UI 做成多窗口/多标签/多 VM 管理器。

## 交付检查

- 至少一组自动化测试覆盖 admission validator 的 blocking / warning 判定。
- 至少一组自动化测试覆盖创建用例在通过校验时会写入 Draft VM bundle，在失败时不会落盘。
- `xcodebuild test` 必须通过，且首页与创建向导的代码路径能参与实际编译。
- 文档中记录宿主机摘要展示内容、预设值和当前硬性阻断规则。

## 执行裁决规则

- 如果创建动作在 blocking 条件下仍能落盘 bundle，直接判定无效。
- 如果向导没有展示阻断原因或软警告，直接判定无效。
- 如果实现绕过 phase-1 的 bundle store 另起一套落盘路径，直接判定无效。
- 如果本阶段把真实 VM 启动或运行窗口逻辑混进来，直接回退到本 phase 边界。
