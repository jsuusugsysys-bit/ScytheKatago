# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述
修改版 KataGo，为 11x11 棋盘添加**镰刀规则**：第 11-49 手期间，每方有 3 次机会连续走 3 步。

**平台**：Windows (MSVC/CMake)，CPU (Eigen) 后端。

## 构建命令

```batch
build.bat              # 完整构建（首次使用）
start_scythe.bat       # 启动 GUI（推荐）
```

**快速编译**（修改代码后）：
```powershell
cd D:\ScytheKatago\KataGo\cpp\build
& 'C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe' katago.sln /p:Configuration=Release /m
```

**输出**：`KataGo/cpp/build/Release/katago.exe`

## 项目结构

```
D:\ScytheKatago\
├── KataGo\cpp\           # KataGo C++ 源码
│   ├── game\             # 核心游戏逻辑
│   │   ├── boardhistory.h/cpp  # 镰刀状态管理
│   │   └── board.h/cpp         # 棋盘表示
│   ├── search\           # MCTS 搜索
│   │   └── search.cpp          # 玩家切换逻辑
│   └── command\          # 命令行接口
│       └── gtp.cpp             # GTP 命令 + undo
├── lizzieyzy-main\       # GUI（Java）
│   └── target\           # 编译输出
└── eigen3\               # CPU 线性代数库
```

## 镰刀架构

**状态变量** (`boardhistory.h:104-110`)：
- `blackScythes` / `whiteScythes`: 各方剩余镰刀次数（初始3）
- `scytheCombo`: 当前连续落子计数（0-3）
- `manualScytheTrigger`: GUI 手动触发标志

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
- **undo 处理**：必须保存/恢复镰刀状态

## 用户说明

- **语言**：始终使用中文交流
- **背景**：用户是编程新手，需要详细清晰的解释
- **修改前先读取代码**
- **命令要清晰**：长命令单独一行给出，不要放在表格里
- **确保理解我意思了，再写代码
- **尽量你自动化测试，除非花很长时间，我能快速手动帮你解决的
- **如果同一个bug出现2次，反思原因，确立修改计划后再操作
- **为了减少不必要的token消耗，你需要高效率的执行代码，分析解决问题
 **每次改动到一定程度帮我提交到分支或者主线，然后开始下次，以确保我朝正确方向逐步完善，不至于陷入死循环，甚至回退到过时版本
