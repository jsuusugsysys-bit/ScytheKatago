========================================
远程服务器文件下载脚本使用说明
========================================

创建时间: 2026-01-24
服务器: jxcb@123.181.192.94:60022
密码: zOh17lGDsbmrcmX

========================================
📦 两种下载方式
========================================

【方式 1】普通下载（需要保持窗口打开）
---------------------------------------
运行: download_from_remote.bat

特点:
- 交互式界面，可以看到下载进度
- 需要确认后开始下载
- 窗口关闭会中断下载

适合: 想要实时查看进度的情况


【方式 2】后台下载（推荐，可关闭窗口）
---------------------------------------
运行: download_from_remote_background.bat

特点:
- ✅ 后台静默下载
- ✅ 即使关闭 Claude 或窗口也继续下载
- ✅ 自动创建目录
- ✅ 无需确认，直接开始

适合: 想要下载后去做其他事情的情况


========================================
📂 下载内容清单
========================================

从服务器 /home/jxcb/scythe_training/ 下载:

1. configs/                    → remote_training/configs/
   - selfplay_scythe.cfg (训练配置)
   - 其他配置文件

2. *.sh 脚本文件                → remote_training/scripts/
   - benchmark_selfplay.sh (参数测试脚本)
   - start_8gpu.sh (8 GPU 启动脚本)
   - backup_training_data.sh (备份脚本)

3. logs/*.log                  → remote_training/logs/
   - 最新的训练日志
   - selfplay_gpu0.log ~ gpu7.log

4. *.bin.gz, models/*.bin.gz   → remote_training/models/
   - kata1-b6c96.bin.gz (神经网络模型)
   - 其他模型文件

5. katago/cpp/build/katago     → remote_training/katago_tensorrt/
   - TensorRT 版 KataGo 可执行文件

6. /home/jxcb/tensorrt.deb     → installers/
   - TensorRT 10.14.1 安装包

7. /home/jxcb/backup_20260123/ → backups/
   - 最新备份目录


❌ 不会下载:
- scythe_training/selfplay/ (48GB 训练数据，太大)


========================================
📊 查看下载进度
========================================

实时查看日志:
   D:\ScytheKatago\winscp_download.log

查看状态:
   D:\ScytheKatago\download_status.txt

如果出错:
   D:\ScytheKatago\download_error.txt (如果存在)


========================================
🔍 下载完成后检查
========================================

检查以下目录是否有文件:

1. D:\ScytheKatago\remote_training\configs\
   → 应该有 selfplay_scythe.cfg 等配置文件

2. D:\ScytheKatago\remote_training\scripts\
   → 应该有 benchmark_selfplay.sh 等脚本

3. D:\ScytheKatago\remote_training\logs\
   → 应该有 selfplay_gpu*.log 日志文件

4. D:\ScytheKatago\remote_training\models\
   → 应该有 .bin.gz 模型文件


========================================
⚠️ 常见问题
========================================

Q: 下载失败，提示找不到 WinSCP？
A: 脚本会自动查找以下位置:
   - C:\Program Files (x86)\WinSCP\WinSCP.com
   - C:\Program Files\WinSCP\WinSCP.com
   如果不在这些位置，请手动编辑脚本第 60 行设置路径

Q: 下载中断了怎么办？
A: 重新运行脚本即可，WinSCP 会自动跳过已下载的文件

Q: 如何知道下载完成了？
A: 查看 winscp_download.log 文件末尾是否有 "exit" 字样

Q: 密码过期或错误？
A: 编辑脚本中的密码（第 16 行）:
   -password=zOh17lGDsbmrcmX


========================================
🎯 下载后的下一步操作
========================================

1. 检查配置文件语法错误
   打开: remote_training\configs\selfplay_scythe.cfg
   删除第 190 行的中文注释

2. 查看训练参数
   对比本地和远程的参数差异

3. 备份重要文件
   - 配置文件
   - 脚本文件
   - 最新模型

4. 更新交接文档
   记录下载的文件到 handoff_katago.md


========================================
📞 技术支持
========================================

如有问题，请查看:
- 详细日志: winscp_download.log
- 项目文档: D:\ScytheKatago\progress.md
- 交接文档: .sessions\handoff_katago.md

服务器信息保存在:
- TRAINING_LOG.md (训练日志)
- .sessions\handoff_katago.md (工作交接)


========================================
✅ 推荐操作步骤
========================================

1. 双击运行: download_from_remote_background.bat
2. 等待 5 秒窗口自动关闭
3. 可以安全关闭 Claude 或去做其他事情
4. 稍后查看 download_status.txt 确认下载完成
5. 检查 remote_training 目录下的文件

祝下载顺利！
