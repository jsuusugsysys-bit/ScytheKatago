#!/bin/bash
# 训练状态监控脚本

BASEDIR=~/scythe_training
cd $BASEDIR

echo "======================================"
echo "镰刀训练 - 状态监控"
echo "======================================"
echo "时间: $(date)"
echo ""

# 1. GPU状态
echo "[1] GPU 状态"
echo "---"
nvidia-smi --query-gpu=index,utilization.gpu,utilization.memory,memory.used,memory.total,temperature.gpu,power.draw --format=csv
echo ""

# 2. 进程状态
echo "[2] 进程状态"
echo "---"
selfplay_count=$(ps aux | grep -c 'katago selfplay' || echo 0)
shuffle_count=$(ps aux | grep -c 'shuffle.py' || echo 0)
train_count=$(ps aux | grep -c 'train.py' || echo 0)

echo "  Selfplay: $selfplay_count 个进程"
echo "  Shuffle:  $shuffle_count 个进程"
echo "  Train:    $train_count 个进程"
echo ""

# 3. 数据统计
echo "[3] 数据统计"
echo "---"
selfplay_size=$(du -sh selfplay 2>/dev/null | cut -f1)
selfplay_files=$(find selfplay -name "*.log" 2>/dev/null | wc -l)
shuffled_size=$(du -sh shuffled 2>/dev/null | cut -f1)
shuffled_files=$(find shuffled -name "*.npz" 2>/dev/null | wc -l)
exported_count=$(ls exported/*.bin.gz 2>/dev/null | wc -l)

echo "  Selfplay 数据: $selfplay_size ($selfplay_files 个log文件)"
echo "  Shuffled 数据: $shuffled_size ($shuffled_files 个npz文件)"
echo "  导出模型数量: $exported_count"
echo ""

# 4. 最新日志
echo "[4] 最新 Selfplay 进度"
echo "---"
if [ -f logs/selfplay_stable_gpu0.log ]; then
    tail -5 logs/selfplay_stable_gpu0.log | grep -E 'Started|NN rows|games' || echo "  暂无数据"
else
    echo "  日志文件未找到"
fi
echo ""

# 5. 训练进度
echo "[5] 训练进度"
echo "---"
if [ -f logs/train_daemon.log ]; then
    tail -10 logs/train_daemon.log | grep -E 'Epoch|Loss|Model saved' | tail -3 || echo "  训练尚未开始或暂无进度"
else
    echo "  训练尚未启动"
fi
echo ""

# 6. 预估统计
echo "[6] 性能估算"
echo "---"
if [ -f logs/selfplay_stable_gpu0.log ]; then
    # 提取最近的对局数
    latest_games=$(grep 'Started.*games' logs/selfplay_stable_gpu0.log | tail -1 | grep -oP 'Started \K\d+' || echo 0)

    if [ "$latest_games" -gt 0 ]; then
        # 计算运行时间（简化版，从第一条日志到现在）
        first_log=$(head -1 logs/selfplay_stable_gpu0.log | cut -d' ' -f1-2)
        current_time=$(date +"%Y-%m-%d %H:%M:%S")

        echo "  单GPU已完成: ~$latest_games 盘"
        echo "  8GPU总计: ~$((latest_games * 8)) 盘（估算）"

        # 检查最近日志时间（确认还在运行）
        last_log_time=$(tail -1 logs/selfplay_stable_gpu0.log | cut -d' ' -f1-2)
        echo "  最后更新: $last_log_time"
    else
        echo "  尚未产生对局数据"
    fi
else
    echo "  日志文件未找到"
fi
echo ""

echo "======================================"
echo "刷新命令: watch -n 5 ./monitor_status.sh"
echo "======================================"
