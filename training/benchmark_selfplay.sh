#!/bin/bash
# ==============================================================================
# KataGo 跑谱参数优化测试脚本
# ==============================================================================
#
# 目标：找到最优参数组合，最大化训练数据生成效率
#
# 衡量指标（按重要性排序）：
#   1. rows/sec (samples/sec) - 每秒生成的训练样本数 [最重要]
#   2. games/min - 每分钟完成的对局数
#   3. GPU 利用率 (%) - 显卡使用效率
#   4. NN evals/sec - 神经网络推理吞吐量
#   5. 平均对局长度 - 影响数据多样性
#
# 当前问题：GPU 利用率仅 14-20%，说明瓶颈在 CPU 或参数配置
#
# 参考资料：
#   - KataGo SelfplayTraining.md
#   - configs/training/README.md
#   - https://github.com/lightvector/KataGo
#
# ==============================================================================

set -e

# ===== 全局配置 =====
KATAGO_DIR="$HOME/scythe_training"
KATAGO_BIN="$KATAGO_DIR/katago/cpp/build/katago"
MODEL_DIR="$KATAGO_DIR/models"
BASE_CONFIG="$KATAGO_DIR/configs/selfplay_scythe.cfg"
BENCHMARK_DIR="$KATAGO_DIR/benchmark"
RESULTS_FILE="$BENCHMARK_DIR/results.csv"
LOG_DIR="$BENCHMARK_DIR/logs"

# 测试时长（秒）- 建议至少 120 秒以获得稳定数据
TEST_DURATION=${TEST_DURATION:-180}

# 使用的 GPU 数量（默认单卡测试，可改为 8 全卡测试）
NUM_GPUS=${NUM_GPUS:-1}

# 测试用临时目录
TEST_SELFPLAY_DIR="$BENCHMARK_DIR/test_selfplay"

