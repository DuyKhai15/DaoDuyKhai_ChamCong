import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/auth.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

class OtpScreen extends StatefulWidget {
  final int userId;
  final String purpose; // Login | Register
  final String? devOtp;
  const OtpScreen({super.key, required this.userId, required this.purpose, this.devOtp});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final c = TextEditingController();
  bool busy = false;
  String? dev;

  @override
  void initState() {
    super.initState();
    dev = widget.devOtp;
  }

  Future<void> _verify() async {
    if (c.text.trim().length != 6) return toast(context, 'OTP gồm 6 chữ số', error: true);
    setState(() => busy = true);
    try {
      if (widget.purpose == 'Login') {
        final r = await Api.post('/auth/verify-otp', {'userId': widget.userId, 'code': c.text.trim()});
        if (!mounted) return;
        final auth = context.read<Auth>();
        Navigator.popUntil(context, (r) => r.isFirst);
        await auth.setSession(Map<String, dynamic>.from(r));
      } else {
        final r = await Api.post('/auth/verify-email', {'userId': widget.userId, 'code': c.text.trim()});
        if (!mounted) return;
        toast(context, r['message']);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _resend() async {
    try {
      final r = await Api.post('/auth/resend-otp', {'userId': widget.userId, 'purpose': widget.purpose});
      setState(() => dev = r['devOtp']);
      if (mounted) toast(context, 'Đã gửi lại OTP');
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Xác thực OTP')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 20),
            const Icon(Icons.mark_email_read, size: 72, color: kPurple),
            const SizedBox(height: 12),
            const Text('Nhập mã OTP 6 số đã gửi tới email của bạn', textAlign: TextAlign.center),
            if (dev != null)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: kPurpleLight, borderRadius: BorderRadius.circular(10)),
                child: Text('[DEV] OTP: $dev', style: const TextStyle(fontWeight: FontWeight.bold, color: kPurpleDark)),
              ),
            const SizedBox(height: 20),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 10),
              decoration: const InputDecoration(counterText: ''),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: busy ? null : _verify, child: const Text('Xác nhận')),
            TextButton(onPressed: _resend, child: const Text('Gửi lại OTP')),
          ]),
        ),
      );
}
