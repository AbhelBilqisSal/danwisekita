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
}
