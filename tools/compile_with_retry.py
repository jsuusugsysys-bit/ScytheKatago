#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
编译脚本（带重试管理）

展示如何使用 retry_manager.py 来控制编译过程的重试
"""

import os
import sys
import subprocess
from retry_manager import RetryManager


def compile_katago():
    """编译 KataGo"""
    build_dir = r"D:\ScytheKatago\KataGo\cpp\build"

    def do_compile():
        # 检查目录是否存在
        if not os.path.exists(build_dir):
            raise FileNotFoundError(f"构建目录不存在: {build_dir}")

        # 执行编译
        result = subprocess.run(
            ["cmake", "--build", ".", "--config", "Release", "--parallel", "4"],
            cwd=build_dir,
            capture_output=True,
            text=True
        )

        # 检查返回码
        if result.returncode != 0:
            raise RuntimeError(f"编译失败\n{result.stderr}")

        return result.stdout

    return do_compile


def compile_lizzieyzy():
    """编译 lizzieyzy"""
    lizzie_dir = r"D:\ScytheKatago\lizzieyzy-main"

    def do_compile():
        # 检查目录是否存在
        if not os.path.exists(lizzie_dir):
            raise FileNotFoundError(f"lizzieyzy 目录不存在: {lizzie_dir}")

        # 执行编译
        result = subprocess.run(
            ["mvn", "package", "-DskipTests"],
            cwd=lizzie_dir,
            capture_output=True,
            text=True
        )

        # 检查返回码
        if result.returncode != 0:
            raise RuntimeError(f"编译失败\n{result.stderr}")

        return result.stdout

    return do_compile


def main():
    """主函数"""
    # 创建重试管理器
    manager = RetryManager(
        max_retries=1,  # 最多重试 1 次
        log_file=r"D:\ScytheKatago\compile_retry.log",
        enable_logging=True
    )

    print("========================================")
    print("    镰刀项目编译工具 (带重试管理)")
    print("========================================")
    print()

    # 编译 KataGo
    print("[1/2] 编译 KataGo...")
    success, result = manager.execute_with_retry(
        compile_katago(),
        "编译 KataGo",
        {"component": "KataGo", "language": "C++"}
    )

    if not success:
        print(f"\n[错误] KataGo 编译失败: {result}")
        print(f"请查看日志: D:\\ScytheKatago\\compile_retry.log")
        return 1

    print("[✓] KataGo 编译成功")
    print()

    # 编译 lizzieyzy
    print("[2/2] 编译 lizzieyzy...")
    success, result = manager.execute_with_retry(
        compile_lizzieyzy(),
        "编译 lizzieyzy",
        {"component": "lizzieyzy", "language": "Java"}
    )

    if not success:
        print(f"\n[错误] lizzieyzy 编译失败: {result}")
        print(f"请查看日志: D:\\ScytheKatago\\compile_retry.log")
        return 1

    print("[✓] lizzieyzy 编译成功")
    print()

    print("========================================")
    print("    所有组件编译完成！")
    print("========================================")
    return 0


if __name__ == "__main__":
    sys.exit(main())
