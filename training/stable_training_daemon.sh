#!/bin/bash
# 镰刀训练守护进程 - 稳定版
# 确保即使 SSH 断开也能持续运行
# 策略：稳定 > 速度

set -e

BASEDIR=~/scythe_training
cd $BASEDIR

echo "======================================"
echo "镰刀训练守护进程 - 启动"
echo "======================================"
echo "优先级: 稳定性 > 性能"
echo "特性: SSH断开自动继续运行"
echo ""

# 创建必要目录
mkdir -p logs models shuffled training exported models_toexport

# 1. 检查并使用保守优化的配置
echo "[1/4] 配置选择..."

if [ -f "configs/selfplay_scythe_final_optimized.cfg" ]; then
    # 如果存在激进优化配置，创建一个稳定版
    echo "  创建稳定版配置（基于优化版，但更保守）..."

    sed 's/numGameThreads = 3200/numGameThreads = 1600/;
         s/nnMaxBatchSize = 640/nnMaxBatchSize = 384/;
         s/maxMovesPerGame = 65/maxMovesPerGame = 75/;
         s/scytheRandomTriggerRate = 0.50/scytheRandomTriggerRate = 0.40/;
         s/maxVisits = 280/maxVisits = 320/' \
        configs/selfplay_scythe_final_optimized.cfg > configs/selfplay_stable.cfg

    CONFIG_FILE="configs/selfplay_stable.cfg"
    echo "  ✓ 使用稳定配置: $CONFIG_FILE"
else
    CONFIG_FILE="configs/selfplay_scythe.cfg"
    echo "  ✓ 使用原始配置: $CONFIG_FILE"
fi

echo ""
echo "当前配置参数:"
grep -E 'numGameThreads|maxMovesPerGame|nnMaxBatchSize|scytheRandomTriggerRate' $CONFIG_FILE | sed 's/^/  /'
echo ""

# 2. 停止现有进程（如果有）
echo "[2/4] 清理现有进程..."
pkill -9 katago 2>/dev/null || echo "  无旧进程"
pkill -f "shuffle.py" 2>/dev/null || true
pkill -f "train.py" 2>/dev/null || true
sleep 3
echo "  ✓ 环境已清理"
echo ""

# 3. 启动 Selfplay（8 GPU，后台守护）
echo "[3/4] 启动 Selfplay 守护进程..."

for gpu in 0 1 2 3 4 5 6 7; do
    # 每个GPU独立进程，400个游戏线程（保守）
    CUDA_VISIBLE_DEVICES=$gpu nohup setsid ./katago/cpp/build/katago selfplay \
        -config $CONFIG_FILE \
        -models-dir models \
        -output-dir selfplay \
        -override-config numNNServerThreadsPerModel=1,numGameThreads=400 \
        > logs/selfplay_stable_gpu${gpu}.log 2>&1 &

    PID=$!
    echo $PID > logs/selfplay_gpu${gpu}.pid
    echo "  ✓ GPU $gpu: PID $PID"
    sleep 1
done

echo "  ✓ 8个GPU selfplay进程已启动"
echo ""

# 4. 启动训练循环（异步，后台）
echo "[4/4] 启动训练循环守护进程..."

# 4.1 Shuffle 守护进程
nohup setsid bash -c '
BASEDIR=~/scythe_training
cd $BASEDIR

while true; do
    echo "[$(date)] Shuffle 守护进程运行中..."

    python3 katago/python/shuffle.py \
        $BASEDIR/selfplay \
        $BASEDIR/shuffled \
        -min-rows 200000 \
        -max-rows 1500000 \
        -expand-window-per-row 0.8 \
        -taper-window-per-row 0.1 \
        -out-tmp-dir $BASEDIR/shuffled/tmp \
        -keep-target-rows 1200000 \
        -num-processes 6 \
        2>&1 | tee -a $BASEDIR/logs/shuffle_daemon.log

    # 如果shuffle异常退出，等待后重启
    echo "[$(date)] Shuffle进程退出，10秒后重启..." | tee -a $BASEDIR/logs/shuffle_daemon.log
    sleep 10
done
' > /dev/null 2>&1 &

SHUFFLE_PID=$!
echo $SHUFFLE_PID > logs/shuffle_daemon.pid
echo "  ✓ Shuffle 守护进程: PID $SHUFFLE_PID"

