# 测试验证清单

使用此清单验证每个测试的预期行为。

## 测试前准备

- [ ] KataGo 已成功编译（katago.exe 存在）
- [ ] 神经网络模型文件存在
- [ ] scythe_config.cfg 配置正确

## test_basic.txt - 基本功能测试

**验证点**：
- [ ] 初始状态：blackScythes=3, whiteScythes=3
- [ ] 触发后：isComboActive=true, scytheCombo=2
- [ ] 连击第2手：scytheCombo=1
- [ ] 连击第3手：scytheCombo=0
- [ ] 连击结束：blackScythes=2, isComboActive=false
- [ ] 轮到白方：nextPlayer="W"

## test_boundary.txt - 边界条件测试

**验证点**：
- [ ] 第10手触发：镰刀未生效（canUseScythe=false）
- [ ] 第11手触发：镰刀成功（isComboActive=true）
- [ ] 第49手触发：镰刀成功（最后机会）
- [ ] 第50手触发：镰刀未生效（canUseScythe=false）

## test_combo.txt - 连击逻辑测试

**验证点**：
- [ ] 黑方连击期间：nextPlayer 始终为 "B"
- [ ] 黑方连击结束：nextPlayer 变为 "W"
- [ ] 白方连击期间：nextPlayer 始终为 "W"
- [ ] 白方连击结束：nextPlayer 变为 "B"
- [ ] scytheCombo 正确递减：2 → 1 → 0

## test_count.txt - 镰刀数量测试

**验证点**：
- [ ] 初始：blackScythes=3
- [ ] 第1次使用后：blackScythes=2
- [ ] 第2次使用后：blackScythes=1
- [ ] 第3次使用后：blackScythes=0
- [ ] 第4次尝试：镰刀未触发（blackScythes 仍为 0）

## test_both_players.txt - 双方测试

**验证点**：
- [ ] 黑方使用1次：blackScythes=2, whiteScythes=3
- [ ] 白方使用1次：blackScythes=2, whiteScythes=2
- [ ] 黑方使用2次：blackScythes=1, whiteScythes=2
- [ ] 白方使用2次：blackScythes=1, whiteScythes=1
- [ ] 黑方使用3次：blackScythes=0, whiteScythes=1
- [ ] 白方使用3次：blackScythes=0, whiteScythes=0
- [ ] 双方都无法再触发

## test_board_size.txt - 棋盘大小测试

**验证点**：
- [ ] 9x9 棋盘：镰刀未触发
- [ ] 19x19 棋盘：镰刀未触发
- [ ] 11x11 棋盘：镰刀成功触发

## test_reset.txt - 重置功能测试

**验证点**：
- [ ] 使用1次后：blackScythes=2
- [ ] 重置黑方：blackScythes=3
- [ ] 重置白方：whiteScythes=3
- [ ] 设置为5：blackScythes=5
- [ ] 设置为0：whiteScythes=0
- [ ] 数量为0时无法触发

## 测试结果记录

| 测试名称 | 状态 | 备注 |
|---------|------|------|
| test_basic.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |
| test_boundary.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |
| test_combo.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |
| test_count.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |
| test_both_players.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |
| test_board_size.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |
| test_reset.txt | ⬜ 未测试 / ✅ 通过 / ❌ 失败 | |

## 问题记录

如发现问题，请记录：

**问题 1**：
- 测试名称：
- 预期行为：
- 实际行为：
- 错误信息：

**问题 2**：
- 测试名称：
- 预期行为：
- 实际行为：
- 错误信息：

---

**测试日期**：__________
**测试人员**：__________
**KataGo 版本**：__________
