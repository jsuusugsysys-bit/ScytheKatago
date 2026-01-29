# 野狐镰刀录屏工具
# 使用方法：
# 1. 安装依赖：pip install opencv-python pyautogui pillow
# 2. 运行：python screen_recorder.py
# 3. 按 F9 开始/停止录制
# 4. 按 F10 退出程序

import cv2
import numpy as np
import pyautogui
import time
import os
from datetime import datetime
import threading

# 配置
OUTPUT_DIR = r"D:\ScytheKatago\recordings"
FPS = 10  # 帧率（10帧足够分析，文件也小）
RECORDING = False
RUNNING = True

def ensure_dir():
    """确保输出目录存在"""
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        print(f"创建录制目录: {OUTPUT_DIR}")

def record_screen():
    """录制屏幕"""
    global RECORDING, RUNNING

    ensure_dir()

    # 获取屏幕尺寸
    screen_size = pyautogui.size()
    print(f"屏幕尺寸: {screen_size.width} x {screen_size.height}")

    writer = None
    filename = ""
    frame_count = 0

    print("\n" + "="*50)
    print("野狐镰刀录屏工具")
    print("="*50)
    print("按 F9  = 开始/停止录制")
    print("按 F10 = 退出程序")
    print("="*50 + "\n")
    print("等待开始录制...")

    while RUNNING:
        if RECORDING:
            # 截屏
            screenshot = pyautogui.screenshot()
            frame = np.array(screenshot)
            frame = cv2.cvtColor(frame, cv2.COLOR_RGB2BGR)

            # 如果还没创建视频写入器，创建一个
            if writer is None:
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                filename = os.path.join(OUTPUT_DIR, f"yehu_{timestamp}.mp4")
                fourcc = cv2.VideoWriter_fourcc(*'mp4v')
                writer = cv2.VideoWriter(filename, fourcc, FPS,
                                        (screen_size.width, screen_size.height))
                print(f"\n开始录制: {filename}")
                frame_count = 0

            writer.write(frame)
            frame_count += 1

            # 每秒显示一次进度
            if frame_count % FPS == 0:
                seconds = frame_count // FPS
                print(f"录制中... {seconds} 秒", end='\r')

        else:
            # 停止录制时，保存文件
            if writer is not None:
                writer.release()
                print(f"\n录制完成! 保存到: {filename}")
                print(f"总帧数: {frame_count}, 时长约 {frame_count/FPS:.1f} 秒")
                print("\n等待下次录制...")
                writer = None

        # 控制帧率
        time.sleep(1.0 / FPS)

    # 退出时保存
    if writer is not None:
        writer.release()
        print(f"\n录制完成! 保存到: {filename}")

def key_listener():
    """监听键盘"""
    global RECORDING, RUNNING

    try:
        import keyboard

        def on_f9():
            global RECORDING
            RECORDING = not RECORDING
            if RECORDING:
                print("\n>>> 开始录制! <<<")
            else:
                print("\n>>> 停止录制! <<<")

        def on_f10():
            global RUNNING, RECORDING
            RECORDING = False
            RUNNING = False
            print("\n>>> 退出程序 <<<")

        keyboard.on_press_key('f9', lambda _: on_f9())
        keyboard.on_press_key('f10', lambda _: on_f10())

        # 保持监听
        while RUNNING:
            time.sleep(0.1)

    except ImportError:
        print("需要安装 keyboard 库: pip install keyboard")
        print("或者手动按 Ctrl+C 停止")

        # 简单模式：直接开始录制
        global RECORDING
        RECORDING = True
        try:
            while RUNNING:
                time.sleep(1)
        except KeyboardInterrupt:
            RECORDING = False
            RUNNING = False

def main():
    """主函数"""
    print("正在启动录屏工具...")

    # 检查依赖
    try:
        import cv2
        import pyautogui
    except ImportError as e:
        print(f"缺少依赖: {e}")
        print("\n请运行以下命令安装:")
        print("pip install opencv-python pyautogui pillow keyboard")
        return

    # 启动键盘监听线程
    listener_thread = threading.Thread(target=key_listener, daemon=True)
    listener_thread.start()

    # 主线程录屏
    record_screen()

    print("\n程序已退出")

if __name__ == "__main__":
    main()
