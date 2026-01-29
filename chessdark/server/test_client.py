#!/usr/bin/env python3
"""
ChessDark Bridge 测试客户端
用于验证 WebSocket 桥接服务是否正常工作
"""

import asyncio
import json
import sys
import os

# 绕过代理
os.environ['NO_PROXY'] = '127.0.0.1'
os.environ['http_proxy'] = ''
os.environ['https_proxy'] = ''

import websockets


async def test_bridge():
    """测试桥接服务"""
    uri = "ws://127.0.0.1:8765"

    print("=" * 50)
    print("ChessDark Bridge Test Client")
    print("=" * 50)

    try:
        async with websockets.connect(uri) as ws:
            print(f"\n[OK] Connected to {uri}\n")

            # 测试 1: Ping
            print("[Test 1] Ping...")
            await ws.send(json.dumps({"cmd": "ping"}))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            assert response["status"] == "ok"
            print("  [PASS] Ping successful\n")

            # 测试 2: 启动引擎
            print("[Test 2] Start engine...")
            await ws.send(json.dumps({"cmd": "start"}))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            assert response["status"] == "ok"
            print("  [PASS] Engine started\n")

            # 测试 3: 设置位置 (模拟翻棋)
            print("[Test 3] Set position (e2e4 reveals Queen)...")
            await ws.send(json.dumps({
                "cmd": "position",
                "moves": ["e2e4(Q)"]
            }))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            assert response["status"] == "ok"
            print("  [PASS] Position set\n")

            # 测试 4: 查询信念状态
            print("[Test 4] Query belief state of e4...")
            await ws.send(json.dumps({
                "cmd": "belief",
                "square": "e4"
            }))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            assert response["status"] == "ok"
            print(f"  Belief: {response.get('belief', 'N/A')}")
            print("  [PASS] Belief query successful\n")

            # 测试 5: AI 搜索
            print("[Test 5] AI search for best move (2s)...")
            await ws.send(json.dumps({
                "cmd": "go",
                "movetime": 2000
            }))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            assert response["status"] == "ok"
            print(f"  Best move: {response.get('bestmove', 'N/A')}")
            print("  [PASS] AI search successful\n")

            # 测试 6: 便捷接口 move (新对局)
            print("[Test 6] Convenience interface (move - new game)...")
            await ws.send(json.dumps({
                "cmd": "move",
                "moves": ["d2d4(B)"],
                "movetime": 1000
            }))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            assert response["status"] == "ok"
            print(f"  Best move: {response.get('bestmove', 'N/A')}")
            print("  [PASS] Move interface successful\n")

            # 测试 7: 停止引擎
            print("[Test 7] Stop engine...")
            await ws.send(json.dumps({"cmd": "stop"}))
            response = json.loads(await ws.recv())
            print(f"  Response: {response}")
            print("  [PASS] Engine stopped\n")

            print("=" * 50)
            print("ALL TESTS PASSED!")
            print("=" * 50)

    except ConnectionRefusedError:
        print("[ERROR] Cannot connect to server")
        print("Please start bridge.py first: python bridge.py")
        sys.exit(1)
    except AssertionError as e:
        print(f"[FAIL] Test assertion failed: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"[ERROR] {type(e).__name__}: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(test_bridge())
