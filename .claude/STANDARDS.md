# 代码规范

本文档定义镰刀 KataGo 项目的代码规范和格式要求。

## C++ 代码规范

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 变量 | 驼峰命名法 | `blackScythes`, `moveNumber` |
| 常量 | 全大写+下划线 | `MAX_SCYTHES`, `MIN_MOVE` |
| 函数 | 驼峰命名法 | `makeBoardMove()`, `getStatus()` |
| 类名 | 大写开头 | `BoardHistory`, `ScytheManager` |

### 格式规范

**缩进：** 2 个空格（不使用 Tab）

**大括号：** 左大括号不换行

```cpp
// 正确
if (condition) {
  doSomething();
}

// 错误
if (condition)
{
  doSomething();
}
```

**空格：**
```cpp
int result = a + b;           // 运算符两侧加空格
function(arg1, arg2);         // 逗号后加空格
if (condition) {              // 关键字后加空格
void function() {             // 函数名和括号之间不加空格
```

### 性能优化

**镰刀代码在热路径中，必须高效：**

✅ **推荐：**
- 简单的条件判断
- 引用传递大对象
- 避免不必要的内存分配

❌ **避免：**
- 复杂的计算
- 频繁的日志输出
- 不必要的函数调用

```cpp
// 好的做法
if (moveNum >= 11 && moveNum <= 49 && blackScythes > 0) {
  // 简单高效
}

// 避免
if (isInScytheRange(moveNum) && hasScythes(BLACK)) {
  // 每次都调用函数，增加开销
}
```

### 注释规范

**函数注释：** 解释复杂函数

```cpp
// 检查并处理镰刀触发
// 返回：是否成功触发
bool checkScytheTrigger(Player player) {
  // 实现
}
```

**行内注释：** 解释复杂逻辑

```cpp
// 在连击期间，不切换玩家
if (scytheCombo > 0) {
  scytheCombo--;  // 减少剩余连击次数
  return;
}
```

---

## Java 代码规范（Lizzieyzy）

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 变量 | 驼峰命名法 | `scytheCount`, `isActive` |
| 常量 | 全大写+下划线 | `MAX_SCYTHES` |
| 方法 | 驼峰命名法 | `getScytheStatus()` |
| 类名 | 大写开头 | `ScythePanel` |
| 包名 | 全小写 | `featurecat.lizzie.scythe` |

### 格式规范

**缩进：** 4 个空格

**大括号：** 左大括号不换行

```java
public void method() {
    if (condition) {
        doSomething();
    }
}
```

### GUI 性能优化

**❌ 错误：阻塞 UI 线程**
```java
public void updateStatus() {
    String status = leelaz.sendCommand("kata-get-scythe-status");  // 阻塞
    updateUI(status);
}
```

**✅ 正确：使用后台线程**
```java
public void updateStatus() {
    new Thread(() -> {
        String status = leelaz.sendCommand("kata-get-scythe-status");
        SwingUtilities.invokeLater(() -> updateUI(status));
    }).start();
}
```

**❌ 错误：定时器轮询**
```java
Timer timer = new Timer(100, e -> {
    updateStatus();  // 每 100ms 查询，刷屏
});
```

**✅ 正确：事件驱动**
```java
public void onMoveMade() {
    updateStatus();  // 仅在走棋后更新
}
```

---

## GTP 协议规范

### 关键规则

**所有调试输出必须发送到 stderr，绝不能发送到 stdout**

```cpp
// ✅ 正确：调试信息发送到 stderr
std::cerr << "Scythe triggered" << std::endl;

// ❌ 错误：发送到 stdout 会破坏 GTP 协议
std::cout << "Scythe triggered" << std::endl;
```

### 响应格式

```cpp
// 成功响应
std::cout << "= result\n\n";

// 失败响应
std::cout << "? error message\n\n";

// JSON 响应
std::cout << "= {\"blackScythes\": 3}\n\n";
```

### 命令命名

**自定义命令使用 `kata-` 前缀：**
- ✅ `kata-get-scythe-status`
- ✅ `kata-set-scythe-count`
- ❌ `get-scythe-status`（缺少前缀）

**简短命令可以不用前缀：**
- ✅ `scythe`
- ✅ `scythe_reset`

---

## Git 提交规范

### 提交信息格式

```
<类型>: <简短描述>

<详细描述>（可选）
```

**类型：**
- `feat`: 新功能
- `fix`: 修复 bug
- `refactor`: 重构
- `perf`: 性能优化
- `docs`: 文档更新
- `test`: 测试相关

**示例：**
```
feat: 添加镰刀触发功能

- 在 boardhistory.h 中添加镰刀状态变量
- 在 boardhistory.cpp 中实现触发逻辑
- 在 gtp.cpp 中添加 scythe 命令
```

---

## 测试规范

### 测试清单

提交代码前确保：
- [ ] 代码能编译
- [ ] 基本功能测试通过
- [ ] 边界条件测试通过
- [ ] 没有编译警告
- [ ] 没有性能问题

### GTP 测试

```
# test_scythe.txt
boardsize 11
clear_board
play B D4
# ... 更多命令
kata-get-scythe-status
```

**运行测试：**
```batch
katago.exe gtp < test_scythe.txt
```

---

## 代码质量工具

### 推荐使用 MCP 工具

**Context7 或类似工具：**
- 代码审查
- 规范检查
- 性能优化建议
- 重构建议

**使用场景：**
- 修改代码前：分析现有代码结构
- 提交代码前：检查代码质量
- 重构时：获取优化建议
- 性能优化：识别瓶颈

---

## 常见问题

### Q: 我是编程新手，这些规范太复杂了怎么办？

**A:** 重点关注以下几点：
1. 变量命名要清晰（用完整的英文单词）
2. 缩进要一致（C++ 用 2 空格，Java 用 4 空格）
3. 添加注释解释复杂的逻辑
4. 提交前确保代码能编译

其他规范可以逐步学习。

### Q: 什么时候需要使用 MCP 工具？

**A:** 推荐在以下情况使用：
- 修改复杂代码前，先分析代码结构
- 不确定代码是否符合规范时
- 需要重构代码时
- 想要优化性能时

### Q: GTP 输出规范为什么这么重要？

**A:** 因为 GTP 是严格的文本协议：
- stdout 用于命令响应（必须严格遵守格式）
- stderr 用于调试信息（可以随意输出）
- 如果在 stdout 输出调试信息，会破坏协议，导致 GUI 无法解析

### Q: 如何检查代码是否符合规范？

**A:** 三个步骤：
1. 使用 MCP 工具（如 Context7）自动检查
2. 对照本文档的清单手动检查
3. 编译并运行测试
