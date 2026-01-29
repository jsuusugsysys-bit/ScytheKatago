#!/bin/bash
# ============================================================
# Data Shuffler Loop
# Converts selfplay data to training format
# ============================================================

BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"
PYTHON="${PYTHON:-python3}"

echo "Shuffler loop started at $(date)"

# Wait for initial data
echo "Waiting for selfplay data..."
while [ ! -d "$BASEDIR/selfplay" ] || [ -z "$(find $BASEDIR/selfplay -name '*.npz' 2>/dev/null | head -1)" ]; do
    sleep 60
done

echo "Found selfplay data, starting shuffle loop..."

while true; do
    # Find all model directories with data
    for model_dir in $BASEDIR/selfplay/*/tdata; do
        if [ -d "$model_dir" ]; then
            model_name=$(basename $(dirname $model_dir))
            output_dir="$BASEDIR/shuffled/$model_name"
            mkdir -p "$output_dir"

            # Count new files
            new_files=$(find "$model_dir" -name "*.npz" -newer "$output_dir/.last_shuffle" 2>/dev/null | wc -l)

            if [ "$new_files" -gt 100 ]; then
                echo "$(date): Shuffling $new_files files for $model_name"

                $PYTHON $BASEDIR/katago/python/shuffle.py \
                    -d "$model_dir" \
                    -out-dir "$output_dir" \
                    -keep-target-rows 2000000 \
                    -approx-rows-per-out-file 200000 \
                    2>&1 | tail -5

                touch "$output_dir/.last_shuffle"
                echo "$(date): Shuffle complete for $model_name"
            fi
        fi
    done

    # Sleep before next check
    sleep 300  # Check every 5 minutes
done
