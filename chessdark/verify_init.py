#!/usr/bin/env python3
"""
验证 v2.7 初始化逻辑是否正确
"""

# 模拟初始化逻辑
from enum import Enum

class PieceType(Enum):
    EMPTY = 0
    KING = 1
    QUEEN = 2
    ROOK = 3
    BISHOP = 4
    KNIGHT = 5
    PAWN = 6

class Color(Enum):
    NONE = 0
    WHITE = 1
    BLACK = 2

BOARD_ROWS = 8
BOARD_COLS = 8

# 初始化
board = [[PieceType.EMPTY for _ in range(BOARD_COLS)] for _ in range(BOARD_ROWS)]
piece_owners = {}

# 底线布局
back_rank = [
    PieceType.ROOK, PieceType.KNIGHT, PieceType.BISHOP, PieceType.QUEEN,
    PieceType.KING, PieceType.BISHOP, PieceType.KNIGHT, PieceType.ROOK
]

# 黑方
for c in range(BOARD_COLS):
    board[0][c] = back_rank[c]
    board[1][c] = PieceType.PAWN
for r in range(2):
    for c in range(BOARD_COLS):
        piece_owners[(r, c)] = Color.BLACK

# 白方
for c in range(BOARD_COLS):
    board[6][c] = PieceType.PAWN
    board[7][c] = back_rank[c]
for r in range(6, 8):
    for c in range(BOARD_COLS):
        piece_owners[(r, c)] = Color.WHITE

# 验证关键位置
def notation_to_sq(notation):
    col = ord(notation[0]) - ord('a')
    row = 8 - int(notation[1])
    return (row, col)

test_cases = [
    ("e1", PieceType.KING, Color.WHITE),  # 白王
    ("d1", PieceType.QUEEN, Color.WHITE),  # 白后
    ("g1", PieceType.KNIGHT, Color.WHITE),  # 白马 (g1f3 的起点)
    ("e2", PieceType.PAWN, Color.WHITE),  # 白兵
    ("e8", PieceType.KING, Color.BLACK),  # 黑王
    ("d8", PieceType.QUEEN, Color.BLACK),  # 黑后
    ("g8", PieceType.KNIGHT, Color.BLACK),  # 黑马
    ("e7", PieceType.PAWN, Color.BLACK),  # 黑兵
]

print("=" * 60)
print("验证棋盘初始化")
print("=" * 60)

all_passed = True
for notation, expected_piece, expected_color in test_cases:
    r, c = notation_to_sq(notation)
    actual_piece = board[r][c]
    actual_color = piece_owners.get((r, c), Color.NONE)

    piece_match = actual_piece == expected_piece
    color_match = actual_color == expected_color

    status = "[PASS]" if (piece_match and color_match) else "[FAIL]"
    print(f"{status} {notation} (row={r}, col={c}): "
          f"piece={actual_piece.name} (期望 {expected_piece.name}), "
          f"color={actual_color.name} (期望 {expected_color.name})")

    if not (piece_match and color_match):
        all_passed = False

print("=" * 60)
if all_passed:
    print("[OK] 所有验证通过！")
else:
    print("[FAIL] 存在错误，请检查初始化逻辑")
print("=" * 60)

# 统计
black_count = sum(1 for r in range(2) for c in range(8) if (r, c) in piece_owners)
white_count = sum(1 for r in range(6, 8) for c in range(8) if (r, c) in piece_owners)
print(f"\n棋子统计:")
print(f"  黑方: {black_count} 个 (期望 16)")
print(f"  白方: {white_count} 个 (期望 16)")
