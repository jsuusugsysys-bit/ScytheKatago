#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试脚本（带重试管理）

使用重试管理器运行镰刀功能测试套件
"""

import os
import sys
import subprocess
from retry_manager import RetryManager


def run_single_test(test_file: str, katago_exe: str, model_path: str, config_path: str, output_dir: str):
    """运行单个测试"""
    def do_test():
        # 准备输出文件
        test_name = os.path.splitext(os.path.basename(test_file))[0]
        output_file = os.path.join(output_dir, f"{test_name}_output.txt")
        error_file = os.path.join(output_dir, f"{test_name}_error.txt")

        # 运行测试
        with open(test_file, 'r', encoding='utf-8') as stdin_file:
            with open(output_file, 'w', encoding='utf-8') as stdout_file:
                with open(error_file, 'w', encoding='utf-8') as stderr_file:
                    result = subprocess.run(
                        [katago_exe, "gtp", "-model", model_path, "-config", config_path],
                        stdin=stdin_file,
                        stdout=stdout_file,
                        stderr=stderr_file,
                        text=True
                    )

        # 检查返回码
        if result.returncode != 0:
            # 读取错误信息
            with open(error_file, 'r', encoding='utf-8') as f:
                error_content = f.read()
            raise RuntimeError(f"测试失败，返回码: {result.returncode}\n{error_content}")

        return output_file

    return do_test


def main():
    """主函数"""
    # 配置路径
    katago_exe = r"D:\ScytheKatago\katago.exe"
    model_path = r"D:\2025-05-19-win64-RTX50XX特供版\weights\28b.bin.gz"
    config_path = r"D:\ScytheKatago\scythe_config.cfg"
    test_dir = r"D:\ScytheKatago\test_scythe_suite"
    result_dir = os.path.join(test_dir, "results")

    # 创建结果目录
    if not os.path.exists(result_dir):
        os.makedirs(result_dir)

    # 创建本次测试的结果目录
    from datetime import datetime
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    current_result_dir = os.path.join(result_dir, f"test_{timestamp}")
    os.makedirs(current_result_dir)

    print("========================================")
    print("镰刀功能自动化测试套件（带重试管理）")
    print("========================================")
    print()
    print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"结果目录: {current_result_dir}")
    print()

    # 检查文件
    if not os.path.exists(katago_exe):
        print(f"[错误] 找不到 KataGo 可执行文件: {katago_exe}")
        print("请先运行 build_with_retry.bat 编译项目")
        return 1

    if not os.path.exists(model_path):
        print(f"[警告] 找不到神经网络模型: {model_path}")
        print("测试将继续，但可能会失败")
        print()

    if not os.path.exists(config_path):
        print(f"[错误] 找不到配置文件: {config_path}")
        return 1

    # 测试文件列表
    test_files = [
        "test_basic.txt",
        "test_boundary.txt",
        "test_combo.txt",
        "test_count.txt",
        "test_both_players.txt",
        "test_board_size.txt",
        "test_reset.txt"
    ]

    # 创建重试管理器
    manager = RetryManager(
        max_retries=1,
        log_file=os.path.join(current_result_dir, "test_retry.log"),
        enable_logging=True
    )

    # 运行测试
    total_tests = 0
    passed_tests = 0
    failed_tests = 0

    for test_file in test_files:
        total_tests += 1
        test_path = os.path.join(test_dir, test_file)

        if not os.path.exists(test_path):
            print(f"[跳过] {test_file} - 文件不存在")
            continue

        print("========================================")
        print(f"运行测试: {test_file}")
        print("========================================")

        # 执行测试（带重试）
        success, result = manager.execute_with_retry(
            run_single_test(test_path, katago_exe, model_path, config_path, current_result_dir),
            f"测试: {test_file}",
            {"test_file": test_file}
        )

        if success:
            print(f"[✓ 通过] {test_file}")
            passed_tests += 1
        else:
            print(f"[✗ 失败] {test_file} - {result}")
            failed_tests += 1

        print()

    # 生成测试报告
    report_file = os.path.join(current_result_dir, "test_report.txt")
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("========================================\n")
        f.write("镰刀功能测试报告\n")
        f.write("========================================\n")
        f.write("\n")
        f.write(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        f.write(f"KataGo 版本: {katago_exe}\n")
        f.write(f"神经网络: {model_path}\n")
        f.write("\n")
        f.write("----------------------------------------\n")
        f.write("测试统计\n")
        f.write("----------------------------------------\n")
        f.write(f"总测试数: {total_tests}\n")
        f.write(f"通过: {passed_tests}\n")
        f.write(f"失败: {failed_tests}\n")
        f.write("\n")
        f.write("========================================\n")
        f.write("测试完成\n")
        f.write("========================================\n")

    # 显示测试报告
    print()
    print("========================================")
    print("测试完成")
    print("========================================")
    print()
    with open(report_file, 'r', encoding='utf-8') as f:
        print(f.read())
    print()
    print(f"详细结果保存在: {current_result_dir}")
    print()

    # 返回结果
    if failed_tests > 0:
        print(f"[警告] 有 {failed_tests} 个测试失败")
        print("请查看错误日志文件了解详情")
        return 1
    else:
        print("[成功] 所有测试通过！")
        return 0


if __name__ == "__main__":
    sys.exit(main())
