# 快速开始指南

## 第一次使用测试套件

### 步骤 1：确保 KataGo 已编译

在运行测试前，确保 KataGo 已成功编译：

```batch
cd D:\ScytheKatago
build.bat
```

或者如果只修改了 C++ 代码：

```batch
compile.bat
```

### 步骤 2：运行测试

**最简单的方法**：双击 `run_all_tests.bat`

或者在命令行中：

```batch
cd D:\ScytheKatago\test_scythe_suite
run_all_tests.bat
```

### 步骤 3：查看结果

测试完成后，结果保存在：
```
test_scythe_suite\results\test_<时间戳>\
```

查看 `test_report.txt` 了解测试统计。

## 测试列表

| 测试文件 | 测试内容 | 预计时间 |
|---------|---------|---------|
| test_basic.txt | 基本功能 | 2-3 分钟 |
| test_boundary.txt | 边界条件 | 3-5 分钟 |
| test_combo.txt | 连击逻辑 | 3-4 分钟 |
| test_count.txt | 数量限制 | 4-6 分钟 |
| test_both_players.txt | 双方测试 | 5-7 分钟 |
| test_board_size.txt | 棋盘大小 | 2-3 分钟 |
| test_reset.txt | 重置功能 | 2-3 分钟 |

**总计**：约 15-30 分钟（取决于硬件配置）

## 运行单个测试

如果只想测试某个功能：

```batch
run_single_test.bat test_basic.txt
```

## 常见问题

### Q: 测试太慢怎么办？

**A**: 编辑 `D:\ScytheKatago\scythe_config.cfg`，减少 `maxVisits`：

```
maxVisits = 100  # 原来是 500
```

### Q: 如何判断测试是否通过？

**A**: 查看控制台输出：
- `[通过]` = 测试成功
- `[失败]` = 测试失败

或查看 `test_report.txt` 中的统计信息。

### Q: 测试失败了怎么办？

**A**:
1. 查看对应的错误日志文件（`*_error.txt`）
2. 查看输出文件（`*_output.txt`）
3. 检查是否满足镰刀触发条件：
   - 棋盘为 11x11
   - 手数在 11-49 之间
   - 镰刀数大于 0

### Q: 可以修改测试吗？

**A**: 可以！测试文件是纯文本的 GTP 命令序列，可以用任何文本编辑器修改。

## 下一步

详细的测试说明请查看 `README.md`。
