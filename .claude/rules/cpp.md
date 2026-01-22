# C++ 开发规范

paths:
  - KataGo/cpp/**

---

## GTP 协议约束

**关键**：调试输出必须发到 `stderr`，绝不能发到 `stdout`

```cpp
// 正确
std::cerr << "Scythe triggered" << std::endl;

// 错误 - 会破坏 GTP 协议
std::cout << "Scythe triggered" << std::endl;
```

## 代码规范

- **缩进**：2 空格
- **C++17**：使用 `std::shuffle`（不用已弃用的 `std::random_shuffle`）

## 编译命令

```batch
# 快速编译（修改代码后）
cd /d D:\ScytheKatago\KataGo\cpp\build
cmake --build . --config Release --parallel 4

# 或使用 MSBuild
"C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" katago.sln /p:Configuration=Release /m
```

**输出**：`KataGo/cpp/build/Release/katago.exe`

## 调试技巧

- **GTP 日志**：保存在 `gtp_logs/` 目录
- **编译错误**：使用 `file_path:line_number` 格式定位

## undo 处理

必须保存/恢复镰刀状态（通过 `scytheTriggerHistory` 追踪）