# ==============================================================================
# 关键参数说明（完整版）
# ==============================================================================
#
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           吞吐量相关参数                                      ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║ numGameThreads                                                               ║
# ║   - 并行游戏数，需要远大于 CPU 核心数（因为每个线程等待 NN 时阻塞）             ║
# ║   - 太低: GPU 空闲等待; 太高: CPU 调度开销大，内存压力                         ║
# ║   - 官方 8 GPU 配置: 1600; 单 GPU: 128-256                                   ║
# ║                                                                              ║
# ║ nnMaxBatchSize                                                               ║
# ║   - NN 推理批次大小，影响 GPU 利用效率                                        ║
# ║   - 需要与 numGameThreads 匹配：batchSize ≈ threads / (visits * 某系数)      ║
# ║   - 太低: GPU 未充分利用; 太高: 延迟增加，显存压力                             ║
# ║   - 官方 8 GPU: 400; 单 GPU: 128-256                                         ║
# ║                                                                              ║
# ║ numNNServerThreadsPerModel                                                   ║
# ║   - 每个模型的 NN 服务线程数，多 GPU 时应等于 GPU 数量                         ║
# ║   - 单 GPU: 1; 8 GPU: 8                                                      ║
# ║                                                                              ║
# ║ numSearchThreads                                                             ║
# ║   - 每个游戏的搜索线程数，通常保持为 1                                         ║
# ║   - 增加可能提高单局质量但降低吞吐                                            ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║                           搜索质量相关参数                                    ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║ maxVisits                                                                    ║
# ║   - 每步最大访问数，直接影响落子质量和速度                                     ║
# ║   - 早期训练(弱网络): 400-800                                                ║
# ║   - 中期训练: 800-1500                                                       ║
# ║   - 后期训练(强网络): 1500-2500                                              ║
# ║                                                                              ║
# ║ cheapSearchProb                                                              ║
# ║   - 使用低访问搜索的概率，可大幅加速数据生成                                   ║
# ║   - 官方: 0.75; 加速可设 0.85-0.95                                           ║
# ║                                                                              ║
# ║ cheapSearchVisits                                                            ║
# ║   - 低访问搜索的访问数                                                        ║
# ║   - 官方: maxVisits/6 ~ maxVisits/3                                          ║
# ║                                                                              ║
# ║ cheapSearchTargetWeight                                                      ║
# ║   - 低访问搜索数据的训练权重，通常设为 0                                       ║
# ║                                                                              ║
# ║ reducedVisitsMin                                                             ║
# ║   - 优势方最小访问数，应 >= cheapSearchVisits                                 ║
# ║                                                                              ║
# ║ reduceVisitsThreshold                                                        ║
# ║   - 胜率达到此值时减少访问数，通常 0.9                                         ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║                           对局设置参数                                        ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║ maxMovesPerGame                                                              ║
# ║   - 最大手数，镰刀 11x11 可设较小值 (~65-80)                                   ║
# ║   - 官方 19x19: 1600; 11x11 可用 100-200                                     ║
# ║                                                                              ║
# ║ resignThreshold                                                              ║
# ║   - 认输阈值 (胜率)，负值表示落后多少认输                                      ║
# ║   - 太高: 游戏过早结束，数据不完整                                            ║
# ║   - 太低: 浪费算力下已定局面                                                  ║
# ║   - 镰刀建议: -0.85 ~ -0.90                                                  ║
# ║                                                                              ║
# ║ resignConsecTurns                                                            ║
# ║   - 连续多少手满足认输条件才真正认输                                          ║
# ║   - 太低: 可能误判; 太高: 浪费算力                                            ║
# ║                                                                              ║
# ║ resignMinMovesPerGame                                                        ║
# ║   - 最少下多少手才能认输                                                      ║
# ║   - 镰刀: 镰刀用完约第 49 手，建议设 50                                       ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║                           数据生成参数                                        ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║ maxDataQueueSize                                                             ║
# ║   - 数据队列大小，影响内存使用                                                ║
# ║   - 太小: 可能丢数据; 太大: 内存压力                                          ║
# ║                                                                              ║
# ║ maxRowsPerTrainFile                                                          ║
# ║   - 每个训练文件的行数                                                        ║
# ║   - 影响文件 I/O 频率和 shuffle 效率                                          ║
# ║                                                                              ║
# ║ policySurpriseDataWeight / valueSurpriseDataWeight                           ║
# ║   - 惊讶数据权重，影响训练重点                                                ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║                           缓存相关参数                                        ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║ nnCacheSizePowerOfTwo                                                        ║
# ║   - NN 缓存大小 (2^n 条目)                                                    ║
# ║   - 影响内存使用和缓存命中率                                                  ║
# ║   - 21 = 2M 条目; 24 = 16M 条目; 25 = 32M 条目                               ║
# ║                                                                              ║
# ║ nnMutexPoolSizePowerOfTwo                                                    ║
# ║   - 互斥锁池大小，通常设为 nnCacheSizePowerOfTwo - 6                          ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║                           游戏初始化参数                                      ║
# ╠══════════════════════════════════════════════════════════════════════════════╣
# ║ initGamesWithPolicy                                                          ║
# ║   - 是否用策略网络高温采样开局，增加开局多样性                                 ║
# ║                                                                              ║
# ║ policyInitAreaProp                                                           ║
# ║   - 策略初始化的平均手数 = 棋盘面积 * 此值                                     ║
# ║                                                                              ║
# ║ forkGameProb / earlyForkGameProb                                             ║
# ║   - 分叉游戏概率，增加对局多样性                                              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# ==============================================================================

# ===== 待测试的参数组合 =====
# 格式: "名称|numGameThreads|maxVisits|cheapSearchVisits|cheapSearchProb|nnMaxBatchSize|nnCacheSizePowerOfTwo|maxMovesPerGame|resignThreshold|numSearchThreads"

