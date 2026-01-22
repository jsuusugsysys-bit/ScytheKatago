# GUI 调试验证 Skill

当涉及 GUI 界面、外部客户端交互、需要用户操作验证的功能时使用此 skill。

## 核心原则

1. **先加日志，后改逻辑** - 任何修改前先添加可见的调试输出
2. **用户能看到的反馈** - 弹窗、控制台输出、状态显示
3. **最小化用户描述负担** - 让程序自己报告状态

## 调试方法清单

### Java GUI 调试

```java
// 1. 弹窗显示关键信息（用户一定能看到）
javax.swing.JOptionPane.showMessageDialog(null, "调试信息: " + value);

// 2. 控制台输出（查看 lizzieyzy 控制台）
System.err.println("[DEBUG] 关键变量: " + value);

// 3. 状态栏/标签显示
label.setText("检测状态: " + status);
```

### 添加"测试按钮"

当功能复杂时，添加一个测试按钮让用户点击查看结果：
```java
JButton btnTest = new JButton("测试检测");
btnTest.addActionListener(e -> {
    String result = performDetection();
    JOptionPane.showMessageDialog(null, result);
});
```

### 文件日志

```java
// 写入日志文件，事后分析
try (PrintWriter pw = new PrintWriter(new FileWriter("debug.log", true))) {
    pw.println(LocalDateTime.now() + ": " + message);
}
```

## 当前项目：镰刀检测调试

### 需要验证的断点

1. **readboard 窗口是否显示** → 用户可直接观察
2. **镰刀检测区域是否设置** → 添加状态显示
3. **像素颜色值是否符合预期** → 添加测试按钮显示实际颜色值
4. **触发命令是否发送** → 添加弹窗确认

### 调试代码添加位置

| 文件 | 位置 | 添加内容 |
|------|------|---------|
| ToolFrame.java | detectScythe() | 显示检测到的像素比例 |
| ToolFrame.java | triggerScythe() | 弹窗确认触发 |
| ReadBoard.java | parseLine() | 打印收到的命令 |

## 执行步骤

1. 读取当前代码
2. 添加调试输出（弹窗/控制台）
3. 重新编译
4. 让用户测试并观察输出
5. 根据实际输出调整代码

## 迭代优化

- 一次只改一个地方
- 每次修改后立即测试
- 保留有用的调试代码（可用开关控制）
