@echo off
chcp 65001 >nul
echo ========================================
echo 镰刀分析模式测试
echo ========================================
echo.
echo 测试步骤：
echo 1. lizzieyzy 会自动启动
echo 2. 新建 11x11 对局
echo 3. 手动下棋到第 11 手
echo 4. 点击黑色镰刀图标 ●
echo 5. 观察 AI 是否连续计算并显示 3 手黑子
echo.
echo 预期结果：
echo - GUI 显示 [黑连3手] → [黑连2手] → [黑连1手]
echo - 棋盘上自动显示 3 手黑子落点
echo - 黑方镰刀次数从 3 减为 2
echo.
echo 日志位置：
echo - scythe_lizzie\lizzieyzy_debug.log
echo - scythe_lizzie\gtp_logs\最新日志.log
echo.
pause
echo.
echo 启动 lizzieyzy...
cd /d D:\ScytheKatago\scythe_lizzie
start javaw -jar lizzie-yzy2.5.3-shaded.jar
echo.
echo lizzieyzy 已启动，请按上述步骤测试
echo 测试完成后按任意键关闭此窗口
pause >nul
