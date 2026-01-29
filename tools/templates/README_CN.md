# 镰刀自动检测模板

此目录存放野狐镰刀提示的模板图片，用于自动检测。

## 需要的文件

1. **black_scythe.png** - 黑方镰刀提示截图
   - 从野狐游戏中截取"黑方镰刀"提示区域
   - 保持原始分辨率，不要缩放
   - 尽量只包含提示文字/图标，去除多余背景

2. **white_scythe.png** - 白方镰刀提示截图
   - 从野狐游戏中截取"白方镰刀"提示区域
   - 与黑方模板保持相同的截取方式

## 截图方法

1. 在野狐中开始一局镰刀对局
2. 等待镰刀提示出现
3. 使用截图工具（如 Windows 截图、Snipping Tool）截取提示区域
4. 保存为 PNG 格式

## 检测参数

- **检测间隔**: 500ms
- **匹配阈值**: 85%
- **颜色容差**: RGB 各 30
- **连续匹配**: 需要连续 2 帧检测到才触发
- **冷却时间**: 触发后 3 秒内不再触发同色镰刀

## 调试

启用自动检测后，控制台（stderr）会输出匹配日志：

```
ScytheDetector: Black template match 1/2
ScytheDetector: Black template match 2/2
ScytheDetector: Match found at (x, y) with similarity 0.92
ScytheDetector: Triggering BLACK scythe
```

如果检测不稳定，可尝试：
1. 重新截取更清晰的模板
2. 调整 ScytheDetector.java 中的参数
