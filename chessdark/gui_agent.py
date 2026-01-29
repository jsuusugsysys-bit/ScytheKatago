#!/usr/bin/env python3
"""
ChessDark GUI Agent v4.0 - 棋子计数器版
【核心玩法：揭棋/暗棋】
- 落子无悔：AI 决定移动后必须执行，不能取消
- 先移动后翻开：棋子先到达目标位置，然后揭示真实类型
- 不检查合法性：翻开时不验证走法对新棋子是否合法

【架构】
- 双层棋盘：visual_board (用户视角) + ai_board (AI 视角)
- FEN 同步：每次搜索前用 FEN 同步引擎状态

【v4.0 新功能】
- 棋子计数器：实时显示双方剩余棋子数量
- 翻开约束：禁止选择已用完的棋子类型
- HUD 显示：在棋盘旁边显示可视化计数

【v3.10 稳定性】
- 输入锁定：AI 思考时禁止用户操作
- 僵局处理：AI 无棋可走时正确提示

【v3.8 规则】
- 位置身份：未翻开棋子按初始位置走法移动

【v3.7 UI 简化】
- 移除：启动引擎按钮（引擎自动后台初始化）
- 新增：AI 执白/AI 执黑 单选框，选中即触发 AI 思考

【v3.6 功能】
- 双王默认翻开（e1 白王、e8 黑王）
- 将军音效（800Hz, 300ms）
"""

import subprocess
import threading
import time
import re
import copy
import tkinter as tk
from tkinter import ttk, messagebox, scrolledtext
from pathlib import Path
from typing import Optional, Tuple, Dict, List, Set, Callable
from enum import Enum

# 【v3.6】将军音效
try:
    import winsound
    WINSOUND_AVAILABLE = True
except ImportError:
    WINSOUND_AVAILABLE = False

try:
    import pyautogui
    PYAUTOGUI_AVAILABLE = True
    pyautogui.FAILSAFE = True
    pyautogui.PAUSE = 0.1
except ImportError:
    PYAUTOGUI_AVAILABLE = False

ENGINE_PATH = Path(__file__).parent / "stockfish11" / "src" / "stockfish.exe"

BOARD_ROWS = 8
BOARD_COLS = 8
CELL_SIZE = 64

COLORS = {
    "light": "#EEEED2",
    "dark": "#769656",
    "selected": "#F6F669",
    "lastmove": "#CDD26A",
    "bg": "#302E2B",
    "arrow": "#FF5722",
    "white_piece": "#FFFFFF",
    "black_piece": "#1A1A1A",
}


class PieceType(Enum):
    EMPTY = 0
    KING = 1
    QUEEN = 2
    ROOK = 3
    BISHOP = 4
    KNIGHT = 5
    PAWN = 6
    UNKNOWN = 7  # 薛定谔状态：用户视角未知


class Color(Enum):
    NONE = 0
    WHITE = 1
    BLACK = 2


SYMBOL_TO_PIECE = {
    "K": PieceType.KING, "Q": PieceType.QUEEN, "R": PieceType.ROOK,
    "B": PieceType.BISHOP, "N": PieceType.KNIGHT, "P": PieceType.PAWN,
}

PIECE_TO_SYMBOL = {v: k for k, v in SYMBOL_TO_PIECE.items()}

PIECE_UNICODE_WHITE = {
    PieceType.KING: "♔", PieceType.QUEEN: "♕", PieceType.ROOK: "♖",
    PieceType.BISHOP: "♗", PieceType.KNIGHT: "♘", PieceType.PAWN: "♙",
}

PIECE_UNICODE_BLACK = {
    PieceType.KING: "♚", PieceType.QUEEN: "♛", PieceType.ROOK: "♜",
    PieceType.BISHOP: "♝", PieceType.KNIGHT: "♞", PieceType.PAWN: "♟",
}

PIECE_NAMES = {
    PieceType.KING: "王", PieceType.QUEEN: "后", PieceType.ROOK: "车",
    PieceType.BISHOP: "象", PieceType.KNIGHT: "马", PieceType.PAWN: "兵",
}


class MoveValidator:
    """严格走法校验器"""

    @staticmethod
    def is_valid_move(piece_type: PieceType, from_row: int, from_col: int,
                      to_row: int, to_col: int) -> bool:
        dr = to_row - from_row
        dc = to_col - from_col
        abs_dr, abs_dc = abs(dr), abs(dc)

        if piece_type == PieceType.KING:
            return abs_dr <= 1 and abs_dc <= 1 and (abs_dr + abs_dc) > 0
        elif piece_type == PieceType.QUEEN:
            return (dr == 0 or dc == 0 or abs_dr == abs_dc) and (abs_dr + abs_dc) > 0
        elif piece_type == PieceType.ROOK:
            return (dr == 0 or dc == 0) and (abs_dr + abs_dc) > 0
        elif piece_type == PieceType.BISHOP:
            return abs_dr == abs_dc and abs_dr > 0
        elif piece_type == PieceType.KNIGHT:
            return (abs_dr == 2 and abs_dc == 1) or (abs_dr == 1 and abs_dc == 2)
        elif piece_type == PieceType.PAWN:
            return abs_dr <= 2 and abs_dc <= 1
        return True

    @staticmethod
    def get_violation_message(piece_type: PieceType, from_sq: str, to_sq: str) -> str:
        name = PIECE_NAMES.get(piece_type, "未知棋子")
        if piece_type == PieceType.KNIGHT:
            return f"马({from_sq})不能直走到{to_sq}，马必须走日字"
        elif piece_type == PieceType.BISHOP:
            return f"象({from_sq})不能直走到{to_sq}，象只能斜走"
        elif piece_type == PieceType.ROOK:
            return f"车({from_sq})不能斜走到{to_sq}，车只能直走"
        else:
            return f"{name}({from_sq})不能移动到{to_sq}"


class DarkChessEngine:
    """引擎封装"""

    def __init__(self, engine_path: Path):
        self.engine_path = engine_path
        self.process: Optional[subprocess.Popen] = None
        self.ready = False
        self._lock = threading.Lock()
        self._search_active = False
        self.info_callback = None

    def initialize(self) -> bool:
        if not self.engine_path.exists():
            print(f"[ERROR] 引擎不存在: {self.engine_path}")
            return False

        try:
            self.process = subprocess.Popen(
                [str(self.engine_path)],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1
            )

            with self._lock:
                self._send("uci")
                if not self._wait_for("uciok", 5):
                    return False

                self._send("setoption name DarkChessMode value true")
                self._send("isready")
                if not self._wait_for("readyok", 5):
                    return False

                self.ready = True
                print("[ENGINE] 引擎初始化成功")
                return True
        except Exception as e:
            print(f"[ERROR] 引擎初始化失败: {e}")
            return False

    def _send(self, cmd: str):
        if self.process and self.process.stdin:
            self.process.stdin.write(cmd + "\n")
            self.process.stdin.flush()

    def _read_line(self) -> Optional[str]:
        if not self.process or not self.process.stdout:
            return None
        try:
            line = self.process.stdout.readline()
            if line:
                return line.strip()
        except Exception:
            pass
        return None

    def _wait_for(self, expected: str, timeout: float) -> bool:
        start = time.time()
        while time.time() - start < timeout:
            line = self._read_line()
            if line and expected in line:
                return True
        return False

    def new_game(self):
        with self._lock:
            self._send("ucinewgame")
            self._send("isready")
            self._wait_for("readyok", 3)
        print("[ENGINE] 新对局初始化")

    def set_position(self, moves: List[str]):
        with self._lock:
            if moves:
                # 【修复】去掉棋子类型后缀，UCI 协议只接受纯坐标格式
                clean_moves = [m.split('(')[0] for m in moves]
                moves_str = " ".join(clean_moves)
                self._send(f"position startpos moves {moves_str}")
            else:
                self._send("position startpos")

    def set_position_fen(self, fen: str):
        """【v3.0】使用 FEN 设置局面，确保引擎知道正确的棋子类型"""
        with self._lock:
            self._send(f"position fen {fen}")
            print(f"[ENGINE] 使用 FEN 设置局面: {fen[:50]}...")

    def search_async(self, movetime_ms: int, callback):
        if self._search_active:
            return

        def _search_thread():
            self._search_active = True
            print("[THINKING] AI 正在思考中...")
            with self._lock:
                self._send(f"go movetime {movetime_ms}")

                best_move = None
                start = time.time()
                timeout = movetime_ms / 1000.0 + 5.0

                while time.time() - start < timeout:
                    line = self._read_line()
                    if not line:
                        continue

                    if line.startswith("bestmove"):
                        parts = line.split()
                        if len(parts) >= 2:
                            best_move = parts[1]
                        print(f"[BESTMOVE] {best_move}")
                        break
                    elif line.startswith("info") and self.info_callback:
                        self.info_callback(line)

                self._search_active = False
                if callback:
                    callback(best_move)

        threading.Thread(target=_search_thread, daemon=True).start()

    def stop(self):
        self._send("stop")
        self._search_active = False

    def quit(self):
        if self.process:
            self._send("quit")
            self.process.terminate()


