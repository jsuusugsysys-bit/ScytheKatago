#!/bin/bash
# 镰刀权重训练脚本 - 快速版（2-4小时）
# 执行方式: ssh登录服务器后，复制粘贴以下命令

set -e  # 遇到错误立即退出

echo "========================================="
echo "镰刀 KataGo 权重训练 - 快速版"
echo "预计耗时: 2-4小时"
echo "========================================="

# 切换到工作目录
cd ~/scythe_training

# ==========================================
# 步骤1: Shuffle 数据（10-30分钟）
# ==========================================
echo ""
echo "[步骤1/4] 开始 shuffle selfplay 数据..."
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 检查 selfplay 数据是否存在
if [ ! -d "selfplay" ]; then
    echo "❌ 错误: selfplay 目录不存在！"
    exit 1
fi

SELFPLAY_SIZE=$(du -sh selfplay | cut -f1)
echo "✓ selfplay 数据大小: $SELFPLAY_SIZE"

# 清空旧的 shuffleddata（节省空间）
echo "清理旧的 shuffleddata..."
rm -rf shuffleddata/*

# 运行 shuffle
echo "开始 shuffle（这会需要10-30分钟，请耐心等待）..."
./katago/katago shuffle \
  -config configs/shuffle.cfg \
  -output-dir shuffleddata \
  selfplay/*.npz \
  2>&1 | tee logs/shuffle_$(date +%Y%m%d_%H%M%S).log

SHUFFLE_SIZE=$(du -sh shuffleddata | cut -f1)
echo "✓ Shuffle 完成！shuffleddata 大小: $SHUFFLE_SIZE"

# ==========================================
# 步骤2: 训练 5000 步（1-2小时）
# ==========================================
echo ""
echo "[步骤2/4] 开始训练 5000 步..."
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 备份当前 checkpoint
if [ -f "training/checkpoint.ckpt" ]; then
    cp training/checkpoint.ckpt training/checkpoint_backup_$(date +%Y%m%d_%H%M%S).ckpt
    echo "✓ 已备份旧 checkpoint"
fi

# 运行训练（5000步，约1-2小时）
echo "开始训练（预计1-2小时）..."
./katago/katago train \
  -config configs/train.cfg \
  -train-from-checkpoint training/checkpoint.ckpt \
  -num-train-steps 5000 \
  -max-train-steps 5000 \
  2>&1 | tee logs/train_quick_$(date +%Y%m%d_%H%M%S).log

echo "✓ 训练完成！"

# ==========================================
# 步骤3: 导出新权重（1分钟）
# ==========================================
echo ""
echo "[步骤3/4] 导出新权重..."
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 创建导出目录
mkdir -p exported

# 导出新权重
EXPORT_NAME="scythe_trained_$(date +%Y%m%d_%H%M%S).bin.gz"
./katago/katago model \
  -config configs/gtp.cfg \
  -model training/checkpoint.ckpt \
  -export-model exported/$EXPORT_NAME

echo "✓ 新权重已导出到: exported/$EXPORT_NAME"
echo ""
echo "========================================="
echo "✅ 新权重路径（完整）:"
echo "~/scythe_training/exported/$EXPORT_NAME"
echo "========================================="

# ==========================================
# 步骤4: 对比测试（30-60分钟）
# ==========================================
echo ""
echo "[步骤4/4] 对比新旧权重棋力..."
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"

# 检查旧权重是否存在
OLD_MODEL="models/model.txt.gz"  # 或您的初始权重路径
if [ ! -f "$OLD_MODEL" ]; then
    echo "⚠️  警告: 找不到旧权重 $OLD_MODEL"
    echo "请手动指定旧权重路径进行对比测试"
    exit 0
fi

# 运行对比测试（100局）
echo "开始对比测试（新vs旧，100局，约30-60分钟）..."
./katago/katago match \
  -config configs/gtp.cfg \
  -sgf-output-dir benchmark/quick_test_$(date +%Y%m%d) \
  -log-file logs/match_quick_$(date +%Y%m%d_%H%M%S).log \
  -numGamesTotal 100 \
  -model1 exported/$EXPORT_NAME \
  -model2 $OLD_MODEL \
  -model1name "Scythe_New_5000steps" \
  -model2name "Scythe_Initial" \
  -rules scythe \
  -boardSize 11 \
  -komi 7.5

echo ""
echo "========================================="
echo "✅ 所有任务完成！"
echo "========================================="
echo ""
echo "📊 结果汇总:"
echo "1. 新权重路径: ~/scythe_training/exported/$EXPORT_NAME"
echo "2. 对比测试结果: logs/match_quick_*.log"
echo "3. 对局 SGF: benchmark/quick_test_*/  "
echo ""
echo "📥 下载新权重到本地:"
echo "使用 WinSCP 或 scp 命令:"
echo "scp -P 60022 jxcb@123.181.192.94:~/scythe_training/exported/$EXPORT_NAME D:\\ScytheKatago\\"
echo ""
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
