# 野狐镰刀自动检测 - 任务计划

**目标**: 为野狐围棋实现镰刀自动检测功能（棋盘同步 + 镰刀自动触发 + 自动落子）

**更新时间**: 2026-01-22

---

## 当前状态总览

| 模块 | 状态 | 说明 |
|------|------|------|
| KataGo 镰刀版 v1.3 | ✅ 完成 | 编译成功，GTP 命令可用 |
| lizzieyzy 镰刀面板 | ✅ 完成 | ScythePanel.java 已实现 |
| readboard 棋盘同步 | ✅ 完成 | BoardOCR 已实现 |
| **readboard 镰刀检测** | ✅ 完成 | **ToolFrame.java 防抖+冷却机制完整实现** |
| **野狐镰刀识别** | ✅ **成功** | **野狐镰刀状态和数量识别成功** |
| 镰刀版 lizzieyzy | ✅ 完成 | scythe_lizzie/ 目录和启动脚本 |
| 编译集成 | ✅ 完成 | readboard + lizzieyzy 已编译 |
| **自动落子功能** | 🔄 **进行中** | **野狐轮到我方时自动落子** |

**2026-01-22 重大突破**:
- ✅ 野狐镰刀状态和数量识别成功！
- ✅ `detectScythe()` - 检测入口
- ✅ 颜色检测：蓝紫色（黑方）、红色（白方）
- ✅ 防抖机制：`REQUIRED_MATCHES = 2`
- ✅ 冷却机制：`COOLDOWN_MS = 3000`
- 🔄 **当前任务**: 实现自动落子功能

---

## 阶段计划

### Phase 1: 优化 readboard 镰刀检测 `complete`

**目标**: 在现有基础上添加防抖和冷却机制，避免误触发

**具体任务**:
- [x] 读取 ToolFrame.java 现有实现
- [x] 确认防抖机制已存在（`REQUIRED_MATCHES = 2`）
- [x] 确认冷却机制已存在（`COOLDOWN_MS = 3000`）
- [x] 编译 readboard-java → `target/readboard-1.6.2-shaded.jar`

**验收标准**: ✅ 全部通过
- 连续匹配 2 次才触发（防抖）✅
- 触发后 3 秒内不重复触发（冷却）✅
- 编译无错误 ✅

### Phase 2: 集成到镰刀版 lizzieyzy `complete`

**目标**: 将新编译的 readboard 集成到镰刀版

**具体任务**:
- [x] 复制 jar 到 `lizzieyzy-main/src/main/resources/assets/readboard_java/`
- [x] 编译 lizzieyzy → `target/lizzie-yzy2.5.3-shaded.jar`
- [x] 验证编译无错误

**编译时间**: 2026-01-22 12:50

### Phase 3: 启动和配置 `complete`

**目标**: 启动镰刀版 lizzieyzy 并完成首次配置

**具体任务**:
- [x] 用户关闭现有 lizzieyzy 进程（如果有）
- [x] 启动镰刀版（工作目录 scythe_lizzie/）
- [x] 配置引擎：菜单加载 KataGo
  - 引擎路径: `KataGo/cpp/build/Release/katago.exe`
  - 配置文件: `scythe_config.cfg`
  - 模型文件: （用户提供）
- [x] 框选野狐镰刀检测区域
- [x] 勾选"自动检测"
- [x] **野狐镰刀状态和数量识别成功！**

**验收标准**: ✅ 全部通过
- 镰刀版 lizzieyzy 启动成功 ✅
- KataGo 引擎加载成功 ✅
- 野狐镰刀区域框选完成 ✅
- 镰刀状态和数量识别成功 ✅

### Phase 4: 端到端测试 `pending`

**目标**: 验证完整链路（野狐 → readboard → lizzieyzy → KataGo）

**测试用例**:
| ID | 测试项 | 预期结果 | 验收标准 |
|----|--------|---------|---------|
| TC-1 | 黑方镰刀自动触发 | 计数递减 | 延迟 < 1.5s |
| TC-2 | 白方镰刀自动触发 | 计数递减 | 延迟 < 1.5s |
| TC-3 | 防抖机制 | 快速移动窗口不触发 | 0 误触发 |
| TC-4 | 冷却机制 | 3秒内不重复触发 | 单次触发 |
| TC-5 | 棋盘同步 | 野狐 → lizzieyzy → KataGo | 识别率 > 95% |

