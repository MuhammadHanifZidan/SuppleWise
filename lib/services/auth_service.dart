import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'api_service.dart';

/// Service untuk mengelola autentikasi.
///
/// Saat ini menyimpan user info secara lokal.
/// Google Sign-In akan diintegrasikan setelah SHA-1 + Client ID ready.
class AuthService {
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';

  static SharedPreferences? _prefs;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Scopes opsional bisa ditambahkan di sini, contoh:
    // scopes: ['email', 'https://www.googleapis.com/auth/contacts.readonly'],
  );

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Cek apakah user sudah login (ada token tersimpan).
  static Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getString(_keyToken) != null;
  }

  /// Ambil stored token.
  static Future<String?> getToken() async {
    final prefs = await _instance;
    return prefs.getString(_keyToken);
  }

  /// Simpan token dan user data.
  static Future<void> saveSession(String token, User user) async {
    final prefs = await _instance;
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  /// Ambil user tersimpan dari cache lokal.
  static Future<User?> getUser() async {
    final prefs = await _instance;
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Logout — hapus semua data auth lokal dan sign out dari Google.
  static Future<void> logout() async {
    final prefs = await _instance;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      // Ignored: Mungkin belum pernah login Google (misal: sisa dev-token)
    }
  }

  /// Login dengan Google Sign-In asli
  static Future<User> googleLogin() async {
    try {
      // Mulai proses login via Google Play Services
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Login dibatalkan oleh pengguna.');
      }

      // Opsional: Ambil auth object jika kamu butuh idToken / accessToken
      // untuk dikirimkan ke backend Laravel.
      // final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      // final idToken = googleAuth.idToken;

      final user = User(
        id: googleUser.id.hashCode, // Hash ID sebagai mock ID numerik
        name: googleUser.displayName ?? 'Google User',
        email: googleUser.email,
      );

      // Sementara menggunakan id Google sebagai token karena belum ada auth backend
      await saveSession(googleUser.id, user);

      return user;
    } catch (e) {
      throw Exception('Gagal login dengan Google: $e');
    }
  }

  /// Login dengan Email dan Password ke Laravel Backend
  static Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        await saveSession(token, user);
        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Login gagal');
      }
    } catch (e) {
      throw Exception('Gagal login: $e');
    }
  }

  /// Register dengan Name, Email dan Password ke Laravel Backend
  static Future<User> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final user = User.fromJson(data['user']);

        await saveSession(token, user);
        return user;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Register gagal');
      }
    } catch (e) {
      throw Exception('Gagal register: $e');
    }
  }
}
