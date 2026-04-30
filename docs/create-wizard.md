# Create Wizard And Admission Gates

phase-2 把首页的“Create Virtual Machine”从占位按钮升级为真实的创建向导，并锁定以下输入与校验边界：

- 输入项：VM 名称、安装镜像路径、CPU、内存、磁盘
- 预设：Light = 2 vCPU / 4 GiB / 32 GiB，Standard = 4 vCPU / 8 GiB / 64 GiB
- 宿主机摘要：Apple silicon / macOS 版本、总内存、可用 CPU、推荐预设

当前 blocking 规则：

- 宿主机不是 Apple silicon
- macOS 版本低于 14
- 已存在 1 台 VM，违反单 VM MVP 边界
- ISO 路径不存在、不可读、指向目录或扩展名明显不对
- ISO 文件名显式表明是 x86_64 / amd64 镜像
- CPU、内存、磁盘低于产品下限
- CPU 或内存超过当前宿主机安全阈值
- 可用磁盘空间不足以创建 bundle 并留出安装余量

当前 warning 规则：

- ISO 文件名无法确认 ARM64
- 发行版不在 Ubuntu Desktop ARM64 主验收或 Fedora Workstation ARM64 补充验证范围内
- Fedora 虽可继续，但只属于补充验证矩阵

创建成功后，应用会立即写入一个 `Draft` VM bundle，并在首页展示该 VM 的摘要；后续 phase 再把它接入真实启动与运行路径。