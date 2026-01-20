分析并修复编译错误或运行时错误：

1. 如果用户提供了错误信息，直接分析
2. 否则尝试编译项目获取错误：
   ```
   cd D:\ScytheKatago\KataGo\cpp\build
   MSBuild katago.sln /p:Configuration=Release /m /v:minimal
   ```
3. 解析错误信息：
   - 定位出错的文件和行号
   - 理解错误类型（语法错误、类型错误、链接错误等）
4. 读取相关代码上下文
5. 提出修复方案并实施
6. 重新编译验证修复是否成功
7. 如果是括号不匹配等结构性错误，检查周围的代码缩进