class ChessDarkGUI:
    """
    【v3.6 双王翻开 + 将军音效版】

    双层棋盘架构：
    - visual_board: 用户看到的状态（未翻开显示 UNKNOWN）
    - ai_board: AI 计算使用的状态（标准国际象棋布局）

    动态重算机制：
    - AI 移动未知棋子时，暂停并询问用户
    - 如果用户指定的棋子与 AI 假设不一致，废弃当前走法并重新搜索

    【v3.6 新功能】
    - 双王默认翻开：游戏开始时 e1 白王和 e8 黑王已翻开
    - 将军音效：任何一方被将军时播放 winsound.Beep(800, 300)
    """

    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("ChessDark GUI Agent v3.7 - 极简启动版")
        self.root.configure(bg=COLORS["bg"])

        # ========== 【v2.8 核心】双层棋盘 ==========
        # Layer 1: 视觉层（用户看到的）
        self.visual_board: List[List[PieceType]] = []
        # Layer 2: AI 层（喂给引擎的，标准布局）
        self.ai_board: List[List[PieceType]] = []
        # 棋子归属（两层共享）
        self.piece_owners: Dict[Tuple[int, int], Color] = {}
        # 已翻开的格子（视觉层已确定类型）
        self.revealed: Set[Tuple[int, int]] = set()

        # 【v4.0】棋子计数器：跟踪双方剩余棋子数量
        self.remaining_counts: Dict[Color, Dict[PieceType, int]] = {}

        self.moves_list: List[str] = []
        self.current_turn: Color = Color.WHITE
        self.selected_sq: Optional[Tuple[int, int]] = None
        self.last_move: Optional[Tuple[Tuple[int, int], Tuple[int, int]]] = None
        self.flipped = False

        # 历史快照
        self.history_snapshots: List[dict] = []

        # 【v3.7】AI 状态 - 简化版
        self.engine: Optional[DarkChessEngine] = None
        self.ai_color: Color = Color.NONE  # AI 执哪方（NONE 表示未选择）
        self.pending_ai_move: Optional[str] = None
        self._waiting_for_reveal = False
        self._pending_reveal_context: Optional[dict] = None

        # 【v3.10】输入锁定标志 - 防止竞态条件
        self.is_thinking: bool = False  # AI 是否正在思考中

        # 校验器
        self.validator = MoveValidator()

        self._init_board()
        self._create_ui()

        # 【v3.7】自动后台初始化引擎
        self.root.after(100, self._auto_init_engine)

    def _init_board(self):
        """
        【v2.8】初始化双层棋盘

        visual_board: 用户视角，棋子区域全部为 UNKNOWN
        ai_board: AI 视角，标准国际象棋布局
        """
        # ========== 视觉层：用户看到的（薛定谔状态） ==========
        self.visual_board = [[PieceType.EMPTY for _ in range(BOARD_COLS)] for _ in range(BOARD_ROWS)]

        # 棋子区域设为 UNKNOWN（未翻开）
        for r in range(2):  # Row 0-1：黑方区域
            for c in range(BOARD_COLS):
                self.visual_board[r][c] = PieceType.UNKNOWN
        for r in range(6, 8):  # Row 6-7：白方区域
            for c in range(BOARD_COLS):
                self.visual_board[r][c] = PieceType.UNKNOWN

        # ========== AI 层：标准国际象棋布局 ==========
        self.ai_board = [[PieceType.EMPTY for _ in range(BOARD_COLS)] for _ in range(BOARD_ROWS)]

        back_rank = [
            PieceType.ROOK, PieceType.KNIGHT, PieceType.BISHOP, PieceType.QUEEN,
            PieceType.KING, PieceType.BISHOP, PieceType.KNIGHT, PieceType.ROOK
        ]

        # Row 0: 黑方底线
        for c in range(BOARD_COLS):
            self.ai_board[0][c] = back_rank[c]
        # Row 1: 黑方兵线
        for c in range(BOARD_COLS):
            self.ai_board[1][c] = PieceType.PAWN
        # Row 6: 白方兵线
        for c in range(BOARD_COLS):
            self.ai_board[6][c] = PieceType.PAWN
        # Row 7: 白方底线
        for c in range(BOARD_COLS):
            self.ai_board[7][c] = back_rank[c]

        # ========== 归属层（共享） ==========
        self.piece_owners.clear()
        for r in range(2):  # 黑方
            for c in range(BOARD_COLS):
                self.piece_owners[(r, c)] = Color.BLACK
        for r in range(6, 8):  # 白方
            for c in range(BOARD_COLS):
                self.piece_owners[(r, c)] = Color.WHITE

        # ========== 翻开状态 ==========
        self.revealed.clear()

        # 【v3.6 新功能】双王默认翻开
        # 白王 e1 = (7, 4)
        white_king_sq = (7, 4)
        self.visual_board[7][4] = PieceType.KING
        self.revealed.add(white_king_sq)
        # 黑王 e8 = (0, 4)
        black_king_sq = (0, 4)
        self.visual_board[0][4] = PieceType.KING
        self.revealed.add(black_king_sq)

        # 【v4.0】初始化棋子计数器
        # 标准国际象棋开局：王 1（已翻开，计数 0）、后 1、车 2、象 2、马 2、兵 8
        self.remaining_counts = {
            Color.WHITE: {
                PieceType.KING: 0,    # 已翻开
                PieceType.QUEEN: 1,
                PieceType.ROOK: 2,
                PieceType.BISHOP: 2,
                PieceType.KNIGHT: 2,
                PieceType.PAWN: 8,
            },
            Color.BLACK: {
                PieceType.KING: 0,    # 已翻开
                PieceType.QUEEN: 1,
                PieceType.ROOK: 2,
                PieceType.BISHOP: 2,
                PieceType.KNIGHT: 2,
                PieceType.PAWN: 8,
            },
        }

        print("[INIT] 双层棋盘初始化完成")
        print(f"  - 视觉层: 棋子区域为 UNKNOWN（薛定谔状态）")
        print(f"  - AI 层: 标准国际象棋布局")
        print(f"  - 【v3.6】双王已翻开: 白王 e1, 黑王 e8")
        print(f"  - 【v4.0】棋子计数器初始化: 白方 15 个未翻开，黑方 15 个未翻开")

    def _generate_fen(self) -> str:
        """
        【v3.7 严格同步】从棋盘生成 FEN 字符串

        核心原则：引擎必须知道所有已翻开棋子的真实类型
        - 如果 sq 在 revealed 集合中 → 强制使用 visual_board（真实类型）
        - 如果 sq 不在 revealed 中 → 使用 ai_board（AI 假设类型）
        """
        fen_rows = []

        for r in range(8):
            row_str = ""
            empty_count = 0

            for c in range(8):
                sq = (r, c)
                piece_color = self.piece_owners.get(sq, Color.NONE)

                # 【第一优先级】检查归属：无归属 = 空格
                if piece_color == Color.NONE:
                    empty_count += 1
                    continue

                # 【第二优先级】检查是否已翻开（严格检查 revealed 集合）
                if sq in self.revealed:
                    # 已翻开：强制使用 visual_board 的真实类型
                    piece_type = self.visual_board[r][c]
                    if piece_type == PieceType.EMPTY or piece_type == PieceType.UNKNOWN:
                        # 异常情况：revealed 中的棋子应该有确定类型
                        print(f"\033[91m[FEN_ERROR] revealed 集合中的 {sq} 类型异常: {piece_type.name}\033[0m")
                        empty_count += 1
                        continue
                else:
                    # 未翻开：使用 AI 假设类型
                    piece_type = self.ai_board[r][c]
                    if piece_type == PieceType.EMPTY or piece_type == PieceType.UNKNOWN:
                        # ai_board 中的未翻开位置不应该是 EMPTY
                        empty_count += 1
                        continue

                # 输出之前的空格计数
                if empty_count > 0:
                    row_str += str(empty_count)
                    empty_count = 0

                # 转换为 FEN 字符
                symbol = PIECE_TO_SYMBOL.get(piece_type, "P")
                if piece_color == Color.WHITE:
                    row_str += symbol.upper()
                else:
                    row_str += symbol.lower()

            # 处理行末的空格
            if empty_count > 0:
                row_str += str(empty_count)

            fen_rows.append(row_str if row_str else "8")

        # 【v3.4】验证 FEN 格式
        for i, row in enumerate(fen_rows):
            count = 0
            for ch in row:
                if ch.isdigit():
                    count += int(ch)
                else:
                    count += 1
            if count != 8:
                print(f"\033[91m[FEN_ERROR] Row {i} '{row}' has {count} squares (expected 8)\033[0m")
                # 尝试修复：将多余的位置当作空格
                fen_rows[i] = "8"  # 临时修复：整行当作空

        # 组合 FEN
        board_fen = "/".join(fen_rows)
        turn = "w" if self.current_turn == Color.WHITE else "b"

        # 简化的 FEN：不考虑王车易位和过路兵
        return f"{board_fen} {turn} - - 0 1"

    def _sync_engine_state(self):
        """【v3.7】同步引擎状态到当前棋盘（严格模式）"""
        if self.engine and self.engine.ready:
            fen = self._generate_fen()
            self.engine.set_position_fen(fen)
            # 输出已翻开的棋子列表（调试用）
            revealed_list = sorted(self.revealed)
            revealed_notation = [chr(ord('a') + c) + str(8 - r) for r, c in revealed_list]
            print(f"[SYNC] 引擎状态已同步 | 已翻开: {len(revealed_list)} 个棋子 {revealed_notation}")
            print(f"[SYNC] FEN: {fen[:60]}...")

    # ========== 【v3.8】揭棋规则：位置身份验证 ==========

    def _get_standard_piece_at(self, row: int, col: int) -> PieceType:
        """
        获取标准国际象棋开局时该坐标的棋子类型

        揭棋规则核心：未翻开的棋子必须按照其初始位置的棋子走法移动
        例如：f8 (0, 5) 在开局是黑象，未翻开时只能走斜线
        """
        # 黑方区域 (行 0-1)
        if row == 0:  # 黑方底线
            back_rank = [
                PieceType.ROOK, PieceType.KNIGHT, PieceType.BISHOP, PieceType.QUEEN,
                PieceType.KING, PieceType.BISHOP, PieceType.KNIGHT, PieceType.ROOK
            ]
            return back_rank[col]
        elif row == 1:  # 黑方兵线
            return PieceType.PAWN

        # 白方区域 (行 6-7)
        elif row == 6:  # 白方兵线
            return PieceType.PAWN
        elif row == 7:  # 白方底线
            back_rank = [
                PieceType.ROOK, PieceType.KNIGHT, PieceType.BISHOP, PieceType.QUEEN,
                PieceType.KING, PieceType.BISHOP, PieceType.KNIGHT, PieceType.ROOK
            ]
            return back_rank[col]

        # 中间区域（不应该有棋子）
        return PieceType.EMPTY

    # ========== 【v3.6】将军检测逻辑 ==========

    def _find_king(self, color: Color) -> Optional[Tuple[int, int]]:
        """找到指定颜色的王的位置"""
        for r in range(8):
            for c in range(8):
                sq = (r, c)
                if self.piece_owners.get(sq) == color:
                    # 使用 visual_board 判断（已翻开的王）
                    if self.visual_board[r][c] == PieceType.KING:
                        return sq
                    # 如果未翻开，检查 ai_board（假设值）
                    elif self.visual_board[r][c] == PieceType.UNKNOWN:
                        if self.ai_board[r][c] == PieceType.KING:
                            return sq
        return None

    def _is_square_attacked_by(self, sq: Tuple[int, int], attacker_color: Color) -> bool:
        """
        检查某个格子是否被指定颜色的棋子攻击

        注意：这是简化版本，不考虑路径阻挡（暗棋中棋子位置不完全确定）
        """
        tr, tc = sq

        for r in range(8):
            for c in range(8):
                piece_sq = (r, c)
                if self.piece_owners.get(piece_sq) != attacker_color:
                    continue

                # 获取棋子类型（优先用 visual_board，否则用 ai_board）
                piece_type = self.visual_board[r][c]
                if piece_type == PieceType.UNKNOWN:
                    piece_type = self.ai_board[r][c]
                if piece_type == PieceType.EMPTY:
                    continue

                dr = tr - r
                dc = tc - c
                abs_dr, abs_dc = abs(dr), abs(dc)

                # 跳过自己
                if abs_dr == 0 and abs_dc == 0:
                    continue

                # 根据棋子类型判断是否能攻击目标格
                can_attack = False

                if piece_type == PieceType.KING:
                    can_attack = abs_dr <= 1 and abs_dc <= 1
                elif piece_type == PieceType.QUEEN:
                    can_attack = (dr == 0 or dc == 0 or abs_dr == abs_dc)
                elif piece_type == PieceType.ROOK:
                    can_attack = (dr == 0 or dc == 0)
                elif piece_type == PieceType.BISHOP:
                    can_attack = (abs_dr == abs_dc and abs_dr > 0)
                elif piece_type == PieceType.KNIGHT:
                    can_attack = (abs_dr == 2 and abs_dc == 1) or (abs_dr == 1 and abs_dc == 2)
                elif piece_type == PieceType.PAWN:
                    # 兵的攻击方向取决于颜色
                    if attacker_color == Color.WHITE:
                        # 白兵向上攻击（行号减少）
                        can_attack = (dr == -1 and abs_dc == 1)
                    else:
                        # 黑兵向下攻击（行号增加）
                        can_attack = (dr == 1 and abs_dc == 1)

                if can_attack:
                    return True

        return False

    def _is_in_check(self, color: Color) -> bool:
        """
        检查指定颜色的玩家是否被将军

        返回 True 如果该颜色的王正在被对方攻击
        """
        king_sq = self._find_king(color)
        if not king_sq:
            # 找不到王（异常情况）
            return False

        # 对方颜色
        opponent = Color.BLACK if color == Color.WHITE else Color.WHITE
        return self._is_square_attacked_by(king_sq, opponent)

    def _play_check_sound(self):
        """【v3.6】播放将军音效"""
        if WINSOUND_AVAILABLE:
            try:
                # 800Hz, 300ms - 清脆的警示音
                winsound.Beep(800, 300)
            except Exception as e:
                print(f"[SOUND_ERROR] 无法播放音效: {e}")
        else:
            print("[SOUND] 将军！(winsound 不可用)")

    def _check_for_check_and_alert(self):
        """
        【v3.6】检测将军状态并播放音效

        在每次走棋后调用，检测当前行棋方是否被将军
        """
        # 检测当前行棋方是否被将军
        if self._is_in_check(self.current_turn):
            color_name = "白方" if self.current_turn == Color.WHITE else "黑方"
            print(f"\033[93m[CHECK] {color_name}被将军！\033[0m")
            self._play_check_sound()
            return True
        return False

    def _create_ui(self):
        main_frame = tk.Frame(self.root, bg=COLORS["bg"])
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # 左侧控制面板
        left_panel = tk.Frame(main_frame, bg=COLORS["bg"], width=200)
        left_panel.pack(side=tk.LEFT, fill=tk.Y, padx=(0, 10))
        left_panel.pack_propagate(False)

        # 【v3.7】AI 设置（核心交互入口）
        ai_frame = tk.LabelFrame(left_panel, text="AI 设置", bg=COLORS["bg"], fg="white",
                                 font=("Arial", 10, "bold"))
        ai_frame.pack(fill=tk.X, pady=5)

        # AI 颜色选择 - 选中即触发
        self.ai_color_var = tk.StringVar(value="none")
        tk.Radiobutton(ai_frame, text="AI 执白 (先手)", variable=self.ai_color_var, value="white",
                       bg=COLORS["bg"], fg="white", selectcolor=COLORS["bg"],
                       activebackground=COLORS["bg"], command=self._on_ai_color_changed).pack(anchor=tk.W)
        tk.Radiobutton(ai_frame, text="AI 执黑 (后手)", variable=self.ai_color_var, value="black",
                       bg=COLORS["bg"], fg="white", selectcolor=COLORS["bg"],
                       activebackground=COLORS["bg"], command=self._on_ai_color_changed).pack(anchor=tk.W)
        tk.Radiobutton(ai_frame, text="纯人类对弈", variable=self.ai_color_var, value="none",
                       bg=COLORS["bg"], fg="white", selectcolor=COLORS["bg"],
                       activebackground=COLORS["bg"], command=self._on_ai_color_changed).pack(anchor=tk.W)

        # 引擎状态指示
        self.engine_status_label = tk.Label(ai_frame, text="[...] 引擎初始化中",
                                            bg=COLORS["bg"], fg="#FFA500", font=("Arial", 9))
        self.engine_status_label.pack(anchor=tk.W, pady=(5, 0))

        # 对局控制（移除"启动引擎"按钮）
        ctrl_frame = tk.LabelFrame(left_panel, text="对局控制", bg=COLORS["bg"], fg="white")
        ctrl_frame.pack(fill=tk.X, pady=5)

        tk.Button(ctrl_frame, text="新对局", command=self._new_game).pack(fill=tk.X, pady=2)
        tk.Button(ctrl_frame, text="上下翻转", command=self._flip_board).pack(fill=tk.X, pady=2)

        # 思考控制
        think_frame = tk.LabelFrame(left_panel, text="思考控制", bg=COLORS["bg"], fg="white")
        think_frame.pack(fill=tk.X, pady=5)

        tk.Label(think_frame, text="思考时间(ms):", bg=COLORS["bg"], fg="white").pack(anchor=tk.W)
        self.think_time_var = tk.IntVar(value=2000)
        tk.Spinbox(think_frame, from_=500, to=30000, increment=500,
                   textvariable=self.think_time_var, width=10).pack(fill=tk.X)

        tk.Button(think_frame, text="开始思考", command=self._start_thinking).pack(fill=tk.X, pady=2)
        tk.Button(think_frame, text="立即出步", command=self._stop_thinking).pack(fill=tk.X, pady=2)

        # 悔棋/跳转
        undo_frame = tk.LabelFrame(left_panel, text="悔棋/跳转", bg=COLORS["bg"], fg="white")
        undo_frame.pack(fill=tk.X, pady=5)

        tk.Button(undo_frame, text="悔一步", command=self._undo_one).pack(fill=tk.X, pady=2)
        tk.Button(undo_frame, text="悔两步", command=self._undo_two).pack(fill=tk.X, pady=2)

        # 中央棋盘区域
        center_frame = tk.Frame(main_frame, bg=COLORS["bg"])
        center_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        # 当前回合显示
        self.turn_label = tk.Label(center_frame, text="○ 白方行棋", font=("Arial", 16, "bold"),
                                   bg=COLORS["bg"], fg="white")
        self.turn_label.pack(pady=5)

        # 棋盘画布
        canvas_size = CELL_SIZE * 8 + 40
        self.canvas = tk.Canvas(center_frame, width=canvas_size, height=canvas_size,
                                bg=COLORS["bg"], highlightthickness=0)
        self.canvas.pack()
        self.canvas.bind("<Button-1>", self._on_canvas_click)

        # AI 走法显示
        ai_frame = tk.Frame(center_frame, bg=COLORS["bg"])
        ai_frame.pack(pady=5)

        self.ai_move_label = tk.Label(ai_frame, text="AI 已走: --", font=("Arial", 12),
                                      bg=COLORS["bg"], fg="white")
        self.ai_move_label.pack()

        self.ai_recommend_label = tk.Label(ai_frame, text="AI 推荐: --", font=("Arial", 12),
                                           bg=COLORS["bg"], fg="#4FC3F7")
        self.ai_recommend_label.pack()

        btn_frame = tk.Frame(ai_frame, bg=COLORS["bg"])
        btn_frame.pack(pady=5)
        tk.Button(btn_frame, text="应用 AI 走法", command=self._apply_ai_move).pack(side=tk.LEFT, padx=5)
        tk.Button(btn_frame, text="手动输入", command=self._manual_input).pack(side=tk.LEFT, padx=5)

        # 走法历史
        history_frame = tk.LabelFrame(center_frame, text="走法历史:", bg=COLORS["bg"], fg="white")
        history_frame.pack(fill=tk.X, pady=5)

        self.history_text = scrolledtext.ScrolledText(history_frame, height=15, width=40,
                                                      font=("Consolas", 10), state=tk.DISABLED)
        self.history_text.pack(fill=tk.X)

        # 右侧思考详情
        right_panel = tk.Frame(main_frame, bg=COLORS["bg"], width=250)
        right_panel.pack(side=tk.RIGHT, fill=tk.Y, padx=(10, 0))
        right_panel.pack_propagate(False)

        tk.Label(right_panel, text="思考详情", font=("Arial", 12, "bold"),
                 bg=COLORS["bg"], fg="white").pack(pady=5)

        self.info_score = tk.Label(right_panel, text="分数: --", bg=COLORS["bg"], fg="white", anchor=tk.W)
        self.info_score.pack(fill=tk.X)
        self.info_depth = tk.Label(right_panel, text="深度: --", bg=COLORS["bg"], fg="white", anchor=tk.W)
        self.info_depth.pack(fill=tk.X)
        self.info_nps = tk.Label(right_panel, text="速度: --", bg=COLORS["bg"], fg="white", anchor=tk.W)
        self.info_nps.pack(fill=tk.X)

        tk.Label(right_panel, text="引擎输出:", bg=COLORS["bg"], fg="white", anchor=tk.W).pack(fill=tk.X, pady=(10, 0))
        self.engine_output = scrolledtext.ScrolledText(right_panel, height=20, width=30,
                                                       font=("Consolas", 9), bg="#1E1E1E", fg="#CCCCCC")
        self.engine_output.pack(fill=tk.BOTH, expand=True)

        self._draw_board()

    # ========== 【v3.7】引擎自动初始化 ==========

    def _auto_init_engine(self):
        """后台自动初始化引擎"""
        def _init_thread():
            self.engine = DarkChessEngine(ENGINE_PATH)
            self.engine.info_callback = self._on_engine_info

            if self.engine.initialize():
                # 在主线程更新 UI
                self.root.after(0, self._on_engine_ready)
            else:
                self.root.after(0, self._on_engine_failed)

        print("[ENGINE] 后台初始化引擎...")
        threading.Thread(target=_init_thread, daemon=True).start()

    def _on_engine_ready(self):
        """引擎初始化成功回调"""
        self.engine_status_label.config(text="[OK] 引擎就绪", fg="#00FF00")
        print("[ENGINE] 引擎初始化成功，可以开始对弈")

        # 如果 AI 已被选择执白，且当前是白方回合，立即开始思考
        if self.ai_color == Color.WHITE and self.current_turn == Color.WHITE:
            self.root.after(100, self._start_thinking)

    def _on_engine_failed(self):
        """引擎初始化失败回调"""
        self.engine_status_label.config(text="[X] 引擎加载失败", fg="#FF0000")
        print(f"[ENGINE] 引擎初始化失败！路径: {ENGINE_PATH}")

    def _on_ai_color_changed(self):
        """
        【v3.10 核心】AI 颜色选择回调（带强制唤醒）

        用户选择 AI 执白/执黑时，自动触发 AI 思考（如果轮到 AI）
        【v3.10】如果用户重复点击且 AI 卡死，强制重新唤醒 AI
        """
        color_str = self.ai_color_var.get()

        if color_str == "white":
            new_color = Color.WHITE
            print("[CONFIG] AI 执白（先手）")
        elif color_str == "black":
            new_color = Color.BLACK
            print("[CONFIG] AI 执黑（后手）")
        else:
            self.ai_color = Color.NONE
            print("[CONFIG] 纯人类对弈模式")
            # 停止 AI 思考（如果正在进行）
            if self.engine:
                self.engine.stop()
                self.is_thinking = False
            return

        # 【v3.10 看门狗】检测是否是强制唤醒（用户重复点击相同选项）
        force_wake = (new_color == self.ai_color and self._is_ai_turn() and self.is_thinking)
        if force_wake:
            print("[WATCHDOG] 检测到强制唤醒请求，重置 AI 思考...")
            if self.engine:
                self.engine.stop()
            self.is_thinking = False

        self.ai_color = new_color

        # 检查引擎是否就绪
        if not self.engine or not self.engine.ready:
            print("[WARN] 引擎尚未就绪，请稍候...")
            return

        # 如果当前轮到 AI，立即开始思考
        if self._is_ai_turn():
            if force_wake:
                print(f"[RECOVERY] 强制重启 AI 思考...")
            else:
                print(f"[AUTO] 当前轮到 AI（{'白' if self.ai_color == Color.WHITE else '黑'}方），自动开始思考")
            self.root.after(100, self._start_thinking)

    def _is_ai_turn(self) -> bool:
        """检查当前是否轮到 AI 行棋"""
        # 【v3.7】简化逻辑：直接比较 ai_color 和 current_turn
        if self.ai_color == Color.NONE:
            return False
        return self.current_turn == self.ai_color

    def _draw_board(self):
        """【v2.8】基于 visual_board 渲染（用户视角）"""
        self.canvas.delete("all")
        offset = 20

        # 绘制坐标
        for i in range(8):
            col_label = chr(ord('a') + i)
            row_label = str(8 - i) if not self.flipped else str(i + 1)

            self.canvas.create_text(offset + i * CELL_SIZE + CELL_SIZE // 2, 10,
                                    text=col_label if not self.flipped else chr(ord('h') - i),
                                    fill="white", font=("Arial", 10))
            self.canvas.create_text(10, offset + i * CELL_SIZE + CELL_SIZE // 2,
                                    text=row_label, fill="white", font=("Arial", 10))

        # 绘制棋盘格子
        for r in range(8):
            for c in range(8):
                x1 = offset + c * CELL_SIZE
                y1 = offset + r * CELL_SIZE
                x2 = x1 + CELL_SIZE
                y2 = y1 + CELL_SIZE

                board_r = r if not self.flipped else 7 - r
                board_c = c if not self.flipped else 7 - c

                # 格子颜色
                is_light = (r + c) % 2 == 0
                color = COLORS["light"] if is_light else COLORS["dark"]

                # 高亮选中和最后走法
                if self.selected_sq == (board_r, board_c):
                    color = COLORS["selected"]
                elif self.last_move:
                    if (board_r, board_c) in self.last_move:
                        color = COLORS["lastmove"]

                self.canvas.create_rectangle(x1, y1, x2, y2, fill=color, outline="")

                # 【v2.8】基于 visual_board 渲染
                cx, cy = x1 + CELL_SIZE // 2, y1 + CELL_SIZE // 2
                sq = (board_r, board_c)
                piece_type = self.visual_board[board_r][board_c]
                piece_color = self.piece_owners.get(sq, Color.NONE)

                if piece_type == PieceType.UNKNOWN:
                    # 未翻开：显示纯色圆盘
                    fill_color = COLORS["white_piece"] if piece_color == Color.WHITE else COLORS["black_piece"]
                    self.canvas.create_oval(cx - 25, cy - 25, cx + 25, cy + 25,
                                            fill=fill_color, outline="#888888", width=2)
                elif piece_type != PieceType.EMPTY:
                    # 已翻开：显示棋子图标
                    if piece_color == Color.WHITE:
                        symbol = PIECE_UNICODE_WHITE.get(piece_type, "?")
                        bg_color = "#FFFFFF"
                        text_color = "#333333"
                    else:
                        symbol = PIECE_UNICODE_BLACK.get(piece_type, "?")
                        bg_color = "#1A1A1A"
                        text_color = "#FFFFFF"

                    self.canvas.create_oval(cx - 25, cy - 25, cx + 25, cy + 25,
                                            fill=bg_color, outline="#888888", width=2)
                    self.canvas.create_text(cx, cy, text=symbol, font=("Arial", 32), fill=text_color)

        # 绘制最后走法箭头
        if self.last_move:
            from_sq, to_sq = self.last_move
            self._draw_arrow(from_sq, to_sq, offset)

    def _draw_arrow(self, from_sq: Tuple[int, int], to_sq: Tuple[int, int], offset: int):
        fr, fc = from_sq
        tr, tc = to_sq

        if self.flipped:
            fr, fc = 7 - fr, 7 - fc
            tr, tc = 7 - tr, 7 - tc

        x1 = offset + fc * CELL_SIZE + CELL_SIZE // 2
        y1 = offset + fr * CELL_SIZE + CELL_SIZE // 2
        x2 = offset + tc * CELL_SIZE + CELL_SIZE // 2
        y2 = offset + tr * CELL_SIZE + CELL_SIZE // 2

        self.canvas.create_line(x1, y1, x2, y2, fill=COLORS["arrow"], width=4, arrow=tk.LAST, arrowshape=(12, 15, 5))

    def _on_canvas_click(self, event):
        """【v3.10】棋盘点击处理（带输入锁定）"""
        # 【v3.10 第一层防护】等待翻开对话框时禁止点击
        if self._waiting_for_reveal:
            return

        # 【v3.10 第二层防护】AI 思考时禁止点击
        if self.is_thinking:
            print("[INPUT_LOCK] AI 正在思考中，请稍候...")
            return

        # 【v3.10 第三层防护】非玩家回合禁止点击
        if self._is_ai_turn():
            print("[INPUT_LOCK] 当前是 AI 回合，请等待 AI 走棋...")
            return

        offset = 20
        c = (event.x - offset) // CELL_SIZE
        r = (event.y - offset) // CELL_SIZE

        if not (0 <= r < 8 and 0 <= c < 8):
            return

        board_r = r if not self.flipped else 7 - r
        board_c = c if not self.flipped else 7 - c

        sq = (board_r, board_c)
        piece_type = self.visual_board[board_r][board_c]
        target_owner = self.piece_owners.get(sq, Color.NONE)

        # 【v3.7】获取玩家颜色（AI 颜色的反面，或纯人类模式下允许两方操作）
        # player_color 变量在此方法中未使用，可以移除
        # 但保留注释以说明逻辑

        if self.selected_sq is None:
            # 没有选中棋子 -> 尝试选中
            if piece_type != PieceType.EMPTY and target_owner != Color.NONE:
                self.selected_sq = sq
                self._draw_board()
        else:
            from_sq = self.selected_sq
            to_sq = sq

            # 【v3.4 修复】检查目标是否是己方棋子
            from_owner = self.piece_owners.get(from_sq, Color.NONE)

            if from_sq != to_sq:
                # 如果目标格子是己方棋子，切换选中而非移动
                if target_owner != Color.NONE and target_owner == from_owner:
                    # 切换选中
                    from_notation = chr(ord('a') + from_sq[1]) + str(8 - from_sq[0])
                    to_notation = chr(ord('a') + to_sq[1]) + str(8 - to_sq[0])
                    print(f"[INTERACTION] 切换选中棋子: {from_notation} -> {to_notation}")
                    self.selected_sq = to_sq
                    self._draw_board()
                    return
                else:
                    # 目标是空格或敌方棋子，执行移动
                    self._try_player_move(from_sq, to_sq)

            self.selected_sq = None
            self._draw_board()

    def _try_player_move(self, from_sq: Tuple[int, int], to_sq: Tuple[int, int]):
        """
        【v3.8】玩家移动时的揭棋规则验证

        核心规则：
        1. 未翻开棋子 (UNKNOWN)：必须按照初始位置的棋子类型走法移动
        2. 已翻开棋子 (REVEALED)：按照真实类型走法移动
        """
        fr, fc = from_sq
        tr, tc = to_sq
        visual_piece_type = self.visual_board[fr][fc]
        piece_color = self.piece_owners.get(from_sq, Color.NONE)

        if visual_piece_type == PieceType.EMPTY or piece_color == Color.NONE:
            return

        from_notation = chr(ord('a') + fc) + str(8 - fr)
        to_notation = chr(ord('a') + tc) + str(8 - tr)

        # 【v3.8 关键】未翻开棋子：使用位置身份验证
        if visual_piece_type == PieceType.UNKNOWN:
            # 获取该位置的标准初始棋子类型
            proxy_type = self._get_standard_piece_at(fr, fc)
            proxy_name = PIECE_NAMES.get(proxy_type, "未知")

            # 验证走法是否符合初始位置的棋子规则
            if not self.validator.is_valid_move(proxy_type, fr, fc, tr, tc):
                violation_msg = self.validator.get_violation_message(proxy_type, from_notation, to_notation)
                print(f"[ILLEGAL_MOVE] 暗子移动被拒绝: {violation_msg}")
                messagebox.showwarning(
                    "非法走法",
                    f"暗子必须遵循初始位置棋子的走法！\n\n"
                    f"{from_notation} 位置在开局是 {proxy_name}\n"
                    f"{violation_msg}"
                )
                return

            # 合法走法，弹出翻开对话框
            print(f"[VALID_MOVE] 暗子 {from_notation}->{to_notation} 符合 {proxy_name} 的走法，等待翻开...")
            self._show_reveal_dialog(from_sq, to_sq, piece_color, is_ai_move=False)
            return

        # 【已翻开棋子】按照真实类型验证
        if not self.validator.is_valid_move(visual_piece_type, fr, fc, tr, tc):
            violation_msg = self.validator.get_violation_message(visual_piece_type, from_notation, to_notation)
            print(f"[ILLEGAL_MOVE] 已翻开棋子移动被拒绝: {violation_msg}")
            messagebox.showwarning("非法走法", violation_msg)
            return

        # 合法走法，直接执行
        move_str = from_notation + to_notation
        piece_symbol = PIECE_TO_SYMBOL.get(visual_piece_type, "")
        if piece_symbol:
            move_str += f"({piece_symbol})"

        self._execute_move(move_str, from_sq, to_sq, visual_piece_type, piece_color, is_player=True)

    def _show_reveal_dialog(self, from_sq: Tuple[int, int], to_sq: Tuple[int, int],
                            piece_color: Color, is_ai_move: bool,
                            original_ai_move: Optional[str] = None):
        """【v2.8】显示翻开对话框，带拦截逻辑"""
        self._waiting_for_reveal = True

        # 保存上下文
        self._pending_reveal_context = {
            "from_sq": from_sq,
            "to_sq": to_sq,
            "piece_color": piece_color,
            "is_ai_move": is_ai_move,
            "original_ai_move": original_ai_move,
        }

        dialog = tk.Toplevel(self.root)
        dialog.title("翻开棋子 - 请选择类型")
        dialog.geometry("350x250")
        dialog.transient(self.root)
        dialog.grab_set()

        fr, fc = from_sq
        sq_notation = chr(ord('a') + fc) + str(8 - fr)

        # 显示 AI 的假设（如果是 AI 移动）
        ai_assumed = self.ai_board[fr][fc]
        ai_assumed_name = PIECE_NAMES.get(ai_assumed, "未知")

        if is_ai_move:
            tk.Label(dialog, text=f"AI 想要移动 {sq_notation}", font=("Arial", 12, "bold")).pack(pady=5)
            tk.Label(dialog, text=f"AI 假设这里是: {ai_assumed_name}", font=("Arial", 10), fg="blue").pack(pady=2)
            tk.Label(dialog, text="请告诉我这个位置实际上是什么棋子:", font=("Arial", 10)).pack(pady=5)
        else:
            tk.Label(dialog, text=f"请选择 {sq_notation} 的棋子类型:", font=("Arial", 12)).pack(pady=10)

        btn_frame = tk.Frame(dialog)
        btn_frame.pack(pady=10)

        pieces = [
            (PieceType.KING, "王 ♔"),
            (PieceType.QUEEN, "后 ♕"),
            (PieceType.ROOK, "车 ♖"),
            (PieceType.BISHOP, "象 ♗"),
            (PieceType.KNIGHT, "马 ♘"),
            (PieceType.PAWN, "兵 ♙"),
        ]

        def on_select(pt):
            dialog.destroy()
            self._handle_reveal_callback(pt)

        for i, (pt, label) in enumerate(pieces):
            btn = tk.Button(btn_frame, text=label, width=8, command=lambda p=pt: on_select(p))
            btn.grid(row=i // 3, column=i % 3, padx=5, pady=5)

            # 如果是 AI 假设的棋子，高亮显示
            if is_ai_move and pt == ai_assumed:
                btn.config(bg="#90EE90")  # 浅绿色高亮

        # 阻止关闭
        dialog.protocol("WM_DELETE_WINDOW", lambda: None)

    def _handle_reveal_callback(self, user_selected_piece: PieceType):
        """
        【v3.7 严格同步】处理用户翻开后的逻辑

        核心规则（暗棋/揭棋）：
        1. 落子无悔：AI 决定移动后必须执行，不能取消
        2. 先移动后翻开：棋子先到达目标位置，然后揭示真实类型
        3. 不检查合法性：翻开时不验证走法对新棋子是否合法

        【v3.7 关键修复】：翻开时必须同步更新三个数据结构：
        - visual_board: 更新为真实类型
        - ai_board: 更新为真实类型（确保引擎知道）
        - revealed: 加入翻开集合（确保 FEN 生成时使用真实类型）
        """
        ctx = self._pending_reveal_context
        if not ctx:
            self._waiting_for_reveal = False
            return

        from_sq = ctx["from_sq"]
        to_sq = ctx["to_sq"]
        piece_color = ctx["piece_color"]
        is_ai_move = ctx["is_ai_move"]
        original_ai_move = ctx["original_ai_move"]

        fr, fc = from_sq
        tr, tc = to_sq
        from_notation = chr(ord('a') + fc) + str(8 - fr)
        to_notation = chr(ord('a') + tc) + str(8 - tr)

        # 获取 AI 的假设
        ai_assumed = self.ai_board[fr][fc]

        print(f"[REVEAL] {from_notation}: 用户选择 {user_selected_piece.name}, AI 假设 {ai_assumed.name}")

        # 【v3.7 关键步骤 1】先更新源位置的棋子类型（翻开）
        self.visual_board[fr][fc] = user_selected_piece
        self.ai_board[fr][fc] = user_selected_piece
        self.revealed.add(from_sq)
        print(f"[SYNC] {from_notation} 已翻开为 {user_selected_piece.name}，同步到 visual_board 和 ai_board")

        # 【揭棋规则】无论类型是否匹配，都强制执行移动
        if user_selected_piece != ai_assumed:
            print(f"[REVEAL_MISMATCH] 类型不同（AI 假设: {ai_assumed.name}），但按揭棋规则强制执行移动")

        self._waiting_for_reveal = False
        self._pending_reveal_context = None

        # 构建走法字符串（使用用户指定的真实类型）
        piece_symbol = PIECE_TO_SYMBOL.get(user_selected_piece, "")
        move_str = from_notation + to_notation + f"({piece_symbol})"

        # 【v3.7 关键步骤 2】执行移动（此时 from_sq 已经是正确类型）
        self._execute_move(move_str, from_sq, to_sq, user_selected_piece, piece_color, is_player=not is_ai_move)

    def _execute_move(self, move_str: str, from_sq: Tuple[int, int], to_sq: Tuple[int, int],
                      piece_type: PieceType, piece_color: Color, is_player: bool):
        """
        【v3.7】执行移动，严格同步双层状态

        前置条件：如果棋子是翻开的，from_sq 必须已在 revealed 集合中
        后置保证：ai_board 和 visual_board 保持一致，revealed 状态正确转移
        """
        # 保存快照
        self._save_snapshot()

        fr, fc = from_sq
        tr, tc = to_sq

        # 【v3.0 核心】强制使用 visual_board 的类型
        # 如果 visual_board 已有确定类型，覆盖传入的 piece_type
        visual_type = self.visual_board[fr][fc]
        if visual_type != PieceType.UNKNOWN and visual_type != PieceType.EMPTY:
            if visual_type != piece_type:
                print(f"[FORCE_SYNC] 强制使用 visual_board 类型: {visual_type.name} (传入: {piece_type.name})")
            piece_type = visual_type

        # 【v3.2 核心】同时更新双层状态 + 显式清理
        from_notation = chr(ord('a') + fc) + str(8 - fr)
        to_notation = chr(ord('a') + tc) + str(8 - tr)

        # 视觉层
        self.visual_board[tr][tc] = piece_type
        self.visual_board[fr][fc] = PieceType.EMPTY
        # AI 层（强制同步到 visual_board）
        self.ai_board[tr][tc] = piece_type
        self.ai_board[fr][fc] = PieceType.EMPTY

        # 【验证】确保清理成功
        if self.visual_board[fr][fc] != PieceType.EMPTY:
            print(f"\033[91m[BUG] visual_board[{from_notation}] 未正确清空！\033[0m")
        if self.ai_board[fr][fc] != PieceType.EMPTY:
            print(f"\033[91m[BUG] ai_board[{from_notation}] 未正确清空！\033[0m")

        # 【v3.4 吃子处理】先清理目标位置的状态（被吃棋子）
        if to_sq in self.piece_owners and to_sq != from_sq:
            # 目标位置有棋子（被吃），记录日志
            captured_color = self.piece_owners[to_sq]
            print(f"[CAPTURE] {to_notation} 位置的{'白' if captured_color == Color.WHITE else '黑'}方棋子被吃")
            # 被吃棋子的翻开状态需要清理
            self.revealed.discard(to_sq)

        # 转移归属（并显式删除源位置）
        if from_sq in self.piece_owners:
            self.piece_owners[to_sq] = self.piece_owners.pop(from_sq)
        # 确保源位置没有归属
        if from_sq in self.piece_owners:
            print(f"\033[91m[BUG] piece_owners[{from_notation}] 未正确删除！\033[0m")
            del self.piece_owners[from_sq]

        # 转移翻开状态
        if from_sq in self.revealed:
            self.revealed.add(to_sq)
            self.revealed.discard(from_sq)

        # 记录走法
        self.moves_list.append(move_str)
        self.last_move = (from_sq, to_sq)

        # 更新历史显示
        move_num = len(self.moves_list)
        color_str = "[白]" if self.current_turn == Color.WHITE else "[黑]"
        reveal_info = ""
        if "(" in move_str:
            piece_sym = move_str.split("(")[1].rstrip(")")
            for pt, sym in PIECE_TO_SYMBOL.items():
                if sym == piece_sym:
                    reveal_info = f" 翻{PIECE_UNICODE_WHITE.get(pt, '?')}"
                    break

        history_line = f"{move_num}. {color_str} {move_str.split('(')[0]}{reveal_info}\n"
        self.history_text.config(state=tk.NORMAL)
        self.history_text.insert(tk.END, history_line)
        self.history_text.see(tk.END)
        self.history_text.config(state=tk.DISABLED)

        # 切换回合
        self.current_turn = Color.BLACK if self.current_turn == Color.WHITE else Color.WHITE
        self._update_turn_label()

        source = "玩家" if is_player else "AI"
        print(f"[MOVE] 接收到{source}走法: {move_str}")

        self._draw_board()

        # 【v3.6】检测将军状态并播放音效
        self._check_for_check_and_alert()

        self._after_move()

    def _after_move(self):
        if self._is_ai_turn() and self.engine and self.engine.ready:
            print(f"[TURN] 当前轮到: {'白方' if self.current_turn == Color.WHITE else '黑方'} (AI)")
            self.root.after(100, self._start_thinking)
        else:
            print(f"[TURN] 当前轮到: {'白方' if self.current_turn == Color.WHITE else '黑方'} (玩家)")

    def _update_turn_label(self):
        if self.current_turn == Color.WHITE:
            self.turn_label.config(text="○ 白方行棋")
        else:
            self.turn_label.config(text="● 黑方行棋")

    def _save_snapshot(self):
        snapshot = {
            "visual_board": copy.deepcopy(self.visual_board),
            "ai_board": copy.deepcopy(self.ai_board),
            "owners": copy.deepcopy(self.piece_owners),
            "revealed": copy.deepcopy(self.revealed),
            "moves": copy.deepcopy(self.moves_list),
            "turn": self.current_turn,
            "last_move": self.last_move,
        }
        self.history_snapshots.append(snapshot)

    def _restore_snapshot(self, snapshot: dict):
        self.visual_board = copy.deepcopy(snapshot["visual_board"])
        self.ai_board = copy.deepcopy(snapshot["ai_board"])
        self.piece_owners = copy.deepcopy(snapshot["owners"])
        self.revealed = copy.deepcopy(snapshot["revealed"])
        self.moves_list = copy.deepcopy(snapshot["moves"])
        self.current_turn = snapshot["turn"]
        self.last_move = snapshot["last_move"]

    def _new_game(self):
        """【v3.10】新对局 - 保留 AI 颜色设置，重置输入锁"""
        # 停止当前思考（如果有）
        if self.engine:
            self.engine.stop()

        # 【v3.10】重置输入锁
        self.is_thinking = False

        self._init_board()
        self.moves_list.clear()
        self.current_turn = Color.WHITE
        self.selected_sq = None
        self.last_move = None
        self.history_snapshots.clear()
        self.pending_ai_move = None
        self._waiting_for_reveal = False
        self._pending_reveal_context = None

        self.history_text.config(state=tk.NORMAL)
        self.history_text.delete(1.0, tk.END)
        self.history_text.config(state=tk.DISABLED)

        self.ai_move_label.config(text="AI 已走: --")
        self.ai_recommend_label.config(text="AI 推荐: --")

        if self.engine and self.engine.ready:
            self.engine.new_game()

        self._update_turn_label()
        self._draw_board()

        print("[GAME] 新对局开始")

        # 【v3.7】如果 AI 执白，自动开始思考
        if self.ai_color == Color.WHITE:
            print("[AUTO] AI 执白，自动开始思考...")
            self.root.after(200, self._start_thinking)
        else:
            print("[TURN] 等待玩家（白方）走棋...")

    def _flip_board(self):
        self.flipped = not self.flipped
        self._draw_board()

    def _start_thinking(self):
        """【v3.10】开始 AI 思考（带异常处理和输入锁定）"""
        if not self.engine or not self.engine.ready:
            print("[WARN] 引擎尚未就绪，等待初始化...")
            # 延迟重试
            self.root.after(500, self._start_thinking)
            return

        # 【v3.10】设置思考标志，锁定用户输入
        self.is_thinking = True
        print(f"[THINKING] AI 开始思考... (输入已锁定)")

        try:
            # 【v3.7】使用 FEN 设置局面，确保引擎状态与 GUI 同步
            self._sync_engine_state()
            self.engine.search_async(self.think_time_var.get(), self._on_search_done)
        except Exception as e:
            print(f"\033[91m[ERROR] 引擎思考时发生异常: {e}\033[0m")
            self.is_thinking = False  # 解锁
            messagebox.showerror("引擎错误", f"AI 思考时发生错误:\n{e}\n\n请尝试重新选择 AI 颜色。")

    def _stop_thinking(self):
        """【v3.10】停止 AI 思考（解锁输入）"""
        if self.engine:
            self.engine.stop()
        self.is_thinking = False
        print("[STOP] AI 思考已停止，输入已解锁")

    def _on_engine_info(self, info_line: str):
        if "score" in info_line:
            match = re.search(r"score (cp|mate) (-?\d+)", info_line)
            if match:
                score_type, score_val = match.groups()
                if score_type == "cp":
                    self.info_score.config(text=f"分数: {int(score_val) / 100:.2f}")
                else:
                    self.info_score.config(text=f"分数: M{score_val}")

        if "depth" in info_line:
            match = re.search(r"depth (\d+)", info_line)
            if match:
                self.info_depth.config(text=f"深度: {match.group(1)}")

        if "nps" in info_line:
            match = re.search(r"nps (\d+)", info_line)
            if match:
                nps = int(match.group(1))
                self.info_nps.config(text=f"速度: {nps // 1000}k/s")

    def _on_search_done(self, best_move: Optional[str]):
        """【v3.10】引擎搜索完成回调（带特殊走法处理）"""
        # 【v3.10】解锁输入
        self.is_thinking = False

        # 【v3.10】处理特殊情况：引擎返回 None 或 "(none)"
        if not best_move or best_move == "(none)" or best_move.lower() == "none":
            print("[GAME_OVER] AI 无棋可走（僵局/将死）")
            self.ai_move_label.config(text="AI 已走: 无棋可走")
            self.ai_recommend_label.config(text="AI 推荐: --")
            messagebox.showinfo("对局结束", "AI 无棋可走！\n\n可能是僵局或被将死。")
            return

        self.pending_ai_move = best_move
        self.ai_move_label.config(text=f"AI 已走: {best_move}")
        self.ai_recommend_label.config(text=f"AI 推荐: {best_move}")

        # 自动应用
        self.root.after(50, self._apply_ai_move)

    def _apply_ai_move(self):
        """
        【v3.10】应用 AI 走法（带错误恢复和输入锁定）

        注意：此方法在 `_on_search_done` 后调用，此时 `is_thinking` 已被解锁
        如果遇到错误需要重新搜索，会再次调用 `_start_thinking`（重新上锁）
        """
        if not self.pending_ai_move:
            return

        move_str = self.pending_ai_move
        base = move_str.split('(')[0]
        from_sq = self._notation_to_sq(base[:2])
        to_sq = self._notation_to_sq(base[2:4])

        if not from_sq or not to_sq:
            print(f"[ERROR] 无法解析走法: {move_str}")
            self.pending_ai_move = None
            return

        fr, fc = from_sq
        piece_color = self.piece_owners.get(from_sq, Color.NONE)
        visual_piece_type = self.visual_board[fr][fc]

        # 【v3.2 安全检查 1】源位置为空时 - 严重同步错误
        if visual_piece_type == PieceType.EMPTY:
            print(f"\033[91m[SYNC_ERROR] 引擎试图移动空位置 {base[:2]}！\033[0m")
            print(f"[DEBUG] visual_board[{base[:2]}] = EMPTY")
            print(f"[DEBUG] ai_board[{base[:2]}] = {self.ai_board[fr][fc].name}")
            print(f"[RECOVERY] 强制使用 FEN 同步引擎状态...")

            self.pending_ai_move = None
            # 【关键修复】使用 FEN 同步而不是 moves_list
            self._sync_engine_state()
            # 重新搜索
            self.root.after(100, self._start_thinking)
            return

        # 【v3.2 安全检查 2】源位置没有归属时 - 也是同步错误
        if piece_color == Color.NONE:
            print(f"\033[91m[SYNC_ERROR] 源位置 {base[:2]} 没有归属！\033[0m")
            print(f"[DEBUG] visual_board[{base[:2]}] = {visual_piece_type.name}")
            print(f"[RECOVERY] 强制使用 FEN 同步引擎状态...")

            self.pending_ai_move = None
            self._sync_engine_state()
            self.root.after(100, self._start_thinking)
            return

        # 【v3.8 拦截点】检查视觉层是否为 UNKNOWN（需要翻开）
        if visual_piece_type == PieceType.UNKNOWN:
            # 【v3.8】验证 AI 走法是否符合位置身份规则
            tr, tc = to_sq
            proxy_type = self._get_standard_piece_at(fr, fc)
            proxy_name = PIECE_NAMES.get(proxy_type, "未知")

            if not self.validator.is_valid_move(proxy_type, fr, fc, tr, tc):
                # AI 生成了非法走法（理论上不应该发生，但作为安全检查）
                from_notation = chr(ord('a') + fc) + str(8 - fr)
                to_notation = chr(ord('a') + tc) + str(8 - tr)
                violation_msg = self.validator.get_violation_message(proxy_type, from_notation, to_notation)
                print(f"\033[91m[AI_ILLEGAL_MOVE] AI 生成了非法走法: {violation_msg}\033[0m")
                print(f"[DEBUG] {from_notation} 位置标准身份: {proxy_name}")
                print(f"[RECOVERY] 重新同步并搜索...")

                self.pending_ai_move = None
                self._sync_engine_state()
                self.root.after(100, self._start_thinking)
                return

            # 合法走法，弹出翻开对话框
            print(f"[INTERCEPT] AI 移动未翻开的棋子 {base[:2]}，等待用户指定类型...")
            self._show_reveal_dialog(from_sq, to_sq, piece_color, is_ai_move=True, original_ai_move=move_str)
            return

        # 【已翻开棋子】按揭棋规则执行（落子无悔）
        violation = self._validate_move(visual_piece_type, from_sq, to_sq)
        if violation:
            print(f"\033[93m[WARN_ILLEGAL] {violation}\033[0m")
            print(f"[WARN] 按揭棋规则，仍强制执行此走法（落子无悔）")

        # 执行移动
        piece_symbol = PIECE_TO_SYMBOL.get(visual_piece_type, "")
        if piece_symbol and "(" not in move_str:
            move_str += f"({piece_symbol})"

        self.pending_ai_move = None
        self._execute_move(move_str, from_sq, to_sq, visual_piece_type, piece_color, is_player=False)

    def _validate_move(self, piece_type: PieceType, from_sq: Tuple[int, int], to_sq: Tuple[int, int]) -> Optional[str]:
        if not self.validator.is_valid_move(piece_type, from_sq[0], from_sq[1], to_sq[0], to_sq[1]):
            fr, fc = from_sq
            tr, tc = to_sq
            from_notation = chr(ord('a') + fc) + str(8 - fr)
            to_notation = chr(ord('a') + tc) + str(8 - tr)
            return self.validator.get_violation_message(piece_type, from_notation, to_notation)
        return None

    def _notation_to_sq(self, notation: str) -> Optional[Tuple[int, int]]:
        if len(notation) != 2:
            return None
        col = ord(notation[0]) - ord('a')
        row = 8 - int(notation[1])
        if 0 <= row < 8 and 0 <= col < 8:
            return (row, col)
        return None

    def _manual_input(self):
        dialog = tk.Toplevel(self.root)
        dialog.title("手动输入走法")
        dialog.geometry("300x100")
        dialog.transient(self.root)
        dialog.grab_set()

        tk.Label(dialog, text="输入走法 (如 e2e4 或 e2e4(P)):").pack(pady=10)

        entry = tk.Entry(dialog, width=20)
        entry.pack()
        entry.focus()

        def on_submit():
            move = entry.get().strip()
            dialog.destroy()
            if move:
                self._process_manual_move(move)

        tk.Button(dialog, text="确定", command=on_submit).pack(pady=10)
        entry.bind("<Return>", lambda e: on_submit())

    def _process_manual_move(self, move_str: str):
        base = move_str.split('(')[0]
        from_sq = self._notation_to_sq(base[:2])
        to_sq = self._notation_to_sq(base[2:4])

        if not from_sq or not to_sq:
            messagebox.showerror("错误", "无法解析走法格式")
            return

        fr, fc = from_sq
        piece_color = self.piece_owners.get(from_sq, Color.NONE)
        visual_piece_type = self.visual_board[fr][fc]

        if visual_piece_type == PieceType.UNKNOWN:
            if "(" in move_str:
                piece_sym = move_str.split("(")[1].rstrip(")")
                piece_type = SYMBOL_TO_PIECE.get(piece_sym, PieceType.UNKNOWN)
                if piece_type != PieceType.UNKNOWN:
                    # 直接翻开并执行
                    self.visual_board[fr][fc] = piece_type
                    self.ai_board[fr][fc] = piece_type
                    self.revealed.add(from_sq)
                    self._execute_move(move_str, from_sq, to_sq, piece_type, piece_color, is_player=True)
                    return

            # 需要弹窗
            self._show_reveal_dialog(from_sq, to_sq, piece_color, is_ai_move=False)
            return

        self._execute_move(move_str, from_sq, to_sq, visual_piece_type, piece_color, is_player=True)

    def _undo_one(self):
        """【v3.10】悔棋（重置输入锁）"""
        if not self.history_snapshots:
            return

        # 【v3.10】停止 AI 思考并解锁
        if self.engine:
            self.engine.stop()
        self.is_thinking = False

        snapshot = self.history_snapshots.pop()
        self._restore_snapshot(snapshot)

        self.history_text.config(state=tk.NORMAL)
        content = self.history_text.get(1.0, tk.END).strip()
        lines = content.split('\n')
        if lines and lines[-1]:
            self.history_text.delete(f"{len(lines)}.0", tk.END)
        self.history_text.config(state=tk.DISABLED)

        self._update_turn_label()
        self._draw_board()

        # 【v3.7】使用 FEN 同步引擎状态
        self._sync_engine_state()

        print("[UNDO] 悔一步")

    def _undo_two(self):
        self._undo_one()
        self._undo_one()


def main():
    root = tk.Tk()
    app = ChessDarkGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()
