# 野狐镰刀自动检测 - 进度日志

**更新时间**: 2026-01-22

> **注意**: 此文件记录的是**棋盘同步工具（C#版 readboard.exe）**的开发任务
> **另一个任务**: 远程8卡5090训练镰刀规则KataGo（在另一个终端进行，与此任务无关）

---

## 📅 当前会话 (2026-01-22) - 野狐镰刀识别成功 + 自动落子开发

### 🎉 重大突破

**野狐镰刀状态和数量识别成功！**
- ✅ 镰刀版 lizzieyzy 启动成功
- ✅ KataGo 引擎加载成功
- ✅ 野狐镰刀区域框选完成
- ✅ **镰刀状态和数量识别成功**

**完成的模块**:
| 模块 | 状态 | 说明 |
|------|------|------|
| Phase 1: readboard 镰刀检测 | ✅ 完成 | 防抖+冷却机制 |
| Phase 2: 集成到 lizzieyzy | ✅ 完成 | JAR 编译集成 |
| Phase 3: 启动和配置 | ✅ **完成** | **野狐镰刀识别成功** |

### 🔄 当前任务：Phase 6 - 自动落子功能

**目标**: 野狐轮到我方时，棋盘同步工具实现自动落子

**核心需求**:
1. 识别野狐当前轮到哪方下棋
2. 获取 KataGo 推荐的最佳落子点
3. 模拟鼠标点击野狐棋盘对应位置
4. 确保时机正确（我方回合才落子）

**技术方案**:
- 回合检测: ToolFrame.java 添加 `detectMyTurn()` 方法
- 获取落子点: 与 lizzieyzy 通信，获取当前最佳手
- 坐标转换: 使用棋盘框选区域映射
- 点击执行: Robot.mouseMove() + Robot.mousePress()

### 与其他任务的区分

| 任务 | 状态 | 说明 |
|------|------|------|
| **自动落子功能开发** | 🔄 **进行中** | 本文件记录 |
| 野狐镰刀识别 | ✅ **成功** | Phase 3 完成 |
| KataGo 镰刀版 v1.3 | ✅ 完成 | 已编译成功 |
| lizzieyzy 镰刀面板 | ✅ 完成 | ScythePanel.java |
| 远程训练（8卡5090） | 🔄 另一终端 | 与此无关 |

---

## 📅 历史会话 (2026-01-21)

### 会话目标
实现野狐围棋镰刀自动检测功能（棋盘同步 + 镰刀自动触发）

### 技术方案
**Java 方案**（修改 readboard-java 中的 ToolFrame.java）
- 原因：基础代码已存在（90% 完成）
- 优势：无需额外依赖，直接集成到 lizzieyzy
- 工作量：仅需 3 个小修改（防抖+冷却）

---

## ✅ 已完成模块总览

### KataGo 镰刀版 v1.3
- `boardhistory.h`: 镰刀状态变量定义（104-111行）
- `boardhistory.cpp`: 镰刀触发和连击逻辑
- `gtp.cpp`: GTP 命令接口 + scytheTriggerHistory 追踪
- `search.cpp`: 玩家切换逻辑（presumedNextMovePla）
- 编译输出: `KataGo/cpp/build/Release/katago.exe`
- 测试: 7 个测试套件全部通过

### lizzieyzy GUI
- `ScythePanel.java`: 镰刀状态显示面板
- 手动点击触发功能
- 自动检测器集成（ScytheDetector 引用）
- GTP 命令通信（kata-set-param scythe_trigger）

### readboard 棋盘同步
- `BoardOCR.java`: 棋盘识别（用户已有）
- `ReadBoard.java`: 协议处理（已支持 scythe_trigger 命令）
- 配置持久化: Config.java

### 镰刀版 lizzieyzy 环境
- `scythe_lizzie/` 独立目录
- `scythe_lizzie/config.txt` 镰刀配置（11路棋盘）
- `start_scythe_lizzie.bat` 启动脚本
- `/gui` skill 命令

---

## 🔄 当前任务：Phase 6 - 自动落子功能

### 任务清单

**已完成**:
- [x] Phase 1: 优化 readboard 镰刀检测
- [x] Phase 2: 集成到 lizzieyzy
- [x] Phase 3: 启动和配置
- [x] **野狐镰刀状态和数量识别成功**

