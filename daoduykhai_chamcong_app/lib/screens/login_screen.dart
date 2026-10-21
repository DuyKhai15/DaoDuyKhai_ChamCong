import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'otp_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final u = TextEditingController(), p = TextEditingController();
  bool busy = false, hide = true;

  Future<void> _login() async {
    if (u.text.trim().isEmpty || p.text.isEmpty) return toast(context, 'Nhập tên đăng nhập và mật khẩu', error: true);
    setState(() => busy = true);
    try {
      final r = await Api.post('/auth/login', {'username': u.text.trim(), 'password': p.text});
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(userId: r['userId'], purpose: 'Login', devOtp: r['devOtp'])));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } catch (e) {
      if (mounted) toast(context, 'Không kết nối được máy chủ: $e', error: true);
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [
            GradientHeader(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(children: const [
                    CircleAvatar(radius: 38, backgroundColor: Colors.white, child: Icon(Icons.fingerprint, size: 48, color: kPurple)),
                    SizedBox(height: 14),
                    Text('CHẤM CÔNG', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    Text('DaoDuyKhai', style: TextStyle(color: Colors.white70)),
                  ]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                TextField(controller: u, decoration: const InputDecoration(labelText: 'Tên đăng nhập', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 14),
                TextField(
                  controller: p,
                  obscureText: hide,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(icon: Icon(hide ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => hide = !hide)),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(onPressed: busy ? null : _login, child: busy ? const CircularProgressIndicator() : const Text('Đăng nhập (nhận OTP)')),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Chưa có tài khoản? Đăng ký qua email'),
                ),
              ]),
            ),
          ]),
        ),
      );
}
