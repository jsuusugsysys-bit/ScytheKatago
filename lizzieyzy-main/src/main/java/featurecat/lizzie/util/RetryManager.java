package featurecat.lizzie.util;

import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;

/**
 * 重试管理器 (Retry Manager) 用于限制失败操作的重试次数，避免无意义的重复尝试
 *
 * <p>使用场景： - GTP 命令通信失败 - 引擎响应超时 - 文件读写失败
 *
 * <p>核心原则： - 最多重试 1 次（总共尝试 2 次） - 失败时记录详细日志 - 不要相信"下一次会更好"
 */
public class RetryManager {
  private final int maxRetries;
  private final String logFile;
  private final boolean enableLogging;
  private final DateTimeFormatter dateFormatter;

  /**
   * 构造函数
   *
   * @param maxRetries 最大重试次数（默认 1，即总共尝试 2 次）
   * @param logFile 日志文件路径
   * @param enableLogging 是否启用日志记录
   */
  public RetryManager(int maxRetries, String logFile, boolean enableLogging) {
    this.maxRetries = maxRetries;
    this.logFile = logFile;
    this.enableLogging = enableLogging;
    this.dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
  }

  /** 默认构造函数（最多重试 1 次，启用日志） */
  public RetryManager() {
    this(1, "retry_failures.log", true);
  }

  /** 执行操作的接口 */
  @FunctionalInterface
  public interface Operation<T> {
    T execute() throws Exception;
  }

  /** 执行结果 */
  public static class RetryResult<T> {
    public final boolean success;
    public final T result;
    public final Exception error;

    private RetryResult(boolean success, T result, Exception error) {
      this.success = success;
      this.result = result;
      this.error = error;
    }

    public static <T> RetryResult<T> success(T result) {
      return new RetryResult<>(true, result, null);
    }

    public static <T> RetryResult<T> failure(Exception error) {
      return new RetryResult<>(false, null, error);
    }
  }

  /**
   * 执行操作，失败时自动重试
   *
   * @param operation 要执行的操作
   * @param operationName 操作名称（用于日志）
   * @param context 额外的上下文信息（可选）
   * @return 执行结果
   */
  public <T> RetryResult<T> executeWithRetry(
      Operation<T> operation, String operationName, Map<String, String> context) {

    int attempt = 0;
    Exception lastError = null;

    while (attempt <= maxRetries) {
      try {
        // 记录尝试
        if (attempt > 0) {
          logRetry(operationName, attempt, context);
        } else {
          logStart(operationName, context);
        }

        // 执行操作
        T result = operation.execute();

        // 成功
        logSuccess(operationName, attempt, context);
        return RetryResult.success(result);

      } catch (Exception e) {
        lastError = e;
        attempt++;

        // 记录失败
        logFailure(operationName, attempt, e, context);

        // 判断是否继续重试
        if (attempt > maxRetries) {
          break;
        }

        // 短暂延迟后重试（避免连续失败）
        try {
          Thread.sleep(500);
        } catch (InterruptedException ie) {
          Thread.currentThread().interrupt();
          break;
        }
      }
    }

    // 所有尝试都失败了
    logFinalFailure(operationName, maxRetries + 1, lastError, context);
    return RetryResult.failure(lastError);
  }

  /** 简化版本（无上下文） */
  public <T> RetryResult<T> executeWithRetry(Operation<T> operation, String operationName) {
    return executeWithRetry(operation, operationName, null);
  }

  /** 记录操作开始 */
  private void logStart(String operationName, Map<String, String> context) {
    String msg = "开始执行: " + operationName;
    if (context != null && !context.isEmpty()) {
      msg += " | 上下文: " + context;
    }
    log("INFO", msg);
  }

  /** 记录重试 */
  private void logRetry(String operationName, int attempt, Map<String, String> context) {
    String msg = String.format("重试 [%d/%d]: %s", attempt, maxRetries, operationName);
    if (context != null && !context.isEmpty()) {
      msg += " | 上下文: " + context;
    }
    log("WARN", msg);
  }

  /** 记录成功 */
  private void logSuccess(String operationName, int attempt, Map<String, String> context) {
    String msg = "成功: " + operationName;
    if (attempt > 0) {
      msg += String.format(" (经过 %d 次重试)", attempt);
    }
    if (context != null && !context.isEmpty()) {
      msg += " | 上下文: " + context;
    }
    log("INFO", msg);
  }

  /** 记录失败 */
  private void logFailure(
      String operationName, int attempt, Exception error, Map<String, String> context) {
    String msg = String.format("失败 [%d/%d]: %s", attempt, maxRetries + 1, operationName);
    msg += String.format(" | 错误: %s: %s", error.getClass().getSimpleName(), error.getMessage());
    if (context != null && !context.isEmpty()) {
      msg += " | 上下文: " + context;
    }
    log("ERROR", msg);
  }

  /** 记录最终失败 */
  private void logFinalFailure(
      String operationName, int totalAttempts, Exception error, Map<String, String> context) {
    StringBuilder msg = new StringBuilder();
    msg.append("==============================\n");
    msg.append("最终失败: ").append(operationName).append("\n");
    msg.append("总尝试次数: ").append(totalAttempts).append("\n");
    msg.append("最后错误: ")
        .append(error.getClass().getSimpleName())
        .append(": ")
        .append(error.getMessage())
        .append("\n");
    if (context != null && !context.isEmpty()) {
      msg.append("上下文: ").append(context).append("\n");
    }
    msg.append("时间: ").append(LocalDateTime.now().format(dateFormatter)).append("\n");
    msg.append("==============================\n");

    log("CRITICAL", msg.toString());
  }

  /** 写入日志 */
  private void log(String level, String message) {
    String timestamp = LocalDateTime.now().format(dateFormatter);
    String logLine = String.format("[%s] [%s] %s", timestamp, level, message);

    // 输出到 stderr（避免破坏 GTP 协议）
    System.err.println(logLine);

    // 写入文件
    if (enableLogging) {
      try (FileWriter fw = new FileWriter(logFile, true);
          PrintWriter pw = new PrintWriter(fw)) {
        pw.println(logLine);
      } catch (IOException e) {
        System.err.println("无法写入日志文件: " + e.getMessage());
      }
    }
  }

  /** 测试方法 */
  public static void main(String[] args) {
    System.out.println("测试重试管理器...");

    RetryManager manager = new RetryManager(1, "test_retry.log", true);

    // 测试 1：成功的操作
    RetryResult<String> result1 = manager.executeWithRetry(() -> "成功结果", "测试成功操作");
    assert result1.success;
    assert "成功结果".equals(result1.result);
    System.out.println("✅ 测试 1 通过: " + result1.result);

    // 测试 2：第一次失败，第二次成功
    final int[] attemptCounter = {0};
    RetryResult<String> result2 =
        manager.executeWithRetry(
            () -> {
              attemptCounter[0]++;
              if (attemptCounter[0] == 1) {
                throw new RuntimeException("第一次尝试失败");
              }
              return "第二次成功";
            },
            "测试重试一次");
    assert result2.success;
    assert "第二次成功".equals(result2.result);
    System.out.println("✅ 测试 2 通过: " + result2.result);

    // 测试 3：总是失败
    Map<String, String> context = new HashMap<>();
    context.put("key", "value");
    RetryResult<String> result3 =
        manager.executeWithRetry(
            () -> {
              throw new RuntimeException("总是失败的操作");
            },
            "测试总是失败",
            context);
    assert !result3.success;
    assert result3.error instanceof RuntimeException;
    System.out.println("✅ 测试 3 通过: 正确处理了失败");

    System.out.println("\n所有测试通过！");
  }
}
