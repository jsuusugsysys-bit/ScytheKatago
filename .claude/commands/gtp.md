启动 KataGo GTP 交互模式进行手动测试：

启动命令：
```
D:\ScytheKatago\KataGo\cpp\build\Release\katago.exe gtp -model <模型路径> -config D:\ScytheKatago\scythe_config.cfg
```

常用 GTP 命令：
```
boardsize 11          # 设置 11x11 棋盘
clear_board           # 清空棋盘
play black D4         # 黑棋落子
play white E5         # 白棋落子
genmove black         # AI 生成黑棋着法
showboard             # 显示当前棋盘

# 镰刀专用命令
kata-get-scythe-status              # 查询镰刀状态
kata-set-param scythe_trigger true  # 触发镰刀
kata-set-param scythe_count_black 3 # 设置黑方镰刀数
kata-set-param scythe_count_white 3 # 设置白方镰刀数

undo                  # 悔棋
quit                  # 退出
```

测试场景建议：
1. 基本镰刀触发测试
2. 连续三步落子测试
3. undo 后镰刀状态恢复测试
4. 边界条件测试（手数<11 或 >49）
