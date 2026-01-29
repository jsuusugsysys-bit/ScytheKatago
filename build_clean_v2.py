import subprocess
import os
import sys

def run_command(cmd, step_name):
    print(f"\n--- [STEP] {step_name} ---")
    print(f"Command: {cmd}")

    try:
        # 使用 shell=True 执行命令
        # encoding='mbcs' 通常能很好地处理 Windows 本地编码 (GBK/CP936)
        # errors='replace' 确保即使有乱码也不会崩溃
        result = subprocess.run(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            encoding='mbcs',
            errors='replace'
        )

        print(result.stdout)

        if result.returncode != 0:
            print(f"!!! {step_name} FAILED with return code {result.returncode} !!!")
            return False
        else:
            print(f"=== {step_name} SUCCESS ===")
            return True

    except Exception as e:
        print(f"Exception during {step_name}: {e}")
        return False

def main():
    # 1. 定义路径
    vcvars = r"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"

    # 源代码和构建目录 (纯净版)
    source_dir = r"D:\ScytheKatago\KataGo\cpp"
    build_dir = r"D:\ScytheKatago\KataGo\cpp\build"

    # 依赖库
    eigen_dir = r"D:/ScytheKatago/eigen3"
    zlib_dir = r"D:/ScytheKatago/zlib"
    zlib_lib = r"D:/ScytheKatago/zlib/build/Release/zs.lib"

    # 2. 准备构建目录
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)

    # 清理缓存以防万一
    cache_file = os.path.join(build_dir, "CMakeCache.txt")
    if os.path.exists(cache_file):
        os.remove(cache_file)
        print("Cleared old CMakeCache.txt")

    # 3. 构造命令
    # 注意：必须在同一个 subprocess 调用中先 call vcvars，然后执行 cmake

    # 配置命令
    cmake_config = (
        f'call "{vcvars}" && '
        f'cd /d "{build_dir}" && '
        f'cmake "{source_dir}" '
        f'-DUSE_BACKEND=EIGEN '
        f'-DEIGEN3_INCLUDE_DIRS="{eigen_dir}" '
        f'-DZLIB_INCLUDE_DIR="{zlib_dir}" '
        f'-DZLIB_LIBRARY="{zlib_lib}"'
    )

    # 编译命令
    cmake_build = (
        f'call "{vcvars}" && '
        f'cd /d "{build_dir}" && '
        f'cmake --build . --config Release --parallel 4 --verbose'
    )

    # 4. 执行
    if run_command(cmake_config, "CMake Configuration"):
        run_command(cmake_build, "Build Execution")
    else:
        print("Skipping build because configuration failed.")

if __name__ == "__main__":
    main()
