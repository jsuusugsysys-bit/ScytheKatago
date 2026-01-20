# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

修改版 KataGo，为 11x11 棋盘添加**镰刀规则**：第 11-49 手期间，每方有 3 次机会连续走 3 步。

**当前版本**：v1.1（详见 `.claude/VERSIONS.md`）

**平台**：Windows (MSVC/CMake)，CPU (Eigen) 后端

## 构建命令

```batch
build.bat              # 完整构建（首次使用，包含 zlib）
start_scythe.bat       # 启动 GUI（lizzieyzy）
```

**快速编译**（修改代码后）：
```powershell
cd D:\ScytheKatago\KataGo\cpp\build
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe' katago.sln /p:Configuration=Release /m
```

**输出**：`KataGo/cpp/build/Release/katago.exe`

## 测试命令

```batch
# 运行完整测试套件
test_scythe_suite\run_all_tests.bat

# 运行单个测试
test_scythe_suite\run_single_test.bat test_basic.txt

# 手动测试（GTP 交互）
KataGo\cpp\build\Release\katago.exe gtp -model <model.bin.gz> -config scythe_config.cfg
```

测试文件位于 `test_scythe_suite/`，包含 7 个测试场景（basic、boundary、combo、count、both_players、board_size、reset）。

## 项目结构

```
D:\ScytheKatago\
├── KataGo\cpp\           # KataGo C++ 源码
│   ├── game\             # 核心游戏逻辑
│   │   ├── boardhistory.h/cpp  # 镰刀状态管理（核心修改）
│   │   └── board.h/cpp         # 棋盘表示
│   ├── search\           # MCTS 搜索
│   │   └── search.cpp          # 玩家切换逻辑
│   └── command\          # 命令行接口
│       └── gtp.cpp             # GTP 命令 + undo + scytheTriggerHistory
├── lizzieyzy-main\       # GUI（Java）
│   └── target\           # 编译输出（lizzie-yzy2.5.3-shaded.jar）
├── test_scythe_suite\    # 自动化测试套件
├── eigen3\               # CPU 线性代数库
├── zlib\                 # 压缩库依赖
└── scythe_config.cfg     # 镰刀专用配置文件
```

## 镰刀架构

**状态变量** (`boardhistory.h:104-111`)：
- `blackScythes` / `whiteScythes`: 各方剩余镰刀次数（初始3）
- `scytheCombo`: 当前连续落子计数（0-3）
- `manualScytheTrigger`: GUI 手动触发标志
- `scytheRandomMode`: 训练模式随机触发开关
- `scytheRandomTriggers`: 预生成的随机触发手数列表

**触发历史追踪** (`gtp.cpp`)：
- `scytheTriggerHistory`: 记录每次镰刀触发的手数，undo 时用于正确恢复计数

**核心流程**：
1. GUI 发送 `kata-set-param scythe_trigger true`
2. `gtp.cpp` 设置 `manualScytheTrigger = true`
3. `boardhistory.cpp:makeBoardMoveAssumeLegal` 检测触发，递减计数，设置 combo
4. `presumedNextMovePla` 在 combo 期间不切换玩家
5. `search.cpp:355` 使用 `presumedNextMovePla` 决定下一手玩家

## 镰刀 GTP 命令

```
kata-get-scythe-status              # 查询状态（JSON）
kata-set-param scythe_trigger true  # 触发镰刀
kata-set-param scythe_count_black 3 # 设置黑方镰刀数
kata-set-param scythe_count_white 3 # 设置白方镰刀数
```

## 重要约束

- **GTP 协议**：调试输出必须发到 `stderr`，绝不能发到 `stdout`
- **镰刀条件**：棋盘 11x11 + 手数 11-49 + 剩余镰刀 > 0
- **C++17**：使用 `std::shuffle`（不用 `std::random_shuffle`）
- **undo 处理**：必须保存/恢复镰刀状态（通过 `scytheTriggerHistory` 追踪）

## 自定义 Skill 命令

项目专用的快捷命令（位于 `.claude/commands/`）：

- `/build` - 编译 KataGo 项目
- `/gui` - 编译 lizzieyzy 并启动调试
- `/test` - 为镰刀功能创建或运行测试
- `/fix` - 分析并修复编译错误或运行时错误
- `/debug` - 调试 KataGo 或镰刀功能问题
- `/review` - 审查当前分支的所有代码改动
- `/explain` - 详细解释指定代码的工作原理
- `/status` - 显示项目当前状态
- `/gtp` - 启动 KataGo GTP 交互模式进行手动测试
- `/optimize` - 分析性能并提出优化建议
- `/push` - 提交所有变更文件并推送到远程仓库

## 开发规范

- **语言**：始终使用中文交流
- **修改前先读取代码**
- **命令要清晰**：长命令单独一行给出，不要放在表格里
- **同一 bug 出现 2 次时**：先反思原因，确立修改计划后再操作
- **定期提交**：每次改动到一定程度提交到分支或主线，避免陷入死循环
