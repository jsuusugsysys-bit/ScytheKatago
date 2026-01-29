package featurecat.lizzie.gui;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import javax.swing.Timer;

/**
 * 镰刀自动检测器 - 检测野狐游戏窗口的镰刀提示 Scythe Auto Detector - Detects scythe prompts in Fox Weiqi game window
 *
 * <p>使用屏幕截图 + 像素模板匹配，自动识别"黑方镰刀"/"白方镰刀"提示
 */
public class ScytheDetector {

  // 检测间隔 (毫秒)
  private static final int DETECTION_INTERVAL = 500;

  // 模板匹配阈值 (0-1)
  private static final double MATCH_THRESHOLD = 0.85;

  // 颜色容差 (RGB 各通道)
  private static final int COLOR_TOLERANCE = 30;

  // 冷却时间 (毫秒)
  private static final long COOLDOWN_MS = 3000;

  // 连续匹配次数要求
  private static final int CONSECUTIVE_MATCHES_REQUIRED = 2;

  // 降采样因子 (加速搜索)
  private static final int DOWNSAMPLE_FACTOR = 2;

  // 状态
  private boolean enabled = false;
  private Timer detectionTimer;
  private Robot robot;

  // 模板图片
  private BufferedImage blackTemplate;
  private BufferedImage whiteTemplate;

  // 连续匹配计数
  private int blackConsecutiveMatches = 0;
  private int whiteConsecutiveMatches = 0;

  // 冷却时间戳
  private long lastBlackTriggerTime = 0;
  private long lastWhiteTriggerTime = 0;

  // 回调引用
  private ScythePanel scythePanel;

  public ScytheDetector() {
    try {
      robot = new Robot();
    } catch (AWTException e) {
      System.err.println("ScytheDetector: Failed to create Robot - " + e.getMessage());
      return;
    }

    // 加载模板图片
    loadTemplates();

    // 初始化检测定时器
    detectionTimer =
        new Timer(
            DETECTION_INTERVAL,
            e -> {
              if (enabled) {
                performDetection();
              }
            });
  }

  /** 加载模板图片 */
  private void loadTemplates() {
    // 尝试多个可能的路径
    String[] basePaths = {
      "tools/templates/",
      "../tools/templates/",
      "D:/ScytheKatago/tools/templates/",
      System.getProperty("user.dir") + "/tools/templates/"
    };

    for (String basePath : basePaths) {
      File blackFile = new File(basePath + "black_scythe.png");
      File whiteFile = new File(basePath + "white_scythe.png");

      if (blackFile.exists() && whiteFile.exists()) {
        try {
          blackTemplate = ImageIO.read(blackFile);
          whiteTemplate = ImageIO.read(whiteFile);
          System.err.println("ScytheDetector: Templates loaded from " + basePath);
          return;
        } catch (IOException e) {
          System.err.println("ScytheDetector: Failed to load templates - " + e.getMessage());
        }
      }
    }

    System.err.println(
        "ScytheDetector: Template files not found. Please place black_scythe.png and white_scythe.png in tools/templates/");
  }

  /**
   * 设置 ScythePanel 引用
   *
   * @param panel ScythePanel 实例
   */
  public void setScythePanel(ScythePanel panel) {
    this.scythePanel = panel;
  }

  /**
   * 设置检测开关
   *
   * @param enabled 是否启用
   */
  public void setEnabled(boolean enabled) {
    this.enabled = enabled;
    if (enabled) {
      if (blackTemplate == null || whiteTemplate == null) {
        System.err.println("ScytheDetector: Cannot enable - templates not loaded");
        this.enabled = false;
        return;
      }
      detectionTimer.start();
      System.err.println("ScytheDetector: Detection enabled");
    } else {
      detectionTimer.stop();
      resetConsecutiveMatches();
      System.err.println("ScytheDetector: Detection disabled");
    }
  }

  /** 切换检测状态 */
  public void toggle() {
    setEnabled(!enabled);
  }

