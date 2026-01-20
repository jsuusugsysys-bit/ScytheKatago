调试 KataGo 或镰刀功能问题：

1. 收集问题信息：
   - 用户描述的现象
   - 相关的 GTP 命令序列
   - 错误输出或异常行为

2. 定位问题：
   - 检查 gtp.cpp 中的命令处理
   - 检查 boardhistory.cpp 中的状态管理
   - 检查 search.cpp 中的玩家切换逻辑

3. 添加调试输出（注意必须用 stderr）：
   ```cpp
   std::cerr << "DEBUG: variable=" << value << std::endl;
   ```

4. 关键调试点：
   - `kata-set-param scythe_trigger` 处理
   - `makeBoardMoveAssumeLegal` 中的镰刀检测
   - `presumedNextMovePla` 计算逻辑

5. 验证修复并清理调试代码
