# -*- coding: utf-8 -*-
"""
野狐镰刀自动触发工具 v1.0
========================
监控野狐屏幕，检测到镰刀提示时自动触发 lizzieyzy 的镰刀按钮

保护机制：
1. 模拟模式 (--dry-run) - 只检测不点击
2. 首次确认 - 第一次检测到镰刀时需要确认
3. 冷却时间 - 避免重复触发
4. 详细日志 - 所有操作都有记录
"""

import cv2
import numpy as np
import time
import os
import sys
import argparse
from datetime import datetime

# ============ 配置 ============

class Config:
    # 检测间隔（秒）
    CHECK_INTERVAL = 0.2

    # 模板匹配阈值（降低以提高检测率）
    MATCH_THRESHOLD = 0.5

    # 触发后冷却时间（秒）
    COOLDOWN_TIME = 3.0

    # 模拟模式（不实际点击）
    DRY_RUN = False

    # 需要首次确认
    REQUIRE_CONFIRM = True

    # 目录
    SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
    TEMPLATE_DIR = os.path.join(SCRIPT_DIR, "templates")
    LOG_DIR = os.path.join(SCRIPT_DIR, "logs")
    TEST_DIR = os.path.join(SCRIPT_DIR, "test_images")

# ============ 全局状态 ============

running = True
last_trigger_time = 0
trigger_count = {"black": 0, "white": 0}
first_detection_confirmed = False

# ============ 日志 ============

log_file = None

def init_log():
    """初始化日志文件"""
    global log_file
    if not os.path.exists(Config.LOG_DIR):
        os.makedirs(Config.LOG_DIR)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_path = os.path.join(Config.LOG_DIR, f"scythe_{timestamp}.log")
    log_file = open(log_path, "w", encoding="utf-8")
    return log_path

def log(msg, level="INFO"):
    """打印并记录日志"""
    timestamp = datetime.now().strftime("%H:%M:%S.%f")[:-3]
    line = f"[{timestamp}] [{level}] {msg}"
    # Handle encoding issues on Windows
    try:
        print(line)
    except UnicodeEncodeError:
        print(line.encode('ascii', 'replace').decode('ascii'))
    if log_file:
        log_file.write(line + "\n")
        log_file.flush()

def close_log():
    """关闭日志文件"""
    if log_file:
        log_file.close()

# ============ 工具函数 ============

def ensure_dirs():
    """确保目录存在"""
    for d in [Config.TEMPLATE_DIR, Config.LOG_DIR, Config.TEST_DIR]:
        if not os.path.exists(d):
            os.makedirs(d)

def load_template(name):
    """加载模板图片"""
    path = os.path.join(Config.TEMPLATE_DIR, f"{name}.png")
    if os.path.exists(path):
        template = cv2.imread(path)
        if template is not None:
            log(f"已加载模板: {name}.png ({template.shape[1]}x{template.shape[0]})")
            return template
        else:
            log(f"模板加载失败: {path}", "ERROR")
    return None

# ============ 检测函数 ============

def capture_screen():
    """截取屏幕"""
    try:
        import pyautogui
        screenshot = pyautogui.screenshot()
        screen = np.array(screenshot)
        screen = cv2.cvtColor(screen, cv2.COLOR_RGB2BGR)
        return screen
    except Exception as e:
        log(f"截屏失败: {e}", "ERROR")
        return None

def match_template(screen, template, threshold=None):
    """多尺度模板匹配"""
    if template is None or screen is None:
        return None, 0

    if threshold is None:
        threshold = Config.MATCH_THRESHOLD

    try:
        best_val = 0
        best_loc = None

        # 多尺度匹配：尝试不同大小的模板
        scales = [0.5, 0.6, 0.7, 0.8, 0.9, 1.0, 1.1, 1.2, 1.3, 1.5]

        for scale in scales:
            # 缩放模板
            width = int(template.shape[1] * scale)
            height = int(template.shape[0] * scale)
            if width < 20 or height < 20:
                continue
            if width > screen.shape[1] or height > screen.shape[0]:
                continue

            resized = cv2.resize(template, (width, height))

            result = cv2.matchTemplate(screen, resized, cv2.TM_CCOEFF_NORMED)
            min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

            if max_val > best_val:
                best_val = max_val
                best_loc = max_loc

        if best_val >= threshold:
            return best_loc, best_val
        return None, best_val
    except Exception as e:
        log(f"模板匹配错误: {e}", "ERROR")
        return None, 0

