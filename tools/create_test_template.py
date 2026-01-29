"""
创建测试用的镰刀模板图片
运行: python create_test_template.py
"""
from PIL import Image, ImageDraw, ImageFont

def create_template(filename, text, bg_color, text_color):
    # 创建 200x60 的图片
    img = Image.new('RGB', (200, 60), bg_color)
    draw = ImageDraw.Draw(img)

    # 尝试使用系统字体
    try:
        font = ImageFont.truetype("msyh.ttc", 32)  # 微软雅黑
    except:
        try:
            font = ImageFont.truetype("simsun.ttc", 32)  # 宋体
        except:
            font = ImageFont.load_default()

    # 绘制文字
    draw.text((20, 10), text, fill=text_color, font=font)

    # 保存
    img.save(filename)
    print(f"已创建: {filename}")

if __name__ == "__main__":
    # 黑方镰刀 - 黑底白字
    create_template(
        "templates/black_scythe.png",
        "黑方镰刀",
        (30, 30, 30),      # 深灰背景
        (255, 255, 255)    # 白色文字
    )

    # 白方镰刀 - 白底黑字
    create_template(
        "templates/white_scythe.png",
        "白方镰刀",
        (240, 240, 240),   # 浅灰背景
        (0, 0, 0)          # 黑色文字
    )

    print("\n测试方法:")
    print("1. 启动 lizzieyzy")
    print("2. 点击 [自动:关] 开启检测")
    print("3. 全屏显示 black_scythe.png 或 white_scythe.png")
    print("4. 观察控制台输出")
