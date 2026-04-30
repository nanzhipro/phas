# Phase 4 执行包

本文件不能单独使用。执行 Phase 4 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-4-runtime-ui.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-4-runtime-ui.md`

## 执行目标

- 把 phase-3 的虚拟化后端能力接到真实 GUI，让单 VM 运行路径在产品表面闭环。
- 在不引入恢复/诊断/发布工作的前提下，先把详情展示、运行窗口和生命周期控制做完整。

## 本次允许改动

- `App/**`
- `Features/**`
- `Domain/**`
- `Infrastructure/**`
- `Resources/**`
- `Tests/**`
- `docs/**`
- `README.md`
- `.gitignore`

## 本次不要做

- 不实现应用 relaunch 后的会话恢复、损坏 bundle 自动修复、日志导出或验证矩阵自动化。
- 不扩展为多 VM 管理器，也不提前做 phase-5 的诊断工作流或 phase-6/7 的收尾材料。
- 不让 UI 直接持有或拼装 `VZVirtualMachineConfiguration` 细节。

## 交付检查

- 至少一组自动化测试覆盖运行详情展示模型或按钮 enable/disable 规则。
- 至少一组自动化测试覆盖运行窗口绑定边界或运行会话注入路径，不允许把 delegate 细节泄漏到视图层。
- `xcodebuild test` 必须通过，且运行窗口相关代码路径参与真实编译。
- 文档明确说明运行窗口入口、生命周期按钮语义和当前仍未覆盖的恢复边界。

## 执行裁决规则

- 如果 UI 仍需直接理解 `VZVirtualMachine` delegate 才能更新状态，直接判定无效。
- 如果在不允许的状态下仍然暴露 Start/Stop/Force Stop 按钮入口，直接判定无效。
- 如果本阶段把应用 relaunch 恢复、诊断导出或 release 文档提前混进来，直接回退到本 phase 边界。
- 如果运行窗口没有真正绑定 `VZVirtualMachineView`，只做静态占位，则直接判定无效。
