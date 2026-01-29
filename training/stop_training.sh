#!/bin/bash
# ============================================================
# Stop All Training Processes
# ============================================================

BASEDIR="${BASEDIR:-/home/user/katago_scythe_training}"

echo "Stopping KataGo Scythe Training..."

# Stop all components gracefully
for component in selfplay shuffler training backup; do
    pid_file="$BASEDIR/logs/${component}.pid"
    if [ -f "$pid_file" ]; then
        pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            echo "Stopping $component (PID: $pid)..."
            kill "$pid"
            sleep 2
            # Force kill if still running
            if kill -0 "$pid" 2>/dev/null; then
                echo "Force killing $component..."
                kill -9 "$pid" 2>/dev/null
            fi
        fi
        rm -f "$pid_file"
    fi
done

# Also kill any remaining katago processes
pkill -f "katago selfplay" 2>/dev/null || true

echo ""
echo "All training processes stopped."
echo ""
echo "To resume training, run: ./start_training.sh"
