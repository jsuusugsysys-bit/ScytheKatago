#!/bin/bash
# ============================================================
# Training Status Monitor
# ============================================================

BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"
BACKUP_DIR="${BACKUP_DIR:-/home/user/backup}"

echo "=============================================="
echo "KataGo Scythe Training Status"
echo "Time: $(date)"
echo "=============================================="
echo ""

# Process status
echo "=== Process Status ==="
for component in selfplay shuffler training backup; do
    pid_file="$BASEDIR/logs/${component}.pid"
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "  $component: RUNNING (PID: $pid)"
        else
            echo "  $component: DEAD (stale PID file)"
        fi
    else
        echo "  $component: NOT STARTED"
    fi
done
echo ""

# GPU status
echo "=== GPU Status ==="
nvidia-smi --query-gpu=index,utilization.gpu,memory.used,memory.total,temperature.gpu --format=csv,noheader 2>/dev/null || echo "  nvidia-smi failed"
echo ""

# Data statistics
echo "=== Data Statistics ==="
selfplay_games=$(find $BASEDIR/selfplay -name "*.sgf" 2>/dev/null | wc -l)
training_files=$(find $BASEDIR/shuffled -name "*.npz" 2>/dev/null | wc -l)
models=$(ls -1 $BASEDIR/models/*.bin.gz 2>/dev/null | wc -l)
exported=$(ls -1 $BASEDIR/exported/*.bin.gz 2>/dev/null | wc -l)

echo "  Selfplay games: $selfplay_games"
echo "  Training files: $training_files"
echo "  Models in queue: $models"
echo "  Exported models: $exported"
echo ""

# Disk usage
echo "=== Disk Usage ==="
echo "  Training data: $(du -sh $BASEDIR 2>/dev/null | cut -f1)"
echo "  Backups: $(du -sh $BACKUP_DIR 2>/dev/null | cut -f1)"
df -h $BASEDIR 2>/dev/null | tail -1 | awk '{print "  Disk free: " $4 " (" $5 " used)"}'
echo ""

# Recent activity
echo "=== Recent Activity ==="
if [ -f "$BASEDIR/logs/selfplay.log" ]; then
    echo "  Last selfplay: $(tail -1 $BASEDIR/logs/selfplay.log 2>/dev/null | cut -c1-80)"
fi
if [ -f "$BASEDIR/logs/training.log" ]; then
    echo "  Last training: $(tail -1 $BASEDIR/logs/training.log 2>/dev/null | cut -c1-80)"
fi
if [ -f "$BASEDIR/logs/backup.log" ]; then
    echo "  Last backup: $(tail -1 $BASEDIR/logs/backup.log 2>/dev/null | cut -c1-80)"
fi
echo ""

# Latest models
echo "=== Latest Models ==="
ls -lt $BASEDIR/exported/*.bin.gz 2>/dev/null | head -5 | awk '{print "  " $NF " (" $5 " bytes)"}' || echo "  No exported models yet"
echo ""

# Backup status
echo "=== Backup Status ==="
ls -lt $BACKUP_DIR/backup_*.tar.gz 2>/dev/null | head -3 | awk '{print "  " $NF}' || echo "  No backups yet"
echo ""
