#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
镰刀 PV 验证脚本
测试 kata-analyze 在镰刀模式下是否返回连续同方落子的 PV
"""

import subprocess
import json
import time
import sys

def run_test():
    print("=" * 60)
    print("镰刀 PV 验证测试")
    print("=" * 60)

    # 启动 KataGo GTP 进程
    katago_path = r"D:\ScytheKatago\ScytheEngine\katago.exe"
    model_path = r"D:\ScytheKatago\ScytheEngine\scythe11.bin.gz"
    config_path = r"D:\ScytheKatago\ScytheEngine\scythe_config.cfg"

    cmd = [katago_path, "gtp", "-model", model_path, "-config", config_path]

    print(f"\n启动 KataGo: {' '.join(cmd)}")
    proc = subprocess.Popen(
        cmd,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        bufsize=1
    )

    def send_command(cmd_str):
        """发送 GTP 命令并读取响应"""
        print(f"\n>>> {cmd_str}")
        proc.stdin.write(cmd_str + "\n")
        proc.stdin.flush()

        # 读取响应直到遇到空行
        response_lines = []
        while True:
            line = proc.stdout.readline()
            if not line:
                break
            line = line.strip()
            if line.startswith('=') or line.startswith('?'):
                response_lines.append(line)
                # 继续读取直到空行
                while True:
                    next_line = proc.stdout.readline().strip()
                    if not next_line:
                        break
                    response_lines.append(next_line)
                break

        response = '\n'.join(response_lines)
        print(f"<<< {response[:200]}{'...' if len(response) > 200 else ''}")
        return response

    try:
        # 等待引擎初始化
        time.sleep(3)

        # 设置棋盘
        send_command("boardsize 11")
        send_command("clear_board")

        # 摆几步棋 (黑白交替，最后白棋，轮到黑棋)
        send_command("play B F6")
        send_command("play W G6")
        send_command("play B F7")
        send_command("play W G7")

        # 激活镰刀
        print("\n" + "=" * 60)
        print("激活黑方镰刀")
        print("=" * 60)
        send_command("kata-set-param scythe_trigger true")
        send_command("kata-set-param scythe_trigger_player black")

        # 检查镰刀状态
        status_response = send_command("kata-get-scythe-status")
        print(f"\n镰刀状态: {status_response}")

        # 运行分析
        print("\n" + "=" * 60)
        print("运行 kata-analyze")
        print("=" * 60)

        proc.stdin.write("kata-analyze interval 100 minmoves 0 maxmoves 10\n")
        proc.stdin.flush()

        # 读取分析输出
        analysis_lines = []
        json_count = 0
        max_json = 3  # 只读取前3个 JSON

        while json_count < max_json:
            line = proc.stdout.readline()
            if not line:
                break
            line = line.strip()

            # 检查是否是 JSON 行
            if line and (line.startswith('{') or line.startswith('info')):
                analysis_lines.append(line)
                if line.startswith('{'):
                    json_count += 1
                    print(f"\n收到 JSON #{json_count}:")
                    print(line[:300] + "..." if len(line) > 300 else line)

        # 停止分析
        send_command("kata-analyze-stop")

        # 解析 JSON 并检查 PV
        print("\n" + "=" * 60)
        print("PV 验证结果")
        print("=" * 60)

        found_valid_pv = False
        test_passed = False

        for line in analysis_lines:
            if not line.startswith('{'):
                continue

            try:
                data = json.loads(line)

                # 检查是否有 pv 和 pvPlayers
                if 'moveInfos' in data:
                    for move_info in data['moveInfos']:
                        if 'pv' in move_info and 'pvPlayers' in move_info:
                            pv = move_info['pv']
                            pv_players = move_info['pvPlayers']
                            move = move_info.get('move', 'unknown')

                            print(f"\n落子: {move}")
                            print(f"PV: {pv[:5]}")
                            print(f"PV Players: {pv_players[:5]}")

                            found_valid_pv = True

                            # 检查前两手是否都是 B
                            if len(pv_players) >= 2:
                                if pv_players[0] == 'B' and pv_players[1] == 'B':
                                    print("✅ SUCCESS: Scythe Active (B->B)")
                                    test_passed = True
                                else:
                                    print(f"❌ FAIL: Normal Go Logic ({pv_players[0]}->{pv_players[1]})")

                            break

                    if found_valid_pv:
                        break

            except json.JSONDecodeError as e:
                print(f"JSON 解析错误: {e}")
                continue

        if not found_valid_pv:
            print("\n❌ 未找到有效的 PV 数据")
            print("可能的原因:")
            print("1. kata-analyze 未返回 JSON")
            print("2. pvPlayers 字段缺失")
            print("3. 引擎启动失败")

        print("\n" + "=" * 60)
        print(f"最终结果: {'✅ PASS' if test_passed else '❌ FAIL'}")
        print("=" * 60)

        return test_passed

    finally:
        # 关闭进程
        try:
            send_command("quit")
            proc.wait(timeout=5)
        except:
            proc.kill()

        # 打印 stderr
        stderr_output = proc.stderr.read()
        if stderr_output:
            print("\n" + "=" * 60)
            print("引擎调试输出 (stderr 最后 30 行):")
            print("=" * 60)
            stderr_lines = stderr_output.strip().split('\n')
            for line in stderr_lines[-30:]:
                print(line)

if __name__ == "__main__":
    success = run_test()
    sys.exit(0 if success else 1)
