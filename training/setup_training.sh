#!/bin/bash
# ============================================================
# KataGo Scythe Training Setup Script
# 8x RTX 5090 Linux Server
# ============================================================

set -e

# Configuration - MODIFY THESE
BASEDIR="/home/user/katago_scythe_training"
BACKUP_DIR="/home/user/backup"  # Local backup
REMOTE_BACKUP="user@your-server:/path/to/backup"  # Optional: rsync remote backup
BACKUP_INTERVAL=3600  # Backup every hour (seconds)

# Create directory structure
echo "Creating directory structure..."
mkdir -p $BASEDIR/{models,selfplay,shuffled,training,exported,logs,configs}
mkdir -p $BACKUP_DIR

# Copy this message
cat << 'EOF'
============================================================
KataGo Scythe Training Environment Setup
============================================================

IMPORTANT: Before running training, you need to:

1. Compile KataGo on this Linux machine:
   cd $BASEDIR/katago
   mkdir -p cpp/build && cd cpp/build
   cmake .. -DUSE_BACKEND=CUDA -DUSE_TCMALLOC=1
   make -j$(nproc)

2. Get a base model (optional but recommended):
   # Download KataGo b10c128 or similar small model
   wget -O $BASEDIR/models/base_model.bin.gz \
     "https://github.com/lightvector/KataGo/releases/download/v1.12.4/kata1-b10c128.txt.gz"

3. Install Python dependencies:
   pip install torch numpy matplotlib tensorboard

4. Start training with:
   ./start_training.sh

============================================================
EOF
