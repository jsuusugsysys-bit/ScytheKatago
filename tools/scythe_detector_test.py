# 野狐镰刀识别测试工具
# 功能：后台监控屏幕，尝试识别镰刀提示，记录数据供分析
#
# 使用方法：
# 1. pip install opencv-python pyautogui pillow keyboard easyocr
# 2. python scythe_detector_test.py
# 3. 打开野狐下镰刀棋
# 4. 工具会自动检测并记录镰刀出现的截图和时间

import cv2
import numpy as np
import pyautogui
import time
import os
from datetime import datetime
import threading
import json

# ============ 配置 ============
OUTPUT_DIR = r"D:\ScytheKatago\test_data"
CHECK_INTERVAL = 0.2  # 检测间隔（秒），0.2秒=每秒5次
RUNNING = True

# 镰刀关键词（用于OCR检测）
SCYTHE_KEYWORDS = [
    "黑方镰刀", "白方镰刀",
    "本回合走3步", "走3步",
    "镰刀"
]

# ============ 工具函数 ============

def ensure_dir():
    """确保输出目录存在"""
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
    log_dir = os.path.join(OUTPUT_DIR, "logs")
    img_dir = os.path.join(OUTPUT_DIR, "screenshots")
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)
    if not os.path.exists(img_dir):
        os.makedirs(img_dir)
    return log_dir, img_dir

def get_timestamp():
    """获取时间戳"""
    return datetime.now().strftime("%Y%m%d_%H%M%S_%f")[:-3]

# ============ 方法1: 模板匹配 ============

def create_test_templates():
    """创建测试用的模板说明"""
    template_dir = os.path.join(OUTPUT_DIR, "templates")
    if not os.path.exists(template_dir):
        os.makedirs(template_dir)

    readme = """模板匹配说明
====================

请在这个文件夹放入以下截图：

1. black_scythe.png - 野狐"黑方镰刀"提示的截图（只截文字部分）
2. white_scythe.png - 野狐"白方镰刀"提示的截图（只截文字部分）
3. scythe_icon.png  - 镰刀图标的截图

截图方法：
1. 在野狐下棋时，等镰刀出现
2. 按 Win+Shift+S 截图
3. 只截取"黑方镰刀"或"白方镰刀"文字部分
4. 保存到这个文件夹

有了这些模板，识别会更准确更快！
"""
    with open(os.path.join(template_dir, "说明.txt"), "w", encoding="utf-8") as f:
        f.write(readme)

    return template_dir

def match_template(screen_img, template_path, threshold=0.8):
    """模板匹配"""
    if not os.path.exists(template_path):
        return None, 0

    template = cv2.imread(template_path)
    if template is None:
        return None, 0

    result = cv2.matchTemplate(screen_img, template, cv2.TM_CCOEFF_NORMED)
    min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(result)

    if max_val >= threshold:
        return max_loc, max_val
    return None, max_val

# ============ 方法2: OCR文字识别 ============

def init_ocr():
    """初始化OCR"""
    try:
        import easyocr
        reader = easyocr.Reader(['ch_sim', 'en'], gpu=False)
        print("OCR 初始化成功")
        return reader
    except ImportError:
        print("未安装 easyocr，跳过OCR检测")
        print("安装命令: pip install easyocr")
        return None
    except Exception as e:
        print(f"OCR 初始化失败: {e}")
        return None

def ocr_detect(reader, image):
    """OCR检测镰刀文字"""
    if reader is None:
        return []

    try:
        results = reader.readtext(image)
        detected = []
        for (bbox, text, prob) in results:
            for keyword in SCYTHE_KEYWORDS:
                if keyword in text:
                    detected.append({
                        "text": text,
                        "keyword": keyword,
                        "confidence": prob,
                        "bbox": bbox
                    })
        return detected
    except Exception as e:
        return []

# ============ 方法3: 颜色检测 ============

def detect_scythe_colors(image):
    """检测镰刀特征颜色（紫色镰刀图标、蓝色文字等）"""
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # 检测紫色（镰刀图标的颜色）
    purple_lower = np.array([120, 50, 50])
    purple_upper = np.array([150, 255, 255])
    purple_mask = cv2.inRange(hsv, purple_lower, purple_upper)
    purple_pixels = cv2.countNonZero(purple_mask)

    # 检测蓝色（"黑方镰刀"文字的颜色）
    blue_lower = np.array([100, 100, 100])
    blue_upper = np.array([130, 255, 255])
    blue_mask = cv2.inRange(hsv, blue_lower, blue_upper)
    blue_pixels = cv2.countNonZero(blue_mask)

    return {
        "purple_pixels": purple_pixels,
        "blue_pixels": blue_pixels,
        "total_pixels": image.shape[0] * image.shape[1]
    }

