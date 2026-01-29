#!/bin/bash
# ============================================================
# 简化版训练启动脚本
# ============================================================

set -e

export BASEDIR="${BASEDIR:-$HOME/scythe_training}"
export KATAGO="$BASEDIR/katago/cpp/build/katago"
export CONFIG="$BASEDIR/configs/selfplay_scythe.cfg"

echo "=============================================="
echo "镰刀 KataGo 训练启动"
echo "=============================================="

# 检查文件
if [ ! -f "$KATAGO" ]; then
    echo "错误：找不到 KataGo: $KATAGO"
    exit 1
fi

if [ ! -f "$CONFIG" ]; then
    echo "错误：找不到配置文件: $CONFIG"
    exit 1
fi

# 显示 GPU 状态
echo ""
echo "GPU 状态:"
nvidia-smi --query-gpu=index,name,memory.total --format=csv 2>/dev/null || echo "  (无法获取 GPU 信息)"
echo ""

# 测试运行
echo "运行测试 (5局)..."
timeout 120 $KATAGO selfplay \
    -output-dir $BASEDIR/selfplay \
    -models-dir $BASEDIR/models \
    -config $CONFIG \
    -max-games-total 5 \
    2>&1 | tail -20

echo ""
echo "测试完成！"
echo ""
echo "=============================================="
echo "准备开始正式训练..."
echo "=============================================="
echo ""
read -p "按 Enter 开始正式训练，或 Ctrl+C 取消: "

# 启动备份
echo "启动自动备份 (每小时)..."
nohup bash -c '
while true; do
    timestamp=$(date +%Y%m%d_%H%M%S)
    tar -czf $HOME/backup/backup_$timestamp.tar.gz \
        -C '$BASEDIR' models exported training/latest* 2>/dev/null
    ls -t $HOME/backup/backup_*.tar.gz 2>/dev/null | tail -n +25 | xargs rm -f 2>/dev/null
    sleep 3600
done
' > $BASEDIR/logs/backup.log 2>&1 &
echo $! > $BASEDIR/logs/backup.pid
echo "  备份进程 PID: $(cat $BASEDIR/logs/backup.pid)"

# 启动训练
echo ""
echo "启动自对弈训练..."
nohup $KATAGO selfplay \
    -output-dir $BASEDIR/selfplay \
    -models-dir $BASEDIR/models \
    -config $CONFIG \
    > $BASEDIR/logs/selfplay.log 2>&1 &
echo $! > $BASEDIR/logs/selfplay.pid

echo ""
echo "=============================================="
echo "训练已启动！"
echo "=============================================="
echo ""
echo "自对弈 PID: $(cat $BASEDIR/logs/selfplay.pid)"
echo ""
echo "监控命令:"
echo "  tail -f $BASEDIR/logs/selfplay.log"
echo ""
echo "停止训练:"
echo "  kill \$(cat $BASEDIR/logs/selfplay.pid)"
echo ""
echo "查看状态:"
echo "  nvidia-smi"
echo ""
