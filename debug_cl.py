import subprocess
import os

# --- 配置路径 ---
msvc_root = r"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717"
sdk_root = r"C:\Program Files (x86)\Windows Kits\10"
sdk_ver = "10.0.26100.0"

# --- 构造环境变量 ---
# 1. INCLUDE
includes = [
    os.path.join(msvc_root, "include"),
    os.path.join(sdk_root, "Include", sdk_ver, "ucrt"),
    os.path.join(sdk_root, "Include", sdk_ver, "um"),
    os.path.join(sdk_root, "Include", sdk_ver, "shared"),
]

# 2. LIB
libs = [
    os.path.join(msvc_root, "lib", "x64"),
    os.path.join(sdk_root, "Lib", sdk_ver, "ucrt", "x64"),
    os.path.join(sdk_root, "Lib", sdk_ver, "um", "x64"),
]

# 3. PATH (添加编译器和 CMake)
new_path = os.path.join(msvc_root, "bin", "Hostx64", "x64") + os.pathsep + \
           r"C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin" + os.pathsep + \
           os.environ["PATH"]

# --- 准备执行环境 ---
env = os.environ.copy()
env["INCLUDE"] = ";".join(includes)
env["LIB"] = ";".join(libs)
env["PATH"] = new_path

# --- 执行编译 ---
source_file = r"D:\ScytheKatago\test.cpp"
exe_file = r"D:\ScytheKatago\test.exe"
cmd = ["cl.exe", "/EHsc", source_file, f"/Fe{exe_file}"]

print("--- 开始编译测试 ---")
print(f"编译器路径: {os.path.join(msvc_root, 'bin', 'Hostx64', 'x64', 'cl.exe')}")

try:
    # 捕获输出，并尝试解码
    result = subprocess.run(
        cmd,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        encoding='mbcs', # 使用 Windows 本地编码
        errors='replace'
    )

    print("\n--- 编译器输出 ---")
    print(result.stdout)

    if result.returncode == 0:
        print("\n[SUCCESS] 编译成功！")
    else:
        print(f"\n[FAIL] 编译失败，返回码: {result.returncode}")

except Exception as e:
    print(f"\n[ERROR] 执行出错: {e}")
