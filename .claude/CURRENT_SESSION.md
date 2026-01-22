<!--
AI 指令（新会话必读）：
1. **首先阅读**: D:\ScytheKatago\HANDOVER.md（项目交接文档）
2. 如果用户需要启动 lizzieyzy，使用下方的【启动命令】
3. 不理解围棋逻辑时，用简单的话向用户确认
4. 命令行先测试逻辑通了，用户再操作 GUI
-->

# 镰刀项目会话恢复

**更新时间**: 2026-01-22 19:30

## 启动 lizzieyzy【必读】

**每次启动 lizzieyzy 必须用这个命令：**
```bash
cd "D:/ScytheKatago/scythe_lizzie" && "D:/ScytheKatago/java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64/bin/java.exe" -jar "D:/ScytheKatago/lizzieyzy-main/target/lizzie-yzy2.5.3-shaded.jar" &
```

**关键点：**
- 工作目录必须是 `scythe_lizzie/`（不是项目根目录）
- 引擎会自动加载（config.txt 已配置 preload=true）
- 棋盘 11x11，贴目 7.5

## 当前状态

- ✅ KataGo 镰刀版 v1.4: 已编译并推送到 GitHub
- ✅ C# readboard 镰刀检测: 已完全修复（黄色框判断触发方）
- ✅ lizzieyzy ScythePanel: 状态显示面板完善
- ✅ GitHub 推送: feature/yahu-auto-scythe 分支
- ⏳ **下一步**: readboard 自动落子功能修复

## readboard 镰刀检测【已完成】

**检测方式**（C# Form1.cs）：
1. ✅ 白字检测: 识别棋盘上方"本回合走3步"文字（阈值 3%）
2. ✅ 边缘触发: 防止重复触发（`scytheTriggeredThisRound` 标志）
3. ✅ 黄色框检测: 扫描右侧指示区域判断触发方
   - 白区: 15%-35% 高度
   - 黑区: 35%-55% 高度
   - RGB阈值: R≥180, G≥150, B≤120

**关键代码**:
- `Form1.cs:1696-1713`: 同步循环中调用检测
- `Form1.cs:4027-4176`: DetectScytheTrigger() 函数
- `Form1.cs:4179-4238`: DetectYellowBoxPosition() 函数

**日志位置**: `scythe_lizzie/readboard/scythe_detection.log`

## 编译命令

**KataGo (C++):**
```bash
cd "D:/ScytheKatago/KataGo/cpp/build" && cmake --build . --config Release --parallel 4
```

**readboard (C#):**
```batch
cd /d D:\ScytheKatago\readboard-src\readboard
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" readboard.csproj /p:Configuration=Release
```

**lizzieyzy (Java):**
```bash
cd "D:/ScytheKatago/lizzieyzy-main" && mvn clean package -DskipTests
```

**编译后重启 lizzieyzy 的完整流程：**
1. 用户关闭 lizzieyzy
2. 执行编译命令
3. 执行启动命令（上方的标准命令）

## 用户偏好

- 用中文交流
- 不理解围棋逻辑时，用简单的话确认
- 命令行先测试逻辑通了，用户再操作 GUI
- 启动 lizzieyzy 时自动使用标准命令，不需要用户输入
