package featurecat.lizzie.util;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
import java.util.Date;

/** 调试日志工具类 同时输出到 stderr 和日志文件，用于调试自动落子功能 */
public class DebugLogger {
  private static PrintWriter fileWriter = null;
  private static final SimpleDateFormat dateFormat =
      new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
  private static boolean initialized = false;
  private static final String LOG_FILE = "lizzieyzy_debug.log";

  /** 初始化日志文件 日志文件位于 scythe_lizzie 目录下（如果存在），否则在当前目录 */
  private static synchronized void init() {
    if (initialized) return;
    initialized = true;

    try {
      // 尝试在 scythe_lizzie 目录下创建日志文件
      File logDir = new File(".");
      File scytheLizzieDir = new File("scythe_lizzie");
      if (scytheLizzieDir.exists() && scytheLizzieDir.isDirectory()) {
        logDir = scytheLizzieDir;
      }

      File logFile = new File(logDir, LOG_FILE);

      // 追加模式打开，使用 UTF-8 编码
      fileWriter =
          new PrintWriter(
              new OutputStreamWriter(new FileOutputStream(logFile, true), "UTF-8"), true);

      // 写入启动标记
      fileWriter.println("\n========================================");
      fileWriter.println("=== LizzieYzy Debug Log Started ===");
      fileWriter.println("=== " + dateFormat.format(new Date()) + " ===");
      fileWriter.println("========================================\n");
      fileWriter.flush();

    } catch (Exception e) {
      System.err.println("[DebugLogger] Failed to initialize log file: " + e.getMessage());
    }
  }

  /**
   * 记录调试日志
   *
   * @param tag 日志标签，如 [READBOARD], [AUTO-PLAY], [SEND-PLACE]
   * @param message 日志消息
   */
  public static void log(String tag, String message) {
    if (!initialized) {
      init();
    }

    String timestamp = dateFormat.format(new Date());
    String fullMessage = timestamp + " " + tag + " " + message;

    // 输出到 stderr
    System.err.println(fullMessage);

    // 输出到日志文件
    if (fileWriter != null) {
      fileWriter.println(fullMessage);
      fileWriter.flush();
    }
  }

  /** 记录 READBOARD 相关日志 */
  public static void logReadBoard(String message) {
    log("[READBOARD]", message);
  }

  /** 记录 AUTO-PLAY 相关日志 */
  public static void logAutoPlay(String message) {
    log("[AUTO-PLAY]", message);
  }

  /** 记录 SEND-PLACE 相关日志 */
  public static void logSendPlace(String message) {
    log("[SEND-PLACE]", message);
  }

  /** 关闭日志文件 */
  public static synchronized void close() {
    if (fileWriter != null) {
      fileWriter.println("\n=== Log closed at " + dateFormat.format(new Date()) + " ===\n");
      fileWriter.close();
      fileWriter = null;
    }
    initialized = false;
  }
}
