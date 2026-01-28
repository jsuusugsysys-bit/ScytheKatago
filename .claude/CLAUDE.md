# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

## ⚡ 快速命令速查表

### 编译命令

> **编译环境**: Visual Studio 2026 (v18) Developer Command Prompt

```batch
# KataGo 快速编译（Claude Code 可直接执行）
powershell -Command "& cmd /c '\"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat\" && cd /d D:\ScytheKatago\KataGo\cpp\build && cmake --build . --config Release --parallel 4'"

# 或在 Developer Command Prompt 中手动执行
cd /d D:\ScytheKatago\KataGo\cpp\build
cmake --build . --config Release --parallel 4

# lizzieyzy GUI 编译（普通命令行即可）
cd /d D:\ScytheKatago\lizzieyzy-main && mvn package -DskipTests

# 输出位置
# - KataGo: KataGo/cpp/build/Release/katago.exe
# - GUI: lizzieyzy-main/target/lizzie-yzy2.5.3-shaded.jar
```

### 测试命令
```batch
# 运行所有镰刀测试
D:\ScytheKatago\test_scythe_suite\run_all_tests.bat

# 手动 GTP 测试（交互式）
cd /d D:\ScytheKatago && KataGo\cpp\build\Release\katago.exe gtp -model kata1-b6c96.bin.gz -config scythe_config.cfg
```

### 启动命令
```batch
# 启动镰刀版 GUI
cd /d D:\ScytheKatago\scythe_lizzie && start_scythe_lizzie.bat

# 或使用 skill 命令
/gui
```

### 常用 Git 操作
```batch
# 查看当前状态
git status

# 查看修改内容
git diff

# 提交前检查（推荐先运行测试）
test_scythe_suite\run_all_tests.bat

# 使用 skill 提交并推送
/push
```

### 镰刀 GTP 命令（在 katago.exe gtp 模式下）
```gtp
kata-get-scythe-status                # 查询镰刀状态
kata-set-param scythe_trigger true    # 触发镰刀
kata-set-param scythe_count_black 3   # 设置黑方镰刀数
kata-set-param scythe_count_white 3   # 设置白方镰刀数
```

---

# 镰刀 KataGo

修改版 KataGo 围棋引擎，为 11x11 棋盘添加**镰刀规则**：第 11-49 手期间，每方有 3 次机会连续走 3 步。

## 构建命令

```batch
# KataGo C++ 快速编译（增量）
cd KataGo\cpp\build && cmake --build . --config Release --parallel 4

# KataGo 完整重建
cd KataGo\cpp && mkdir build && cd build
cmake .. -DUSE_BACKEND=CUDA -DUSE_AVX2=1
cmake --build . --config Release --parallel 4

# lizzieyzy Java GUI 编译
cd lizzieyzy-main && mvn package -DskipTests
```

**编译输出**:
- KataGo: `KataGo/cpp/build/Release/katago.exe`
- lizzieyzy: `lizzieyzy-main/target/lizzie-yzy2.5.3-shaded.jar`

## 测试命令

```batch
# 运行完整测试套件
test_scythe_suite\run_all_tests.bat

# 运行单个测试
test_scythe_suite\run_single_test.bat test_basic.txt

# 手动 GTP 测试
KataGo\cpp\build\Release\katago.exe gtp -model kata1-b6c96.bin.gz -config scythe_config.cfg
```

## 神经网络后端

| 后端 | 适用场景 | CMake 选项 |
|------|---------|-----------|
| **TensorRT** | NVIDIA GPU 最佳性能 | `-DUSE_BACKEND=TENSORRT` |
| **CUDA** | NVIDIA GPU 通用 | `-DUSE_BACKEND=CUDA` |
| **OpenCL** | AMD/Intel GPU | `-DUSE_BACKEND=OPENCL` |
| **Eigen** | 纯 CPU | `-DUSE_BACKEND=EIGEN` |

## 核心架构

### KataGo C++ 源码结构（按依赖层次）

