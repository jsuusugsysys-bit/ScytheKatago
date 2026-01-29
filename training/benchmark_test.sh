#!/bin/bash
# 快速性能测试 - 单GPU 100盘

cd ~/scythe_training

echo "======================================"
echo "测试优化配置性能"
echo "======================================"

# 停止现有训练
pkill katago 2>/dev/null
sleep 2

# 测试优化配置
echo ""
echo "配置参数:"
grep -E 'numGameThreads|maxVisits|nnMaxBatchSize|scytheRandomTriggerRate' configs/selfplay_scythe_optimized.cfg

echo ""
echo "开始 100 盘测试..."
start_time=$(date +%s)

CUDA_VISIBLE_DEVICES=0 ./katago/cpp/build/katago selfplay \
  -config configs/selfplay_scythe_optimized.cfg \
  -models-dir models \
  -output-dir selfplay/benchmark \
  -max-games-total 100 \
  -override-config numNNServerThreadsPerModel=1,numGameThreads=400 \
  2>&1 | tee /tmp/benchmark.log

end_time=$(date +%s)
duration=$((end_time - start_time))

echo ""
echo "======================================"
echo "测试完成"
echo "总耗时: ${duration} 秒"
echo "速度: $((100 * 60 / duration)) 盘/分钟"
echo "======================================"

# 显示性能数据
echo ""
echo "NN 性能统计:"
grep -E 'NN rows|NN batches|avg batch' /tmp/benchmark.log | tail -5
