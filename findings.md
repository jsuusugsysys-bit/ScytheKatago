# 野狐镰刀自动检测 - 发现与研究

**更新时间**: 2026-01-22

---

## 🎉 2026-01-22 野狐镰刀识别成功

### 验证结果

**镰刀状态和数量识别**：✅ 成功
- 野狐镰刀显示区域框选正确
- 镰刀数量识别准确（3/2/1/0）
- 黑白双方镰刀分别识别
- 防抖机制工作正常（连续 2 次匹配）
- 冷却机制工作正常（3 秒冷却期）

**系统集成**：✅ 成功
- 镰刀版 lizzieyzy 启动正常
- KataGo 引擎加载成功
- readboard 棋盘同步工具正常运行
- 镰刀检测 → lizzieyzy → KataGo 链路畅通

### 下一步：自动落子功能

**核心挑战**:
1. **回合检测**: 如何判断野狐轮到我方下棋？
   - 可能的视觉特征：
     - 倒计时数字（我方倒计时在跳动）
     - 棋盘边框高亮（我方边框亮起）
     - 提示文字（"轮到您了"）
     - 头像边框（我方头像高亮）

2. **落子点获取**: 从哪里获取 KataGo 推荐的最佳手？
   - 方案 A: lizzieyzy GUI 显示的最佳手（需要解析界面）
   - 方案 B: 直接与 KataGo 通信（genmove 命令）
   - 方案 C: 通过 readboard ↔ lizzieyzy 协议传递

3. **坐标转换**: GTP 坐标 → 野狐屏幕像素
   - 已有棋盘区域框选（x1, y1, x2, y2）
   - 需要计算 11x11 交叉点位置
   - 需要映射 GTP 坐标（A1-K11）到像素

4. **鼠标模拟**: 安全性和可靠性
   - Java Robot 类：mouseMove() + mousePress()
   - 添加随机延迟（100-300ms，模拟人类）
   - 安全开关：可随时暂停自动落子

---

## 野狐镰刀界面特征【重要】

### 镰刀剩余数量显示位置（用户截图 2026-01-21）

**位置：棋盘右侧边栏，垂直排列**

```
┌─────────┐
│ ● (黑棋图标)
│ 🔪 (镰刀图标)
│ 3  (黄色数字 - 黑方剩余镰刀)  ← 箭头指向
├─────────┤
│ ○ (白棋图标)
│ 🔪 (镰刀图标)
│ 3  (黄色数字 - 白方剩余镰刀)  ← 箭头指向
├─────────┤
│ 💎 (宝石图标)
│ [攻擂] 按钮
│ [25] 按钮
└─────────┘
```

**视觉特征**：
- 数字颜色：**黄色**，字体较大
- 背景：深色/黑色
- 位置：棋盘右边缘外侧
- 黑白分开显示，上黑下白

### 镰刀触发时的显示

**棋盘中央**：
- 大字显示 **"黑方镰刀"** 或 **"白方镰刀"**
- 文字颜色：**蓝紫色渐变 + 白色描边**（不是纯黑/纯白！）
- 有紫色镰刀武器图案

**右侧信息栏**：
- 黑方镰刀图标 + 数字（3/2/1/0）
- 白方镰刀图标 + 数字（3/2/1/0）
- 数字表示**剩余**镰刀次数

### 镰刀计数解读

| 显示 | 含义 |
|------|------|
| 黑3 白3 | 双方都没用过镰刀 |
| 黑3 白2 | 白方已用1次镰刀 |
| 黑2 白3 | 黑方已用1次镰刀 |

### 中途接入对局

如果中途开始棋盘同步，可以通过右侧的数字判断当前镰刀状态：
- 读取黑方剩余次数
- 读取白方剩余次数
- 同步到 KataGo

---

## 检测算法分析

### 当前算法（可能需要调整）

```java
// 黑方镰刀：检测深色像素
if (r < 60 && g < 60 && b < 60) { targetPixels++; }

// 白方镰刀：检测浅色像素
if (r > 200 && g > 200 && b > 200) { targetPixels++; }
```

### 实际情况

**"黑方镰刀" 文字**：
- 主体：蓝紫色渐变（R≈100-150, G≈50-100, B≈150-200）
- 描边：白色（R>200, G>200, B>200）

**可能的问题**：
- 当前检测"黑方镰刀"用深色阈值，但实际文字是蓝紫色，可能检测不到
- 白色描边可能被误判为"白方镰刀"

### 优化方案

