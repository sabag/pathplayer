/// Thin wrapper around the Subsonic JSON envelope.
///
/// Every Subsonic response is keyed by `subsonic-response` and contains a
/// `status` field. On failure it also contains an `error` object.
class SubsonicResponse {
  const SubsonicResponse({
    required this.status,
    required this.version,
    this.type,
    this.serverVersion,
    this.error,
  });

  final String status;
  final String version;
  final String? type;
  final String? serverVersion;
  final SubsonicError? error;

  bool get isOk => status == 'ok';

  factory SubsonicResponse.fromJson(Map<String, dynamic> json) {
    return SubsonicResponse(
      status: json['status'] as String,
      version: json['version'] as String,
      type: json['type'] as String?,
      serverVersion: json['serverVersion'] as String?,
      error: json['error'] != null
          ? SubsonicError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SubsonicError {
  const SubsonicError({required this.code, required this.message});

  final int code;
  final String message;

  factory SubsonicError.fromJson(Map<String, dynamic> json) {
    return SubsonicError(
      code: json['code'] as int,
      message: json['message'] as String,
    );
  }
}

/// Extracts the inner `subsonic-response` map from a decoded JSON object
/// and throws if the server reported a failure.
Map<String, dynamic> unwrapSubsonicResponse(Map<String, dynamic> body) {
  final response = SubsonicResponse.fromJson(
    body['subsonic-response'] as Map<String, dynamic>,
  );
  if (!response.isOk) {
    final error = response.error;
    throw SubsonicApiException(
      code: error?.code ?? -1,
      message: error?.message ?? 'Unknown Subsonic error',
    );
  }
  return body['subsonic-response'] as Map<String, dynamic>;
}

class SubsonicApiException implements Exception {
  const SubsonicApiException({required this.code, required this.message});

  final int code;
  final String message;

  @override
  String toString() => 'SubsonicApiException($code): $message';
}
