# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# 镰刀 KataGo

修改版 KataGo 围棋引擎，为 11x11 棋盘添加**镰刀规则**：第 11-49 手期间，每方有 3 次机会连续走 3 步。

## 构建命令

```batch
# KataGo C++ 快速编译（增量）
cd /d D:\ScytheKatago\KataGo\cpp\build && cmake --build . --config Release --parallel 4

# KataGo 完整重建（从头配置）
cd /d D:\ScytheKatago\KataGo\cpp && mkdir build && cd build
cmake .. -DUSE_BACKEND=CUDA -DUSE_AVX2=1
cmake --build . --config Release --parallel 4

# lizzieyzy Java GUI 编译
cd /d D:\ScytheKatago\lizzieyzy-main && mvn package -DskipTests
```

**编译输出**:
- KataGo: `KataGo/cpp/build/Release/katago.exe`
- lizzieyzy: `lizzieyzy-main/target/lizzie-yzy2.5.3-shaded.jar`

## 神经网络后端选择

| 后端 | 适用场景 | CMake 选项 |
|------|---------|-----------|
| **TensorRT** | NVIDIA GPU 最佳性能 | `-DUSE_BACKEND=TENSORRT` |
| **CUDA** | NVIDIA GPU 通用 | `-DUSE_BACKEND=CUDA` |
| **OpenCL** | AMD/Intel GPU，跨平台 | `-DUSE_BACKEND=OPENCL` |
| **Eigen** | 纯 CPU，无 GPU | `-DUSE_BACKEND=EIGEN` |

TensorRT 后端需要安装 NVIDIA TensorRT SDK。

## 测试命令

```batch
# 运行完整测试套件
test_scythe_suite\run_all_tests.bat

# 运行单个测试
test_scythe_suite\run_single_test.bat test_basic.txt

# 手动 GTP 测试
KataGo\cpp\build\Release\katago.exe gtp -model kata1-b6c96.bin.gz -config scythe_config.cfg
```

## 核心架构：镰刀数据流

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

**关键修改文件**（镰刀逻辑）：
- `KataGo/cpp/game/boardhistory.h:104-111` - 镰刀状态变量定义
- `KataGo/cpp/game/boardhistory.cpp` - 触发逻辑、combo 管理、undo 恢复
- `KataGo/cpp/command/gtp.cpp` - GTP 命令解析、状态查询
- `KataGo/cpp/search/search.cpp` - `presumedNextMovePla` 玩家切换

## 项目目录

| 目录 | 说明 |
|------|------|
| `KataGo/cpp/` | C++ 引擎源码 |
| `lizzieyzy-main/` | Java GUI（Maven 项目） |
| `readboard-src/` | 野狐棋盘同步工具（C# 版） |
| `readboard-java-src/` | 野狐棋盘同步工具（Java 版） |
| `test_scythe_suite/` | 镰刀 GTP 自动化测试 |
| `scythe_lizzie/` | 镰刀版 lizzieyzy 运行环境 |

## 镰刀 GTP 命令

```
kata-get-scythe-status              # 查询状态（返回 JSON）
kata-set-param scythe_trigger true  # 触发镰刀
kata-set-param scythe_count_black 3 # 设置黑方镰刀数
kata-set-param scythe_count_white 3 # 设置白方镰刀数
```

**状态响应示例**：
```json
{"blackScythes":3,"whiteScythes":3,"scytheCombo":0,"nextPlayer":"B","isComboActive":false,"moveNumber":10,"canUseScythe":true}
```

## 开发规范

详细规范见 `.claude/rules/` 目录：
- `cpp.md` - C++ 代码规范（缩进、GTP 协议约束）
- `java.md` - Java 代码规范
- `scythe.md` - 镰刀规则详解

**核心约束**：
- **GTP 协议**: C++ 调试输出必须发到 `stderr`，绝不能发到 `stdout`
- **undo 处理**: 必须通过 `scytheTriggerHistory` 保存/恢复镰刀状态

## Skill 命令

| 命令 | 说明 |
|------|------|
| `/gui` | 启动镰刀版 lizzieyzy |
| `/build` | 编译 KataGo 和 lizzieyzy |
| `/push` | 提交并推送到远程 |

## 开发注意事项

- **语言**: 始终使用中文
- **修改前先读取代码**
- **同一 bug 出现 2 次**: 先反思原因，确立修改计划后再操作
