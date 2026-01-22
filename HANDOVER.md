# 镰刀 KataGo 项目交接文档

**更新时间**: 2026-01-22 19:30

---

## 当前状态

### ✅ 已完成

#### 1. KataGo 镰刀版 v1.4
- **位置**: `KataGo/cpp/build/Release/katago.exe`
- **功能**: 11x11 棋盘镰刀规则（第 11-49 手，每方 3 次连续走 3 步）
- **修改文件**:
  - `gtp.cpp`: GTP 命令接口优化
  - `boardhistory.cpp`: 镰刀触发逻辑改进
  - `search.cpp`: 玩家切换逻辑调整

#### 2. lizzieyzy GUI v2.5.3
- **位置**: `scythe_lizzie/lizzie-yzy2.5.3-shaded.jar`
- **功能**: 镰刀状态显示面板
- **修改文件**: `ScythePanel.java`

#### 3. C# 棋盘同步工具（readboard）镰刀检测修复 ⭐
- **位置**: `readboard-src/readboard/Form1.cs`
- **已修复问题**:
  1. ✅ `DetectScytheTrigger()` 函数从未被调用 → 已添加调用
  2. ✅ 检测阈值过高 (5%) → 降低到 3%
  3. ✅ 重复触发导致镰刀数量错误 → 实现边缘触发机制
  4. ✅ 无法判断镰刀触发方 → 添加黄色框位置检测
- **编译命令**:
  ```batch
  cd D:\ScytheKatago\readboard-src\readboard
  "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" readboard.csproj /p:Configuration=Release
  ```
- **编译输出**: `readboard-src/readboard/bin/Release/readboard.exe`
- **部署位置**: `scythe_lizzie/readboard/readboard.exe`

#### 4. GitHub 推送
- **分支**: `feature/yahu-auto-scythe`
- **仓库**: https://github.com/jsuusugsysys-bit/ScytheKatago
- **最近提交**:
  - `971cbcd`: 添加 readboard-src C# 源码
  - `66b1970`: v1.4 镰刀核心修改

---

## ⏳ 待完成任务

### 下一步: 修复 readboard 自动落子功能

**问题描述**:
> 用户反馈: "还有棋盘同步识别工具以前是可以自动下棋的，现在下不了，不能实现自动落子"

**排查方向**:
1. 检查 `Form1.cs` 中的落子相关代码
2. 确认是否因为镰刀检测修改影响了落子逻辑
3. 测试野狐围棋窗口的点击坐标计算
4. 验证 TCP 发送落子命令是否正常

**相关代码位置**:
- `Form1.cs`: 棋盘坐标映射和鼠标点击模拟
- 可能涉及的方法: `SendMove()`, `ClickBoardPosition()` 等

---

## 项目架构

```
D:\ScytheKatago\
├── KataGo/cpp/                    # KataGo C++ 引擎
│   ├── game/boardhistory.cpp      # 镰刀状态和触发逻辑
│   ├── command/gtp.cpp            # GTP 命令
│   ├── search/search.cpp          # 玩家切换
│   └── build/Release/katago.exe   # 编译输出 ⭐
│
├── lizzieyzy-main/                # Java GUI
│   ├── src/main/java/.../gui/ScythePanel.java
│   └── target/lizzie-yzy2.5.3-shaded.jar  # 编译输出
│
├── readboard-src/                 # C# 棋盘同步工具 ⭐
│   ├── readboard/Form1.cs         # 主窗体（镰刀检测）
│   └── readboard/bin/Release/readboard.exe
│
├── scythe_lizzie/                 # 运行环境
│   ├── lizzie-yzy2.5.3-shaded.jar
│   ├── katago.exe
│   ├── readboard/readboard.exe
│   └── start_scythe_lizzie.bat    # 启动脚本
│
└── test_scythe_suite/             # 测试套件
```

---

## 镰刀 GTP 命令

```bash
kata-get-scythe-status              # 查询状态（JSON）
kata-set-param scythe_trigger true  # 触发镰刀
kata-set-param scythe_count_black 3 # 设置黑方镰刀数
kata-set-param scythe_count_white 3 # 设置白方镰刀数
```