PARAM_SETS=(
    # === 基准配置 (当前) ===
    "baseline|3200|280|50|0.85|640|25|65|-0.85|1"

    # === 降低 visits 测试（提高吞吐） ===
    "low_visits_1|3200|150|30|0.85|640|25|65|-0.85|1"
    "low_visits_2|3200|100|25|0.90|640|25|65|-0.85|1"
    "ultra_low_visits|3200|50|20|0.95|640|25|65|-0.80|1"

    # === 调整 numGameThreads ===
    # 当前 3200 可能太高，尝试降低
    "threads_2400|2400|200|40|0.85|512|24|65|-0.85|1"
    "threads_2000|2000|200|40|0.85|512|24|65|-0.85|1"
    "threads_1600|1600|200|50|0.80|512|24|65|-0.85|1"
    "threads_1200|1200|250|60|0.75|384|23|65|-0.85|1"
    "threads_800|800|300|80|0.75|256|22|65|-0.85|1"
    "threads_400|400|400|100|0.70|128|21|65|-0.85|1"
    "threads_200|200|500|120|0.65|64|20|65|-0.85|1"

    # === 调整 nnMaxBatchSize ===
    "batch_1024|2400|150|30|0.85|1024|25|65|-0.85|1"
    "batch_768|2000|180|40|0.85|768|25|65|-0.85|1"
    "batch_512|1600|200|50|0.80|512|24|65|-0.85|1"
    "batch_384|1200|220|55|0.78|384|23|65|-0.85|1"
    "batch_256|1000|250|60|0.75|256|23|65|-0.85|1"
    "batch_128|600|350|90|0.70|128|22|65|-0.85|1"

    # === cheapSearch 优化 ===
    "cheap_high|2000|200|30|0.90|512|24|65|-0.85|1"
    "cheap_ultra|2000|150|20|0.95|512|24|65|-0.85|1"
    "cheap_low|2000|300|100|0.60|512|24|65|-0.85|1"

    # === resign 参数优化（加速结束已定局面） ===
    "resign_fast|2000|200|50|0.80|512|24|65|-0.80|1"
    "resign_faster|2000|200|50|0.80|512|24|60|-0.75|1"
    "resign_slow|2000|200|50|0.80|512|24|80|-0.92|1"

    # === 综合优化配置（基于 KataGo 官方配置） ===
    # 参考 selfplay1.cfg (小规模单 GPU)
    "kata_small|128|600|100|0.75|128|21|65|-0.85|1"
    # 参考 selfplay8b.cfg (8 GPU 早期)
    "kata_8gpu_early|1600|1000|200|0.75|400|24|65|-0.85|1"
    # 参考 selfplay8b20.cfg (20 block 网络)
    "kata_8gpu_b20|1024|1000|200|0.75|256|24|65|-0.85|1"

    # === 针对 11x11 镰刀优化 ===
    # 11x11 面积 121，比 19x19 (361) 小很多，可以用更少的 visits
    "scythe_opt1|1000|200|50|0.80|384|23|65|-0.85|1"
    "scythe_opt2|1500|150|40|0.85|512|24|65|-0.85|1"
    "scythe_opt3|800|250|60|0.75|256|22|65|-0.85|1"
    "scythe_opt4|1200|180|45|0.82|384|23|70|-0.88|1"
    "scythe_balanced|1000|200|50|0.80|384|23|65|-0.85|1"

    # === 极端配置（探索边界） ===
    "extreme_fast|2000|50|15|0.98|512|24|55|-0.70|1"
    "extreme_quality|500|800|200|0.50|256|23|80|-0.95|1"
    "extreme_threads|4000|100|25|0.90|768|25|65|-0.80|1"
    "extreme_batch|1600|150|40|0.85|1280|26|65|-0.85|1"

    # === 高质量训练配置 ===
    "hq_train|800|600|150|0.60|256|23|80|-0.92|1"
    "hq_train_2|600|800|200|0.50|192|22|85|-0.95|1"
)

# ==============================================================================
# 工具函数
# ==============================================================================

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

setup_dirs() {
    log "创建测试目录..."
    mkdir -p "$BENCHMARK_DIR"
    mkdir -p "$TEST_SELFPLAY_DIR"
    mkdir -p "$LOG_DIR"

    # 初始化结果文件
    if [ ! -f "$RESULTS_FILE" ]; then
        echo "timestamp,name,numGameThreads,maxVisits,cheapSearchVisits,cheapSearchProb,nnMaxBatchSize,nnCachePow,maxMoves,resignThresh,numSearchThreads,rows_total,rows_per_sec,games_completed,games_per_min,gpu_util_avg,nn_evals_per_sec,avg_game_length,duration_sec,notes" > "$RESULTS_FILE"
    fi
}

