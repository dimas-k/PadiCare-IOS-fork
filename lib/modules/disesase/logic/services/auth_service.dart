import 'package:shared_preferences/shared_preferences.dart';

/// Layanan autentikasi sederhana dengan kredensial HARDCODE.
///
/// Sesuai arahan pembimbing: username & password ditanam langsung di kode,
/// tanpa backend / database. Status login disimpan di shared_preferences
/// sehingga user tidak perlu login ulang setiap membuka aplikasi.
class AuthService {
  // ==================== KREDENSIAL HARDCODE ====================
  static const String _validUsername = 'petanipintar';
  static const String _validPassword = 'padisehat123';

  static const String _loggedInKey = 'is_logged_in';

  /// Cek apakah username & password cocok dengan nilai hardcode.
  bool checkCredentials(String username, String password) {
    return username.trim() == _validUsername && password == _validPassword;
  }

  /// Coba login. Mengembalikan true bila berhasil dan menyimpan status login.
  Future<bool> login(String username, String password) async {
    if (!checkCredentials(username, password)) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, true);
    return true;
  }

  /// Apakah user sudah login sebelumnya?
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  /// Keluar / logout.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }
}
