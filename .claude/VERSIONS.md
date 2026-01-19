# 版本记录

这个文件记录代码的重要版本节点。当你想要回退到某个版本时，告诉我：
- "回退到 v1.0" 或 "git checkout v1.0"

---

## 版本列表

### v1.0 - 2026-01-20 - 镰刀基础功能（当前版本）
**状态**：编译通过，基础功能可用，但 undo 有 bug

**已完成**：
- 镰刀核心逻辑（boardhistory.h/cpp）
- GTP 命令接口（gtp.cpp）
- search.cpp 玩家切换逻辑
- GUI 面板（ScythePanel.java）

**已知问题**：
- undo 后镰刀计数正确保持，但 moveNumber 被重置
- 根本原因：undo 重放棋步时，镰刀连击期间的棋步被当作玩家切换处理

**关键文件**：
- `KataGo/cpp/game/boardhistory.h:104-110` - 镰刀状态变量
- `KataGo/cpp/game/boardhistory.cpp` - 核心逻辑
- `KataGo/cpp/command/gtp.cpp:653-686` - undo 函数
- `KataGo/cpp/search/search.cpp:189-224` - setPlayerAndClearHistory

---

## 如何使用

**查看所有版本标签**：
```
git tag
```

**回退到某个版本**：
```
git checkout v1.0
```

**回到最新版本**：
```
git checkout main
```

**查看版本之间的差异**：
```
git diff v1.0 v1.1
```
