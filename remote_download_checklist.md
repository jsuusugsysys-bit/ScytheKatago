# 远程服务器文件下载检查清单

**检查时间**: 2026-01-24
**远程服务器**: jxcb@123.181.192.94:60022
**远程目录**: `/home/jxcb/scythe_training/`

---

## 📋 文件下载状态检查

### ✅ 已在本地的文件

| 文件类型 | 本地路径 | 说明 |
|---------|---------|------|
| 训练脚本 | `D:\ScytheKatago\training\benchmark_selfplay.sh` | ✅ 已存在（2026-01-23） |
| 配置文件 | `D:\ScytheKatago\training\selfplay_scythe_final_optimized.cfg` | ✅ 已存在 |
| 配置文件 | `D:\ScytheKatago\KataGo\cpp\configs\training\selfplay_scythe.cfg` | ✅ 已存在 |
| 模型文件 | `D:\ScytheKatago\kata1-b6c96.bin.gz` | ✅ 已存在 |
| 模型文件 | `D:\ScytheKatago\scythe11.bin.gz` | ✅ 已存在 |

### ❌ 需要从远程下载的文件

#### 🔴 高优先级（必须下载）

| 远程路径 | 说明 | 为什么需要 | 本地保存位置 |
|---------|------|-----------|-------------|
| `/home/jxcb/scythe_training/configs/selfplay_scythe.cfg` | **实际运行的配置文件** | 远程实际运行参数，与本地可能不同 | `D:\ScytheKatago\remote_training\configs\` |
| `/home/jxcb/scythe_training/start_8gpu.sh` | **8 GPU 启动脚本** | 多 GPU 并行启动逻辑 | `D:\ScytheKatago\remote_training\scripts\` |
| `/home/jxcb/scythe_training/logs/selfplay_gpu*.log` | **训练日志（最新）** | 了解训练状态、参数、错误 | `D:\ScytheKatago\remote_training\logs\` |
| `/home/jxcb/backup_training_data.sh` | **备份脚本** | 远程的备份策略 | `D:\ScytheKatago\remote_training\scripts\` |

#### 🟡 中优先级（建议下载）

| 远程路径 | 说明 | 为什么需要 | 本地保存位置 |
|---------|------|-----------|-------------|
| `/home/jxcb/scythe_training/katago/cpp/build/katago` | **TensorRT 编译版** | 与 CUDA 版性能对比 | `D:\ScytheKatago\remote_training\katago_tensorrt\` |
| `/home/jxcb/scythe_training/models/*.bin.gz` | **远程训练的模型** | 如果远程有新模型 | `D:\ScytheKatago\remote_training\models\` |
| `/home/jxcb/backup_20260123/` | **最新备份** | 配置快照 | `D:\ScytheKatago\backups\` |

#### ⚪ 低优先级（可选）

| 远程路径 | 说明 | 为什么可选 | 本地保存位置 |
|---------|------|-----------|-------------|
| `/home/jxcb/tensorrt.deb` | TensorRT 安装包 | 本地 Windows 用不上 | `D:\ScytheKatago\installers\` |
| `/home/jxcb/scythe_training/katago/cpp/` | KataGo 源码 | 本地已有 | 不需要下载 |

#### ❌ 不要下载

| 远程路径 | 说明 | 为什么跳过 |
|---------|------|-----------|
| `/home/jxcb/scythe_training/selfplay/` | 自对弈数据（48GB） | 太大，服务器上保留 |
| `/home/jxcb/scythe_training/training/` | 训练数据 | 服务器上保留 |

---

## 🎯 关键差异分析

### 远程 vs 本地配置文件

| 项目 | 本地 | 远程（预期） |
|------|------|-------------|
| 配置文件 | `selfplay_scythe_final_optimized.cfg` | `selfplay_scythe.cfg` |
| 修改时间 | 2026-01-22 | 2026-01-23（可能更新） |
| 参数 | 本地优化版 | **实际运行版（可能有 override）** |
| 语法错误 | 未知 | ⚠️ 已知第 190 行有中文注释 |

**重要**: 远程配置文件有两个版本：
1. **configs/selfplay_scythe.cfg** - 基础配置
2. **实际运行时的 override 参数** - 在启动脚本中

根据 `handoff_katago.md`:
- 配置写的: `numGameThreads=800`
- 实际运行: `numGameThreads=300` (override)

### 8 GPU 启动脚本

**本地缺失**: `start_8gpu.sh`

这是关键文件，包含：
- 每个 GPU 的独立进程启动
- `CUDA_VISIBLE_DEVICES` 环境变量设置
- nohup 后台运行逻辑
- 参数 override 逻辑

**必须下载**，否则无法复现远程的 8 GPU 训练。

---

## 📊 本地已有的训练资源

### ✅ 可用的训练脚本

本地 `D:\ScytheKatago\training\` 目录已有：

| 脚本 | 功能 | 可用性 |
|------|------|--------|
| `benchmark_selfplay.sh` | 参数测试 | ✅ 可用（2026-01-23） |
| `start_full_training.sh` | 完整训练启动 | ✅ 可用 |
| `stable_training_daemon.sh` | 守护进程 | ✅ 可用 |
| `monitor_status.sh` | 状态监控 | ✅ 可用 |
| `restart_optimized.sh` | 优化重启 | ✅ 可用 |

**但缺少**: `start_8gpu.sh` - 8 GPU 并行启动脚本

### ✅ 可用的模型文件

| 模型 | 大小 | 说明 |
|------|------|------|
| `kata1-b6c96.bin.gz` | ~100MB | KataGo 官方 b6c96 模型 |
| `scythe11.bin.gz` | 未知 | 本地训练的镰刀模型？ |

### ✅ 可用的配置文件

| 配置 | 路径 | 说明 |
|------|------|------|
| `selfplay_scythe_final_optimized.cfg` | `training/` | 本地优化版 |
| `selfplay_scythe.cfg` | `KataGo/cpp/configs/training/` | KataGo 源码版 |

---

## 🚀 下一步行动建议

### 方案 1：最小必要下载（推荐）

只下载**关键差异文件**，快速迁移到新服务器：

```
必须下载（优先级 1）:
1. /home/jxcb/scythe_training/start_8gpu.sh
2. /home/jxcb/scythe_training/configs/selfplay_scythe.cfg
3. /home/jxcb/scythe_training/logs/*.log（最新 1-2 个）

可选下载（优先级 2）:
4. /home/jxcb/backup_training_data.sh
5. /home/jxcb/scythe_training/katago/cpp/build/katago（TensorRT 版）
```

**下载后操作**:
1. 对比远程和本地配置差异
2. 修复远程配置第 190 行中文注释
3. 合并 start_8gpu.sh 逻辑到本地脚本

### 方案 2：完整备份（保险）

下载所有配置、脚本、日志（不含数据）：

```
下载清单:
- configs/ 完整目录
- *.sh 所有脚本
- logs/ 最新日志
- models/ 如果有新模型
- katago TensorRT 可执行文件
- backup_20260123/ 备份
```

**适合**: 担心遗漏，想要完整备份

---

## 💡 迁移到新服务器的准备

### 需要上传到新服务器的文件

**核心文件（优先级 1）**:
1. ✅ KataGo 源码（本地 `D:\ScytheKatago\KataGo\`）
   - 包含镰刀修改的 boardhistory.cpp/h, gtp.cpp
2. ✅ 训练配置（下载后对比选最优）
3. ✅ 启动脚本（合并本地 + 远程的 8 GPU 脚本）
4. ✅ 初始模型（kata1-b6c96.bin.gz）

**辅助文件（优先级 2）**:
5. ✅ 监控脚本（本地已有）
6. ✅ 备份脚本（下载远程的）

### 新服务器操作流程

```bash
# 1. 上传 KataGo 源码到新服务器
scp -r D:\ScytheKatago\KataGo user@new-server:~/scythe_training/

# 2. 上传配置和脚本
scp D:\ScytheKatago\remote_training\configs\selfplay_scythe.cfg user@new-server:~/scythe_training/configs/
scp D:\ScytheKatago\remote_training\scripts\start_8gpu.sh user@new-server:~/scythe_training/

# 3. 上传模型
scp D:\ScytheKatago\kata1-b6c96.bin.gz user@new-server:~/scythe_training/models/

# 4. SSH 登录新服务器
ssh user@new-server

# 5. 编译 KataGo（根据 GPU 后端选择）
cd ~/scythe_training/katago/cpp/build
cmake .. -DUSE_BACKEND=CUDA  # 或 TENSORRT
make -j$(nproc)

# 6. 修复配置文件语法
sed -i '190d' ~/scythe_training/configs/selfplay_scythe.cfg

# 7. 启动训练
chmod +x ~/scythe_training/start_8gpu.sh
./start_8gpu.sh
```

---

## ⚠️ 重要注意事项

### 配置文件语法错误

**已知问题**: 远程 `selfplay_scythe.cfg` 第 190 行有中文注释
```
maxMoves游戏限制 = 70
```

**修复方法**:
```bash
# 删除该行
sed -i '190d' configs/selfplay_scythe.cfg

# 或改为合法格式
sed -i 's/maxMoves游戏限制/maxMoves/' configs/selfplay_scythe.cfg
```

### 参数 Override

远程实际运行参数可能与配置文件不同，需检查：
- `start_8gpu.sh` 中的命令行参数
- 日志中的实际参数值

### GPU 后端选择

| 后端 | 适用场景 | 编译参数 |
|------|---------|---------|
| CUDA | 通用，稳定 | `-DUSE_BACKEND=CUDA` |
| TensorRT | 最佳性能 | `-DUSE_BACKEND=TENSORRT` |
| OpenCL | AMD/Intel GPU | `-DUSE_BACKEND=OPENCL` |

远程服务器用的是 **TensorRT**，新服务器建议也用 TensorRT。

---

## ✅ 检查清单（下载前）

下载前确认：
- [ ] WinSCP 已连接到远程服务器
- [ ] 本地已创建 `D:\ScytheKatago\remote_training\` 目录
- [ ] 已创建子目录：`configs\`, `scripts\`, `logs\`, `models\`
- [ ] 确认远程目录路径：`/home/jxcb/scythe_training/`

## ✅ 检查清单（下载后）

下载完成后检查：
- [ ] `remote_training\configs\selfplay_scythe.cfg` 存在
- [ ] `remote_training\scripts\start_8gpu.sh` 存在
- [ ] `remote_training\logs\` 有日志文件
- [ ] 对比远程和本地配置差异
- [ ] 修复配置文件语法错误
- [ ] 更新 `handoff_katago.md` 交接文档

---

## 📝 总结

**当前状态**:
- ✅ 本地已有大部分训练脚本和模型
- ❌ 缺少远程实际运行的配置和 8 GPU 启动脚本
- ❌ 缺少远程训练日志（了解实际运行参数）

**建议操作**:
1. **最小下载**: `start_8gpu.sh` + `configs/selfplay_scythe.cfg` + 最新日志
2. **对比差异**: 远程配置 vs 本地配置
3. **合并优化**: 将远程的 8 GPU 逻辑合并到本地脚本
4. **准备迁移**: 整理上传清单，准备新服务器

**预估下载时间**:
- 最小下载：<5 分钟（几十 KB）
- 完整下载（含日志、模型）：10-30 分钟（几百 MB）

---

**下次租用新服务器时，需要做的事**:
1. 上传 KataGo 源码（含镰刀修改）
2. 上传优化后的配置和脚本
3. 上传初始模型
4. 编译 KataGo（选择合适的 GPU 后端）
5. 启动训练
6. 监控 GPU 利用率和训练进度

祝训练顺利！
