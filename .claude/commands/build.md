# 统一编译命令

编译镰刀项目的各个组件。

## 使用方法

```
/build           # 显示可编译的组件列表
/build readboard # 编译 C# 棋盘同步工具
/build lizzie    # 编译 Java GUI
/build katago    # 编译 KataGo 引擎
/build all       # 编译所有组件
```

## 编译配置

### readboard (C# 棋盘同步工具)
- **MSBuild 路径**: `C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe`
- **项目文件**: `D:\ScytheKatago\readboard-src\readboard\readboard.csproj`
- **输出**: `readboard-src\readboard\bin\Release\readboard.exe`
- **部署到**: `scythe_lizzie\readboard\readboard.exe`

### lizzieyzy (Java GUI)
- **Maven**: `mvn package -DskipTests`
- **项目目录**: `D:\ScytheKatago\lizzieyzy-main`
- **输出**: `lizzieyzy-main\target\lizzie-yzy2.5.3-shaded.jar`

### katago (C++ 引擎)
- **CMake**: `cmake --build . --config Release --parallel 4`
- **构建目录**: `D:\ScytheKatago\KataGo\cpp\build`
- **输出**: `KataGo\cpp\build\Release\katago.exe`

## 执行步骤

根据用户参数执行对应的编译命令：

1. 如果参数是 `readboard`：
```powershell
powershell.exe -Command "& 'C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe' 'D:\ScytheKatago\readboard-src\readboard\readboard.csproj' '/p:Configuration=Release' '/t:Build'"
```
然后复制到部署目录：
```powershell
Copy-Item 'D:\ScytheKatago\readboard-src\readboard\bin\Release\readboard.exe' 'D:\ScytheKatago\scythe_lizzie\readboard\readboard.exe' -Force
```

2. 如果参数是 `lizzie`：
```bash
cd "D:\ScytheKatago\lizzieyzy-main" && mvn package -DskipTests
```

3. 如果参数是 `katago`：
```bash
cd "D:\ScytheKatago\KataGo\cpp\build" && cmake --build . --config Release --parallel 4
```

4. 如果参数是 `all`：按顺序编译 readboard → lizzie → katago

5. 如果没有参数或参数无效：显示帮助信息

## 编译后验证

编译成功后显示：
- 输出文件路径
- 文件修改时间
- 文件大小
