import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class UserService {
  static const String _baseUrl = 'https://reqres.in/api/users';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': 'reqres-free-v1',
  };

  // Mengambil daftar user[cite: 1, 3]
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await http
          .get(
        Uri.parse('$_baseUrl?page=1'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['data'];
        return data.map((item) => UserModel.fromJson(item)).toList();
      } else {
        throw Exception('Gagal mengambil data (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on TimeoutException {
      throw Exception('Request terlalu lama, coba lagi');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Membuat user baru[cite: 1, 3]
  Future<Map<String, dynamic>> createUser(String name, String job) async {
    try {
      final response = await http
          .post(
        Uri.parse(_baseUrl),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'job': job,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal membuat user (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on TimeoutException {
      throw Exception('Request terlalu lama, coba lagi');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Memperbarui user[cite: 1, 3]
  Future<Map<String, dynamic>> updateUser(int id, String name, String job) async {
    try {
      final response = await http
          .put(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'job': job,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal memperbarui user (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on TimeoutException {
      throw Exception('Request terlalu lama, coba lagi');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Menghapus user[cite: 1, 3]
  Future<void> deleteUser(int id) async {
    try {
      final response = await http
          .delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      } else {
        throw Exception('Gagal menghapus user (Status: ${response.statusCode})');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet');
    } on TimeoutException {
      throw Exception('Request terlalu lama, coba lagi');
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}