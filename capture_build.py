import subprocess
import sys

def run_and_capture():
    # 目标脚本
    batch_file = r"D:\ScytheKatago\FORCE_BUILD.bat"

    print(f"--- 正在启动监视器，目标: {batch_file} ---")

    try:
        # 启动进程，重定向输出
        process = subprocess.Popen(
            batch_file,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            encoding='mbcs', # 使用 Windows 本地编码处理中文
            errors='replace'
        )

        # 实时读取输出
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                # 去掉换行符并打印
                print(line.strip())
                sys.stdout.flush()

        rc = process.poll()
        print(f"\n--- 构建结束，返回码: {rc} ---")

    except Exception as e:
        print(f"监视器发生错误: {e}")

if __name__ == "__main__":
    run_and_capture()