**状态响应示例**:
```json
{"blackScythes":3,"whiteScythes":3,"scytheCombo":0,"nextPlayer":"B","isComboActive":false,"moveNumber":10,"canUseScythe":true}
```

---

## 编译命令速查

### KataGo (C++)
```batch
# 快速增量编译
cd D:\ScytheKatago\KataGo\cpp\build
cmake --build . --config Release --parallel 4

# 完整重建
cd D:\ScytheKatago\KataGo\cpp
rmdir /s /q build && mkdir build && cd build
cmake .. -DUSE_BACKEND=CUDA -DUSE_AVX2=1
cmake --build . --config Release --parallel 4
```

### lizzieyzy (Java)
```batch
cd D:\ScytheKatago\lizzieyzy-main
mvn package -DskipTests
```

### readboard (C#)
```batch
cd D:\ScytheKatago\readboard-src\readboard
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" readboard.csproj /p:Configuration=Release
```

---

## 开发规范

### C++ (KataGo)
- **缩进**: 2 空格
- **调试输出**: 必须用 `std::cerr`，禁止 `std::cout`（会破坏 GTP 协议）
- **C++17**: 使用 `std::shuffle`（不用 `std::random_shuffle`）

### Java (lizzieyzy)
- **缩进**: 4 空格
- **Java 版本**: 8+

### C# (readboard)
- **缩进**: 4 空格
- **框架**: .NET Framework 4.8.1

---

## 测试流程

### 1. 启动 GUI
```batch
cd D:\ScytheKatago\scythe_lizzie
start_scythe_lizzie.bat
```

### 2. 测试镰刀功能
1. 创建 11x11 新棋局
2. 走到第 11 手
3. 发送 `kata-set-param scythe_trigger true`
4. 观察连续走 3 步

### 3. 测试 readboard 镰刀检测
1. lizzieyzy 中按 `Alt+O` 打开棋盘同步工具
2. 勾选"启用"镰刀检测
3. 打开野狐围棋，进入镰刀棋局
4. 点击"持续同步"
5. 当野狐显示"本回合走3步"时，应自动触发镰刀

---

## 关键文件速查

| 文件 | 行数 | 说明 |
|------|------|------|
| `KataGo/cpp/game/boardhistory.h` | 104-111 | 镰刀状态变量定义 |
| `KataGo/cpp/game/boardhistory.cpp` | 1100+ | 镰刀触发逻辑 |
| `KataGo/cpp/command/gtp.cpp` | 3100+ | GTP 命令处理 |
| `readboard-src/readboard/Form1.cs` | 1696-1713 | 镰刀检测调用 |
| `readboard-src/readboard/Form1.cs` | 4027-4176 | `DetectScytheTrigger()` 函数 |
| `readboard-src/readboard/Form1.cs` | 4179-4238 | `DetectYellowBoxPosition()` 函数 |

---

## 常见问题

### Q1: 编译 KataGo 失败
- 检查 CUDA 环境变量
- 确认 Visual Studio 2022 已安装
- 查看 `build_log.txt`

### Q2: readboard 编译失败
- 确认 MSBuild.exe 路径
- 检查 NuGet 包是否已恢复
- 查看 `readboard-src/readboard/obj/Release/` 错误日志

### Q3: 镰刀检测不工作
- 查看日志: `scythe_lizzie/readboard/scythe_detection.log`
- 确认"启用"复选框已勾选
- 确认野狐窗口句柄正确

---

## 日志位置

- **镰刀检测日志**: `scythe_lizzie/readboard/scythe_detection.log`
- **GTP 日志**: `gtp_logs/`
- **lizzieyzy 日志**: `scythe_lizzie/logs/`

---

## Git 信息

- **当前分支**: `feature/yahu-auto-scythe`
- **远程仓库**: https://github.com/jsuusugsysys-bit/ScytheKatago.git
- **最新提交**: `971cbcd` (2026-01-22)

---

## 联系信息

- **项目文档**: `D:\ScytheKatago\.claude\CLAUDE.md`
- **开发规范**: `D:\ScytheKatago\.claude\rules/`
- **计划文档**: `C:\Users\31437\.claude\plans\linked-knitting-papert.md`

---

**下次对话请先阅读此文档，了解当前进度后继续开发。**
