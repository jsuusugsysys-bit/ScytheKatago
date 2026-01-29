#!/bin/bash
# 看门狗脚本 - 自动检测并重启异常退出的进程
# 建议每5分钟运行一次（通过cron或手动）

BASEDIR=~/scythe_training
cd $BASEDIR

LOG_FILE=logs/watchdog.log
echo "[$(date)] 看门狗检查..." >> $LOG_FILE

# 检查 selfplay 进程
selfplay_count=$(ps aux | grep 'katago selfplay' | grep -v grep | wc -l)
if [ $selfplay_count -lt 8 ]; then
    echo "[$(date)] 警告: 只有 $selfplay_count 个 selfplay 进程（应该8个）" | tee -a $LOG_FILE
    echo "[$(date)] 建议手动重启: ./stable_training_daemon.sh" | tee -a $LOG_FILE
fi

# 检查 shuffle 进程
if ! ps aux | grep 'shuffle.py' | grep -v grep > /dev/null; then
    echo "[$(date)] 警告: Shuffle 进程未运行" | tee -a $LOG_FILE
fi

# 检查 train 进程
if ! ps aux | grep 'train.py' | grep -v grep > /dev/null; then
    echo "[$(date)] 警告: Train 进程未运行" | tee -a $LOG_FILE
fi

# 检查磁盘空间
disk_usage=$(df -h $BASEDIR | tail -1 | awk '{print $5}' | sed 's/%//')
if [ $disk_usage -gt 90 ]; then
    echo "[$(date)] 警告: 磁盘使用率 ${disk_usage}% 过高！" | tee -a $LOG_FILE
fi

echo "[$(date)] 检查完成" >> $LOG_FILE