# 4.2 等待初始数据
echo "  等待 shuffle 产生初始数据（最多60秒）..."
for i in {1..60}; do
    if ls shuffled/*.npz 1> /dev/null 2>&1; then
        echo "  ✓ 训练数据已就绪"
        break
    fi
    sleep 1
    [ $((i % 10)) -eq 0 ] && echo "    等待中... ${i}秒"
done

# 4.3 Train 守护进程
nohup setsid bash -c '
BASEDIR=~/scythe_training
cd $BASEDIR

while true; do
    echo "[$(date)] Train 守护进程运行中..."

    python3 katago/python/train.py \
        $BASEDIR/training \
        $BASEDIR/shuffled \
        $BASEDIR/models_toexport \
        -name-prefix scythe11- \
        -model-kind b6c96 \
        -batch-size 256 \
        -lr-scale 1.0 \
        -max-train-bucket-per-new-data 3 \
        -max-train-bucket-size 4000000 \
        -sub-epochs 4 \
        -gpu-memory-frac 0.35 \
        2>&1 | tee -a $BASEDIR/logs/train_daemon.log

    # 如果训练异常退出，等待后重启
    echo "[$(date)] Train进程退出，15秒后重启..." | tee -a $BASEDIR/logs/train_daemon.log
    sleep 15
done
' > /dev/null 2>&1 &

TRAIN_PID=$!
echo $TRAIN_PID > logs/train_daemon.pid
echo "  ✓ Train 守护进程: PID $TRAIN_PID"

# 4.4 Export 守护进程
nohup setsid bash -c '
BASEDIR=~/scythe_training
cd $BASEDIR

while true; do
    sleep 120  # 每2分钟检查一次

    for model_dir in $BASEDIR/models_toexport/*; do
        if [ -d "$model_dir" ] && [ ! -f "$model_dir/.exported" ]; then
            echo "[$(date)] 发现新模型，开始导出: $model_dir" | tee -a $BASEDIR/logs/export_daemon.log

            python3 $BASEDIR/katago/python/export_model_pytorch.py \
                "$model_dir" \
                $BASEDIR/exported \
                2>&1 | tee -a $BASEDIR/logs/export_daemon.log

            touch "$model_dir/.exported"

            # 复制最新模型到 selfplay 使用
            latest=$(ls -t $BASEDIR/exported/*.bin.gz 2>/dev/null | head -1)
            if [ -n "$latest" ]; then
                cp "$latest" $BASEDIR/models/model.bin.gz
                echo "[$(date)] 新模型已部署: $(basename $latest)" | tee -a $BASEDIR/logs/export_daemon.log
            fi
        fi
    done
done
' > /dev/null 2>&1 &

EXPORT_PID=$!
echo $EXPORT_PID > logs/export_daemon.pid
echo "  ✓ Export 守护进程: PID $EXPORT_PID"

echo ""
echo "======================================"
echo "✓ 所有守护进程已启动"
echo "======================================"
echo ""
echo "进程信息:"
echo "  Selfplay: 8个GPU进程 (PIDs in logs/selfplay_gpu*.pid)"
echo "  Shuffle:  PID $SHUFFLE_PID"
echo "  Train:    PID $TRAIN_PID"
echo "  Export:   PID $EXPORT_PID"
echo ""
echo "特性:"
echo "  ✓ 使用 setsid，SSH 断开不影响运行"
echo "  ✓ 使用 nohup，终端关闭不影响运行"
echo "  ✓ 自动重启机制（shuffle/train 异常会自动恢复）"
echo "  ✓ 保守参数（稳定性优先）"
echo ""
echo "监控命令:"
echo "  watch -n 2 nvidia-smi                   # GPU状态"
echo "  tail -f logs/selfplay_stable_gpu0.log  # Selfplay日志"
echo "  tail -f logs/shuffle_daemon.log        # Shuffle日志"
echo "  tail -f logs/train_daemon.log          # Train日志"
echo "  tail -f logs/export_daemon.log         # Export日志"
echo ""
echo "检查运行状态:"
echo "  ps aux | grep katago                   # Selfplay进程"
echo "  ps aux | grep 'shuffle.py\|train.py'   # 训练进程"
echo ""
echo "停止所有训练:"
echo "  pkill -P $SHUFFLE_PID; pkill -P $TRAIN_PID; pkill -P $EXPORT_PID; pkill katago"
echo ""
echo "======================================"
echo "10秒后检查GPU利用率..."
sleep 10

echo ""
nvidia-smi --query-gpu=index,utilization.gpu,memory.used,memory.total --format=csv
echo ""
echo "如果GPU利用率仍然很低，查看日志排查问题"
echo ""