  /**
   * 获取当前状态
   *
   * @return 是否启用
   */
  public boolean isEnabled() {
    return enabled;
  }

  /** 执行检测 */
  private void performDetection() {
    if (robot == null || blackTemplate == null || whiteTemplate == null) {
      return;
    }

    // 截取全屏
    Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
    Rectangle screenRect = new Rectangle(screenSize);
    BufferedImage screenshot = robot.createScreenCapture(screenRect);

    // 检测黑方镰刀
    if (matchTemplate(screenshot, blackTemplate)) {
      blackConsecutiveMatches++;
      System.err.println(
          "ScytheDetector: Black template match "
              + blackConsecutiveMatches
              + "/"
              + CONSECUTIVE_MATCHES_REQUIRED);
      if (blackConsecutiveMatches >= CONSECUTIVE_MATCHES_REQUIRED) {
        if (canTriggerBlack()) {
          triggerBlackScythe();
        }
        blackConsecutiveMatches = 0;
      }
    } else {
      blackConsecutiveMatches = 0;
    }

    // 检测白方镰刀
    if (matchTemplate(screenshot, whiteTemplate)) {
      whiteConsecutiveMatches++;
      System.err.println(
          "ScytheDetector: White template match "
              + whiteConsecutiveMatches
              + "/"
              + CONSECUTIVE_MATCHES_REQUIRED);
      if (whiteConsecutiveMatches >= CONSECUTIVE_MATCHES_REQUIRED) {
        if (canTriggerWhite()) {
          triggerWhiteScythe();
        }
        whiteConsecutiveMatches = 0;
      }
    } else {
      whiteConsecutiveMatches = 0;
    }
  }

  /**
   * 模板匹配
   *
   * @param screen 屏幕截图
   * @param template 模板图片
   * @return 是否匹配
   */
  private boolean matchTemplate(BufferedImage screen, BufferedImage template) {
    int screenWidth = screen.getWidth();
    int screenHeight = screen.getHeight();
    int templateWidth = template.getWidth();
    int templateHeight = template.getHeight();

    // 确保模板不大于屏幕
    if (templateWidth > screenWidth || templateHeight > screenHeight) {
      return false;
    }

    // 降采样后的尺寸
    int dsScreenWidth = screenWidth / DOWNSAMPLE_FACTOR;
    int dsScreenHeight = screenHeight / DOWNSAMPLE_FACTOR;
    int dsTemplateWidth = templateWidth / DOWNSAMPLE_FACTOR;
    int dsTemplateHeight = templateHeight / DOWNSAMPLE_FACTOR;

    // 搜索步长
    int stepX = DOWNSAMPLE_FACTOR * 4; // 每次跳过几个像素
    int stepY = DOWNSAMPLE_FACTOR * 4;

    // 遍历屏幕位置
    for (int y = 0; y <= screenHeight - templateHeight; y += stepY) {
      for (int x = 0; x <= screenWidth - templateWidth; x += stepX) {
        double similarity = calculateSimilarity(screen, template, x, y);
        if (similarity >= MATCH_THRESHOLD) {
          System.err.println(
              "ScytheDetector: Match found at ("
                  + x
                  + ", "
                  + y
                  + ") with similarity "
                  + String.format("%.2f", similarity));
          return true;
        }
      }
    }

    return false;
  }

  /**
   * 计算相似度
   *
   * @param screen 屏幕截图
   * @param template 模板图片
   * @param offsetX 偏移 X
   * @param offsetY 偏移 Y
   * @return 相似度 (0-1)
   */
  private double calculateSimilarity(
      BufferedImage screen, BufferedImage template, int offsetX, int offsetY) {

    int templateWidth = template.getWidth();
    int templateHeight = template.getHeight();

    // 采样检查 (不检查每个像素，加速)
    int sampleStep = DOWNSAMPLE_FACTOR;
    int matchCount = 0;
    int totalCount = 0;

    for (int ty = 0; ty < templateHeight; ty += sampleStep) {
      for (int tx = 0; tx < templateWidth; tx += sampleStep) {
        int screenX = offsetX + tx;
        int screenY = offsetY + ty;

        if (screenX >= screen.getWidth() || screenY >= screen.getHeight()) {
          continue;
        }

        int screenPixel = screen.getRGB(screenX, screenY);
        int templatePixel = template.getRGB(tx, ty);

        // 跳过透明像素
        int templateAlpha = (templatePixel >> 24) & 0xFF;
        if (templateAlpha < 128) {
          continue;
        }

        totalCount++;
        if (pixelsMatch(screenPixel, templatePixel)) {
          matchCount++;
        }
      }
    }

    if (totalCount == 0) {
      return 0;
    }

    return (double) matchCount / totalCount;
  }

