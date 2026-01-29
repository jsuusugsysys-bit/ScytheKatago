# 镰刀检测功能测试指南

## 测试步骤

### 1. 准备模板图片
从野狐截取镰刀提示图片：
- `black_scythe.png` - 黑方镰刀提示区域
- `white_scythe.png` - 白方镰刀提示区域

截图建议：
- 只截取提示文字/图标区域，不要包含太多背景
- 保持原始分辨率，不要缩放
- 保存为 PNG 格式

### 2. 启动测试

```batch
cd /d D:\ScytheKatago\lizzieyzy-main\target
java -jar lizzie-yzy2.5.3-shaded.jar
```

### 3. 开启检测
- 点击界面上的 `[自动:关]` 切换为 `[自动:开]`
- 观察控制台输出

### 4. 测试检测
方法一：打开模板图片全屏显示
方法二：打开野狐进入镰刀对局

### 5. 预期输出
```
ScytheDetector: Templates loaded from tools/templates/
ScytheDetector: Detection enabled
ScytheDetector: Black template match 1/2
ScytheDetector: Black template match 2/2
ScytheDetector: Match found at (x, y) with similarity 0.87
ScytheDetector: Triggering BLACK scythe
```

## 常见问题

### 检测不到？
1. 确认模板图片路径正确
2. 尝试调整截图区域
3. 检查 ScytheDetector.java 中的阈值参数

### 误触发？
1. 截取更精确的模板区域
2. 提高 MATCH_THRESHOLD（默认 0.85）
3. 增加 CONSECUTIVE_MATCHES_REQUIRED（默认 2）
