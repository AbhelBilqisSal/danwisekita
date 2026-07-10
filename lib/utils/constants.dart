import 'package:danwise/constants/constants.dart' as config;

/// Konstanta global untuk aplikasi DanWise.
///
/// Base URL menggunakan 10.0.2.2 agar dapat diakses dari
/// Android Emulator — ini adalah alias ke localhost mesin host.
class AppConstants {
  AppConstants._();

  // ─── Base URL ──────────────────────────────────────────────
  // Diambil secara dinamis dari lib/constants/constants.dart
  static String get baseUrl {
    final rawUrl = config.AppConstants.apiBaseUrl.trim();
    if (rawUrl.endsWith('/api')) return rawUrl;
    if (rawUrl.endsWith('/')) return '${rawUrl}api';
    return '$rawUrl/api';
  }

  // URL Server host utama tanpa /api (e.g. http://localhost:8000 atau https://ngrok...)
  static String get serverUrl {
    try {
      final uri = Uri.parse(baseUrl);
      final currentHost = uri.host;
      final currentPort = uri.port;
      final currentScheme = uri.scheme;
      return "$currentScheme://$currentHost" + (currentPort != 0 ? ":$currentPort" : "");
    } catch (e) {
      return config.AppConstants.backendHost;
    }
  }

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

  // Mendapatkan URL gambar profil/produk lengkap secara dinamis berdasarkan server aktif
  static String getImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('data:image')) return imageUrl;
    
    final server = serverUrl;
    
    // Jika path relatif (misal: "avatar.jpg")
    if (!imageUrl.startsWith('http')) {
      if (imageUrl.startsWith('uploads/')) {
        return '$server/storage/$imageUrl';
      }
      return '$server/storage/uploads/$imageUrl';
    }
    
    // Kembalikan URL yang sudah disanitasi jika ada localhost/127.0.0.1
    return sanitizeImageUrl(imageUrl);
  }
}