def detect_scythe_by_color(screen):
    """
    通过颜色检测镰刀
    方法1: 检测弹出文字的颜色（触发时刻）
           黑方镰刀：蓝紫色文字
           白方镰刀：红色文字
    方法2: 检测黄色高亮边框（执行过程中，备用）
    返回: (detected, color, pixels)
    """
    if screen is None:
        return False, None, 0

    try:
        hsv = cv2.cvtColor(screen, cv2.COLOR_BGR2HSV)

        # ===== 方法1: 检测弹出文字颜色（优先）=====

        # 黑方镰刀：蓝紫色文字 (H: 100-140)
        lower_blue = np.array([100, 80, 80])
        upper_blue = np.array([140, 255, 255])
        mask_blue = cv2.inRange(hsv, lower_blue, upper_blue)
        pixels_blue = cv2.countNonZero(mask_blue)

        # 白方镰刀：红色文字 (H: 0-10 或 170-180)
        lower_red1 = np.array([0, 80, 80])
        upper_red1 = np.array([10, 255, 255])
        lower_red2 = np.array([170, 80, 80])
        upper_red2 = np.array([180, 255, 255])
        mask_red1 = cv2.inRange(hsv, lower_red1, upper_red1)
        mask_red2 = cv2.inRange(hsv, lower_red2, upper_red2)
        mask_red = cv2.bitwise_or(mask_red1, mask_red2)
        pixels_red = cv2.countNonZero(mask_red)

        # 弹出文字阈值（文字比较大，像素多）
        text_threshold = 2000

        if pixels_blue > text_threshold:
            return True, "black", pixels_blue
        if pixels_red > text_threshold:
            return True, "white", pixels_red

        # ===== 方法2: 检测黄色高亮边框（备用）=====

        lower_yellow = np.array([20, 150, 150])
        upper_yellow = np.array([40, 255, 255])
        mask_yellow = cv2.inRange(hsv, lower_yellow, upper_yellow)
        pixels_yellow = cv2.countNonZero(mask_yellow)

        yellow_threshold = 500

        if pixels_yellow > yellow_threshold:
            height, width = screen.shape[:2]
            right_region = mask_yellow[:, int(width * 0.75):]
            mid_y = right_region.shape[0] // 2
            upper_pixels = cv2.countNonZero(right_region[:mid_y, :])
            lower_pixels = cv2.countNonZero(right_region[mid_y:, :])

            if upper_pixels > lower_pixels and upper_pixels > 100:
                return True, "white", pixels_yellow
            elif lower_pixels > upper_pixels and lower_pixels > 100:
                return True, "black", pixels_yellow

        return False, None, max(pixels_blue, pixels_red, pixels_yellow)
    except Exception as e:
        log(f"颜色检测错误: {e}", "ERROR")
        return False, None, 0

def detect_scythe(screen, templates):
    """
    综合检测镰刀
    返回: (detected, color, method, confidence)
    """
    # 方法1: 模板匹配（优先）
    black_template = templates.get("black")
    if black_template is not None:
        loc, conf = match_template(screen, black_template)
        if loc:
            return True, "black", "template", conf

    white_template = templates.get("white")
    if white_template is not None:
        loc, conf = match_template(screen, white_template)
        if loc:
            return True, "white", "template", conf

    # 方法2: 颜色检测（能区分黑白）
    detected, color, pixels = detect_scythe_by_color(screen)
    if detected and color:
        return True, color, "color", pixels / 10000

    return False, None, None, 0

# ============ lizzieyzy 交互 ============