**进行中 - Phase 6 自动落子**:
- [ ] 分析野狐界面：判断轮到我方下棋的特征
- [ ] 实现回合检测逻辑（detectMyTurn）
- [ ] 获取 KataGo 推荐落子点（genmove 或分析结果）
- [ ] 坐标转换：GTP → 野狐屏幕像素
- [ ] 模拟鼠标点击（Robot 类）
- [ ] 添加安全机制（手动开关、日志）

**待办**:
- [ ] 端到端测试（Phase 4）
- [ ] 野狐实测优化（Phase 5）

---

## 📊 关键发现记录

### 2026-01-22 野狐镰刀识别成功

**🎉 重大突破**:
- ✅ **野狐镰刀状态和数量识别成功**
- ✅ 镰刀版 lizzieyzy 启动成功
- ✅ KataGo 引擎正常工作
- ✅ 棋盘同步功能正常
- ✅ 镰刀检测防抖和冷却机制工作正常

**下一步目标**:
- 🔄 实现自动落子功能
- 需要识别野狐"轮到我方"的特征
- 需要获取 KataGo 推荐落子点
- 需要坐标转换和鼠标模拟

### 2026-01-21 会话开始

**重要发现**:
- ✨ ToolFrame.java (545-607行) 已实现基础镰刀检测代码
- ✨ detectScytheByColor() 像素统计逻辑完善
- ✨ UI 组件（自动检测开关、设置区域按钮）已完成
- ✨ 配置持久化（Config.java）已完成

**缺失功能**:
- ✅ 防抖机制（已完成）
- ✅ 冷却机制（已完成）
- ✅ 阈值已通过野狐实测验证

---

## 🔧 代码修改记录

### ToolFrame.java 计划修改

**修改 1**: 第 107 行后添加变量
```java
// 防抖和冷却机制
private int blackConsecutiveMatches = 0;
private int whiteConsecutiveMatches = 0;
private long lastBlackTriggerTime = 0;
private long lastWhiteTriggerTime = 0;
private static final int REQUIRED_MATCHES = 2;
private static final long COOLDOWN_MS = 3000;
```

**修改 2**: 增强 detectScytheText() 方法（545-573行）
- 添加连续匹配计数逻辑
- 添加冷却检查
- 重置计数器

**修改 3**: 新增冷却检查方法（607行后）
```java
private boolean canTriggerBlack() {
    long now = System.currentTimeMillis();
    return (now - lastBlackTriggerTime) >= COOLDOWN_MS;
}

private boolean canTriggerWhite() {
    long now = System.currentTimeMillis();
    return (now - lastWhiteTriggerTime) >= COOLDOWN_MS;
}
```

---

## 🧪 测试计划

### Phase 4 测试用例

| ID | 测试项 | 验收标准 | 状态 |
|----|--------|---------|------|
| TC-1 | 黑方镰刀自动触发 | 延迟 < 1.5s，计数递减 | ⏳ 待测 |
| TC-2 | 白方镰刀自动触发 | 延迟 < 1.5s，计数递减 | ⏳ 待测 |
| TC-3 | 防抖机制 | 快速移动窗口不触发 | ⏳ 待测 |
| TC-4 | 冷却机制 | 3秒内不重复触发 | ⏳ 待测 |
| TC-5 | 棋盘同步 | 识别率 > 95% | ⏳ 待测 |

---

## ⚠️ 待修复的代码问题

> 来源：code-error-checker agent 检查结果（优先级低于功能开发）

### 严重问题（KataGo 镰刀版）

1. **随机触发时机错误**
   - 位置: `boardhistory.cpp:1109-1126`
   - 问题: 在 `moveHistory.push_back` 之后检查，导致晚一手触发
   - 修复: 将检查移到 `push_back` 之前
   - 状态: ⏳ Phase 6 修复

2. **manualScytheTrigger 未处理**
   - 位置: `boardhistory.cpp`
   - 问题: BoardHistory 层没有处理手动触发标志
   - 修复: 添加 manualScytheTrigger 检查逻辑
   - 状态: ⏳ Phase 6 修复

