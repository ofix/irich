class RequestLog {
  int? id;
  final String providerId;
  final String apiType;
  final String url;
  final DateTime requestTime;
  final int? statusCode;
  final String? errorMessage;
  final int duration; // 毫秒
  int retryCount;
  bool isResolved;

  RequestLog({
    this.id,
    required this.providerId,
    required this.apiType,
    required this.url,
    required this.requestTime,
    this.statusCode,
    this.errorMessage,
    required this.duration,
    this.retryCount = 0,
    this.isResolved = false,
  });

  // 添加copyWith方法以便更新内存中的日志
  RequestLog copyWith({
    int? id, // 自增ID
    String? providerId, // 供应商ID
    String? apiType, // API类别
    String? url, // 请求URL
    DateTime? requestTime, // 请求时间
    int? statusCode, // 状态吗
    String? errorMessage, // 错误信息
    int? duration, // 请求持续时间
    int? retryCount, // 重试次数
    bool? isResolved, // 是否解决
  }) {
    return RequestLog(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      apiType: apiType ?? this.apiType,
      url: url ?? this.url,
      requestTime: requestTime ?? this.requestTime,
      statusCode: statusCode ?? this.statusCode,
      errorMessage: errorMessage ?? this.errorMessage,
      duration: duration ?? this.duration,
      retryCount: retryCount ?? this.retryCount,
      isResolved: isResolved ?? this.isResolved,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'provider_id': providerId,
      'api_type': apiType,
      'url': url,
      'request_time': requestTime.millisecondsSinceEpoch,
      'status_code': statusCode,
      'error_message': errorMessage,
      'duration': duration,
      'retry_count': retryCount,
      'is_resolved': isResolved ? 1 : 0,
    };
  }

  factory RequestLog.fromMap(Map<String, dynamic> map) {
    return RequestLog(
      id: map['id'],
      providerId: map['provider_id'],
      apiType: map['api_type'],
      url: map['url'],
      requestTime: DateTime.fromMillisecondsSinceEpoch(map['request_time']),
      statusCode: map['status_code'],
      errorMessage: map['error_message'],
      duration: map['duration'],
      retryCount: map['retry_count'],
      isResolved: map['is_resolved'] == 1,
    );
  }
}
