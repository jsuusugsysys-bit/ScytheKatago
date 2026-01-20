编译 lizzieyzy 并启动进行调试：

1. 编译 lizzieyzy（如果 Java 文件有改动）：
   ```batch
   cd /d d:\ScytheKatago\lizzieyzy-main
   mvn package -DskipTests -q
   ```

2. 启动 lizzieyzy：
   ```batch
   cd /d d:\ScytheKatago\lizzieyzy-main\target
   java -jar lizzie-yzy2.5.3-shaded.jar
   ```

3. 调试提示：
   - 11x11 棋盘 + 第 11-49 手才能使用镰刀
   - 点击镰刀按钮触发连续 3 步
   - 观察 GTP 控制台的 stderr 输出