```
external/     低层：第三方库
    ↓
core/         低层：基础工具（哈希、随机数、文件系统）
    ↓
game/         游戏逻辑层
├── rules.cpp/h       规则结构体
├── board.cpp/h       棋盘实现（不含历史）
├── boardhistory.cpp/h 棋盘+历史（包含镰刀状态）
└── graphhash.cpp/h   蒙特卡洛图搜索哈希
    ↓
neuralnet/    神经网络层
├── desc.cpp/h        网络结构和权重
├── nninputs.cpp/h    输入特征
├── nneval.cpp/h      线程安全的批量查询
└── *backend.cpp      各后端实现
    ↓
search/       搜索引擎层
├── searchparams.cpp/h 搜索参数
├── search.cpp/h      多线程 MCTS 实现
├── searchresults.cpp 结果处理、落子选择
└── asyncbot.cpp/h    异步 pondering
    ↓
command/      用户命令层
├── gtp.cpp           GTP 协议引擎
├── analysis.cpp      JSON 分析引擎
├── benchmark.cpp     性能测试
└── selfplay.cpp      自对弈数据生成
```

### 镰刀数据流

```
GUI 触发镰刀:
  lizzieyzy (ScythePanel.java)
       │
       ▼  kata-set-param scythe_trigger true
  gtp.cpp ─────► boardhistory.manualScytheTrigger = true
       │
       ▼  makeBoardMoveAssumeLegal()
  boardhistory.cpp ─────► scytheCombo++, 扣减镰刀次数
       │
       ▼  presumedNextMovePla 不切换
  search.cpp ─────► 继续为同一玩家搜索
```

### 镰刀关键修改点

| 文件 | 位置 | 职责 |
|------|------|------|
| `boardhistory.h` | :104-111 | 镰刀状态变量定义 |
| `boardhistory.cpp` | | 触发逻辑、combo 管理、undo 恢复 |
| `gtp.cpp` | | GTP 命令解析、状态查询 |
| `search.cpp` | | `presumedNextMovePla` 玩家切换控制 |

### 镰刀 GTP 命令

```
kata-get-scythe-status              # 查询状态（返回 JSON）
kata-set-param scythe_trigger true  # 触发镰刀
kata-set-param scythe_count_black 3 # 设置黑方镰刀数
kata-set-param scythe_count_white 3 # 设置白方镰刀数
```

## 项目目录

| 目录 | 说明 |
|------|------|
| `KataGo/cpp/` | C++ 引擎源码 |
| `lizzieyzy-main/` | Java GUI（Maven 项目） |
| `readboard-src/` | 野狐棋盘同步工具（C# 版） |
| `readboard-java-src/` | 野狐棋盘同步工具（Java 版） |
| `test_scythe_suite/` | 镰刀 GTP 自动化测试 |
| `scythe_lizzie/` | 镰刀版 lizzieyzy 运行环境 |

## 开发规范

详细规范见 `.claude/rules/` 目录：
- `cpp.md` - C++ 代码规范
- `java.md` - Java 代码规范
- `scythe.md` - 镰刀规则详解
- `git-workflow.md` - Git 提交规范

**核心约束**：
- **GTP 协议**: C++ 调试输出必须发到 `stderr`，绝不能发到 `stdout`
- **undo 处理**: 必须通过 `scytheTriggerHistory` 保存/恢复镰刀状态
- **C++ 缩进**: 2 空格
- **Java 缩进**: 4 空格

## Skill 命令

| 命令 | 说明 |
|------|------|
| `/push` | 提交并推送到远程 |
| `/handoff` | 会话交接（保存/恢复工作上下文） |
| `/research` | 联网研究与技术调研 |

## 开发注意事项

- **语言**: 始终使用中文
- **修改前先读取代码**
- **同一 bug 出现 2 次**: 先反思原因，确立修改计划后再操作
- **Git 操作**: 所有 git add/commit/push 操作必须先询问用户确认
