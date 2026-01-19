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

  // UI 组件
  private JLabel blackLabel;
  private JLabel whiteLabel;
  private JLabel blackCountLabel;
  private JLabel whiteCountLabel;

  // 闪烁效果
  private Timer flashTimer;
  private boolean flashState = false;
  private String flashingColor = ""; // "B" or "W"
  private int flashCount = 0;

  // 状态刷新定时器
  private Timer refreshTimer;

  public ScythePanel() {
    setLayout(new FlowLayout(FlowLayout.CENTER, 10, 5));
    setOpaque(false);

    // 创建黑棋图标和数字
    blackLabel = new JLabel("\u25CF"); // 黑色圆点
    blackLabel.setFont(new Font("Dialog", Font.BOLD, 24));
    blackLabel.setForeground(Color.BLACK);
    blackLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
    blackLabel.setToolTipText("点击触发黑方镰刀 / Click to trigger Black's scythe");

    blackCountLabel = new JLabel("3");
    blackCountLabel.setFont(new Font("Dialog", Font.BOLD, 18));
    blackCountLabel.setForeground(Color.BLACK);

    // 创建白棋图标和数字
    whiteLabel = new JLabel("\u25CB"); // 白色圆点
    whiteLabel.setFont(new Font("Dialog", Font.BOLD, 24));
    whiteLabel.setForeground(Color.BLACK);
    whiteLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
    whiteLabel.setToolTipText("点击触发白方镰刀 / Click to trigger White's scythe");

    whiteCountLabel = new JLabel("3");
    whiteCountLabel.setFont(new Font("Dialog", Font.BOLD, 18));
    whiteCountLabel.setForeground(Color.BLACK);

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

    // 布局: ● 3  |  ○ 3
    add(blackLabel);
    add(blackCountLabel);
    add(new JLabel("  |  "));
    add(whiteLabel);
    add(whiteCountLabel);

    // 初始化闪烁定时器
    flashTimer =
        new Timer(
            200,
            e -> {
              flashState = !flashState;
              updateFlashDisplay();
              flashCount++;
              if (flashCount >= 10) { // 闪烁5次后停止
                stopFlash();
              }
            });

    // 初始化状态刷新定时器 (已禁用自动刷新，避免性能问题)
    // 改为事件驱动：仅在点击触发或棋盘落子后刷新
    // refreshTimer =
    //     new Timer(
    //         1000,
    //         e -> {
    //           refreshScytheStatus();
    //         });
    // refreshTimer.start();

    // 延迟初始化查询（等待引擎启动）
    Timer initTimer =
        new Timer(
            500,
            e -> {
              refreshScytheStatus();
            });
    initTimer.setRepeats(false);
    initTimer.start();
  }

  /**
   * 触发镰刀
   *
   * @param color "black" 或 "white"
   */
  public void triggerScythe(String color) {
    System.err.println("DEBUG: triggerScythe called, color=" + color);

    if (Lizzie.leelaz == null) {
      System.err.println("DEBUG: Lizzie.leelaz is null");
      return;
    }

    if (!Lizzie.leelaz.isKatago) {
      System.err.println("DEBUG: Not KataGo engine");
      return;
    }

    // 检查是否有剩余镰刀
    if (color.equals("black") && blackScythes <= 0) {
      System.err.println("DEBUG: No black scythes remaining");
      return; // 没有镰刀了，不触发
    }
    if (color.equals("white") && whiteScythes <= 0) {
      System.err.println("DEBUG: No white scythes remaining");
      return; // 没有镰刀了，不触发
    }

    System.err.println("DEBUG: Triggering scythe for " + color);

    // 设置待触发标志（等待落子时真正触发）
    scythePending = true;
    scythePendingPlayer = color.equals("black");

    // 发送触发命令
    if (color.equals("black")) {
      System.err.println("DEBUG: Sending kata-set-param command for black");
      Lizzie.leelaz.sendCommand("kata-set-param scythe_trigger true");
      // 立即显示数字减少（乐观更新）
      optimisticDecrement("B");
      startFlash("B");
    } else {
      System.err.println("DEBUG: Sending kata-set-param command for white");
      Lizzie.leelaz.sendCommand("kata-set-param scythe_trigger true");
      // 立即显示数字减少（乐观更新）
      optimisticDecrement("W");
      startFlash("W");
    }

    // 不要立即刷新状态，避免覆盖乐观更新
    // 等待落子后再刷新
  }

  /** 从引擎获取镰刀状态 */
  public void refreshScytheStatus() {
    if (Lizzie.leelaz == null || !Lizzie.leelaz.isKatago) {
      return;
    }

    // 发送状态查询命令
    // 注意：这里需要异步处理响应，暂时用简单方式
    try {
      Lizzie.leelaz.sendCommand("kata-get-scythe-status");
    } catch (Exception e) {
      // 忽略错误
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

      // 只有当状态真正改变时才更新显示
      boolean changed = false;
      if (blackScythes != newBlackScythes || whiteScythes != newWhiteScythes) {
        changed = true;
      }

      blackScythes = newBlackScythes;
      whiteScythes = newWhiteScythes;
      scytheCombo = newScytheCombo;
      isComboActive = newIsComboActive;
      nextPlayer = newNextPlayer;

      // 更新显示
      blackCountLabel.setText(String.valueOf(blackScythes));
      whiteCountLabel.setText(String.valueOf(whiteScythes));

      // 根据剩余数量设置颜色
      blackCountLabel.setForeground(blackScythes > 0 ? Color.BLACK : Color.GRAY);
      whiteCountLabel.setForeground(whiteScythes > 0 ? Color.BLACK : Color.GRAY);

      // 如果正在连击中，显示闪烁
      if (isComboActive && flashingColor.isEmpty()) {
        startFlash(nextPlayer);
      } else if (!isComboActive && !flashingColor.isEmpty()) {
        stopFlash();
      }

      repaint();
    } catch (Exception e) {
      // JSON 解析错误，忽略
    }
  }

  /** 乐观更新：立即减少镰刀次数（不等引擎响应） 用于提供即时反馈 */
  public void optimisticDecrement(String color) {
    if (color.equals("B") && blackScythes > 0) {
      blackScythes--;
      blackCountLabel.setText(String.valueOf(blackScythes));
      // 如果用完了，改变颜色提示
      if (blackScythes == 0) {
        blackCountLabel.setForeground(Color.GRAY);
      }
      repaint();
    } else if (color.equals("W") && whiteScythes > 0) {
      whiteScythes--;
      whiteCountLabel.setText(String.valueOf(whiteScythes));
      // 如果用完了，改变颜色提示
      if (whiteScythes == 0) {
        whiteCountLabel.setForeground(Color.GRAY);
      }
      repaint();
    }
  }

  /**
   * 开始闪烁效果
   *
   * @param color "B" 或 "W"
   */
  private void startFlash(String color) {
    flashingColor = color;
    flashCount = 0;
    flashState = true;
    flashTimer.start();
  }

  /** 停止闪烁效果 */
  private void stopFlash() {
    flashTimer.stop();
    flashingColor = "";
    flashState = false;
    // 恢复正常颜色
    blackLabel.setForeground(Color.BLACK);
    blackCountLabel.setForeground(Color.BLACK);
    whiteLabel.setForeground(Color.BLACK);
    whiteCountLabel.setForeground(Color.BLACK);
  }

  /** 更新闪烁显示 */
  private void updateFlashDisplay() {
    Color flashColor = flashState ? Color.RED : Color.BLACK;

    if (flashingColor.equals("B")) {
      blackLabel.setForeground(flashColor);
      blackCountLabel.setForeground(flashColor);
    } else if (flashingColor.equals("W")) {
      whiteLabel.setForeground(flashColor);
      whiteCountLabel.setForeground(flashColor);
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
    refreshScytheStatus();
  }

  /** 重置镰刀次数 */
  public void resetScythes() {
    if (Lizzie.leelaz == null || !Lizzie.leelaz.isKatago) {
      return;
    }

    Lizzie.leelaz.sendCommand("scythe_reset");
    refreshScytheStatus();
  }

  /** 重置显示到初始状态 (3/3) */
  public void resetDisplay() {
    blackScythes = 3;
    whiteScythes = 3;
    scytheCombo = 0;
    isComboActive = false;
    guiComboRemaining = 0; // 重置GUI连击状态
    scythePending = false; // 重置待触发标志
    blackCountLabel.setText("3");
    whiteCountLabel.setText("3");
    // 重置颜色为黑色（可用状态）
    blackCountLabel.setForeground(Color.BLACK);
    whiteCountLabel.setForeground(Color.BLACK);
    stopFlash();
    repaint();
  }

  /** 停止定时器 (关闭时调用) */
  public void shutdown() {
    if (flashTimer != null) {
      flashTimer.stop();
    }
    if (refreshTimer != null) {
      refreshTimer.stop();
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
   * 检查是否在GUI连击中（同步判断，不依赖异步的引擎响应）
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

  /** 落子前调用，检查是否有待触发的镰刀 如果有，激活连击状态 */
  public void onBeforeMove() {
    if (scythePending) {
      // 激活连击状态
      guiComboRemaining = 3; // 接下来3手都是同一玩家
      guiComboPlayer = scythePendingPlayer;
      scythePending = false; // 清除待触发标志
    }
  }

  /** 落子后调用，递减连击计数 */
  public void decrementGuiCombo() {
    if (guiComboRemaining > 0) {
      guiComboRemaining--;
    }
  }
}
