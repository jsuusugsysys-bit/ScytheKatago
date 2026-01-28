package featurecat.lizzie.gui;

import featurecat.lizzie.Lizzie;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;
import org.json.JSONObject;

/**
 * 镰刀状态面板 - 显示黑白双方的镰刀次数，点击触发镰刀 Scythe Status Panel - Shows scythe counts for both players, click to
 * trigger
 */
public class ScythePanel extends JPanel {

  // 镰刀状态
  private int blackScythes = 3;
  private int whiteScythes = 3;
  private int scytheCombo = 0;
  private boolean isComboActive = false;
  private String nextPlayer = "B";

  // GUI端的连击状态（用于同步判断，不依赖异步的引擎响应）
  private int guiComboRemaining = 0; // 剩余连击次数（0=不在连击中，1-3=连击中）
  private boolean guiComboPlayer = true; // 连击的玩家（true=黑棋，false=白棋）
  private boolean scythePending = false; // 镰刀待触发标志（点击后等待落子）
  private boolean scythePendingPlayer = true; // 待触发镰刀的玩家
  private boolean isAiScythe = false; // 是否是 AI 方的镰刀（用于连击处理）
  private boolean guiComboAuthority = false; // GUI 连击状态优先标志（防止引擎覆盖）

  // UI 组件
  private JLabel blackLabel;
  private JLabel whiteLabel;
  private JLabel blackCountLabel;
  private JLabel whiteCountLabel;
  private JLabel comboLabel; // 连击提示标签

  // 闪烁效果
  private Timer flashTimer;
  private boolean flashState = false;
  private String flashingColor = ""; // "B" or "W"
  private boolean persistentFlash = false; // 是否持续闪烁（连击期间）

  // 状态刷新定时器
  private Timer refreshTimer;

  // 自动检测器
  private ScytheDetector detector;
  private JLabel autoDetectLabel;

  // 颜色常量
  private static final Color COLOR_GOLD = new Color(255, 215, 0); // 金色
  private static final Color COLOR_ORANGE = new Color(255, 140, 0); // 橙色
  private static final Color COLOR_BLACK_STONE = new Color(30, 30, 30); // 深灰黑
  private static final Color COLOR_WHITE_STONE = new Color(240, 240, 240); // 浅灰白

  public ScythePanel() {
    setLayout(new FlowLayout(FlowLayout.CENTER, 8, 5));
    setOpaque(true);
    setBackground(new Color(40, 40, 40, 220)); // 半透明深灰背景

    // 创建黑棋图标和数字
    blackLabel = new JLabel("\u25CF"); // 黑色圆点
    blackLabel.setFont(new Font("Dialog", Font.BOLD, 22));
    blackLabel.setForeground(COLOR_BLACK_STONE);
    blackLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
    blackLabel.setToolTipText("点击触发黑方镰刀");

    blackCountLabel = new JLabel("3");
    blackCountLabel.setFont(new Font("Dialog", Font.BOLD, 16));
    blackCountLabel.setForeground(Color.YELLOW);

    // 创建白棋图标和数字
    whiteLabel = new JLabel("\u25CB"); // 白色圆点
    whiteLabel.setFont(new Font("Dialog", Font.BOLD, 22));
    whiteLabel.setForeground(COLOR_WHITE_STONE);
    whiteLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
    whiteLabel.setToolTipText("点击触发白方镰刀");

    whiteCountLabel = new JLabel("3");
    whiteCountLabel.setFont(new Font("Dialog", Font.BOLD, 16));
    whiteCountLabel.setForeground(Color.CYAN);

    // 连击提示标签
    comboLabel = new JLabel("");
    comboLabel.setFont(new Font("Dialog", Font.BOLD, 14));
    comboLabel.setForeground(COLOR_GOLD);
    comboLabel.setVisible(false);

    // 添加点击事件
    blackLabel.addMouseListener(
        new MouseAdapter() {
          @Override
          public void mouseClicked(MouseEvent e) {
            triggerScythe("black");
          }
        });

    whiteLabel.addMouseListener(
        new MouseAdapter() {
          @Override
          public void mouseClicked(MouseEvent e) {
            triggerScythe("white");
          }
        });

    // 初始化自动检测器
    detector = new ScytheDetector();
    detector.setScythePanel(this);

    // 自动检测开关标签
    autoDetectLabel = new JLabel("[自动]");
    autoDetectLabel.setFont(new Font("Dialog", Font.PLAIN, 11));
    autoDetectLabel.setForeground(Color.GRAY);
    autoDetectLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
    autoDetectLabel.setToolTipText("点击开启/关闭野狐镰刀自动检测");
    autoDetectLabel.addMouseListener(
        new MouseAdapter() {
          @Override
          public void mouseClicked(MouseEvent e) {
            toggleAutoDetect();
          }
        });

    // 布局: ● 3 | ○ 3 [连下X手] [自动]
    add(blackLabel);
    add(blackCountLabel);
    JLabel separator = new JLabel("|");
    separator.setForeground(Color.GRAY);
    add(separator);
    add(whiteLabel);
    add(whiteCountLabel);
    add(comboLabel);
    add(autoDetectLabel);

    // 初始化闪烁定时器 - 更快的闪烁频率
    flashTimer =
        new Timer(
            150,
            e -> {
              flashState = !flashState;
              updateFlashDisplay();
              // 如果不是持续闪烁模式且闪烁了足够次数，停止
              if (!persistentFlash && ++flashCount >= 10) {
                stopFlash();
              }
            });

    // 延迟初始化显示（等待引擎启动）
    // 注意：不发送 GTP 查询，避免干扰分析
    Timer initTimer =
        new Timer(
            500,
            e -> {
              refreshDisplay();
            });
    initTimer.setRepeats(false);
    initTimer.start();
  }

