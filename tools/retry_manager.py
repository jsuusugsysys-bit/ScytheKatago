#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重试管理器 (Retry Manager)
用于限制失败操作的重试次数，避免无意义的重复尝试

使用场景：
- 编译失败
- 测试失败
- 命令执行失败
"""

import os
import sys
import time
import logging
from typing import Callable, Any, Optional
from datetime import datetime


class RetryManager:
    """
    重试管理器

    核心原则：
    - 最多重试 1 次（总共尝试 2 次）
    - 失败时记录详细日志
    - 不要相信"下一次会更好"
    """

    def __init__(self,
                 max_retries: int = 1,
                 log_file: str = "retry_failures.log",
                 enable_logging: bool = True):
        """
        初始化重试管理器

        参数说明：
        - max_retries: 最大重试次数（默认 1，即总共尝试 2 次）
        - log_file: 日志文件路径
        - enable_logging: 是否启用日志记录
        """
        self.max_retries = max_retries
        self.log_file = log_file
        self.enable_logging = enable_logging

        # 设置日志
        if self.enable_logging:
            self._setup_logging()

    def _setup_logging(self):
        """配置日志系统"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s [%(levelname)s] %(message)s',
            handlers=[
                logging.FileHandler(self.log_file, encoding='utf-8'),
                logging.StreamHandler(sys.stderr)  # 输出到 stderr，避免破坏 GTP 协议
            ]
        )
        self.logger = logging.getLogger(__name__)

    def execute_with_retry(self,
                           operation: Callable[[], Any],
                           operation_name: str,
                           context: Optional[dict] = None) -> tuple[bool, Any]:
        """
        执行操作，失败时自动重试

        参数说明：
        - operation: 要执行的操作（一个函数）
        - operation_name: 操作名称（用于日志）
        - context: 额外的上下文信息（可选）

        返回值：
        - (成功标志, 结果)
        - 如果失败，返回 (False, 错误信息)
        """
        attempt = 0
        last_error = None

        while attempt <= self.max_retries:
            try:
                # 记录尝试
                if attempt > 0:
                    self._log_retry(operation_name, attempt, context)
                else:
                    self._log_start(operation_name, context)

                # 执行操作
                result = operation()

                # 成功
                self._log_success(operation_name, attempt, context)
                return (True, result)

            except Exception as e:
                last_error = e
                attempt += 1

                # 记录失败
                self._log_failure(operation_name, attempt, e, context)

                # 判断是否继续重试
                if attempt > self.max_retries:
                    break

                # 短暂延迟后重试（避免连续失败）
                time.sleep(0.5)

        # 所有尝试都失败了
        self._log_final_failure(operation_name, self.max_retries + 1, last_error, context)
        return (False, last_error)

    def _log_start(self, operation_name: str, context: Optional[dict]):
        """记录操作开始"""
        msg = f"开始执行: {operation_name}"
        if context:
            msg += f" | 上下文: {context}"
        if self.enable_logging:
            self.logger.info(msg)
        else:
            print(msg, file=sys.stderr)

    def _log_retry(self, operation_name: str, attempt: int, context: Optional[dict]):
        """记录重试"""
        msg = f"重试 [{attempt}/{self.max_retries}]: {operation_name}"
        if context:
            msg += f" | 上下文: {context}"
        if self.enable_logging:
            self.logger.warning(msg)
        else:
            print(f"[警告] {msg}", file=sys.stderr)

    def _log_success(self, operation_name: str, attempt: int, context: Optional[dict]):
        """记录成功"""
        msg = f"成功: {operation_name}"
        if attempt > 0:
            msg += f" (经过 {attempt} 次重试)"
        if context:
            msg += f" | 上下文: {context}"
        if self.enable_logging:
            self.logger.info(msg)
        else:
            print(msg, file=sys.stderr)

    def _log_failure(self, operation_name: str, attempt: int, error: Exception, context: Optional[dict]):
        """记录失败"""
        msg = f"失败 [{attempt}/{self.max_retries + 1}]: {operation_name}"
        msg += f" | 错误: {type(error).__name__}: {str(error)}"
        if context:
            msg += f" | 上下文: {context}"
        if self.enable_logging:
            self.logger.error(msg)
        else:
            print(f"[错误] {msg}", file=sys.stderr)

    def _log_final_failure(self, operation_name: str, total_attempts: int, error: Exception, context: Optional[dict]):
        """记录最终失败"""
        msg = f"==============================\n"
        msg += f"最终失败: {operation_name}\n"
        msg += f"总尝试次数: {total_attempts}\n"
        msg += f"最后错误: {type(error).__name__}: {str(error)}\n"
        if context:
            msg += f"上下文: {context}\n"
        msg += f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        msg += f"==============================\n"

        if self.enable_logging:
            self.logger.critical(msg)
        else:
            print(f"\n[严重错误]\n{msg}", file=sys.stderr)


def test_retry_manager():
    """测试重试管理器"""
    manager = RetryManager(max_retries=1, log_file="test_retry.log")

    # 测试 1：成功的操作
    def success_operation():
        print("执行成功的操作")
        return "成功结果"

    success, result = manager.execute_with_retry(success_operation, "测试成功操作")
    assert success == True
    assert result == "成功结果"
    print(f"[OK] 测试 1 通过: {result}")

    # 测试 2：第一次失败，第二次成功
    attempt_counter = [0]
    def retry_once_operation():
        attempt_counter[0] += 1
        if attempt_counter[0] == 1:
            raise RuntimeError("第一次尝试失败")
        return "第二次成功"

    success, result = manager.execute_with_retry(retry_once_operation, "测试重试一次")
    assert success == True
    assert result == "第二次成功"
    print(f"[OK] 测试 2 通过: {result}")

    # 测试 3：总是失败
    def always_fail_operation():
        raise RuntimeError("总是失败的操作")

    success, result = manager.execute_with_retry(always_fail_operation, "测试总是失败", {"key": "value"})
    assert success == False
    assert isinstance(result, RuntimeError)
    print(f"[OK] 测试 3 通过: 正确处理了失败")

    print("\n所有测试通过！")


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--test":
        test_retry_manager()
    else:
        print("重试管理器模块")
        print("使用方法: python retry_manager.py --test")