3. **Pass 拦截逻辑冲突**
   - 位置: `gtp.cpp:3117-3142`
   - 问题: Pass 被误用为镰刀触发信号
   - 修复: 移除 Pass 拦截，只用 kata-set-param
   - 状态: ⏳ Phase 6 修复

---

## 📝 决策记录

### 2026-01-22: 自动落子实现方案
**决策**: 在 readboard-java 中实现自动落子功能
**原因**:
- ✅ readboard 已有棋盘区域框选功能
- ✅ Java Robot 类可模拟鼠标点击
- ✅ 与 lizzieyzy 通信已建立（协议通道）
- ✅ 可复用现有坐标映射逻辑

**技术要点**:
1. **回合检测**: 视觉特征识别（读秒、边框高亮）
2. **落子点获取**: 与 lizzieyzy 通信获取最佳手
3. **坐标转换**: GTP 坐标 → 野狐屏幕像素
4. **鼠标模拟**: Robot.mouseMove() + Robot.mousePress()

### 2026-01-21: 技术方案选择
**决策**: 使用 Java 方案（修改 readboard）而非 Python
**原因**:
- ✅ readboard 基础代码已存在（detectScytheByColor）
- ✅ 不需要额外安装软件
- ✅ 直接集成到 lizzieyzy
- ❌ Python 方案依赖安装失败（Windows Store 限制）

### 2026-01-21: 实现方式选择
**决策**: 轻量级优化（无需新建 ScytheDetector 类）
**原因**:
- ✅ ToolFrame.java 已有 90% 代码
- ✅ 只需添加 3 个小修改（防抖+冷却）
- ✅ 降低复杂度，快速实现
- ✅ **已验证成功**

### 2026-01-21: 使用 planning-with-files skill
**决策**: 采用 Manus 风格文件规划
**原因**:
- ✅ 任务复杂，涉及多个阶段
- ✅ 需要持久化规划和发现
- ✅ 便于会话恢复和上下文管理
- ✅ **效果很好**

---

## 📂 关键文件路径

### 当前阶段需要关注的文件

**readboard-java**:
- `readboard-java-src/src/main/java/boardsync/ToolFrame.java` - **主要修改文件**
- `readboard-java-src/src/main/java/boardsync/Config.java` - 配置持久化 ✅
- `readboard-java-src/src/main/java/boardsync/ScytheAreaDialog.java` - 区域框选 ✅
- `readboard-java-src/pom.xml` - Maven 构建配置

**lizzieyzy**:
- `lizzieyzy-main/src/main/java/featurecat/lizzie/analysis/ReadBoard.java` - 协议处理 ✅
- `lizzieyzy-main/src/main/java/featurecat/lizzie/gui/ScythePanel.java` - GUI 显示 ✅
- `lizzieyzy-main/pom.xml` - Maven 构建配置

**镰刀版环境**:
- `scythe_lizzie/config.txt` - 镰刀配置 ✅
- `start_scythe_lizzie.bat` - 启动脚本 ✅

---

## 🎯 下一步行动

**当前阶段**: Phase 1 - 优化 readboard 镰刀检测

**立即执行**:
1. 读取 ToolFrame.java 完整代码（确认行号）
2. 添加防抖和冷却机制（3 处修改）
3. 编译 readboard-java
4. 验证编译无错误

**等待用户**:
- Phase 3: 关闭现有 lizzieyzy 进程
- Phase 3: 提供 KataGo 模型文件路径
- Phase 5: 野狐实测反馈和参数调优

---

## 📈 里程碑

- [x] **2026-01-20**: KataGo 镰刀版 v1.3 编译成功
- [x] **2026-01-20**: lizzieyzy 镰刀面板完成
- [x] **2026-01-21**: 发现 readboard 基础代码已存在
- [x] **2026-01-21**: 创建 Manus 风格规划文件
- [x] **2026-01-22**: 完成 readboard 镰刀检测优化
- [x] **2026-01-22**: 镰刀版 lizzieyzy 首次启动
- [x] **2026-01-22**: 🎉 **野狐镰刀状态和数量识别成功**
- [ ] **2026-01-22**: 自动落子功能开发（进行中）
- [ ] **2026-01-22**: 野狐自动下棋首次成功
