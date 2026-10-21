import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/api.dart';
import '../../core/theme.dart';

/// 3 chức năng trình bày: (1) Chia sẻ vị trí GPS  (2) Quét QR  (3) Vân tay / sinh trắc học
class CheckService {
  static Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw ApiError('Hãy bật GPS (dịch vụ vị trí)');
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) throw ApiError('Chưa cấp quyền vị trí cho ứng dụng');
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  /// method: GPS | QR | BIOMETRIC. Trả về thông báo từ server.
  static Future<String> run(BuildContext context, {required bool isIn, required String method}) async {
    String? qr;
    if (method == 'QR') {
      qr = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const QrScanPage()));
      if (qr == null) throw ApiError('Đã hủy quét QR');
    }
    if (method == 'BIOMETRIC') {
      final la = LocalAuthentication();
      if (!await la.isDeviceSupported()) throw ApiError('Thiết bị không hỗ trợ vân tay / sinh trắc học');
      final ok = await la.authenticate(
        localizedReason: 'Xác thực vân tay để chấm công',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (!ok) throw ApiError('Xác thực vân tay thất bại');
    }
    final pos = await _position();
    final r = await Api.post(isIn ? '/attendance/check-in' : '/attendance/check-out', {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'method': method,
      'qrToken': qr,
      'isMockLocation': pos.isMocked, // chống Fake GPS
    });
    return r['message'];
  }
}

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});
  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  bool done = false;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Quét QR chấm công')),
        body: Stack(children: [
          MobileScanner(onDetect: (cap) {
            if (done) return;
            final v = cap.barcodes.isNotEmpty ? cap.barcodes.first.rawValue : null;
            if (v != null) {
              done = true;
              Navigator.pop(context, v);
            }
          }),
          Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: kPurple, width: 4), borderRadius: BorderRadius.circular(20)))),
          const Positioned(bottom: 40, left: 0, right: 0, child: Center(child: Text('Đưa mã QR trên màn hình công ty vào khung', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
        ]),
      );
}