# ============ 主检测循环 ============

def detection_loop(ocr_reader, log_dir, img_dir, template_dir):
    """主检测循环"""
    global RUNNING

    detection_count = 0
    scythe_count = 0
    last_scythe_time = 0

    # 检测日志
    log_file = os.path.join(log_dir, f"detection_{get_timestamp()}.jsonl")

    print("\n" + "="*50)
    print("开始监控野狐屏幕...")
    print("按 Ctrl+C 停止")
    print("="*50 + "\n")

    with open(log_file, "w", encoding="utf-8") as f:
        while RUNNING:
            try:
                start_time = time.time()

                # 截屏
                screenshot = pyautogui.screenshot()
                screen_img = np.array(screenshot)
                screen_img = cv2.cvtColor(screen_img, cv2.COLOR_RGB2BGR)

                detection_count += 1
                result = {
                    "timestamp": get_timestamp(),
                    "detection_id": detection_count,
                    "scythe_detected": False,
                    "methods": {}
                }

                # 方法1: 模板匹配
                black_template = os.path.join(template_dir, "black_scythe.png")
                white_template = os.path.join(template_dir, "white_scythe.png")

                black_loc, black_conf = match_template(screen_img, black_template)
                white_loc, white_conf = match_template(screen_img, white_template)

                result["methods"]["template"] = {
                    "black": {"found": black_loc is not None, "confidence": black_conf},
                    "white": {"found": white_loc is not None, "confidence": white_conf}
                }

                if black_loc or white_loc:
                    result["scythe_detected"] = True
                    result["scythe_color"] = "black" if black_loc else "white"

                # 方法2: OCR (每2秒检测一次，因为比较慢)
                if detection_count % 10 == 0 and ocr_reader:
                    ocr_results = ocr_detect(ocr_reader, screen_img)
                    result["methods"]["ocr"] = ocr_results
                    if ocr_results:
                        result["scythe_detected"] = True

                # 方法3: 颜色检测
                color_result = detect_scythe_colors(screen_img)
                result["methods"]["color"] = color_result

                # 如果检测到镰刀
                if result["scythe_detected"]:
                    current_time = time.time()
                    # 避免重复记录（2秒内不重复）
                    if current_time - last_scythe_time > 2:
                        scythe_count += 1
                        last_scythe_time = current_time

                        # 保存截图
                        img_filename = f"scythe_{scythe_count}_{get_timestamp()}.png"
                        img_path = os.path.join(img_dir, img_filename)
                        cv2.imwrite(img_path, screen_img)
                        result["screenshot"] = img_filename

                        print(f"[{get_timestamp()}] 检测到镰刀! #{scythe_count} - 截图已保存")

                # 记录检测时间
                result["detection_time_ms"] = int((time.time() - start_time) * 1000)

                # 写入日志
                f.write(json.dumps(result, ensure_ascii=False) + "\n")
                f.flush()

                # 每100次检测报告一次
                if detection_count % 100 == 0:
                    print(f"已检测 {detection_count} 次，发现镰刀 {scythe_count} 次")

                # 等待下一次检测
                elapsed = time.time() - start_time
                sleep_time = max(0, CHECK_INTERVAL - elapsed)
                time.sleep(sleep_time)

            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"检测错误: {e}")
                time.sleep(1)

    print(f"\n检测结束！共检测 {detection_count} 次，发现镰刀 {scythe_count} 次")
    print(f"日志保存在: {log_file}")
    print(f"截图保存在: {img_dir}")

# ============ 主函数 ============

def main():
    global RUNNING

    print("="*50)
    print("野狐镰刀识别测试工具")
    print("="*50)

    # 创建目录
    log_dir, img_dir = ensure_dir()
    template_dir = create_test_templates()

    print(f"\n数据目录: {OUTPUT_DIR}")
    print(f"模板目录: {template_dir}")
    print(f"\n请先阅读 {template_dir}\\说明.txt")
    print("放入镰刀截图模板可以提高识别准确率\n")

    # 初始化OCR
    print("正在初始化OCR（可能需要下载模型，请稍候）...")
    ocr_reader = init_ocr()

    # 开始检测
    try:
        detection_loop(ocr_reader, log_dir, img_dir, template_dir)
    except KeyboardInterrupt:
        RUNNING = False
        print("\n用户中断")

if __name__ == "__main__":
    main()
