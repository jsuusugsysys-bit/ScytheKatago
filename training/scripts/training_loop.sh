#!/bin/bash
# ============================================================
# Neural Network Training Loop
# Trains on shuffled data, exports new models
# ============================================================

BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"
PYTHON="${PYTHON:-python3}"
BATCH_SIZE="${BATCH_SIZE:-256}"
LEARNING_RATE="${LEARNING_RATE:-0.0001}"

echo "Training loop started at $(date)"
echo "Batch size: $BATCH_SIZE"
echo "Learning rate: $LEARNING_RATE"

# Network architecture for 11x11
# b6c96 = 6 blocks, 96 channels (small, fast)
# b10c128 = 10 blocks, 128 channels (medium)
MODEL_KIND="${MODEL_KIND:-b6c96}"
echo "Model architecture: $MODEL_KIND"

# Wait for shuffled data
echo "Waiting for shuffled data..."
while [ -z "$(find $BASEDIR/shuffled -name '*.npz' 2>/dev/null | head -1)" ]; do
    sleep 60
done

echo "Found shuffled data, starting training loop..."

iteration=0
while true; do
    iteration=$((iteration + 1))

    # Find latest shuffled data
    latest_data=$(ls -td $BASEDIR/shuffled/*/ 2>/dev/null | head -1)

    if [ -z "$latest_data" ]; then
        echo "$(date): No shuffled data found, waiting..."
        sleep 300
        continue
    fi

    # Count training files
    train_files=$(find "$latest_data" -name "*.npz" 2>/dev/null | wc -l)

    if [ "$train_files" -lt 10 ]; then
        echo "$(date): Not enough training data ($train_files files), waiting..."
        sleep 300
        continue
    fi

    echo ""
    echo "=============================================="
    echo "Training iteration #$iteration at $(date)"
    echo "Data source: $latest_data"
    echo "Training files: $train_files"
    echo "=============================================="

    # Run training
    $PYTHON $BASEDIR/katago/python/train.py \
        -traindir $BASEDIR/training \
        -datadir "$latest_data" \
        -pos-len 11 \
        -batch-size $BATCH_SIZE \
        -model-kind $MODEL_KIND \
        -lr $LEARNING_RATE \
        -max-epochs 1 \
        -gpu 0 \
        2>&1 | tail -20

    # Check for new checkpoint
    latest_ckpt=$(ls -t $BASEDIR/training/*.ckpt 2>/dev/null | head -1)

    if [ -n "$latest_ckpt" ]; then
        echo "$(date): Found checkpoint: $(basename $latest_ckpt)"

        # Export to KataGo format
        export_name="scythe_$(date +%Y%m%d_%H%M%S)"
        export_file="$BASEDIR/exported/$export_name.bin.gz"

        echo "$(date): Exporting model to $export_file"
        $PYTHON $BASEDIR/katago/python/export_model.py \
            -checkpoint "$latest_ckpt" \
            -export-dir $BASEDIR/exported \
            -model-name "$export_name" \
            -pos-len 11 \
            2>&1 | tail -5

        if [ -f "$export_file" ]; then
            echo "$(date): Export successful!"

            # Copy to models directory for selfplay to pick up
            cp "$export_file" "$BASEDIR/models/"
            echo "$(date): Model copied to models directory"

            # Log model info
            echo "$(date) - $export_name - iter=$iteration files=$train_files" >> $BASEDIR/logs/model_history.txt
        else
            echo "$(date): WARNING - Export may have failed"
        fi
    fi

    # Brief pause between iterations
    sleep 60
done