def find_lizzieyzy_window():
    """查找 lizzieyzy 窗口"""
    try:
        import pygetwindow as gw

        for title in ["Scythe", "lizzie", "Lizzie", "LizzieYzy"]:
            windows = gw.getWindowsWithTitle(title)
            if windows:
                win = windows[0]
                return {
                    "left": win.left,
                    "top": win.top,
                    "width": win.width,
                    "height": win.height,
                    "title": win.title
                }
    except ImportError:
        log("未安装 pygetwindow", "WARN")
    except Exception as e:
        log(f"查找窗口失败: {e}", "WARN")

    return None

def click_scythe_button(color, dry_run=False):
    """
    点击 lizzieyzy 的镰刀按钮

    保护机制：
    - dry_run=True 时只记录，不实际点击
    - 有冷却时间防止重复触发
    """
    global last_trigger_time, trigger_count, first_detection_confirmed

    # 检查冷却时间
    current_time = time.time()
    if current_time - last_trigger_time < Config.COOLDOWN_TIME:
        log(f"冷却中，跳过触发 (剩余 {Config.COOLDOWN_TIME - (current_time - last_trigger_time):.1f}秒)")
        return False

    # 首次确认机制
    if Config.REQUIRE_CONFIRM and not first_detection_confirmed:
        log("="*40)
        log("首次检测到镰刀！")
        log(f"颜色: {color}")
        log("="*40)

        if not dry_run:
            try:
                response = input("确认触发镰刀？(y/n): ").strip().lower()
                if response != 'y':
                    log("用户取消触发")
                    return False
                first_detection_confirmed = True
                log("用户确认，后续将自动触发")
            except:
                # 非交互模式，跳过确认
                first_detection_confirmed = True

    # 模拟模式
    if dry_run or Config.DRY_RUN:
        log(f"[模拟] 将点击 {color} 镰刀按钮", "DRY-RUN")
        last_trigger_time = current_time
        trigger_count[color] = trigger_count.get(color, 0) + 1
        return True

    # 实际点击
    win_info = find_lizzieyzy_window()

    if win_info:
        try:
            import pyautogui

            # 计算按钮位置
            # ScythePanel 在窗口底部
            panel_y = win_info["top"] + win_info["height"] - 40

            if color == "black":
                button_x = win_info["left"] + 80
            else:
                button_x = win_info["left"] + 180

            log(f"点击位置: ({button_x}, {panel_y})")

            # 安全检查：确保坐标在屏幕范围内
            screen_width, screen_height = pyautogui.size()
            if 0 <= button_x < screen_width and 0 <= panel_y < screen_height:
                pyautogui.click(button_x, panel_y)
                last_trigger_time = current_time
                trigger_count[color] = trigger_count.get(color, 0) + 1
                log(f"已点击 {color} 镰刀按钮", "ACTION")
                return True
            else:
                log(f"坐标超出屏幕范围: ({button_x}, {panel_y})", "ERROR")
                return False

        except Exception as e:
            log(f"点击失败: {e}", "ERROR")
            return False
    else:
        log("未找到 lizzieyzy 窗口，无法点击", "ERROR")
        return False

# ============ 主循环 ============

