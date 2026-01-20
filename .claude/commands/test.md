为镰刀功能创建或运行测试：

如果指定了测试文件：运行 test_scythe_suite\run_single_test.bat $ARGUMENTS

如果需要创建新测试：
1. 在 test_scythe_suite\ 目录下创建测试文件
2. 测试文件格式（GTP 命令序列）：
   ```
   boardsize 11
   clear_board
   # 测试描述注释
   play black D4
   kata-get-scythe-status
   # 期望输出检查
   ```

运行完整测试套件：
```
test_scythe_suite\run_all_tests.bat
```

测试要点：
- 镰刀触发条件（11x11棋盘，11-49手，剩余次数>0）
- 连续落子计数正确性
- undo 后状态恢复
- 边界情况处理
