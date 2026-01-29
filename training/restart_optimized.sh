#!/bin/bash
# 停止当前训练，使用优化配置重启

set -e

cd ~/scythe_training

echo "======================================"
echo "镰刀训练 - 优化配置重启"
echo "======================================"
echo ""

# 1. 停止当前selfplay
echo "步骤 1: 停止当前 selfplay 进程..."
pkill -9 katago || true
sleep 3

echo "确认进程已停止:"
ps aux | grep katago | grep -v grep || echo "  ✓ 所有 katago 进程已停止"
echo ""

# 2. 备份当前数据
echo "步骤 2: 备份当前数据..."
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp -r models $BACKUP_DIR/
echo "  ✓ 模型已备份到 $BACKUP_DIR/"
echo ""

# 3. 使用优化配置重启8GPU selfplay
echo "步骤 3: 使用优化配置重启 8GPU selfplay..."
echo ""

for gpu in 0 1 2 3 4 5 6 7; do
  CUDA_VISIBLE_DEVICES=$gpu nohup ./katago/cpp/build/katago selfplay \
    -config configs/selfplay_scythe_final_optimized.cfg \
    -models-dir models \
    -output-dir selfplay \
    -override-config numNNServerThreadsPerModel=1,numGameThreads=400 \
    > logs/selfplay_opt_gpu$gpu.log 2>&1 &

  PID=$!
  echo "  ✓ GPU $gpu: PID $PID"
  sleep 1
done

echo ""
echo "======================================"
echo "Selfplay 优化版已启动"
echo "======================================"
echo ""
echo "关键优化:"
echo "  • maxMovesPerGame: 200 → 65 (节省67%)"
echo "  • numGameThreads: 300 → 3200"
echo "  • nnMaxBatchSize: 256 → 640"
echo "  • resignThreshold: -0.90 → -0.85"
echo "  • scytheRandomTriggerRate: 0.35 → 0.50"
echo ""
echo "预期性能:"
echo "  • 跑谱速度: ~20,000 盘/分钟"
echo "  • GPU 利用率: 80%+"
echo "  • 8小时产出: 60-80万盘"
echo ""
echo "监控命令:"
echo "  watch -n 1 nvidia-smi"
echo "  tail -f logs/selfplay_opt_gpu0.log"
echo ""
echo "等待10秒后检查GPU利用率..."
sleep 10

nvidia-smi --query-gpu=index,utilization.gpu,memory.used --format=csv
echo ""
echo "如果GPU利用率仍然很低，可能需要进一步调整 numGameThreads"
echo ""