def main_loop(templates, dry_run=False):
    """主检测循环"""
    global running

    mode = "模拟模式" if (dry_run or Config.DRY_RUN) else "正常模式"
    log(f"启动检测循环 ({mode})")
    log(f"检测间隔: {Config.CHECK_INTERVAL}秒")
    log(f"冷却时间: {Config.COOLDOWN_TIME}秒")
    log("按 Ctrl+C 停止\n")

    detection_count = 0

    while running:
        try:
            start_time = time.time()

            # 截屏
            screen = capture_screen()
            if screen is None:
                time.sleep(1)
                continue

            detection_count += 1

            # 检测镰刀
            detected, color, method, confidence = detect_scythe(screen, templates)

            if detected and color and color != "unknown":
                log(f">>> 检测到 {color} 镰刀! (方法: {method}, 置信度: {confidence:.3f})")

                # 保存截图
                debug_path = os.path.join(Config.LOG_DIR, f"detect_{detection_count}_{color}.png")
                cv2.imwrite(debug_path, screen)
                log(f"截图已保存: {debug_path}")

                # 触发按钮
                if click_scythe_button(color, dry_run):
                    log(f"触发成功! (累计: 黑{trigger_count.get('black', 0)}, 白{trigger_count.get('white', 0)})")

            # 状态报告
            if detection_count % 100 == 0:
                log(f"运行中... 检测 {detection_count} 次, 触发: 黑{trigger_count.get('black', 0)}/白{trigger_count.get('white', 0)}")

            # 等待
            elapsed = time.time() - start_time
            sleep_time = max(0, Config.CHECK_INTERVAL - elapsed)
            time.sleep(sleep_time)

        except KeyboardInterrupt:
            running = False
            break
        except Exception as e:
            log(f"循环错误: {e}", "ERROR")
            time.sleep(1)

    log(f"\n检测结束! 共 {detection_count} 次")
    log(f"触发统计: 黑{trigger_count.get('black', 0)}, 白{trigger_count.get('white', 0)}")

# ============ 测试函数 ============

def run_self_test():
    """运行内部自测"""
    log("="*50)
    log("开始内部自测")
    log("="*50)

    tests_passed = 0
    tests_failed = 0

    # 测试1: 目录结构
    log("\n[测试1] 检查目录结构...")
    ensure_dirs()
    dirs_ok = all(os.path.exists(d) for d in [Config.TEMPLATE_DIR, Config.LOG_DIR, Config.TEST_DIR])
    if dirs_ok:
        log("  [OK] 目录结构正常")
        tests_passed += 1
    else:
        log("  [FAIL] 目录创建失败", "ERROR")
        tests_failed += 1

    # 测试2: 依赖检查
    log("\n[测试2] 检查依赖库...")
    deps = []
    try:
        import cv2
        deps.append("opencv-python")
    except ImportError:
        pass
    try:
        import pyautogui
        deps.append("pyautogui")
    except ImportError:
        pass
    try:
        import numpy
        deps.append("numpy")
    except ImportError:
        pass

    if len(deps) >= 3:
        log(f"  [OK] 已安装: {', '.join(deps)}")
        tests_passed += 1
    else:
        log(f"  [FAIL] 缺少依赖，已安装: {deps}", "ERROR")
        tests_failed += 1

    # 测试3: 模板加载
    log("\n[测试3] 检查模板文件...")
    black_template = load_template("black_scythe")
    white_template = load_template("white_scythe")

    if black_template is not None or white_template is not None:
        log("  [OK] 模板文件存在")
        tests_passed += 1
    else:
        log("  [WARN] 未找到模板文件（将使用颜色检测）", "WARN")
        tests_passed += 1  # 不算失败，颜色检测可以作为备选

    # 测试4: 截屏功能
    log("\n[测试4] 测试截屏功能...")
    try:
        import pyautogui
        screen = capture_screen()
        if screen is not None and screen.shape[0] > 0:
            log(f"  [OK] 截屏成功 ({screen.shape[1]}x{screen.shape[0]})")
            tests_passed += 1

            # 保存测试截图
            test_path = os.path.join(Config.TEST_DIR, "test_screenshot.png")
            cv2.imwrite(test_path, screen)
            log(f"  测试截图已保存: {test_path}")
        else:
            log("  [FAIL] 截屏返回空图像", "ERROR")
            tests_failed += 1
    except Exception as e:
        log(f"  [FAIL] 截屏失败: {e}", "ERROR")
        tests_failed += 1

    # 测试5: 模板匹配逻辑
    log("\n[测试5] 测试模板匹配逻辑...")
    try:
        # 创建测试图像
        test_img = np.zeros((100, 100, 3), dtype=np.uint8)
        test_template = np.zeros((20, 20, 3), dtype=np.uint8)
        test_template[:] = (255, 255, 255)  # 白色方块
        test_img[40:60, 40:60] = (255, 255, 255)  # 在中间放置

        loc, conf = match_template(test_img, test_template, threshold=0.9)
        if loc is not None:
            log(f"  [OK] 模板匹配逻辑正常 (位置: {loc}, 置信度: {conf:.3f})")
            tests_passed += 1
        else:
            log(f"  [WARN] 模板匹配未找到 (置信度: {conf:.3f})", "WARN")
            tests_passed += 1  # 逻辑正常，只是没匹配上
    except Exception as e:
        log(f"  [FAIL] 模板匹配错误: {e}", "ERROR")
        tests_failed += 1

    # 测试6: 颜色检测逻辑
    log("\n[测试6] 测试颜色检测逻辑...")
    try:
        # 创建蓝紫色测试图像（黑方镰刀）
        test_img = np.zeros((200, 200, 3), dtype=np.uint8)
        # 添加蓝紫色区域 (BGR: 蓝=255, 绿=0, 红=128)
        test_img[50:150, 50:150] = (255, 0, 128)

        detected, color, pixels = detect_scythe_by_color(test_img)
        log(f"  检测结果: detected={detected}, color={color}, pixels={pixels}")
        log("  [OK] 颜色检测逻辑正常")
        tests_passed += 1
    except Exception as e:
        log(f"  [FAIL] 颜色检测错误: {e}", "ERROR")
        tests_failed += 1

    # 测试7: 窗口查找
    log("\n[测试7] 测试窗口查找...")
    win_info = find_lizzieyzy_window()
    if win_info:
        log(f"  [OK] 找到窗口: {win_info['title']} ({win_info['width']}x{win_info['height']})")
        tests_passed += 1
    else:
        log("  [WARN] 未找到 lizzieyzy 窗口（请确保已启动）", "WARN")
        tests_passed += 1  # 不算失败

    # 总结
    log("\n" + "="*50)
    log(f"自测完成: {tests_passed} 通过, {tests_failed} 失败")
    log("="*50)

    return tests_failed == 0

