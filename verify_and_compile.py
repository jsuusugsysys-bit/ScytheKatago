import subprocess
import os
import sys

def run_test():
    print("--- 开始环境验证 ---")

    # 1. 核心路径定义
    msvc_path = r"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Tools\MSVC\14.50.35717"
    sdk_path = r"C:\Program Files (x86)\Windows Kits\10"
    sdk_version = "10.0.26100.0"

    # 2. 构造关键路径
    cl_exe = os.path.join(msvc_path, "bin", "Hostx64", "x64", "cl.exe")
    cmake_exe = r"C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"

    if not os.path.exists(cl_exe):
        print(f"[ERROR] 找不到编译器: {cl_exe}")
        return

    print(f"[OK] 找到编译器: {cl_exe}")

    # 3. 设置环境变量
    env = os.environ.copy()

    # INCLUDE
    includes = [
        os.path.join(msvc_path, "include"),
        os.path.join(sdk_path, "Include", sdk_version, "ucrt"),
        os.path.join(sdk_path, "Include", sdk_version, "um"),
        os.path.join(sdk_path, "Include", sdk_version, "shared"),
    ]
    env["INCLUDE"] = ";".join(includes)

    # LIB
    libs = [
        os.path.join(msvc_path, "lib", "x64"),
        os.path.join(sdk_path, "Lib", sdk_version, "ucrt", "x64"),
        os.path.join(sdk_path, "Lib", sdk_version, "um", "x64"),
    ]
    env["LIB"] = ";".join(libs)

    # PATH
    env["PATH"] = os.path.dirname(cl_exe) + os.pathsep + os.path.dirname(cmake_exe) + os.pathsep + env["PATH"]

    # 4. 测试1: 检查编译器版本
    print("\n[TEST 1] 检查编译器版本...")
    try:
        res = subprocess.run([cl_exe], env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        print(res.stdout)
    except Exception as e:
        print(f"执行出错: {e}")

    # 5. 测试2: 编译 test.cpp
    print("\n[TEST 2] 尝试编译 test.cpp...")
    src_file = r"D:\ScytheKatago\test.cpp"
    out_exe = r"D:\ScytheKatago\test.exe"

    if not os.path.exists(src_file):
        with open(src_file, "w") as f:
            f.write('#include <iostream>\nint main() { std::cout << "OK" << std::endl; return 0; }')

    cmd = [cl_exe, "/EHsc", src_file, f"/Fe{out_exe}"]

    try:
        res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        print("编译器输出:")
        print(res.stdout)

        if res.returncode == 0 and os.path.exists(out_exe):
            print("\n[SUCCESS] 编译成功！环境配置正确。")
        else:
            print("\n[FAIL] 编译失败。请检查上面的错误信息。")

    except Exception as e:
        print(f"编译执行出错: {e}")

if __name__ == "__main__":
    run_test()
