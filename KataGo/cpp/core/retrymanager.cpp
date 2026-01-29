#include "retrymanager.h"
#include <iostream>
#include <sstream>
#include <iomanip>
#include <ctime>

namespace RetryManager {

Manager::Manager(int maxRetries, const std::string& logFile, bool enableLogging)
  : maxRetries(maxRetries),
    logFile(logFile),
    enableLogging(enableLogging) {
}

Manager::~Manager() {
}

void Manager::logStart(const std::string& operationName, const std::string& context) {
  std::ostringstream msg;
  msg << "开始执行: " << operationName;
  if (!context.empty()) {
    msg << " | 上下文: " << context;
  }
  log("INFO", msg.str());
}

void Manager::logRetry(const std::string& operationName, int attempt, const std::string& context) {
  std::ostringstream msg;
  msg << "重试 [" << attempt << "/" << maxRetries << "]: " << operationName;
  if (!context.empty()) {
    msg << " | 上下文: " << context;
  }
  log("WARN", msg.str());
}

void Manager::logSuccess(const std::string& operationName, int attempt, const std::string& context) {
  std::ostringstream msg;
  msg << "成功: " << operationName;
  if (attempt > 0) {
    msg << " (经过 " << attempt << " 次重试)";
  }
  if (!context.empty()) {
    msg << " | 上下文: " << context;
  }
  log("INFO", msg.str());
}

void Manager::logFailure(const std::string& operationName, int attempt, const std::string& error, const std::string& context) {
  std::ostringstream msg;
  msg << "失败 [" << attempt << "/" << (maxRetries + 1) << "]: " << operationName;
  msg << " | 错误: " << error;
  if (!context.empty()) {
    msg << " | 上下文: " << context;
  }
  log("ERROR", msg.str());
}

void Manager::logFinalFailure(const std::string& operationName, int totalAttempts, const std::string& error, const std::string& context) {
  std::ostringstream msg;
  msg << "==============================\n";
  msg << "最终失败: " << operationName << "\n";
  msg << "总尝试次数: " << totalAttempts << "\n";
  msg << "最后错误: " << error << "\n";
  if (!context.empty()) {
    msg << "上下文: " << context << "\n";
  }
  msg << "时间: " << getCurrentTimestamp() << "\n";
  msg << "==============================\n";
  log("CRITICAL", msg.str());
}

void Manager::log(const std::string& level, const std::string& message) {
  std::lock_guard<std::mutex> lock(logMutex);

  std::string timestamp = getCurrentTimestamp();
  std::ostringstream logLine;
  logLine << "[" << timestamp << "] [" << level << "] " << message;

  // 输出到 stderr（避免破坏 GTP 协议）
  std::cerr << logLine.str() << std::endl;

  // 写入文件
  if (enableLogging) {
    std::ofstream logStream(logFile, std::ios::app);
    if (logStream.is_open()) {
      logStream << logLine.str() << std::endl;
      logStream.close();
    } else {
      std::cerr << "无法写入日志文件: " << logFile << std::endl;
    }
  }
}

std::string Manager::getCurrentTimestamp() {
  auto now = std::chrono::system_clock::now();
  auto time_t_now = std::chrono::system_clock::to_time_t(now);
  std::tm tm_now;
  #ifdef _WIN32
    localtime_s(&tm_now, &time_t_now);
  #else
    localtime_r(&time_t_now, &tm_now);
  #endif

  std::ostringstream oss;
  oss << std::put_time(&tm_now, "%Y-%m-%d %H:%M:%S");
  return oss.str();
}

} // namespace RetryManager