  private int flashCount = 0;

  /**
   * 触发镰刀（手动点击时调用，自动判断是否是 AI 方）
   *
   * @param color "black" 或 "white"
   */
  public void triggerScythe(String color) {
    // 手动点击镰刀图标，无论是否在自动对弈模式，都标记为 AI 镰刀
    // 这样可以在分析模式下也能触发 AI 连续计算 3 手
    boolean isAi = true; // 手动点击 = 要求 AI 连续计算
    triggerScythe(color, isAi);
  }

  /**
   * 触发镰刀（带 AI 标志，供 ScytheDetector 调用）
   *
   * @param color "black" 或 "white"
   * @param isAi 是否是 AI 方的镰刀
   */
  public void triggerScythe(String color, boolean isAi) {
    // System.err.println("DEBUG: triggerScythe called, color=" + color + ", isAi=" + isAi);

    if (Lizzie.leelaz == null) {
      // System.err.println("DEBUG: Lizzie.leelaz is null");
      return;
    }

    if (!Lizzie.leelaz.isKatago) {
      // System.err.println("DEBUG: Not KataGo engine");
      return;
    }

    // 检查是否有剩余镰刀
    if (color.equals("black") && blackScythes <= 0) {
      // System.err.println("DEBUG: No black scythes remaining");
      return;
    }
    if (color.equals("white") && whiteScythes <= 0) {
      // System.err.println("DEBUG: No white scythes remaining");
      return;
    }

    // System.err.println("DEBUG: Triggering scythe for " + color + " (isAi=" + isAi + ")");

    // 设置 AI 方标志
    this.isAiScythe = isAi;

    // 设置待触发标志（等待落子时真正触发）
    scythePending = true;
    scythePendingPlayer = color.equals("black");

    // 发送触发命令（明确指定玩家颜色）
    String playerParam = color.equals("black") ? "black" : "white";
    Lizzie.leelaz.sendCommand("kata-set-param scythe_trigger_player " + playerParam);
    Lizzie.leelaz.sendCommand("kata-set-param scythe_trigger true");

    // 立即显示数字减少（乐观更新）
    String playerCode = color.equals("black") ? "B" : "W";
    optimisticDecrement(playerCode);

    // 激活连击状态并开始持续闪烁
    guiComboRemaining = 3;
    guiComboPlayer = color.equals("black");
    guiComboAuthority = true; // 标记 GUI 状态优先，防止引擎覆盖
    updateComboDisplay();
    startPersistentFlash(playerCode);

    // 主动触发 AI 分析（分析模式下显示推荐点）
    if (Lizzie.leelaz != null) {
      // System.err.println("DEBUG: 镰刀触发，主动调用 ponder() 开始分析（连续3手）");
      // 使用 ponder() 触发 kata-analyze，这样会显示推荐点
      // KataGo 引擎会根据 scytheCombo 状态，计算同一玩家连续 3 手的变化
      Lizzie.leelaz.ponder();
    }
  }

