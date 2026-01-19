# 版本记录

当你想要回退到某个版本时，告诉我："回退到 v1.0"

---

## 当前版本：v1.1

## 版本列表

### v1.1 - 2026-01-20 - 修复 undo 镰刀计数 bug
**状态**：编译通过，undo 后镰刀计数正确保持

**修复**：
- gtp.cpp: 添加 scytheTriggerHistory 追踪触发历史
- gtp.cpp: undo 重放时正确恢复镰刀计数
- gtp.cpp: clearBoard/setPosition 清理触发历史

**测试验证**：undo 后 blackScythes=2, scytheCombo=1 ✓

---

### v1.0 - 2026-01-20 - 镰刀基础功能
**状态**：编译通过，基础镰刀功能可用

**已完成**：
- 镰刀核心逻辑（boardhistory.h/cpp）
- GTP 命令接口（gtp.cpp）
- search.cpp 玩家切换逻辑
- GUI 面板（ScythePanel.java）

**已知问题**：
- undo 后 moveNumber 被重置（镰刀计数本身保持正确）
- 原因：undo 重放棋步时，镰刀连击期间的棋步被当作玩家切换处理

---

## 如何使用

告诉 Claude：
- "回退到 v1.0" - 恢复到 v1.0 版本的代码
- "创建新版本 v1.1" - 保存当前代码为新版本
- "查看版本列表" - 显示所有版本

Git 命令（你也可以自己用）：
```
git tag                    # 查看所有版本
git checkout v1.0          # 切换到 v1.0
git checkout master        # 回到最新
```
