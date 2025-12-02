/// 通用结果封装
/// 用于 Service 层向 Controller 层传递操作结果，避免抛出异常
class Result<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;

  Result.success(this.data) : isSuccess = true, errorMessage = null;
  Result.failure(this.errorMessage) : isSuccess = false, data = null;

  // 快捷工厂
  factory Result.ok([T? data]) => Result.success(data);
  factory Result.err(String msg) => Result.failure(msg);
}
