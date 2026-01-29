#!/usr/bin/env python3
"""
ChessDark Bridge Server
WebSocket 中间件：连接微信小程序与 C++ 引擎
"""

import asyncio
import json
import logging
import sys
from pathlib import Path
from typing import Optional

import websockets

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# 引擎路径
ENGINE_PATH = Path(__file__).parent.parent / "stockfish11" / "src" / "stockfish.exe"


class ChessDarkEngine:
    """C++ 引擎管理器"""

    def __init__(self):
        self.process: Optional[asyncio.subprocess.Process] = None
        self.ready = False
        self._lock = asyncio.Lock()

    async def start(self) -> bool:
        """启动引擎进程"""
        if self.process is not None:
            logger.warning("引擎已在运行")
            return True

        if not ENGINE_PATH.exists():
            logger.error(f"引擎文件不存在: {ENGINE_PATH}")
            return False

        try:
            self.process = await asyncio.create_subprocess_exec(
                str(ENGINE_PATH),
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
            logger.info(f"引擎启动成功 (PID: {self.process.pid})")
            return True
        except Exception as e:
            logger.error(f"引擎启动失败: {e}")
            return False

    async def stop(self):
        """停止引擎进程"""
        if self.process is None:
            return

        try:
            await self.send_command("quit")
            await asyncio.wait_for(self.process.wait(), timeout=2.0)
        except asyncio.TimeoutError:
            logger.warning("引擎未响应 quit，强制终止")
            self.process.kill()
        except Exception as e:
            logger.error(f"停止引擎时出错: {e}")
        finally:
            self.process = None
            self.ready = False
            logger.info("引擎已停止")

    async def send_command(self, command: str) -> None:
        """发送命令到引擎"""
        if self.process is None or self.process.stdin is None:
            raise RuntimeError("引擎未启动")

        logger.debug(f">>> {command}")
        self.process.stdin.write(f"{command}\n".encode())
        await self.process.stdin.drain()

    async def read_line(self, timeout: float = 10.0) -> Optional[str]:
        """读取引擎输出的一行"""
        if self.process is None or self.process.stdout is None:
            return None

        try:
            line = await asyncio.wait_for(
                self.process.stdout.readline(),
                timeout=timeout
            )
            if line:
                decoded = line.decode().strip()
                logger.debug(f"<<< {decoded}")
                return decoded
            return None
        except asyncio.TimeoutError:
            logger.warning("读取引擎输出超时")
            return None

    async def read_until(self, target: str, timeout: float = 10.0) -> list[str]:
        """读取直到遇到包含 target 的行"""
        lines = []
        start_time = asyncio.get_event_loop().time()

        while True:
            elapsed = asyncio.get_event_loop().time() - start_time
            remaining = timeout - elapsed
            if remaining <= 0:
                break

            line = await self.read_line(timeout=remaining)
            if line is None:
                break

            lines.append(line)
            if target in line:
                break

        return lines

    async def initialize(self) -> bool:
        """初始化引擎（UCI 握手 + DarkChess 模式）"""
        async with self._lock:
            if not await self.start():
                return False

            try:
                # UCI 握手
                await self.send_command("uci")
                response = await self.read_until("uciok", timeout=5.0)
                if not any("uciok" in line for line in response):
                    logger.error("UCI 握手失败")
                    return False

                # 启用 DarkChess 模式
                await self.send_command("setoption name DarkChessMode value true")

                # 检查就绪
                await self.send_command("isready")
                response = await self.read_until("readyok", timeout=5.0)
                if not any("readyok" in line for line in response):
                    logger.error("引擎未就绪")
                    return False

                self.ready = True
                logger.info("引擎初始化完成 (DarkChess 模式)")
                return True

            except Exception as e:
                logger.error(f"初始化失败: {e}")
                await self.stop()
                return False

    async def set_position(self, moves: list[str] = None, fen: str = None) -> bool:
        """设置棋盘位置"""
        if not self.ready:
            return False

        async with self._lock:
            try:
                if fen:
                    cmd = f"position fen {fen}"
                else:
                    cmd = "position dark startpos"

                if moves:
                    cmd += " moves " + " ".join(moves)

                await self.send_command(cmd)

                # 读取并丢弃 "info string Dark Chess mode enabled" 输出
                # 使用短超时，因为输出可能已经在缓冲区中
                try:
                    line = await self.read_line(timeout=0.5)
                    if line:
                        logger.debug(f"Position output: {line}")
                except asyncio.TimeoutError:
                    pass

                return True
            except Exception as e:
                logger.error(f"设置位置失败: {e}")
                return False

    async def go(self, movetime: int = 2000) -> Optional[str]:
        """搜索最佳走法"""
        if not self.ready:
            return None

        async with self._lock:
            try:
                # 确保引擎就绪
                await self.send_command("isready")
                await self.read_until("readyok", timeout=5.0)

                await self.send_command(f"go movetime {movetime}")

                # 读取直到 bestmove
                timeout = movetime / 1000 + 5  # 额外 5 秒缓冲
                response = await self.read_until("bestmove", timeout=timeout)

                for line in response:
                    if line.startswith("bestmove"):
                        parts = line.split()
                        if len(parts) >= 2:
                            return parts[1]

                return None
            except Exception as e:
                logger.error(f"搜索失败: {e}")
                return None

    async def get_belief(self, square: str) -> Optional[str]:
        """查询格子的信念状态"""
        if not self.ready:
            return None

        async with self._lock:
            try:
                await self.send_command(f"printbelief {square}")
                line = await self.read_line(timeout=2.0)
                return line
            except Exception as e:
                logger.error(f"查询信念失败: {e}")
                return None


class BridgeServer:
    """WebSocket 桥接服务器"""

    def __init__(self, host: str = "127.0.0.1", port: int = 8765):
        self.host = host
        self.port = port
        self.engine = ChessDarkEngine()
        self.clients: set = set()

    async def handle_message(self, websocket, message: str) -> dict:
        """处理客户端消息"""
        try:
            data = json.loads(message)
            cmd = data.get("cmd", "")

            if cmd == "start":
                # 初始化引擎
                success = await self.engine.initialize()
                return {"status": "ok" if success else "error", "message": "引擎已就绪" if success else "初始化失败"}

            elif cmd == "stop":
                # 停止引擎
                await self.engine.stop()
                return {"status": "ok", "message": "引擎已停止"}

            elif cmd == "position":
                # 设置位置
                moves = data.get("moves", [])
                fen = data.get("fen")
                success = await self.engine.set_position(moves=moves, fen=fen)
                return {"status": "ok" if success else "error"}

            elif cmd == "go":
                # 搜索
                movetime = data.get("movetime", 2000)
                bestmove = await self.engine.go(movetime=movetime)
                if bestmove:
                    return {"status": "ok", "bestmove": bestmove}
                else:
                    return {"status": "error", "message": "搜索失败"}

            elif cmd == "move":
                # 设置位置并搜索（便捷接口）
                moves = data.get("moves", [])
                movetime = data.get("movetime", 2000)

                if not await self.engine.set_position(moves=moves):
                    return {"status": "error", "message": "设置位置失败"}

                bestmove = await self.engine.go(movetime=movetime)
                if bestmove:
                    return {"status": "ok", "bestmove": bestmove}
                else:
                    return {"status": "error", "message": "搜索失败"}

            elif cmd == "belief":
                # 查询信念状态
                square = data.get("square", "")
                belief = await self.engine.get_belief(square)
                if belief:
                    return {"status": "ok", "belief": belief}
                else:
                    return {"status": "error", "message": "查询失败"}

            elif cmd == "ping":
                return {"status": "ok", "message": "pong"}

            else:
                return {"status": "error", "message": f"未知命令: {cmd}"}

        except json.JSONDecodeError:
            return {"status": "error", "message": "无效的 JSON 格式"}
        except Exception as e:
            logger.exception("处理消息时出错")
            return {"status": "error", "message": str(e)}

    async def handler(self, websocket):
        """WebSocket 连接处理器"""
        self.clients.add(websocket)
        client_addr = websocket.remote_address
        logger.info(f"客户端连接: {client_addr}")

        try:
            async for message in websocket:
                logger.info(f"收到消息: {message}")
                response = await self.handle_message(websocket, message)
                await websocket.send(json.dumps(response, ensure_ascii=False))
                logger.info(f"发送响应: {response}")

        except websockets.exceptions.ConnectionClosed:
            logger.info(f"客户端断开: {client_addr}")
        except Exception as e:
            logger.exception(f"连接处理出错: {e}")
        finally:
            self.clients.discard(websocket)

    async def start(self):
        """启动服务器"""
        logger.info(f"启动 WebSocket 服务器: ws://{self.host}:{self.port}")

        async with websockets.serve(self.handler, self.host, self.port):
            logger.info("服务器已就绪，等待连接...")
            await asyncio.get_running_loop().create_future()  # 永久运行

    async def shutdown(self):
        """关闭服务器"""
        logger.info("正在关闭服务器...")
        await self.engine.stop()


async def main():
    """主函数"""
    server = BridgeServer(host="127.0.0.1", port=8765)

    try:
        await server.start()
    except KeyboardInterrupt:
        logger.info("收到中断信号")
    finally:
        await server.shutdown()


if __name__ == "__main__":
    print("""
╔═══════════════════════════════════════════════════════╗
║         ChessDark Bridge Server v1.0                  ║
║         WebSocket: ws://127.0.0.1:8765                ║
╚═══════════════════════════════════════════════════════╝
    """)

    # 检查引擎文件
    if not ENGINE_PATH.exists():
        print(f"[错误] 引擎文件不存在: {ENGINE_PATH}")
        print("请先编译 C++ 引擎。")
        sys.exit(1)

    print(f"[引擎] {ENGINE_PATH}")
    print()

    asyncio.run(main())
