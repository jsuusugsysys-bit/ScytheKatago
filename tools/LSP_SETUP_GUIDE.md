# LSP 安装完成指南

## 当前状态

✅ **已完成：**
1. clangd (C++) - 已通过 winget 安装 LLVM 21.1.8
2. jdtls-lsp 插件 - 已在 Claude Code 中安装
3. clangd-lsp 插件 - 已在 Claude Code 中安装
4. csharp-lsp 插件 - 已在 Claude Code 中安装

⚠️ **待完成：**
1. 将 LLVM 添加到系统 PATH（永久生效）
2. 安装 jdtls 二进制文件

---

## 立即操作步骤

### 1. 永久添加 LLVM 到 PATH

**右键点击**以下文件，选择"以管理员身份运行"：
```
D:\ScytheKatago\tools\add_llvm_to_path.ps1
```

运行后，**关闭并重新打开终端**。

验证：
```powershell
clangd --version
```

应该显示：`clangd version 21.1.8`

---

### 2. 安装 jdtls（可选）

#### 方法 A：手动下载（推荐）

1. 访问：https://download.eclipse.org/jdtls/milestones/
2. 下载最新的 `jdt-language-server-*.tar.gz` 文件
3. 解压到：`D:\ScytheKatago\tools\jdtls\`
4. 解压后应该有：`D:\ScytheKatago\tools\jdtls\bin\jdtls.bat`

#### 方法 B：使用 PowerShell 下载（自动）

```powershell
cd D:\ScytheKatago\tools\jdtls
Invoke-WebRequest -Uri "https://download.eclipse.org/jdtls/milestones/1.40.0/jdt-language-server-1.40.0-202409261450.tar.gz" -OutFile "jdtls.tar.gz"
tar -xzf jdtls.tar.gz
```

#### 验证安装

```powershell
ls D:\ScytheKatago\tools\jdtls\bin\
```

应该看到 `jdtls` 或 `jdtls.bat` 文件。

---

### 3. 配置 Claude Code LSP 插件

安装完二进制文件后，重启 Claude Code：

```powershell
# 关闭当前 Claude Code 会话
# 重新运行
claude
```

在 Claude Code 中检查 LSP 状态：
```
/plugin
```

切换到 **Errors** 标签：
- 如果没有红点 = ✅ LSP 正常工作
- 如果有 "Executable not found" = 需要配置路径

---

## 临时解决方案（当前会话）

如果不想永久修改 PATH，可以每次启动 Claude Code 前运行：

```powershell
# 添加 LLVM 到当前会话的 PATH
$env:Path += ";C:\Program Files\LLVM\bin"

# 然后启动 Claude Code
claude
```

---

## C# 支持（可选）

如果需要 C# LSP 支持，安装 csharp-ls：

```powershell
dotnet tool install --global csharp-ls
```

验证：
```powershell
csharp-ls --version
```

---

## 验证 LSP 是否工作

### 方法 1：使用 Claude Code 的 /plugin 命令

```
/plugin
```

切换到 **Errors** 标签，检查是否有错误。

### 方法 2：编辑 C++ 文件测试

在 Claude Code 中打开一个 `.cpp` 文件，故意写错代码（比如未定义的变量）。

如果 LSP 工作正常，你会看到：
- 文件修改后立即显示错误提示
- Claude 会自动注意到错误并修复

---

## 常见问题

### Q: 运行 add_llvm_to_path.ps1 提示"无法加载，因为在此系统上禁止运行脚本"

A: 以管理员身份打开 PowerShell，运行：
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

然后再运行脚本。

### Q: clangd 仍然找不到

A: 手动添加到 PATH：
1. 按 `Win + R`，输入 `sysdm.cpl`，回车
2. 点击"高级" → "环境变量"
3. 在"用户变量"中找到 `Path`，双击
4. 点击"新建"，输入：`C:\Program Files\LLVM\bin`
5. 确定，重启终端

### Q: jdtls 下载失败

A: 从浏览器手动下载，然后解压到指定目录：
https://download.eclipse.org/jdtls/milestones/

---

## 下一步

完成以上步骤后，LSP 应该可以正常工作。你可以：

1. 修改 `KataGo/cpp/search/search.cpp` 等 C++ 文件
2. Claude 会立即看到类型错误和未定义的变量
3. 不用编译就能发现大部分错误

**节省大量调试时间！** 🚀
