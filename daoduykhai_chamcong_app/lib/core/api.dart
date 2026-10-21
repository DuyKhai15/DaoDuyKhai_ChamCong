import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String message;
  ApiError(this.message);
  @override
  String toString() => message;
}

class Api {
  // Android Emulator: 10.0.2.2 trỏ về máy tính chạy Visual Studio (cổng 5080)
  // Máy thật: đổi thành IP LAN của máy tính, ví dụ http://192.168.1.10:5080
  static String host = 'http://192.168.1.180:5080';
  static String get base => '$host/api';
  static String? token;

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _handle(http.Response r) {
    dynamic body;
    if (r.body.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(r.bodyBytes));
      } catch (_) {
        body = r.body;
      }
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    if (r.statusCode == 401) throw ApiError('Sai thông tin hoặc phiên đăng nhập đã hết hạn');
    String msg = 'Lỗi ${r.statusCode}';
    if (body is Map) {
      if (body['message'] != null) {
        msg = body['message'].toString();
      } else if (body['errors'] is Map) {
        msg = (body['errors'] as Map).values.expand((e) => e as List).join('\n');
      } else if (body['title'] != null) {
        msg = body['title'].toString();
      }
    }
    throw ApiError(msg);
  }

  static Uri _u(String p) => Uri.parse('$base$p');
  static const _t = Duration(seconds: 15);

  static Future<dynamic> get(String p) async => _handle(await http.get(_u(p), headers: _h).timeout(_t));
  static Future<dynamic> post(String p, [Object? b]) async =>
      _handle(await http.post(_u(p), headers: _h, body: jsonEncode(b ?? {})).timeout(_t));
  static Future<dynamic> put(String p, Object b) async =>
      _handle(await http.put(_u(p), headers: _h, body: jsonEncode(b)).timeout(_t));
  static Future<dynamic> delete(String p) async => _handle(await http.delete(_u(p), headers: _h).timeout(_t));
}