  /**
   * 刷新显示（不查询引擎，避免干扰分析）
   *
   * <p>镰刀状态固定：黑3次、白3次、手数范围11-49
   */
  public void refreshDisplay() {
    // 不发送 GTP 命令，直接更新显示
    // 镰刀数量固定（目前版本不会扣减）
    SwingUtilities.invokeLater(this::repaint);
  }

  /** 从引擎获取镰刀状态（已弃用，会干扰分析） */
  @Deprecated
  public void refreshScytheStatus() {
    if (Lizzie.leelaz == null || !Lizzie.leelaz.isKatago) {
      return;
    }

    try {
      // 设置标志，表示正在等待镰刀状态响应
      Lizzie.leelaz.scytheQueryPending = true;
      Lizzie.leelaz.sendCommand("kata-get-scythe-status");

      // 超时保护：2秒后如果还没收到响应，自动重置红灯并重启分析
      new Thread(
              () -> {
                try {
                  Thread.sleep(2000); // 等待 2 秒
                } catch (InterruptedException e) {
                }
                if (Lizzie.leelaz.scytheQueryPending) {
                  System.err.println(
                      "WARNING: Scythe query timeout after 2s, forcing green light and ponder");
                  Lizzie.leelaz.scytheQueryPending = false;
                  if (Lizzie.leelaz == Lizzie.leelaz && !Lizzie.leelaz.isPondering()) {
                    Lizzie.leelaz.ponder();
                  }
                }
              })
          .start();
    } catch (Exception e) {
      Lizzie.leelaz.scytheQueryPending = false;
    }
  }

  /**
   * 更新镰刀状态 (从 JSON 响应解析)
   *
   * @param json JSON 格式的状态
   */
  public void updateStatus(String json) {
    try {
      JSONObject status = new JSONObject(json);
      int newBlackScythes = status.optInt("blackScythes", 3);
      int newWhiteScythes = status.optInt("whiteScythes", 3);
      int newScytheCombo = status.optInt("scytheCombo", 0);
      boolean newIsComboActive = status.optBoolean("isComboActive", false);
      String newNextPlayer = status.optString("nextPlayer", "B");

      blackScythes = newBlackScythes;
      whiteScythes = newWhiteScythes;
      scytheCombo = newScytheCombo;
      isComboActive = newIsComboActive;
      nextPlayer = newNextPlayer;

      // 更新显示
      blackCountLabel.setText(String.valueOf(blackScythes));
      whiteCountLabel.setText(String.valueOf(whiteScythes));

      // 根据剩余数量设置颜色
      blackCountLabel.setForeground(blackScythes > 0 ? Color.YELLOW : Color.GRAY);
      whiteCountLabel.setForeground(whiteScythes > 0 ? Color.CYAN : Color.GRAY);

      // 同步 GUI 连击状态
      if (newIsComboActive && newScytheCombo > 0) {
        // 引擎确认连击激活
        if (guiComboRemaining == 0) {
          // 场景 1: GUI 未知连击，引擎报告连击 → 从引擎同步
          guiComboRemaining = newScytheCombo;
          guiComboPlayer = newNextPlayer.equals("B");
          guiComboAuthority = false; // 引擎状态优先
          updateComboDisplay();
          if (!persistentFlash) {
            startPersistentFlash(newNextPlayer);
          }
        } else if (guiComboAuthority) {
          // 场景 2: GUI 已触发连击 → 保持 GUI 值，忽略引擎（可能是延迟响应）
          System.err.println(
              "ScythePanel: GUI 连击状态优先，忽略引擎更新 (gui="
                  + guiComboRemaining
                  + ", engine="
                  + newScytheCombo
                  + ")");
          // 不更新 guiComboRemaining
        } else {
          // 场景 3: 引擎驱动的连击（正常递减同步）
          guiComboRemaining = newScytheCombo;
          guiComboPlayer = newNextPlayer.equals("B");
          updateComboDisplay();
        }
      } else if (!newIsComboActive && guiComboRemaining > 0) {
        // 引擎报告连击结束，但 GUI 仍在连击中
        if (guiComboAuthority) {
          // 场景 4: GUI 刚触发镰刀，引擎还没落子 → 保持 GUI 状态
          System.err.println(
              "ScythePanel: GUI 连击刚触发，忽略引擎'未激活'状态 (guiRemaining=" + guiComboRemaining + ")");
          // 不重置 guiComboRemaining
        } else {
          // 场景 5: 引擎确认连击结束 → 清除 GUI 状态
          guiComboRemaining = 0;
          updateComboDisplay();
          stopFlash();
        }
      }

      repaint();
    } catch (Exception e) {
      // JSON 解析错误，忽略
    }
  }

