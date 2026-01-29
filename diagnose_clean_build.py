import subprocess
import os
import sys

def run_build():
    log_file = r"D:\ScytheKatago\clean_build_log.txt"

    # 1. 定义关键路径
    vs_env_cmd = r'call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"'
    cmake_path = r"C:\Program Files\Microsoft Visual Studio\18\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin"
    source_dir = r"D:\ScytheKatago\KataGo\cpp"
    build_dir = r"D:\ScytheKatago\KataGo\cpp\build"

    # 2. 准备依赖库路径
    eigen_dir = r"D:/ScytheKatago/eigen3"
    zlib_dir = r"D:/ScytheKatago/zlib"
    zlib_lib = r"D:/ScytheKatago/zlib/build/Release/zs.lib"

    # 3. 确保构建目录存在
    if not os.path.exists(build_dir):
        os.makedirs(build_dir)
        print(f"Created build dir: {build_dir}")

    # 4. 构建命令链 (配置 + 编译)
    # 注意：我们显式将 CMake 路径加入 PATH
    setup_env = f'{vs_env_cmd} && set "PATH=%PATH%;{cmake_path}"'

    # CMake 配置命令
    config_cmd = f'cmake "{source_dir}" -B "{build_dir}" -DUSE_BACKEND=EIGEN -DEIGEN3_INCLUDE_DIRS="{eigen_dir}" -DZLIB_INCLUDE_DIR="{zlib_dir}" -DZLIB_LIBRARY="{zlib_lib}"'

    # CMake 编译命令
    build_cmd = f'cmake --build "{build_dir}" --config Release --verbose'

    full_cmd = f'{setup_env} && {config_cmd} && {build_cmd}'

    print("开始执行纯净版编译诊断...")
    print(f"日志将保存到: {log_file}")

    try:
        # 执行命令，捕获二进制输出以避免编码崩溃
        process = subprocess.run(
            full_cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT
        )

        # 尝试解码输出 (Windows通常是 cp936/gbk)
        try:
            output_text = process.stdout.decode('cp936', errors='replace')
        except:
            output_text = process.stdout.decode('utf-8', errors='replace')

        # 写入日志文件
        with open(log_file, "w", encoding="utf-8") as f:
            f.write(output_text)

        print(f"执行结束。返回码: {process.returncode}")

        if process.returncode != 0:
            print(">>> 编译失败！请查看日志文件最后的错误信息。")
            # 打印最后几行错误
            print("\n--- 错误片段 ---")
            print("\n".join(output_text.splitlines()[-20:]))
        else:
            print(">>> 编译成功！")

    except Exception as e:
        print(f"脚本发生异常: {e}")

if __name__ == "__main__":
    run_build()