### Phase 5: 野狐实测优化 `pending`

**目标**: 根据野狐实际界面调整参数

**优化项**:
- [ ] 调整 RGB 阈值（黑色 < 60，白色 > 200）
- [ ] 调整 MIN_PIXELS 最少像素数
- [ ] 监控 CPU 占用率（目标 < 10%）
- [ ] 如需要：实现降采样检测

### Phase 6: 自动落子功能 `in_progress`

**目标**: 野狐轮到我方时，棋盘同步工具实现自动落子

**核心需求**:
- 识别野狐当前轮到哪方下棋
- 获取 KataGo 推荐的最佳落子点
- 模拟鼠标点击野狐棋盘对应位置
- 确保时机正确（我方回合才落子）

**具体任务**:
- [ ] 分析野狐界面：如何判断轮到我方下棋
  - 检测读秒/倒计时显示
  - 检测棋盘边框高亮
  - 或其他视觉特征
- [ ] 实现回合检测逻辑（readboard-java）
- [ ] 获取 KataGo 推荐落子点
  - 通过 GTP 命令 `genmove` 或解析分析结果
  - 获取坐标（如 "D4"）
- [ ] 坐标转换：GTP → 野狐屏幕像素
  - 映射棋盘区域
  - 计算交叉点位置
- [ ] 模拟鼠标点击
  - Java Robot 类点击
  - 添加随机延迟（模拟人类操作）
- [ ] 安全机制
  - 只在我方回合触发
  - 添加手动开关（可暂停自动落子）
  - 记录日志

**技术方案**:
1. **回合检测**: ToolFrame.java 添加 `detectMyTurn()` 方法
2. **获取落子点**: 与 lizzieyzy 通信，获取当前最佳手
3. **坐标转换**: 使用棋盘框选区域映射
4. **点击执行**: Robot.mouseMove() + Robot.mousePress()

**验收标准**:
- 能准确识别我方回合 ✓
- 获取 KataGo 推荐落子点 ✓
- 点击位置误差 < 5 像素 ✓
- 延迟 < 2 秒 ✓
- 无误点（非我方回合不触发）✓

---

## 关键路径文件

| 文件 | 说明 | 修改位置 |
|------|------|---------|
| `readboard-java-src/src/main/java/boardsync/ToolFrame.java` | 镰刀检测核心 | 107行后、545-573行、607行后 |
| `readboard-java-src/pom.xml` | Maven 构建配置 | 无需修改 |
| `lizzieyzy-main/src/main/java/featurecat/lizzie/analysis/ReadBoard.java` | 协议处理 | ✅ 已支持 scythe_trigger |
| `lizzieyzy-main/src/main/java/featurecat/lizzie/gui/ScythePanel.java` | GUI 显示 | ✅ 已完成 |
| `scythe_lizzie/config.txt` | 镰刀版配置 | ✅ 已创建（11路棋盘） |
| `start_scythe_lizzie.bat` | 启动脚本 | ✅ 已创建 |

---

## 错误记录

| 错误 | 阶段 | 解决方案 | 状态 |
|------|------|---------|------|
| - | - | - | - |

（记录所有遇到的错误和解决方案）

---

## 决策记录

### 2026-01-21: 方案选择
- **决策**: 使用 Java 方案（修改 readboard）
- **原因**:
  - ✅ readboard 基础代码已存在（detectScytheByColor）
  - ✅ 不需要额外安装软件
  - ✅ 直接集成到 lizzieyzy
  - ❌ Python 方案依赖安装失败

### 2026-01-21: 实现方式
- **决策**: 轻量级优化（无需新建 ScytheDetector 类）
- **原因**:
  - ToolFrame.java 已有 90% 代码
  - 只需添加 3 个小修改（防抖+冷却）
  - 降低复杂度

---

## 下一步行动

**当前阶段**: Phase 1 - 优化 readboard 镰刀检测

**立即行动**:
1. 读取 ToolFrame.java 现有代码（545-607行）
2. 确认像素统计逻辑
3. 添加防抖和冷却机制
4. 编译测试

**等待用户**:
- 关闭现有 lizzieyzy 进程（Phase 3 启动前）
- 提供 KataGo 模型文件路径（Phase 3 配置时）
- 野狐实测反馈（Phase 5 优化时）