  /** 更新连击显示 */
  private void updateComboDisplay() {
    if (guiComboRemaining > 0) {
      String player = guiComboPlayer ? "黑" : "白";
      comboLabel.setText("[" + player + "连" + guiComboRemaining + "手]");
      comboLabel.setVisible(true);
    } else {
      comboLabel.setText("");
      comboLabel.setVisible(false);
    }
    repaint();
  }

  /** 乐观更新：立即减少镰刀次数 */
  public void optimisticDecrement(String color) {
    if (color.equals("B") && blackScythes > 0) {
      blackScythes--;
      blackCountLabel.setText(String.valueOf(blackScythes));
      if (blackScythes == 0) {
        blackCountLabel.setForeground(Color.GRAY);
      }
      repaint();
    } else if (color.equals("W") && whiteScythes > 0) {
      whiteScythes--;
      whiteCountLabel.setText(String.valueOf(whiteScythes));
      if (whiteScythes == 0) {
        whiteCountLabel.setForeground(Color.GRAY);
      }
      repaint();
    }
  }

  /**
   * 开始持续闪烁（连击期间）
   *
   * @param color "B" 或 "W"
   */
  private void startPersistentFlash(String color) {
    flashingColor = color;
    flashCount = 0;
    flashState = true;
    persistentFlash = true;
    flashTimer.start();
  }

  /**
   * 开始短暂闪烁（触发确认）
   *
   * @param color "B" 或 "W"
   */
  private void startFlash(String color) {
    flashingColor = color;
    flashCount = 0;
    flashState = true;
    persistentFlash = false;
    flashTimer.start();
  }

  /** 停止闪烁效果 */
  private void stopFlash() {
    flashTimer.stop();
    flashingColor = "";
    flashState = false;
    persistentFlash = false;
    // 恢复正常颜色
    blackLabel.setForeground(COLOR_BLACK_STONE);
    blackCountLabel.setForeground(blackScythes > 0 ? Color.YELLOW : Color.GRAY);
    whiteLabel.setForeground(COLOR_WHITE_STONE);
    whiteCountLabel.setForeground(whiteScythes > 0 ? Color.CYAN : Color.GRAY);
    repaint();
  }

  /** 更新闪烁显示 */
  private void updateFlashDisplay() {
    // 使用金色和橙色交替，更醒目
    Color flashColor = flashState ? COLOR_GOLD : COLOR_ORANGE;
    Color normalColor = flashState ? Color.WHITE : Color.LIGHT_GRAY;

    if (flashingColor.equals("B")) {
      blackLabel.setForeground(flashColor);
      blackCountLabel.setForeground(flashColor);
      // 连击提示也闪烁
      comboLabel.setForeground(flashState ? COLOR_GOLD : Color.WHITE);
    } else if (flashingColor.equals("W")) {
      whiteLabel.setForeground(flashColor);
      whiteCountLabel.setForeground(flashColor);
      comboLabel.setForeground(flashState ? COLOR_GOLD : Color.WHITE);
    }
    repaint();
  }

  /**
   * 手动设置镰刀次数
   *
   * @param color "black" 或 "white"
   * @param count 次数 (0-3)
   */
  public void setScytheCount(String color, int count) {
    if (Lizzie.leelaz == null || !Lizzie.leelaz.isKatago) {
      return;
    }

    count = Math.max(0, Math.min(3, count));
    Lizzie.leelaz.sendCommand("kata-set-scythe-count " + color + " " + count);
    // 不发送状态查询，避免中断分析
    refreshDisplay();
  }

  /** 重置镰刀次数 */
  public void resetScythes() {
    if (Lizzie.leelaz == null || !Lizzie.leelaz.isKatago) {
      return;
    }

    Lizzie.leelaz.sendCommand("scythe_reset");
    // 不发送状态查询，避免中断分析
    refreshDisplay();
  }

