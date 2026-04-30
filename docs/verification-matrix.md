# Verification Matrix

phase-6 提供一个本地可复跑的矩阵入口：

```bash
ruby scripts/verify_matrix
```

默认会执行两个 lane：

- `smoke`：快速覆盖创建流程、runtime 展示模型和恢复映射
- `full`：执行完整 `phasTests` 测试集，作为回归基线

## 可用 lane

- `smoke`：创建流程、runtime 展示、恢复评估的快速烟雾验证
- `bundle`：bundle 持久化、虚拟化配置工厂、日志与生命周期策略回归
- `runtime`：首页/运行窗口展示和 runtime 相关回归
- `recovery`：relaunch 恢复、诊断和恢复动作规则回归
- `full`：完整测试集

## 常用命令

```bash
ruby scripts/verify_matrix --list
ruby scripts/verify_matrix smoke
ruby scripts/verify_matrix runtime recovery
ruby scripts/verify_matrix --skip-generate full
```

## 前置工具

- `xcodegen`
- `xcodebuild`
- 当前本机可用的 macOS 测试环境

## 失败语义

- 任一 lane 失败时，脚本会返回非零退出码
- 输出会保留 lane 名称、描述和失败命令上下文，便于定向复跑

## 当前未覆盖范围

- 不包含 release 文档和 acceptance ledger 检查
- 不包含远程 CI 平台配置
- 不包含真实 guest 安装过程的端到端 UI 自动化