create_test_config() {
    local name=$1
    local threads=$2
    local visits=$3
    local cheap_visits=$4
    local cheap_prob=$5
    local batch=$6
    local cache_pow=$7
    local max_moves=$8
    local resign_thresh=$9
    local search_threads=${10}
    local config_file="$BENCHMARK_DIR/test_config_${name}.cfg"

    # 复制基础配置
    cp "$BASE_CONFIG" "$config_file"

    # === 吞吐量参数 ===
    sed -i "s/^numGameThreads = .*/numGameThreads = $threads/" "$config_file"
    sed -i "s/^nnMaxBatchSize = .*/nnMaxBatchSize = $batch/" "$config_file"
    sed -i "s/^numSearchThreads = .*/numSearchThreads = $search_threads/" "$config_file"

    # === 搜索质量参数 ===
    sed -i "s/^maxVisits = .*/maxVisits = $visits/" "$config_file"
    sed -i "s/^cheapSearchVisits = .*/cheapSearchVisits = $cheap_visits/" "$config_file"
    sed -i "s/^cheapSearchProb = .*/cheapSearchProb = $cheap_prob/" "$config_file"

    # reducedVisitsMin 应该 >= cheapSearchVisits
    local reduced_min=$cheap_visits
    sed -i "s/^reducedVisitsMin = .*/reducedVisitsMin = $reduced_min/" "$config_file"

    # === 对局设置参数 ===
    sed -i "s/^maxMovesPerGame = .*/maxMovesPerGame = $max_moves/" "$config_file"
    sed -i "s/^resignThreshold = .*/resignThreshold = $resign_thresh/" "$config_file"

    # === 缓存参数 ===
    sed -i "s/^nnCacheSizePowerOfTwo = .*/nnCacheSizePowerOfTwo = $cache_pow/" "$config_file"
    # mutex pool 通常设为 cache - 6
    local mutex_pow=$((cache_pow - 6))
    if [ $mutex_pow -lt 15 ]; then mutex_pow=15; fi
    sed -i "s/^nnMutexPoolSizePowerOfTwo = .*/nnMutexPoolSizePowerOfTwo = $mutex_pow/" "$config_file"

    # === 日志配置 ===
    sed -i "s/^logGamesEvery = .*/logGamesEvery = 5/" "$config_file"
    sed -i "s/^logToStdout = .*/logToStdout = true/" "$config_file"

    # === GPU 配置 ===
    if [ "$NUM_GPUS" -eq 1 ]; then
        sed -i "s/^numNNServerThreadsPerModel = .*/numNNServerThreadsPerModel = 1/" "$config_file"
        # 注释掉其他 GPU
        for i in {1..7}; do
            sed -i "s/^cudaDeviceToUseModel0Thread$i = .*/#cudaDeviceToUseModel0Thread$i = $i/" "$config_file"
        done
    fi

    echo "$config_file"
}

count_rows() {
    # 统计生成的训练行数
    # 方法1: 统计 npz 文件数 * maxRowsPerTrainFile
    local npz_count=$(find "$TEST_SELFPLAY_DIR" -name "*.npz" 2>/dev/null | wc -l)
    echo $((npz_count * 30000))
}

count_games() {
    # 从日志中提取完成的游戏数
    if [ -f "$BENCHMARK_DIR/selfplay_output.log" ]; then
        # KataGo 日志格式: "Games: X, ..." 或 "Started X games, finished Y games"
        local games=$(grep -oP 'finished \K\d+' "$BENCHMARK_DIR/selfplay_output.log" | tail -1)
        if [ -z "$games" ]; then
            games=$(grep -oP 'Games: \K\d+' "$BENCHMARK_DIR/selfplay_output.log" | tail -1)
        fi
        echo "${games:-0}"
    else
        echo "0"
    fi
}

get_gpu_util() {
    # 获取 GPU 利用率
    if [ "$NUM_GPUS" -eq 1 ]; then
        nvidia-smi --id=0 --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo "0"
    else
        nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | \
            awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print 0}'
    fi
}