  /** 重置显示到初始状态 (3/3) */
  public void resetDisplay() {
    blackScythes = 3;
    whiteScythes = 3;
    scytheCombo = 0;
    isComboActive = false;
    guiComboRemaining = 0;
    guiComboAuthority = false;
    scythePending = false;
    blackCountLabel.setText("3");
    whiteCountLabel.setText("3");
    blackCountLabel.setForeground(Color.YELLOW);
    whiteCountLabel.setForeground(Color.CYAN);
    updateComboDisplay();
    stopFlash();
    repaint();
  }

  /** 切换自动检测状态 */
  private void toggleAutoDetect() {
    if (detector == null) {
      return;
    }

    detector.toggle();
    updateAutoDetectLabel();
  }

  /** 更新自动检测标签显示 */
  private void updateAutoDetectLabel() {
    if (detector != null && detector.isEnabled()) {
      autoDetectLabel.setText("[自动:开]");
      autoDetectLabel.setForeground(new Color(0, 200, 0)); // 亮绿色
    } else {
      autoDetectLabel.setText("[自动]");
      autoDetectLabel.setForeground(Color.GRAY);
    }
    repaint();
  }

  /**
   * 获取自动检测器
   *
   * @return ScytheDetector 实例
   */
  public ScytheDetector getDetector() {
    return detector;
  }

  /** 停止定时器 (关闭时调用) */
  public void shutdown() {
    if (flashTimer != null) {
      flashTimer.stop();
    }
    if (refreshTimer != null) {
      refreshTimer.stop();
    }
    if (detector != null) {
      detector.shutdown();
    }
  }

  // Getter 方法
  public int getBlackScythes() {
    return blackScythes;
  }

  public int getWhiteScythes() {
    return whiteScythes;
  }

  public boolean isComboActive() {
    return isComboActive;
  }

  /**
   * 检查是否在GUI连击中
   *
   * @return true 如果在连击中
   */
  public boolean isGuiComboActive() {
    return guiComboRemaining > 0;
  }

  /**
   * 获取连击的玩家
   *
   * @return true=黑棋，false=白棋
   */
  public boolean getGuiComboPlayer() {
    return guiComboPlayer;
  }

  /**
   * 检查当前镰刀是否是 AI 方的
   *
   * @return true=AI 方镰刀，false=对手方镰刀
   */
  public boolean isAiScythe() {
    return isAiScythe;
  }

  /**
   * 获取剩余连击次数
   *
   * @return 剩余连击次数（0-3）
   */
  public int getGuiComboRemaining() {
    return guiComboRemaining;
  }

  /**
   * 检查是否有待触发的镰刀（用户已点击图标但还没落子）
   *
   * @return true 如果有待触发的镰刀
   */
  public boolean isScythePending() {
    return scythePending;
  }

  /**
   * 获取待触发镰刀的玩家
   *
   * @return true=黑棋，false=白棋
   */
  public boolean getScythePendingPlayer() {
    return scythePendingPlayer;
  }

  /** 落子前调用，检查是否有待触发的镰刀 */
  public void onBeforeMove() {
    if (scythePending) {
      guiComboRemaining = 3;
      guiComboPlayer = scythePendingPlayer;
      guiComboAuthority = true; // 待触发镰刀激活时，GUI 优先
      scythePending = false;
      updateComboDisplay();
    }
  }

  /** 落子后调用，递减连击计数 */
  public void decrementGuiCombo() {
    if (guiComboRemaining > 0) {
      guiComboRemaining--;
      updateComboDisplay();

      // 落子后清除 GUI 优先标志（允许引擎同步）
      if (guiComboRemaining > 0) {
        guiComboAuthority = false; // 第一手落子后，允许引擎同步
      }

      // 连击结束时停止闪烁
      if (guiComboRemaining == 0) {
        guiComboAuthority = false; // 连击结束，清除标志
        stopFlash();
      }
    }
  }

  /**
   * 获取镰刀连击的玩家颜色（供 BoardRenderer 强制渲染使用）
   *
   * @return Stone.BLACK 或 Stone.WHITE
   */
  public featurecat.lizzie.rules.Stone getScythePlayerStone() {
    return guiComboPlayer
        ? featurecat.lizzie.rules.Stone.BLACK
        : featurecat.lizzie.rules.Stone.WHITE;
  }

  /** 清除 AI 镰刀标志（连击完成后调用） 用于在 AI 镰刀连击结束后重置状态 */
  public void clearAiScythe() {
    isAiScythe = false;
    System.err.println("[ScythePanel] AI 镰刀标志已清除");
  }
}
