import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class Auth extends ChangeNotifier {
  bool loading = true;
  String? token;
  Map<String, dynamic>? user;
  String get role => user?['role'] ?? '';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    final u = p.getString('user');
    if (u != null) user = jsonDecode(u);
    Api.token = token;
    loading = false;
    notifyListeners();
  }

  Future<void> setSession(Map<String, dynamic> d) async {
    token = d['token'];
    user = Map<String, dynamic>.from(d['user']);
    Api.token = token;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token!);
    await p.setString('user', jsonEncode(user));
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    user = null;
    Api.token = null;
    final p = await SharedPreferences.getInstance();
    await p.clear();
    notifyListeners();
  }
}