**方案 A**：检测镰刀图案出现（不区分黑白）
- 检测到镰刀提示 → 根据当前轮到谁下棋判断是黑方还是白方

**方案 B**：调整颜色阈值
- 黑方镰刀：检测蓝紫色像素（R<180, G<150, B>100）
- 白方镰刀：检测白色像素（需要看白方镰刀截图）

**方案 C**：OCR 文字识别
- 识别 "黑方镰刀" 或 "白方镰刀" 文字

---

## 系统集成链路

```
野狐围棋界面
    ↓ (Robot.createScreenCapture - 500ms 轮询)
ToolFrame.detectScytheText()
    ↓ (detectScytheByColor - 像素统计)
检测到镰刀
    ↓ (System.out.println: scythe_trigger black/white)
ReadBoard.java 标准输入监听
    ↓ (解析命令)
ScythePanel.triggerScythe()
    ↓ (kata-set-param scythe_trigger true)
KataGo GTP 接口
    ↓ (设置 manualScytheTrigger = true)
BoardHistory.makeBoardMoveAssumeLegal()
    ↓ (检测触发，递减计数，设置 combo)
镰刀连击生效（连续走 3 步）
```

---

## GTP 命令测试结果

**测试时间**: 2026-01-21

```
第 11 手: nextPlayer=W, whiteScythes=3, scytheCombo=0
触发白方镰刀后:
第 12 手: whiteScythes=2, scytheCombo=2, nextPlayer=W  ← 白棋继续
第 13 手: scytheCombo=1, nextPlayer=W                  ← 白棋继续
第 14 手: scytheCombo=0, nextPlayer=B                  ← 轮到黑棋
```

✅ KataGo 镰刀 GTP 命令正常工作

---

## 自动落子技术调研（2026-01-22）

### 回合检测方案对比

| 方案 | 实现难度 | 可靠性 | 说明 |
|------|---------|-------|------|
| 倒计时检测 | 中 | 高 | 检测我方倒计时数字变化 |
| 边框高亮 | 低 | 中 | 检测棋盘边框颜色 |
| OCR 文字识别 | 高 | 高 | 识别"轮到您了"文字 |
| 头像高亮 | 低 | 中 | 检测头像边框颜色 |
| **棋盘状态对比** | **中** | **高** | **对比棋盘是否新增棋子** |

**推荐方案**: 棋盘状态对比
- readboard 已有棋盘识别功能（BoardOCR）
- 每次识别后保存棋盘状态
- 下次识别时对比：如果对方新下了一子 → 轮到我方
- 可靠性高，无需额外视觉特征

### 落子点获取方案对比

| 方案 | 实现难度 | 实时性 | 说明 |
|------|---------|-------|------|
| 解析 lizzieyzy GUI | 高 | 低 | 需要 OCR 或 UI 解析 |
| GTP genmove 命令 | 中 | 中 | 需要等待 KataGo 思考 |
| **解析分析结果** | **低** | **高** | **lizzieyzy 已有分析结果** |

**推荐方案**: 解析分析结果
- lizzieyzy 持续运行分析（kata-analyze）
- readboard 通过协议获取当前最佳手
- 实时性好，无需额外等待

### 坐标转换算法

**已知条件**:
- 棋盘区域：`(boardX1, boardY1, boardX2, boardY2)`
- 棋盘大小：11x11
- GTP 坐标：A1-K11（列：A-K，行：1-11）

**转换公式**:
```java
int boardWidth = boardX2 - boardX1;
int boardHeight = boardY2 - boardY1;
int cellWidth = boardWidth / 10;  // 10 个间隔
int cellHeight = boardHeight / 10;

// GTP 坐标 "D4" → 像素坐标
int col = gtpMove.charAt(0) - 'A';  // D → 3
int row = Integer.parseInt(gtpMove.substring(1)) - 1;  // 4 → 3

int pixelX = boardX1 + col * cellWidth;
int pixelY = boardY1 + (10 - row) * cellHeight;  // Y 轴倒置
```

### 鼠标模拟最佳实践

**Java Robot 类示例**:
```java
Robot robot = new Robot();

// 移动到目标位置
robot.mouseMove(pixelX, pixelY);

// 添加人类延迟（100-300ms）
Thread.sleep(100 + random.nextInt(200));

// 点击
robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
Thread.sleep(50 + random.nextInt(50));
robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
```

**安全机制**:
1. 手动开关：勾选"自动落子"才生效
2. 回合检查：确认轮到我方才点击
3. 区域检查：确认点击位置在棋盘内
4. 日志记录：记录每次落子（时间、坐标、结果）
