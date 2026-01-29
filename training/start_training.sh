#!/bin/bash
# ============================================================
# KataGo Scythe Training - Main Start Script
# 8x RTX 5090 Configuration
# ============================================================

set -e

# === CONFIGURATION ===
export BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"
export KATAGO_BIN="${KATAGO_BIN:-$BASEDIR/katago/cpp/build/katago}"
export CONFIG_FILE="${CONFIG_FILE:-$BASEDIR/configs/selfplay_scythe.cfg}"

# Backup settings
export BACKUP_DIR="${BACKUP_DIR:-/home/user/backup}"
export BACKUP_INTERVAL="${BACKUP_INTERVAL:-3600}"  # 1 hour
export REMOTE_BACKUP="${REMOTE_BACKUP:-}"  # Set to rsync target if needed

# Training settings
export NUM_GPUS=8
export BATCH_SIZE=256
export LEARNING_RATE=0.0001

# === VALIDATION ===
echo "=============================================="
echo "KataGo Scythe Training - Startup Validation"
echo "=============================================="

# Check KataGo binary
if [ ! -f "$KATAGO_BIN" ]; then
    echo "ERROR: KataGo binary not found at $KATAGO_BIN"
    echo "Please compile KataGo first."
    exit 1
fi

# Check config file
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Check CUDA
if ! nvidia-smi &> /dev/null; then
    echo "ERROR: nvidia-smi failed. CUDA may not be properly installed."
    exit 1
fi

# Show GPU info
echo ""
echo "GPU Configuration:"
nvidia-smi --query-gpu=index,name,memory.total --format=csv
echo ""

# Check directories
mkdir -p $BASEDIR/{models,selfplay,shuffled,training,exported,logs}
mkdir -p $BACKUP_DIR

# === TEST RUN ===
echo "Running quick validation test (5 games)..."
$KATAGO_BIN selfplay \
    -output-dir $BASEDIR/selfplay/test \
    -models-dir $BASEDIR/models \
    -config $CONFIG_FILE \
    -max-games-total 5 \
    2>&1 | head -50

if [ $? -ne 0 ]; then
    echo "ERROR: Test run failed!"
    exit 1
fi

echo ""
echo "Validation passed! Starting full training..."
echo ""

# === START COMPONENTS ===

# 1. Start backup daemon in background
echo "Starting backup daemon..."
nohup bash $BASEDIR/scripts/backup_daemon.sh > $BASEDIR/logs/backup.log 2>&1 &
echo $! > $BASEDIR/logs/backup.pid

# 2. Start selfplay
echo "Starting selfplay (8 GPUs)..."
nohup $KATAGO_BIN selfplay \
    -output-dir $BASEDIR/selfplay \
    -models-dir $BASEDIR/models \
    -config $CONFIG_FILE \
    > $BASEDIR/logs/selfplay.log 2>&1 &
echo $! > $BASEDIR/logs/selfplay.pid

# 3. Start shuffler (after delay for data generation)
echo "Starting data shuffler (will wait for data)..."
nohup bash $BASEDIR/scripts/shuffler_loop.sh > $BASEDIR/logs/shuffler.log 2>&1 &
echo $! > $BASEDIR/logs/shuffler.pid

# 4. Start training loop
echo "Starting training loop..."
nohup bash $BASEDIR/scripts/training_loop.sh > $BASEDIR/logs/training.log 2>&1 &
echo $! > $BASEDIR/logs/training.pid

echo ""
echo "=============================================="
echo "Training started successfully!"
echo "=============================================="
echo ""
echo "Monitor commands:"
echo "  tail -f $BASEDIR/logs/selfplay.log   # Watch selfplay"
echo "  tail -f $BASEDIR/logs/training.log   # Watch training"
echo "  tail -f $BASEDIR/logs/backup.log     # Watch backups"
echo ""
echo "Stop training:"
echo "  ./stop_training.sh"
echo ""
echo "Check status:"
echo "  ./status.sh"
echo ""
