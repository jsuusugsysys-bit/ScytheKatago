#!/bin/bash
# ============================================================
# Download Latest Trained Model
# Use this to get the model for testing on your local machine
# ============================================================

BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"
OUTPUT_DIR="${1:-.}"

echo "Finding latest exported model..."

# Find the most recent exported model
latest_model=$(ls -t $BASEDIR/exported/*.bin.gz 2>/dev/null | head -1)

if [ -z "$latest_model" ]; then
    echo "ERROR: No exported models found!"
    echo "Training may still be in progress."
    exit 1
fi

model_name=$(basename "$latest_model")
echo "Latest model: $model_name"
echo "Size: $(du -h "$latest_model" | cut -f1)"
echo ""

# Copy to output directory
cp "$latest_model" "$OUTPUT_DIR/"
echo "Model copied to: $OUTPUT_DIR/$model_name"
echo ""

# Also copy the scythe config for reference
if [ -f "$BASEDIR/configs/selfplay_scythe.cfg" ]; then
    cp "$BASEDIR/configs/selfplay_scythe.cfg" "$OUTPUT_DIR/scythe_config.cfg"
    echo "Config copied to: $OUTPUT_DIR/scythe_config.cfg"
fi

echo ""
echo "To use this model:"
echo "  1. Copy $model_name to your local machine"
echo "  2. Configure lizzieyzy to use it"
echo "  3. Test with 11x11 board, 7.5 komi"
