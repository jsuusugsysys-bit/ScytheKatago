# 镰刀规则详解

> 全局规则，无 paths 限制

---

## 镰刀条件

- 棋盘 **11x11**
- 手数 **11-49**
- 剩余镰刀 **> 0**

## 状态变量 (`boardhistory.h:104-111`)

| 变量 | 说明 |
|------|------|
| `blackScythes` / `whiteScythes` | 各方剩余镰刀次数（初始3） |
| `scytheCombo` | 当前连续落子计数（0-3） |
| `manualScytheTrigger` | GUI 手动触发标志 |
| `scytheRandomMode` | 训练模式随机触发开关 |
| `scytheTriggerHistory` | 触发历史（用于 undo 恢复） |

## GTP 命令

```
kata-get-scythe-status              # 查询状态（JSON）
kata-set-param scythe_trigger true  # 触发镰刀
kata-set-param scythe_count_black 3 # 设置黑方镰刀数
kata-set-param scythe_count_white 3 # 设置白方镰刀数
```

**状态响应示例**：
```json
{"blackScythes":3,"whiteScythes":3,"scytheCombo":0,"nextPlayer":"B","isComboActive":false,"moveNumber":10,"canUseScythe":true}
```

## 核心流程

1. GUI 发送 `kata-set-param scythe_trigger true`
2. `gtp.cpp` 设置 `manualScytheTrigger = true`
3. `boardhistory.cpp:makeBoardMoveAssumeLegal` 检测触发
4. `presumedNextMovePla` 在 combo 期间不切换玩家
5. `search.cpp` 使用 `presumedNextMovePla` 决定下一手玩家
