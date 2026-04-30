# Phase 5 执行包

本文件不能单独使用。执行 Phase 5 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-5-recovery-diagnostics.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-5-recovery-diagnostics.md`

## 执行目标

- 把 phase-4 的运行界面补全为“应用重启后仍然可信”的产品状态机。
- 在不进入验证矩阵和 release 收尾的前提下，先把恢复与诊断工作流做成产品可见能力。

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

- 不实现 phase-6 的自动化矩阵脚本和 phase-7 的 release/acceptance 文档。
- 不引入后台守护、远程日志上报或任何需要云服务的恢复逻辑。
- 不用静默数据改写替代用户可见恢复动作。

## 交付检查

- 至少一组自动化测试覆盖应用 relaunch 后的状态恢复映射，特别是 `Running` / `Installing` 无真实会话时的错误化处理。
- 至少一组自动化测试覆盖诊断快照或恢复动作规则，确保用户可见动作与状态一致。
- `xcodebuild test` 必须通过，且恢复/诊断相关代码路径参与真实编译。
- 文档明确说明 relaunch 恢复语义、脏状态如何处理、哪些动作仍然需要用户显式确认。

## 执行裁决规则

- 如果实现继续把不可信的瞬时态展示为“正常运行”，直接判定无效。
- 如果恢复逻辑会静默删除、重置或覆盖 VM bundle 数据，直接判定无效。
- 如果诊断仍然只有笼统 alert，没有恢复结论和明确动作，直接判定无效。
- 如果本阶段把验证矩阵或 release 收尾提前混进来，直接回退到本 phase 边界。
