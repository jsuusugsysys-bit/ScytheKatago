#ifndef CORE_RETRYMANAGER_H_
#define CORE_RETRYMANAGER_H_

#include <functional>
#include <string>
#include <exception>
#include <chrono>
#include <fstream>
#include <mutex>
#include <thread>

/**
 * 重试管理器 (Retry Manager)
 * 用于限制失败操作的重试次数，避免无意义的重复尝试
 */

namespace RetryManager {

/**
 * 执行结果模板
 */
template <typename T>
struct RetryResult {
  bool success;
  T result;
  std::string errorMessage;

  RetryResult() : success(false), result(), errorMessage("") {}
  RetryResult(bool s, const T& r, const std::string& err = "")
    : success(s), result(r), errorMessage(err) {}

  static RetryResult<T> Success(const T& res) {
    return RetryResult<T>(true, res, "");
  }

  static RetryResult<T> Failure(const std::string& errMsg) {
    return RetryResult<T>(false, T(), errMsg);
  }
};

/**
 * void 类型的特化版本
 */
template <>
struct RetryResult<void> {
  bool success;
  std::string errorMessage;

  RetryResult() : success(false), errorMessage("") {}
  RetryResult(bool s, const std::string& err = "")
    : success(s), errorMessage(err) {}

  static RetryResult<void> Success() {
    return RetryResult<void>(true, "");
  }

  static RetryResult<void> Failure(const std::string& errMsg) {
    return RetryResult<void>(false, errMsg);
  }
};

/**
 * 重试管理器类
 */
class Manager {
public:
  Manager(int maxRetries_ = 1,
          const std::string& logFile_ = "retry_failures.log",
          bool enableLogging_ = true);

  ~Manager();

  /**
   * 执行操作，失败时自动重试
   */
  template <typename T>
  RetryResult<T> executeWithRetry(
      std::function<T()> operation,
      const std::string& operationName,
      const std::string& context = "") {

    int attempt = 0;
    std::string lastError;

    while (attempt <= maxRetries) {
      try {
        if (attempt > 0) {
          logRetry(operationName, attempt, context);
        } else {
          logStart(operationName, context);
        }

        T res = operation();
        logSuccess(operationName, attempt, context);
        return RetryResult<T>::Success(res);

      } catch (const std::exception& e) {
        lastError = e.what();
        attempt++;
        logFailure(operationName, attempt, lastError, context);
        if (attempt > maxRetries) {
          break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(500));

      } catch (...) {
        lastError = "Unknown exception";
        attempt++;
        logFailure(operationName, attempt, lastError, context);
        if (attempt > maxRetries) {
          break;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
      }
    }

    logFinalFailure(operationName, maxRetries + 1, lastError, context);
    return RetryResult<T>::Failure(lastError);
  }

private:
  int maxRetries;
  std::string logFile;
  bool enableLogging;
  std::mutex logMutex;

  void logStart(const std::string& operationName, const std::string& context);
  void logRetry(const std::string& operationName, int attempt, const std::string& context);
  void logSuccess(const std::string& operationName, int attempt, const std::string& context);
  void logFailure(const std::string& operationName, int attempt, const std::string& error, const std::string& context);
  void logFinalFailure(const std::string& operationName, int totalAttempts, const std::string& error, const std::string& context);

  void log(const std::string& level, const std::string& message);
  std::string getCurrentTimestamp();
};

} // namespace RetryManager

#endif // CORE_RETRYMANAGER_H_
