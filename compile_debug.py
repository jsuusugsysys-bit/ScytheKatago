import subprocess
import os

# 配置路径
vcvars = r"C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
build_dir = r"D:\ScytheKatago\KataGo\cpp\build"
log_file = r"D:\ScytheKatago\compile_log_py.txt"

# 组合命令：设置环境 -> 进入目录 -> 执行编译
cmd = f'call "{vcvars}" && cd /d "{build_dir}" && cmake --build . --config Release --parallel 4 --verbose'

print(f"正在执行编译诊断...日志将保存到: {log_file}")

try:
    # 执行命令并捕获所有输出
    result = subprocess.run(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

    # 写入日志文件
    with open(log_file, "w", encoding="utf-8") as f:
        f.write(result.stdout)

    print("执行完成。")
    if result.returncode == 0:
        print("编译成功！")
    else:
        print(f"编译失败，返回码: {result.returncode}")
        # 打印最后20行错误信息到屏幕，方便立即查看
        lines = result.stdout.splitlines()
        print("\n--- 错误摘要 ---")
        for line in lines[-20:]:
            print(line)

except Exception as e:
    print(f"脚本执行出错: {e}")
