# Operator Guide

这个页面面向当前 MVP 的日常操作者，只保留最直接的入口和判断标准。

## 1. 生成与构建

- 生成工程：见 [build-run.md](build-run.md)
- 本地构建：见 [build-run.md](build-run.md)
- 完整验证矩阵：见 [verification-matrix.md](verification-matrix.md)

## 2. 创建 VM

- 从主窗口进入 `Create Virtual Machine`
- 只允许存在一台 VM
- 创建向导会在真正落盘前给出 blocking / warning 结果
- 创建流程细节见 [create-wizard.md](create-wizard.md)

## 3. 运行与控制

- 当唯一 VM 已存在时，首页主按钮会切换为 `Open Runtime Window`
- 首页详情区和运行窗口都会暴露生命周期按钮
- 运行窗口和控制语义见 [runtime-ui.md](runtime-ui.md)

## 4. 恢复与诊断

- 应用 relaunch 后会重新评估持久化状态
- 对于不可信的 `Running` / `Installing` 瞬时态，会显式映射到 `Error`
- 恢复动作和边界见 [recovery-diagnostics.md](recovery-diagnostics.md)

## 5. 验收与当前边界

- 当前 MVP 验收台账见 [acceptance-ledger.md](acceptance-ledger.md)
- 当前不覆盖多 VM、桥接网络、共享目录、剪贴板、音频、Rosetta 和 release 自动化
