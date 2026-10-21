import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/widgets.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final f = GlobalKey<FormState>();
  final name = TextEditingController(), email = TextEditingController(), user = TextEditingController(), phone = TextEditingController(), pass = TextEditingController();
  bool busy = false;

  Future<void> _submit() async {
    if (!f.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final r = await Api.post('/auth/register', {
        'fullName': name.text.trim(), 'email': email.text.trim(), 'username': user.text.trim(),
        'phone': phone.text.trim(), 'password': pass.text,
      });
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => OtpScreen(userId: r['userId'], purpose: 'Register', devOtp: r['devOtp'])));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => busy = false);
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Bắt buộc nhập' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Đăng ký tài khoản')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: f,
            child: Column(children: [
              TextFormField(controller: name, validator: _req, decoration: const InputDecoration(labelText: 'Họ và tên', prefixIcon: Icon(Icons.badge))),
              const SizedBox(height: 12),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email không hợp lệ' : null,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: user, validator: _req, decoration: const InputDecoration(labelText: 'Tên đăng nhập', prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 12),
              TextFormField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 12),
              TextFormField(
                controller: pass,
                obscureText: true,
                validator: (v) => (v == null || v.length < 6) ? 'Tối thiểu 6 ký tự' : null,
                decoration: const InputDecoration(labelText: 'Mật khẩu', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 22),
              ElevatedButton(onPressed: busy ? null : _submit, child: const Text('Đăng ký & nhận OTP email')),
            ]),
          ),
        ),
      );
}
