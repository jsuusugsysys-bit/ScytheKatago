# KataGo 镰刀训练指南

## 快速开始（8卡 RTX 5090 Linux）

### 1. 上传代码到服务器

```bash
# 在本地 Windows
scp -r D:/ScytheKatago/KataGo user@server:/home/user/katago_scythe_training/katago
scp -r D:/ScytheKatago/training/* user@server:/home/user/katago_scythe_training/
```

### 2. 编译 KataGo（在服务器上）

```bash
ssh user@server
cd /home/user/katago_scythe_training/katago/cpp

# 安装依赖
sudo apt update
sudo apt install cmake g++ libzip-dev zlib1g-dev libgoogle-perftools-dev

# 编译 CUDA 版本
mkdir -p build && cd build
cmake .. -DUSE_BACKEND=CUDA -DUSE_TCMALLOC=1 -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# 验证编译
./katago version
```

### 3. 准备基础模型

```bash
cd /home/user/katago_scythe_training/models

# 下载 KataGo 官方小模型作为起点
wget -O base_model.bin.gz \
  "https://media.katagotraining.org/uploaded/networks/models/kata1/kata1-b6c96-s175395328-d26788732.bin.gz"
```

### 4. 配置训练参数

```bash
cd /home/user/katago_scythe_training/configs

# 复制配置文件
cp ../katago/cpp/configs/training/selfplay_scythe.cfg .

# 根据需要调整（可选）
vim selfplay_scythe.cfg
```

### 5. 安装 Python 依赖

```bash
pip install torch numpy scipy matplotlib tensorboard
```

### 6. 启动训练

```bash
cd /home/user/katago_scythe_training
chmod +x *.sh scripts/*.sh

# 设置环境变量
export BASEDIR=/home/user/katago_scythe_training
export KATAGO_BIN=$BASEDIR/katago/cpp/build/katago
export CONFIG_FILE=$BASEDIR/configs/selfplay_scythe.cfg
export BACKUP_DIR=/home/user/backup
export REMOTE_BACKUP=""  # 可选：rsync 远程备份地址

# 启动训练
./start_training.sh
```

### 7. 监控训练

```bash
# 查看状态
./status.sh

# 实时日志
tail -f logs/selfplay.log
tail -f logs/training.log

# GPU 使用情况
watch -n 1 nvidia-smi
```

### 8. 获取训练好的模型

```bash
# 查看已导出的模型
ls -la exported/

# 下载最新模型（在本地）
scp user@server:/home/user/katago_scythe_training/exported/scythe_*.bin.gz ./
```

---

## 备份策略

训练自动每小时备份以下内容：
- `models/` - 所有模型文件
- `exported/` - 导出的模型
- `training/` - 最新训练检查点
- `configs/` - 配置文件

备份位置：
- 本地: `/home/user/backup/`
- 远程: 设置 `REMOTE_BACKUP` 环境变量

**重要**：租用机器随时可能回收，建议：
1. 设置远程备份到自己的服务器
2. 定期手动下载重要模型
3. 记录训练进度

---

## 配置说明

### selfplay_scythe.cfg 关键参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `scytheRandomMode` | true | 启用镰刀随机触发 |
| `scytheRandomTriggerRate` | 0.35 | 35% 的手数会触发镰刀 |
| `bSizes` | 11 | 仅 11x11 棋盘 |
| `numGameThreads` | 2400 | 并行游戏数 |
| `maxVisits` | 400 | 每手搜索访问数 |

### GPU 配置

默认使用全部 8 张 GPU：
```
cudaDeviceToUseModel0Thread0 = 0
cudaDeviceToUseModel0Thread1 = 1
...
cudaDeviceToUseModel0Thread7 = 7
```

### 网络架构

推荐 11x11 使用较小网络：
- `b6c96` - 6 层, 96 通道 (快速训练)
- `b10c128` - 10 层, 128 通道 (更强)

---

## 预期时间线

| 时间 | 预期进度 |
|------|---------|
| 1-2 小时 | 自对弈开始产生数据 |
| 4-6 小时 | 第一个训练模型导出 |
| 12-24 小时 | 模型开始有基本棋力 |
| 2-3 天 | 模型达到业余高段水平 |
| 1-2 周 | 模型达到有竞争力水平 |

---

## 常见问题

### Q: 训练启动失败？
A: 检查：
- CUDA 是否正确安装：`nvidia-smi`
- KataGo 是否编译成功：`./katago version`
- 配置文件路径是否正确

### Q: GPU 使用率很低？
A: 增加 `numGameThreads`，8 卡建议 2000-3000

### Q: 磁盘空间不足？
A: 自对弈数据增长很快，建议：
- 定期清理旧的 selfplay 数据
- 只保留最新的 shuffled 数据
- 使用 `du -sh *` 查看空间占用

### Q: 如何恢复中断的训练？
A: 只需重新运行 `./start_training.sh`，会自动从最新检查点继续

---

## 野狐测试

训练产出模型后：

1. **下载模型**到本地 Windows
2. **配置 lizzieyzy** 使用新模型
3. **启动 lizzieyzy**，选择 11x11 棋盘
4. **连接野狐**，开始镰刀对弈

详细步骤见 `README_YAHU_TEST.md`（待创建）
