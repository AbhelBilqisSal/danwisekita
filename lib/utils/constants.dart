/// Konstanta global untuk aplikasi DanWise.
///
/// Base URL menggunakan 10.0.2.2 agar dapat diakses dari
/// Android Emulator — ini adalah alias ke localhost mesin host.
class AppConstants {
  AppConstants._();

  // ─── Base URL ──────────────────────────────────────────────
  // Untuk emulator Android: 10.0.2.2 → localhost mesin host
  // Untuk device fisik: ganti dengan IP LAN komputer (misal 192.168.x.x)
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // ─── Timeout ───────────────────────────────────────────────
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // ─── SharedPreferences Keys ────────────────────────────────
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserData = 'user_data';
  static const String keyUserRole = 'user_role';
  // ─── Sanitasi URL Gambar ─────────────────────────────────────
  static String sanitizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    try {
      final uri = Uri.parse(baseUrl);
      final currentHost = uri.host;
      final currentPort = uri.port;
      final currentScheme = uri.scheme;
      
      final currentServer = "$currentScheme://$currentHost" + (currentPort != 0 ? ":$currentPort" : "");
      
      String sanitized = url;
      // Ganti URL yang memiliki port 8000
      sanitized = sanitized
          .replaceAll('http://localhost:8000', currentServer)
          .replaceAll('http://127.0.0.1:8000', currentServer)
          .replaceAll('http://10.0.2.2:8000', currentServer);
          
      // Ganti URL lokal tanpa port (port 80 default) ke server port aktif saat ini
      if (sanitized.startsWith('http://localhost/') && !sanitized.startsWith('http://localhost:')) {
        sanitized = sanitized.replaceFirst('http://localhost/', '$currentServer/');
      }
      if (sanitized.startsWith('http://127.0.0.1/') && !sanitized.startsWith('http://127.0.0.1:')) {
        sanitized = sanitized.replaceFirst('http://127.0.0.1/', '$currentServer/');
      }
      
      return sanitized;
    } catch (e) {
      return url;
    }
  }
}