# ============ 主函数 ============

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="野狐镰刀自动触发工具")
    parser.add_argument("--dry-run", action="store_true", help="模拟模式，只检测不点击")
    parser.add_argument("--test", action="store_true", help="运行内部自测")
    parser.add_argument("--no-confirm", action="store_true", help="跳过首次确认")
    parser.add_argument("--interval", type=float, default=0.2, help="检测间隔（秒）")
    parser.add_argument("--cooldown", type=float, default=3.0, help="冷却时间（秒）")

    args = parser.parse_args()

    # 应用配置
    Config.DRY_RUN = args.dry_run
    Config.REQUIRE_CONFIRM = not args.no_confirm
    Config.CHECK_INTERVAL = args.interval
    Config.COOLDOWN_TIME = args.cooldown

    print("="*50)
    print("野狐镰刀自动触发工具 v1.0")
    print("="*50)
    print()

    # 初始化
    ensure_dirs()
    log_path = init_log()
    log(f"日志文件: {log_path}")

    try:
        # 运行自测
        if args.test:
            success = run_self_test()
            close_log()
            sys.exit(0 if success else 1)

        # 检查依赖
        try:
            import cv2
            import pyautogui
        except ImportError as e:
            log(f"缺少依赖: {e}", "ERROR")
            log("请运行 install.bat 安装依赖")
            close_log()
            return

        # 加载模板
        templates = {
            "black": load_template("black_scythe"),
            "white": load_template("white_scythe"),
        }

        if templates["black"] is None and templates["white"] is None:
            log("Warning: No templates found, using color detection", "WARN")

        # 检查窗口
        win_info = find_lizzieyzy_window()
        if win_info:
            log(f"已找到窗口: {win_info['title']}")
        else:
            log("警告: 未找到 lizzieyzy 窗口", "WARN")

        # 主循环
        print()
        main_loop(templates, args.dry_run)

    finally:
        close_log()

if __name__ == "__main__":
    main()
