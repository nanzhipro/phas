# Phase 6 执行包

本文件不能单独使用。执行 Phase 6 时，必须同时携带完整的 `plan/common.md` 和 `plan/phases/phase-6-verification-matrix.md`。

## 必带上下文

- `plan/common.md`
- `plan/phases/phase-6-verification-matrix.md`

## 执行目标

- 把当前项目的验证路径固化为本地可复跑的 smoke/regression matrix。
- 在不进入 release 收尾的前提下，先把“如何证明仓库仍然健康”自动化。

## 本次允许改动

- `App/**`
- `Features/**`
- `Domain/**`
- `Infrastructure/**`
- `Resources/**`
- `Tests/**`
- `docs/**`
- `scripts/**`
- `README.md`
- `.gitignore`

## 本次不要做

- 不实现 CI 平台耦合脚本作为唯一验证入口。
- 不提前写 phase-7 的 release/acceptance 文档或归档动作。
- 不通过删除测试、弱化断言或隐藏失败来“让矩阵通过”。

## 交付检查

- 至少一个脚本入口把 smoke lane 与 regression lane 组织起来。
- 脚本在 lane 失败时返回非零退出码，并给出足够的 lane 级摘要。
- 至少实际执行一次矩阵入口，当前仓库通过。
- 文档明确说明 lane 覆盖范围、前置工具和推荐调用方式。

## 执行裁决规则

- 如果矩阵入口只是一段文档，没有真实脚本命令，直接判定无效。
- 如果脚本失败时仍返回零退出码，直接判定无效。
- 如果矩阵没有覆盖 runtime 或 recovery 相关路径，直接判定无效。
- 如果本阶段把 release 文档或最终验收台账提前混进来，直接回退到本 phase 边界。
