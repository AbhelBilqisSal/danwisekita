/// Custom exception yang dilempar oleh API layer.
///
/// Menyimpan [statusCode] HTTP, [message] pesan error,
/// dan boolean flag [isTimeout] & [isUnauthorized] untuk
/// penanganan di layer atas (UI / provider).
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException({this.statusCode, required this.message});

  /// Apakah error ini disebabkan oleh koneksi timeout.
  bool get isTimeout => message.contains('TimeoutException') ||
      message.contains('timed out') ||
      message.contains('SocketException');

  /// Apakah error ini disebabkan token kedaluwarsa / tidak valid (401).
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