get_nn_evals() {
    # 从日志提取 NN evals/sec
    if [ -f "$BENCHMARK_DIR/selfplay_output.log" ]; then
        # 尝试多种日志格式
        local evals=$(grep -oP 'NN eval[s]?[/: ]+\K[\d.]+' "$BENCHMARK_DIR/selfplay_output.log" | tail -1)
        if [ -z "$evals" ]; then
            evals=$(grep -oP 'evals/sec[: ]+\K[\d.]+' "$BENCHMARK_DIR/selfplay_output.log" | tail -1)
        fi
        echo "${evals:-0}"
    else
        echo "0"
    fi
}

get_avg_game_length() {
    # 从日志提取平均对局长度
    if [ -f "$BENCHMARK_DIR/selfplay_output.log" ]; then
        local avg=$(grep -oP 'avg[a-z ]*(moves|len)[a-z ]*[: ]+\K[\d.]+' "$BENCHMARK_DIR/selfplay_output.log" | tail -1)
        echo "${avg:-0}"
    else
        echo "0"
    fi
}

# ==============================================================================
# 核心测试函数
# ==============================================================================

run_single_test() {
    local name=$1
    local threads=$2
    local visits=$3
    local cheap_visits=$4
    local cheap_prob=$5
    local batch=$6
    local cache_pow=$7
    local max_moves=$8
    local resign_thresh=$9
    local search_threads=${10}

    log "=========================================="
    log "测试: $name"
    log "  numGameThreads=$threads, maxVisits=$visits"
    log "  cheapSearchVisits=$cheap_visits, cheapSearchProb=$cheap_prob"
    log "  nnMaxBatchSize=$batch, nnCachePow=$cache_pow"
    log "  maxMoves=$max_moves, resignThresh=$resign_thresh"
    log "=========================================="

    # 清理测试目录
    rm -rf "$TEST_SELFPLAY_DIR"/* 2>/dev/null || true
    rm -f "$BENCHMARK_DIR/selfplay_output.log" 2>/dev/null || true
    mkdir -p "$TEST_SELFPLAY_DIR"

    # 创建测试配置
    local config=$(create_test_config "$name" $threads $visits $cheap_visits $cheap_prob $batch $cache_pow $max_moves $resign_thresh $search_threads)

    local start_time=$(date +%s)

    # 启动 selfplay
    log "启动 selfplay (GPU: 0-$((NUM_GPUS-1)))..."

    if [ "$NUM_GPUS" -eq 1 ]; then
        CUDA_VISIBLE_DEVICES=0 "$KATAGO_BIN" selfplay \
            -config "$config" \
            -models-dir "$MODEL_DIR" \
            -output-dir "$TEST_SELFPLAY_DIR" \
            -max-games-total 999999 \
            > "$BENCHMARK_DIR/selfplay_output.log" 2>&1 &
    else
        "$KATAGO_BIN" selfplay \
            -config "$config" \
            -models-dir "$MODEL_DIR" \
            -output-dir "$TEST_SELFPLAY_DIR" \
            -max-games-total 999999 \
            > "$BENCHMARK_DIR/selfplay_output.log" 2>&1 &
    fi

    local selfplay_pid=$!

    # 检查是否成功启动
    sleep 5
    if ! kill -0 $selfplay_pid 2>/dev/null; then
        log "错误: selfplay 启动失败"
        cat "$BENCHMARK_DIR/selfplay_output.log"
        return 1
    fi

    # 收集统计数据
    local gpu_samples=()
    local sample_interval=10
    local warmup=30  # 预热时间

    log "预热 ${warmup}s..."
    sleep $warmup

    # 再次检查进程
    if ! kill -0 $selfplay_pid 2>/dev/null; then
        log "错误: selfplay 在预热期间崩溃"
        tail -50 "$BENCHMARK_DIR/selfplay_output.log"
        return 1
    fi

    log "运行 ${TEST_DURATION}s 收集数据..."
    local measure_start=$(date +%s)
    local initial_games=$(count_games)

    for ((i=0; i<TEST_DURATION; i+=sample_interval)); do
        sleep $sample_interval

        # 检查进程是否还在运行
        if ! kill -0 $selfplay_pid 2>/dev/null; then
            log "警告: selfplay 提前退出"
            break
        fi

        # 采样 GPU 利用率
        local gpu_util=$(get_gpu_util)
        gpu_samples+=($gpu_util)

        # 进度显示
        local current_games=$(count_games)
        local games_done=$((current_games - initial_games))
        local elapsed=$(($(date +%s) - measure_start))
        if [ $elapsed -gt 0 ] && [ "$games_done" -gt 0 ]; then
            local rate=$(echo "scale=2; $games_done * 60 / $elapsed" | bc 2>/dev/null || echo "0")
            log "  [$name] games=$games_done, rate=${rate}/min, GPU=${gpu_util}%"
        fi
    done

    # 停止 selfplay
    log "停止 selfplay..."
    kill $selfplay_pid 2>/dev/null || true
    sleep 5
    kill -9 $selfplay_pid 2>/dev/null || true
    wait $selfplay_pid 2>/dev/null || true

    # 计算结果
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time - warmup))
    local total_games=$(count_games)
    local games_this_test=$((total_games - initial_games))
    local total_rows=$(count_rows)

    # 计算平均 GPU 利用率
    local gpu_avg=0
    if [ ${#gpu_samples[@]} -gt 0 ]; then
        local gpu_sum=0
        for g in "${gpu_samples[@]}"; do
            gpu_sum=$(echo "$gpu_sum + $g" | bc 2>/dev/null || echo "0")
        done
        gpu_avg=$(echo "scale=1; $gpu_sum / ${#gpu_samples[@]}" | bc 2>/dev/null || echo "0")
    fi

    # 计算各项指标
    local rows_per_sec=0
    local games_per_min=0
    if [ $total_duration -gt 0 ]; then
        rows_per_sec=$(echo "scale=2; $total_rows / $total_duration" | bc 2>/dev/null || echo "0")
        games_per_min=$(echo "scale=2; $games_this_test * 60 / $total_duration" | bc 2>/dev/null || echo "0")
    fi

    local nn_evals=$(get_nn_evals)
    local avg_length=$(get_avg_game_length)

    log "----------------------------------------"
    log "结果 [$name]:"
    log "  训练行数: $total_rows (${rows_per_sec}/sec)"
    log "  完成对局: $games_this_test (${games_per_min}/min)"
    log "  GPU 利用率: ${gpu_avg}%"
    log "  NN evals/sec: $nn_evals"
    log "  平均对局长度: $avg_length"
    log "----------------------------------------"

    # 记录结果
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$name,$threads,$visits,$cheap_visits,$cheap_prob,$batch,$cache_pow,$max_moves,$resign_thresh,$search_threads,$total_rows,$rows_per_sec,$games_this_test,$games_per_min,$gpu_avg,$nn_evals,$avg_length,$total_duration," >> "$RESULTS_FILE"

    # 保存日志
    cp "$BENCHMARK_DIR/selfplay_output.log" "$LOG_DIR/selfplay_${name}.log" 2>/dev/null || true

    # 短暂休息让系统稳定
    sleep 5
}

run_all_tests() {
    log "=========================================="
    log "KataGo 跑谱参数优化测试"
    log "=========================================="
    log "测试参数组数: ${#PARAM_SETS[@]}"
    log "每组测试时间: ${TEST_DURATION}s (+ 30s 预热)"
    log "使用 GPU 数量: $NUM_GPUS"
    log ""

    local count=0
    local total=${#PARAM_SETS[@]}

    for params in "${PARAM_SETS[@]}"; do
        count=$((count + 1))
        IFS='|' read -r name threads visits cheap_visits cheap_prob batch cache_pow max_moves resign_thresh search_threads <<< "$params"
        log "进度: $count / $total"
        run_single_test "$name" $threads $visits $cheap_visits $cheap_prob $batch $cache_pow $max_moves $resign_thresh $search_threads
    done

    log ""
    log "=========================================="
    log "所有测试完成!"
    log "结果保存在: $RESULTS_FILE"
    log "=========================================="
}

show_results() {
    echo ""
    echo "=========================================="
    echo "测试结果排名"
    echo "=========================================="
    echo ""

    if [ ! -f "$RESULTS_FILE" ]; then
        echo "暂无结果"
        return
    fi

    echo "=== 按 rows/sec 排名（最重要指标） ==="
    echo ""
    printf "%-20s %10s %10s %8s %8s %8s\n" "配置名称" "rows/sec" "games/min" "GPU%" "visits" "threads"
    echo "------------------------------------------------------------------------"
    tail -n +2 "$RESULTS_FILE" | \
        sort -t',' -k13 -rn | \
        head -15 | \
        awk -F',' '{printf "%-20s %10s %10s %8s %8s %8s\n", $2, $13, $15, $16, $4, $3}'

    echo ""
    echo "=== 按 GPU 利用率排名 ==="
    echo ""
    printf "%-20s %8s %10s %8s %8s %8s\n" "配置名称" "GPU%" "rows/sec" "threads" "batch" "visits"
    echo "------------------------------------------------------------------------"
    tail -n +2 "$RESULTS_FILE" | \
        sort -t',' -k16 -rn | \
        head -15 | \
        awk -F',' '{printf "%-20s %8s %10s %8s %8s %8s\n", $2, $16, $13, $3, $7, $4}'

    echo ""
    echo "=== 按 games/min 排名 ==="
    echo ""
    printf "%-20s %10s %10s %8s %8s\n" "配置名称" "games/min" "rows/sec" "GPU%" "visits"
    echo "--------------------------------------------------------------------"
    tail -n +2 "$RESULTS_FILE" | \
        sort -t',' -k15 -rn | \
        head -15 | \
        awk -F',' '{printf "%-20s %10s %10s %8s %8s\n", $2, $15, $13, $16, $4}'

    echo ""
    echo "=== 效率得分排名 (rows/sec * GPU%) ==="
    echo ""
    printf "%-20s %10s %10s %8s\n" "配置名称" "效率分" "rows/sec" "GPU%"
    echo "------------------------------------------------------------"
    tail -n +2 "$RESULTS_FILE" | \
        awk -F',' '{score=$13*$16/100; printf "%s,%.2f,%s,%s\n", $2, score, $13, $16}' | \
        sort -t',' -k2 -rn | \
        head -15 | \
        awk -F',' '{printf "%-20s %10s %10s %8s\n", $1, $2, $3, $4}'

    echo ""
}

quick_test() {
    # 快速测试单个参数组合
    local name=${1:-"quick_test"}
    local threads=${2:-1200}
    local visits=${3:-200}
    local cheap_visits=${4:-50}
    local cheap_prob=${5:-0.80}
    local batch=${6:-512}
    local cache_pow=${7:-24}
    local max_moves=${8:-65}
    local resign_thresh=${9:--0.85}
    local search_threads=${10:-1}

    TEST_DURATION=60
    run_single_test "$name" $threads $visits $cheap_visits $cheap_prob $batch $cache_pow $max_moves $resign_thresh $search_threads
    show_results
}

compare_configs() {
    # 比较两个配置
    local config1=$1
    local config2=$2

    echo "比较配置: $config1 vs $config2"
    echo ""

    if [ ! -f "$RESULTS_FILE" ]; then
        echo "暂无测试结果"
        return
    fi

    for cfg in "$config1" "$config2"; do
        echo "=== $cfg ==="
        grep ",$cfg," "$RESULTS_FILE" | \
            awk -F',' '{
                printf "  rows/sec: %s\n", $13
                printf "  games/min: %s\n", $15
                printf "  GPU%%: %s\n", $16
                printf "  threads: %s\n", $3
                printf "  visits: %s\n", $4
                printf "  batch: %s\n", $7
                printf "  cheap_prob: %s\n", $6
                printf "\n"
            }'
    done
}

export_best_config() {
    # 导出最优配置
    echo "生成最优配置..."

    if [ ! -f "$RESULTS_FILE" ]; then
        echo "暂无测试结果"
        return
    fi

    # 找出 rows/sec 最高的配置
    local best=$(tail -n +2 "$RESULTS_FILE" | sort -t',' -k13 -rn | head -1)
    local best_name=$(echo "$best" | cut -d',' -f2)

    echo "最优配置: $best_name"
    echo ""
    echo "$best" | awk -F',' '{
        printf "# 最优参数 (基于 rows/sec)\n"
        printf "numGameThreads = %s\n", $3
        printf "maxVisits = %s\n", $4
        printf "cheapSearchVisits = %s\n", $5
        printf "cheapSearchProb = %s\n", $6
        printf "nnMaxBatchSize = %s\n", $7
        printf "nnCacheSizePowerOfTwo = %s\n", $8
        printf "maxMovesPerGame = %s\n", $9
        printf "resignThreshold = %s\n", $10
        printf "\n"
        printf "# 性能指标\n"
        printf "# rows/sec: %s\n", $13
        printf "# games/min: %s\n", $15
        printf "# GPU利用率: %s%%\n", $16
    }'
}

# ==============================================================================
# 主程序
# ==============================================================================

print_help() {
    cat << 'EOF'
KataGo 跑谱参数优化测试脚本

用法:
  ./benchmark_selfplay.sh run                - 运行完整测试（所有参数组合）
  ./benchmark_selfplay.sh quick [参数...]    - 快速测试单个参数
  ./benchmark_selfplay.sh results            - 显示测试结果
  ./benchmark_selfplay.sh compare A B        - 比较两个配置
  ./benchmark_selfplay.sh export             - 导出最优配置
  ./benchmark_selfplay.sh clean              - 清理测试目录

快速测试参数:
  ./benchmark_selfplay.sh quick <name> <threads> <visits> <cheap_visits> \
      <cheap_prob> <batch> <cache_pow> <max_moves> <resign_thresh> <search_threads>

示例:
  ./benchmark_selfplay.sh run
  ./benchmark_selfplay.sh quick mytest 1200 200 50 0.80 512 24 65 -0.85 1
  ./benchmark_selfplay.sh compare baseline scythe_opt1
  ./benchmark_selfplay.sh export > best_config.cfg

环境变量:
  TEST_DURATION=180   每组测试时长（秒）
  NUM_GPUS=1          使用的 GPU 数量（1=单卡测试，8=全卡测试）

衡量指标说明:
  rows/sec     - 每秒生成的训练样本数 [最重要]
  games/min    - 每分钟完成的对局数
  GPU%         - GPU 利用率
  nn_evals/sec - NN 推理吞吐量
  效率分       - rows/sec * GPU% / 100

关键参数:
  numGameThreads    - 并行游戏数（主要影响 GPU 利用率）
  maxVisits         - 搜索访问数（影响质量和速度）
  cheapSearchProb   - 低访问搜索概率（加速数据生成）
  nnMaxBatchSize    - NN 批次大小（影响 GPU 效率）
  resignThreshold   - 认输阈值（-0.85 = 落后 85% 胜率认输）

当前问题:
  GPU 利用率: 14-20% (目标: >60%)
  可能原因:
    1. numGameThreads 太高导致 CPU 调度瓶颈
    2. nnMaxBatchSize 与 threads 不匹配
    3. maxVisits 太高导致单步耗时过长

推荐测试顺序:
  1. NUM_GPUS=1 ./benchmark_selfplay.sh quick mytest 1200 200 50 0.80 512 24 65
  2. 调整参数多次 quick 测试，找到大致范围
  3. NUM_GPUS=1 TEST_DURATION=300 ./benchmark_selfplay.sh run
  4. 根据结果选择最优配置应用到生产环境
EOF
}

case "${1:-}" in
    "run")
        setup_dirs
        run_all_tests
        show_results
        ;;
    "quick")
        setup_dirs
        shift
        quick_test "$@"
        ;;
    "results")
        show_results
        ;;
    "compare")
        compare_configs "$2" "$3"
        ;;
    "export")
        export_best_config
        ;;
    "clean")
        log "清理测试目录..."
        rm -rf "$BENCHMARK_DIR"
        log "完成"
        ;;
    "help"|"-h"|"--help")
        print_help
        ;;
    *)
        print_help
        ;;
esac
