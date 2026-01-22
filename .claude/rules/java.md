# Java 开发规范

paths:
  - lizzieyzy-main/**

---

## 代码规范

- **缩进**：4 空格
- **Java 版本**：8+

## 编译命令

```batch
cd /d D:\ScytheKatago\lizzieyzy-main
mvn package -DskipTests
```

**输出**：`target/lizzie-yzy2.5.3-shaded.jar`

## 启动 GUI

```batch
cd /d D:\ScytheKatago\scythe_lizzie
start_scythe_lizzie.bat
```

## 关键文件

- `ScythePanel.java` - 镰刀状态显示面板
- `ScytheDetector.java` - 镰刀检测逻辑
