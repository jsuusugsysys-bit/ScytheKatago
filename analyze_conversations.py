#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析 Claude Conversations 目录，提取高频命令模式和可自动化的工作流
"""

import os
import re
from collections import defaultdict, Counter
from pathlib import Path

CONV_DIR = r"d:\ScytheKatago\Claude Conversations"

# 模式定义
PATTERNS = {
    'compile_commands': [
        (r'cd.*KataGo.*build.*cmake.*--build', 'KataGo 增量编译'),
        (r'cd.*lizzieyzy.*mvn package', 'lizzieyzy Maven 编译'),
        (r'MSBuild.*readboard', 'readboard C# 编译'),
        (r'cmake.*-DUSE_BACKEND=CUDA', 'KataGo CMake 配置'),
    ],
    'test_commands': [
        (r'run.*test.*\.bat', '运行测试脚本'),
        (r'kata-get-scythe-status', '查询镰刀状态'),
        (r'gtp.*test', 'GTP 测试'),
    ],
    'git_operations': [
        (r'git status', 'Git 状态查询'),
        (r'git add.*git commit', 'Git 提交流程'),
        (r'git push', 'Git 推送'),
    ],
    'scythe_operations': [
        (r'kata-set-param scythe', '设置镰刀参数'),
        (r'ScythePanel|镰刀面板', '镰刀 GUI 操作'),
        (r'DetectScytheTrigger|镰刀检测', '镰刀检测逻辑'),
    ],
    'debug_workflows': [
        (r'编译.*测试.*修复', '编译-测试-修复循环'),
        (r'GTP.*日志.*调试', 'GTP 调试流程'),
        (r'野狐.*同步.*readboard', '野狐棋盘同步调试'),
    ]
}

# 错误模式
ERROR_PATTERNS = [
    (r'CMake Error', 'CMake 配置错误'),
    (r'MSBUILD.*error', 'MSBuild 编译错误'),
    (r'error MSB1009', '项目文件不存在'),
    (r'&& was unexpected', 'Bash Hook 错误'),
    (r'路径.*找不到', '路径错误'),
    (r'编译失败|compilation failed', '编译失败'),
]

def analyze_file(filepath):
    """分析单个对话文件"""
    try:
        with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()

        results = {
            'commands': defaultdict(int),
            'errors': defaultdict(int),
            'workflows': defaultdict(int),
        }

        # 匹配命令模式
        for category, patterns in PATTERNS.items():
            for pattern, desc in patterns:
                matches = re.findall(pattern, content, re.IGNORECASE)
                if matches:
                    results['commands'][desc] += len(matches)

        # 匹配错误模式
        for pattern, desc in ERROR_PATTERNS:
            matches = re.findall(pattern, content, re.IGNORECASE)
            if matches:
                results['errors'][desc] += len(matches)

        # 检测工作流（连续操作）
        if re.search(r'(编译|compile).*?(测试|test).*?(修复|fix)', content, re.IGNORECASE | re.DOTALL):
            results['workflows']['编译-测试-修复循环'] += 1

        if re.search(r'cmake.*build.*MSBuild', content, re.IGNORECASE | re.DOTALL):
            results['workflows']['KataGo + lizzieyzy 联合编译'] += 1

        if re.search(r'(野狐|yahu|fox).*?(readboard|棋盘同步).*?(镰刀|scythe)', content, re.IGNORECASE | re.DOTALL):
            results['workflows']['野狐镰刀检测调试'] += 1

        if re.search(r'git.*commit.*push', content, re.IGNORECASE | re.DOTALL):
            results['workflows']['Git 提交推送流程'] += 1

        return results
    except Exception as e:
        print(f"⚠️ 读取文件失败: {filepath} - {e}")
        return None

def main():
    # Windows 命令行编码修复
    import sys
    if sys.platform == 'win32':
        import codecs
        sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'strict')

    print("📊 Claude Conversations 模式分析\n")
    print("=" * 60)

    # 全局统计
    global_commands = Counter()
    global_errors = Counter()
    global_workflows = Counter()

    files = list(Path(CONV_DIR).glob("*.md"))
    print(f"\n📁 扫描 {len(files)} 个对话文件...\n")

    for filepath in files:
        result = analyze_file(filepath)
        if result:
            global_commands.update(result['commands'])
            global_errors.update(result['errors'])
            global_workflows.update(result['workflows'])

    # 输出结果
    print("\n" + "=" * 60)
    print("1️⃣ 高频命令模式（出现 3 次以上）")
    print("=" * 60)
    for cmd, count in sorted(global_commands.items(), key=lambda x: x[1], reverse=True):
        if count >= 3:
            print(f"  ✓ {cmd:<40} {count:>3} 次")

    print("\n" + "=" * 60)
    print("2️⃣ 重复性工作流")
    print("=" * 60)
    for workflow, count in sorted(global_workflows.items(), key=lambda x: x[1], reverse=True):
        if count >= 2:
            print(f"  🔄 {workflow:<40} {count:>3} 次")

    print("\n" + "=" * 60)
    print("3️⃣ 常见错误及解决方案")
    print("=" * 60)
    for error, count in sorted(global_errors.items(), key=lambda x: x[1], reverse=True):
        if count >= 2:
            print(f"  ❌ {error:<40} {count:>3} 次")

    print("\n" + "=" * 60)
    print("4️⃣ 推荐提取为 Skill 的候选项（按价值排序）")
    print("=" * 60)

    skill_candidates = []

    # 基于频率和价值评分
    if global_commands.get('KataGo 增量编译', 0) + global_commands.get('lizzieyzy Maven 编译', 0) >= 5:
        skill_candidates.append({
            'name': 'compile-all',
            'desc': '统一编译命令 - 自动编译 KataGo + lizzieyzy + readboard',
            'value': 95,
            'steps': [
                '1. 编译 KataGo C++ (cmake --build)',
                '2. 编译 lizzieyzy Java (mvn package)',
                '3. 编译 readboard C# (MSBuild)',
                '4. 复制输出到部署目录',
                '5. 验证编译结果'
            ]
        })

    if global_workflows.get('编译-测试-修复循环', 0) >= 3:
        skill_candidates.append({
            'name': 'compile-test-fix',
            'desc': '编译测试修复循环 - 自动化 TDD 工作流',
            'value': 90,
            'steps': [
                '1. 增量编译修改的代码',
                '2. 运行相关测试套件',
                '3. 如果失败，分析错误并提出修复',
                '4. 重复直到通过'
            ]
        })

    if global_workflows.get('野狐镰刀检测调试', 0) >= 3:
        skill_candidates.append({
            'name': 'debug-yahu-scythe',
            'desc': '野狐镰刀检测调试 - 专门用于调试棋盘同步',
            'value': 85,
            'steps': [
                '1. 启动 lizzieyzy + readboard',
                '2. 查看 scythe_detect.log',
                '3. 分析检测参数（阈值、区域）',
                '4. 调整并重新编译测试'
            ]
        })

    if global_commands.get('查询镰刀状态', 0) >= 3:
        skill_candidates.append({
            'name': 'scythe-status',
            'desc': '镰刀状态查询 - 快速诊断镰刀功能',
            'value': 75,
            'steps': [
                '1. 通过 GTP 查询 kata-get-scythe-status',
                '2. 解析 JSON 响应',
                '3. 显示黑/白镰刀次数、combo 状态',
                '4. 检查是否可触发'
            ]
        })

    if global_errors.get('路径错误', 0) + global_errors.get('项目文件不存在', 0) >= 3:
        skill_candidates.append({
            'name': 'fix-path-errors',
            'desc': '路径错误修复 - 自动修复常见路径问题',
            'value': 70,
            'steps': [
                '1. 检测 CMakeLists.txt、.csproj 等配置',
                '2. 验证依赖库路径（eigen3、zlib）',
                '3. 修正绝对/相对路径错误',
                '4. 重新生成构建文件'
            ]
        })

    if global_workflows.get('Git 提交推送流程', 0) >= 3:
        skill_candidates.append({
            'name': 'smart-commit',
            'desc': '智能提交 - 分析变更并生成合理 commit 信息',
            'value': 65,
            'steps': [
                '1. git status 查看变更',
                '2. git diff 分析修改内容',
                '3. 生成符合规范的 commit 信息',
                '4. 用户确认后 commit + push'
            ]
        })

    # 排序并输出
    skill_candidates.sort(key=lambda x: x['value'], reverse=True)

    for i, skill in enumerate(skill_candidates, 1):
        print(f"\n  {i}. **{skill['name']}** (价值: {skill['value']}/100)")
        print(f"     描述: {skill['desc']}")
        print(f"     步骤:")
        for step in skill['steps']:
            print(f"       {step}")

    print("\n" + "=" * 60)
    print("📝 建议优先实现前 3 个 Skill")
    print("=" * 60)

    if skill_candidates:
        print("\n**立即可实现**:")
        for skill in skill_candidates[:3]:
            print(f"  • {skill['name']}: {skill['desc']}")

if __name__ == "__main__":
    main()
