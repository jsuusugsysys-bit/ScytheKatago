# 启动镰刀版 lizzieyzy

**重要**: 每次启动 lizzieyzy 都必须使用以下配置！

## 必须执行的启动命令

```bash
cd "D:/ScytheKatago/scythe_lizzie" && "D:/ScytheKatago/java-1.8.0-openjdk-1.8.0.392-1.b08.redhat.windows.x86_64/bin/java.exe" -jar "D:/ScytheKatago/lizzieyzy-main/target/lizzie-yzy2.5.3-shaded.jar" &
```

## 配置说明

**工作目录必须是** `D:/ScytheKatago/scythe_lizzie`（不是项目根目录！）

**配置文件** `scythe_lizzie/config.txt` 已预配置：
- 引擎名称: KataGo Scythe 28b
- 引擎命令: `D:/ScytheKatago/KataGo/cpp/build/Release/katago.exe gtp -model D:/2025-05-19-win64-RTX50XX特供版/weights/28b.bin.gz -config D:/ScytheKatago/scythe_config.cfg`
- 棋盘: 11x11
- 贴目: 7.5
- 预加载: true（自动启动引擎）
- 默认引擎: true

## 执行步骤

1. 在后台启动 lizzieyzy（使用上面的命令）
2. 告诉用户：
   - lizzieyzy 已启动
   - 引擎会自动加载（预加载=true）
   - 棋盘是 11x11（镰刀规则）

## 如果引擎未自动加载

检查 `scythe_lizzie/config.txt` 中的 `engine-settings-list` 是否包含：
- `"preload": true`
- `"isDefault": true`
- `"width": 11, "height": 11`

## 镰刀功能

- 左侧镰刀面板显示：黑●3 白○3
- 点击图标可手动触发镰刀
- 工具菜单中有"棋盘同步工具"用于野狐自动检测
