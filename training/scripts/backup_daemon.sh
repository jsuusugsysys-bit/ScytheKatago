#!/bin/bash
# ============================================================
# Automatic Backup Daemon
# Runs continuously, backs up critical files every hour
# ============================================================

BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"
BACKUP_DIR="${BACKUP_DIR:-/home/user/backup}"
REMOTE_BACKUP="${REMOTE_BACKUP:-}"
BACKUP_INTERVAL="${BACKUP_INTERVAL:-3600}"

echo "Backup daemon started at $(date)"
echo "Local backup: $BACKUP_DIR"
echo "Remote backup: ${REMOTE_BACKUP:-DISABLED}"
echo "Interval: ${BACKUP_INTERVAL}s"
echo ""

backup_count=0

while true; do
    backup_count=$((backup_count + 1))
    timestamp=$(date +%Y%m%d_%H%M%S)

    echo "=========================================="
    echo "Backup #$backup_count at $timestamp"
    echo "=========================================="

    # Create timestamped backup directory
    LOCAL_BACKUP="$BACKUP_DIR/backup_$timestamp"
    mkdir -p "$LOCAL_BACKUP"

    # === CRITICAL FILES TO BACKUP ===

    # 1. Models (most important!)
    echo "Backing up models..."
    if [ -d "$BASEDIR/models" ]; then
        cp -r $BASEDIR/models "$LOCAL_BACKUP/"
        echo "  Models: $(ls -1 $BASEDIR/models/*.bin.gz 2>/dev/null | wc -l) files"
    fi

    # 2. Exported models
    echo "Backing up exported models..."
    if [ -d "$BASEDIR/exported" ]; then
        cp -r $BASEDIR/exported "$LOCAL_BACKUP/"
    fi

    # 3. Training checkpoints
    echo "Backing up training checkpoints..."
    if [ -d "$BASEDIR/training" ]; then
        # Only copy latest checkpoint to save space
        latest_ckpt=$(ls -t $BASEDIR/training/*.ckpt 2>/dev/null | head -1)
        if [ -n "$latest_ckpt" ]; then
            cp "$latest_ckpt" "$LOCAL_BACKUP/"
            echo "  Latest checkpoint: $(basename $latest_ckpt)"
        fi
    fi

    # 4. Config files
    echo "Backing up configs..."
    cp -r $BASEDIR/configs "$LOCAL_BACKUP/" 2>/dev/null || true

    # 5. Training logs (for analysis)
    echo "Backing up logs..."
    mkdir -p "$LOCAL_BACKUP/logs"
    tail -10000 $BASEDIR/logs/*.log > "$LOCAL_BACKUP/logs/recent_logs.txt" 2>/dev/null || true

    # 6. Create backup info
    cat > "$LOCAL_BACKUP/backup_info.txt" << EOF
Backup Time: $timestamp
Selfplay Games: $(find $BASEDIR/selfplay -name "*.sgf" 2>/dev/null | wc -l)
Training Data Files: $(find $BASEDIR/shuffled -name "*.npz" 2>/dev/null | wc -l)
Models: $(ls -1 $BASEDIR/models/*.bin.gz 2>/dev/null | wc -l)
Disk Usage: $(du -sh $BASEDIR 2>/dev/null | cut -f1)
EOF

    # === COMPRESS BACKUP ===
    echo "Compressing backup..."
    cd $BACKUP_DIR
    tar -czf "backup_$timestamp.tar.gz" "backup_$timestamp" 2>/dev/null
    rm -rf "backup_$timestamp"

    backup_size=$(du -h "backup_$timestamp.tar.gz" | cut -f1)
    echo "Local backup complete: backup_$timestamp.tar.gz ($backup_size)"

    # === REMOTE BACKUP (if configured) ===
    if [ -n "$REMOTE_BACKUP" ]; then
        echo "Syncing to remote: $REMOTE_BACKUP"
        rsync -avz --progress "backup_$timestamp.tar.gz" "$REMOTE_BACKUP/" && \
            echo "Remote backup complete!" || \
            echo "WARNING: Remote backup failed!"
    fi

    # === CLEANUP OLD BACKUPS ===
    # Keep only last 24 local backups (24 hours if hourly)
    echo "Cleaning old local backups..."
    ls -t $BACKUP_DIR/backup_*.tar.gz 2>/dev/null | tail -n +25 | xargs rm -f 2>/dev/null || true

    # Show backup summary
    echo ""
    echo "Backup Summary:"
    echo "  Local backups: $(ls -1 $BACKUP_DIR/backup_*.tar.gz 2>/dev/null | wc -l)"
    echo "  Total backup size: $(du -sh $BACKUP_DIR 2>/dev/null | cut -f1)"
    echo ""

    # Sleep until next backup
    echo "Next backup in ${BACKUP_INTERVAL}s ($(date -d "+${BACKUP_INTERVAL} seconds" +%H:%M:%S))"
    sleep $BACKUP_INTERVAL
done
