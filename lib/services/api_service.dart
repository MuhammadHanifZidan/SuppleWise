import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/category.dart';
import '../models/criteria.dart';
import '../models/supplier.dart';
import '../models/ranking_result.dart';
import 'auth_service.dart';

/// Service utama untuk berkomunikasi dengan REST API Laravel.
///
/// Semua endpoint menggunakan base URL yang dikonfigurasi sesuai platform:
/// - Android Emulator: http://10.0.2.2:8000/api
/// - iOS Simulator / Desktop / Web: http://localhost:8000/api
class ApiService {
  /// Base URL API — otomatis menyesuaikan platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api';
    }
    // Ganti IP ini dengan IP Local PC Anda jika menggunakan device fisik
    if (Platform.isAndroid || Platform.isIOS) {
      return 'http://0.0.0.0:8000/api';
    }
    return 'http://localhost:8000/api';
  }

  /// Header default untuk setiap request, termasuk Bearer token jika ada.
  static Future<Map<String, String>> get _headers async {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = await AuthService.getToken();
    if (token != null && token.isNotEmpty && token != 'dev-token') {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  /// Helper untuk GET request.
  static Future<http.Response> _get(String path) async {
    return http.get(Uri.parse('$baseUrl$path'), headers: await _headers);
  }

  /// Helper untuk POST request.
  static Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    return http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers,
      body: jsonEncode(body),
    );
  }

  /// Helper untuk PUT request.
  static Future<http.Response> _put(String path, Map<String, dynamic> body) async {
    return http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers,
      body: jsonEncode(body),
    );
  }

  /// Helper untuk DELETE request.
  static Future<http.Response> _delete(String path) async {
    return http.delete(Uri.parse('$baseUrl$path'), headers: await _headers);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mengambil semua kategori dari API.
  static Future<List<Category>> getCategories() async {
    final response = await _get('/categories');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    }
    throw Exception('Gagal mengambil data kategori: ${response.statusCode}');
  }

  /// Membuat kategori baru.
  static Future<Category> createCategory(String name) async {
    final response = await _post('/categories', {'category_name': name});
    if (response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal membuat kategori: ${response.statusCode}');
  }

  /// Menghapus kategori.
  static Future<void> deleteCategory(int id) async {
    final response = await _delete('/categories/$id');
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus kategori: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPPLIERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mengambil daftar supplier. Opsional filter berdasarkan [categoryId].
  static Future<List<Supplier>> getSuppliers({int? categoryId}) async {
    String path = '/suppliers';
    if (categoryId != null) path += '?category_id=$categoryId';
    final response = await _get(path);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Supplier.fromJson(json)).toList();
    }
    throw Exception('Gagal mengambil data supplier: ${response.statusCode}');
  }

  /// Mengambil detail satu supplier berdasarkan [id].
  static Future<Supplier> getSupplier(int id) async {
    final response = await _get('/suppliers/$id');
    if (response.statusCode == 200) {
      return Supplier.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal mengambil detail supplier: ${response.statusCode}');
  }

  /// Membuat supplier baru.
  static Future<Supplier> createSupplier(Map<String, dynamic> data) async {
    final response = await _post('/suppliers', data);
    if (response.statusCode == 201) {
      return Supplier.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal membuat supplier: ${response.statusCode}');
  }

  /// Mengupdate supplier.
  static Future<Supplier> updateSupplier(int id, Map<String, dynamic> data) async {
    final response = await _put('/suppliers/$id', data);
    if (response.statusCode == 200) {
      return Supplier.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal mengupdate supplier: ${response.statusCode}');
  }

  /// Menghapus supplier.
  static Future<void> deleteSupplier(int id) async {
    final response = await _delete('/suppliers/$id');
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus supplier: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CRITERIA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mengambil semua kriteria dari API.
  static Future<List<Criteria>> getCriteria() async {
    final response = await _get('/criteria');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Criteria.fromJson(json)).toList();
    }
    throw Exception('Gagal mengambil data kriteria: ${response.statusCode}');
  }

  /// Membuat kriteria baru.
  static Future<Criteria> createCriteria(Map<String, dynamic> data) async {
    final response = await _post('/criteria', data);
    if (response.statusCode == 201) {
      return Criteria.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal membuat kriteria: ${response.statusCode}');
  }

  /// Mengupdate kriteria.
  static Future<Criteria> updateCriteria(int id, Map<String, dynamic> data) async {
    final response = await _put('/criteria/$id', data);
    if (response.statusCode == 200) {
      return Criteria.fromJson(jsonDecode(response.body));
    }
    throw Exception('Gagal mengupdate kriteria: ${response.statusCode}');
  }

  /// Menghapus kriteria.
  static Future<void> deleteCriteria(int id) async {
    final response = await _delete('/criteria/$id');
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus kriteria: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPPLIER VALUES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mengambil semua nilai supplier.
  static Future<List<Map<String, dynamic>>> getSupplierValues() async {
    final response = await _get('/supplier-values');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('Gagal mengambil nilai supplier: ${response.statusCode}');
  }

  /// Membuat/mengupdate nilai supplier per kriteria.
  static Future<void> upsertSupplierValue(Map<String, dynamic> data) async {
    final response = await _post('/supplier-values', data);
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Gagal menyimpan nilai: ${response.statusCode}');
    }
  }

  /// Mengupdate satu nilai supplier.
  static Future<void> updateSupplierValue(int id, Map<String, dynamic> data) async {
    final response = await _put('/supplier-values/$id', data);
    if (response.statusCode != 200) {
      throw Exception('Gagal mengupdate nilai: ${response.statusCode}');
    }
  }

  /// Menghapus satu nilai supplier.
  static Future<void> deleteSupplierValue(int id) async {
    final response = await _delete('/supplier-values/$id');
    if (response.statusCode != 204) {
      throw Exception('Gagal menghapus nilai: ${response.statusCode}');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COPRAS RESULTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Mengambil hasil perhitungan COPRAS berdasarkan [categoryId].
  static Future<Map<String, dynamic>> getResults(int categoryId) async {
    final response = await _get('/results?category_id=$categoryId');
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final rankings = (data['rankings'] as List<dynamic>)
          .map((json) => RankingResult.fromJson(json as Map<String, dynamic>))
          .toList();

      return {
        'rankings': rankings,
        'supplier_count': data['supplier_count'] as int,
        'total_weight': data['total_weight'] as num,
        'category': data['category'],
        'criterias': data['criterias'],
      };
    }
    throw Exception('Gagal mengambil hasil COPRAS: ${response.statusCode}');
  }
}