  /**
   * 检查两个像素是否匹配 (考虑颜色容差)
   *
   * @param pixel1 像素1
   * @param pixel2 像素2
   * @return 是否匹配
   */
  private boolean pixelsMatch(int pixel1, int pixel2) {
    int r1 = (pixel1 >> 16) & 0xFF;
    int g1 = (pixel1 >> 8) & 0xFF;
    int b1 = pixel1 & 0xFF;

    int r2 = (pixel2 >> 16) & 0xFF;
    int g2 = (pixel2 >> 8) & 0xFF;
    int b2 = pixel2 & 0xFF;

    return Math.abs(r1 - r2) <= COLOR_TOLERANCE
        && Math.abs(g1 - g2) <= COLOR_TOLERANCE
        && Math.abs(b1 - b2) <= COLOR_TOLERANCE;
  }

  /** 检查是否可以触发黑方镰刀 (冷却检查) */
  private boolean canTriggerBlack() {
    long now = System.currentTimeMillis();
    return (now - lastBlackTriggerTime) >= COOLDOWN_MS;
  }

  /** 检查是否可以触发白方镰刀 (冷却检查) */
  private boolean canTriggerWhite() {
    long now = System.currentTimeMillis();
    return (now - lastWhiteTriggerTime) >= COOLDOWN_MS;
  }

  /** 触发黑方镰刀 */
  private void triggerBlackScythe() {
    System.err.println("ScytheDetector: Triggering BLACK scythe");
    lastBlackTriggerTime = System.currentTimeMillis();

    // 判断是否是 AI 方的镰刀
    boolean isAi =
        LizzieFrame.toolbar.isAutoPlay && LizzieFrame.toolbar.chkAutoPlayBlack.isSelected();
    System.err.println("ScytheDetector: Black scythe isAi=" + isAi);

    if (scythePanel != null) {
      scythePanel.triggerScythe("black", isAi);
    } else if (LizzieFrame.scythePanel != null) {
      LizzieFrame.scythePanel.triggerScythe("black", isAi);
    }
  }

  /** 触发白方镰刀 */
  private void triggerWhiteScythe() {
    System.err.println("ScytheDetector: Triggering WHITE scythe");
    lastWhiteTriggerTime = System.currentTimeMillis();

    // 判断是否是 AI 方的镰刀
    boolean isAi =
        LizzieFrame.toolbar.isAutoPlay && LizzieFrame.toolbar.chkAutoPlayWhite.isSelected();
    System.err.println("ScytheDetector: White scythe isAi=" + isAi);

    if (scythePanel != null) {
      scythePanel.triggerScythe("white", isAi);
    } else if (LizzieFrame.scythePanel != null) {
      LizzieFrame.scythePanel.triggerScythe("white", isAi);
    }
  }

  /** 重置连续匹配计数 */
  private void resetConsecutiveMatches() {
    blackConsecutiveMatches = 0;
    whiteConsecutiveMatches = 0;
  }

  /** 停止检测器 */
  public void shutdown() {
    if (detectionTimer != null) {
      detectionTimer.stop();
    }
    enabled = false;
  }

  /**
   * 检查模板是否已加载
   *
   * @return 模板是否可用
   */
  public boolean isTemplatesLoaded() {
    return blackTemplate != null && whiteTemplate != null;
  }
}
