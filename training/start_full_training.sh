#!/bin/bash
# 完整训练循环启动脚本
# selfplay → shuffle → train → export

set -e

BASEDIR=~/scythe_training
RUNNAME="scythe11"
MODELKIND="b6c96"
BATCHSIZE=256

cd $BASEDIR

echo "========================================"
echo "镰刀 KataGo 完整训练循环启动"
echo "========================================"
echo "数据目录: $BASEDIR"
echo "模型类型: $MODELKIND (6 blocks, 96 channels)"
echo "批量大小: $BATCHSIZE"
echo ""

# 创建必要目录
mkdir -p logs shuffled training exported models_toexport

# 检查依赖
echo "检查 Python 依赖..."
python3 -c "import torch; print(f'PyTorch: {torch.__version__}')" || {
  echo "错误: PyTorch 未安装！"
  echo "安装命令: pip3 install torch numpy"
  exit 1
}

echo ""
echo "========================================"
echo "步骤 1/4: Selfplay 已在运行"
echo "========================================"
ps aux | grep katago | grep selfplay | grep -v grep || echo "警告: selfplay 未运行"

echo ""
echo "========================================"
echo "步骤 2/4: 启动 Shuffle (数据混洗)"
echo "========================================"

# 启动 shuffle
nohup python3 katago/python/shuffle.py \
  $BASEDIR/selfplay \
  $BASEDIR/shuffled \
  -min-rows 250000 \
  -max-rows 2000000 \
  -expand-window-per-row 0.8 \
  -taper-window-per-row 0.1 \
  -out-tmp-dir $BASEDIR/shuffled/tmp \
  -keep-target-rows 1500000 \
  -num-processes 8 \
  > logs/shuffle.log 2>&1 &

SHUFFLE_PID=$!
echo "Shuffle PID: $SHUFFLE_PID"
echo $SHUFFLE_PID > logs/shuffle.pid

echo ""
echo "========================================"
echo "步骤 3/4: 启动 Training (模型训练)"
echo "========================================"

# 等待 shuffle 产生第一批数据
echo "等待 shuffle 产生训练数据..."
for i in {1..60}; do
  if ls $BASEDIR/shuffled/*.npz 1> /dev/null 2>&1; then
    echo "找到训练数据！"
    break
  fi
  echo "  等待中... ($i/60秒)"
  sleep 1
done

# 启动训练
nohup python3 katago/python/train.py \
  $BASEDIR/training \
  $BASEDIR/shuffled \
  $BASEDIR/models_toexport \
  -name-prefix ${RUNNAME}- \
  -model-kind $MODELKIND \
  -batch-size $BATCHSIZE \
  -lr-scale 1.0 \
  -max-train-bucket-per-new-data 4 \
  -max-train-bucket-size 5000000 \
  -sub-epochs 4 \
  -gpu-memory-frac 0.4 \
  > logs/train.log 2>&1 &

TRAIN_PID=$!
echo "Train PID: $TRAIN_PID"
echo $TRAIN_PID > logs/train.pid

echo ""
echo "========================================"
echo "步骤 4/4: 启动 Export (模型导出)"
echo "========================================"

# 启动导出循环
nohup bash -c '
BASEDIR='"$BASEDIR"'
while true; do
  for model_dir in $BASEDIR/models_toexport/*; do
    if [ -d "$model_dir" ] && [ ! -f "$model_dir/.exported" ]; then
      echo "[$(date)] 导出模型: $model_dir"
      python3 $BASEDIR/katago/python/export_model_pytorch.py \
        $model_dir \
        $BASEDIR/exported
      touch "$model_dir/.exported"

      # 复制到 selfplay 使用的 models 目录
      latest_export=$(ls -t $BASEDIR/exported/*.bin.gz 2>/dev/null | head -1)
      if [ -n "$latest_export" ]; then
        cp "$latest_export" $BASEDIR/models/model.bin.gz
        echo "[$(date)] 新模型已部署到 selfplay"
      fi
    fi
  done
  sleep 60
done
' > logs/export.log 2>&1 &

EXPORT_PID=$!
echo "Export PID: $EXPORT_PID"
echo $EXPORT_PID > logs/export.pid

echo ""
echo "========================================"
echo "训练循环已启动！"
echo "========================================"
echo ""
echo "进程状态:"
echo "  Selfplay: $(pgrep -c -f 'katago selfplay') 个进程"
echo "  Shuffle:  PID $SHUFFLE_PID"
echo "  Train:    PID $TRAIN_PID"
echo "  Export:   PID $EXPORT_PID"
echo ""
echo "监控命令:"
echo "  tail -f logs/shuffle.log   # 数据混洗日志"
echo "  tail -f logs/train.log     # 训练日志"
echo "  tail -f logs/export.log    # 导出日志"
echo ""
echo "停止命令:"
echo "  pkill -P $SHUFFLE_PID; pkill -P $TRAIN_PID; pkill -P $EXPORT_PID"
echo ""
