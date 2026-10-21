import 'package:flutter/material.dart';
import 'theme.dart';

void toast(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c).showSnackBar(SnackBar(
    content: Text(m),
    backgroundColor: error ? Colors.red.shade700 : kPurple,
    behavior: SnackBarBehavior.floating,
  ));
}

Future<bool> confirm(BuildContext c, String msg) async =>
    await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Đồng ý')),
        ],
      ),
    ) ??
    false;

class GradientHeader extends StatelessWidget {
  final Widget child;
  const GradientHeader({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: kGradient,
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
        ),
        child: child,
      );
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const StatCard(this.label, this.value, this.icon, {super.key, this.color = kPurple});
  @override
  Widget build(BuildContext context) => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
            const Spacer(),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ]),
        ),
      );
}

String hhmm(dynamic iso) {
  if (iso == null) return '--:--';
  final d = DateTime.parse(iso.toString());
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

String ddmmyyyy(dynamic iso) {
  final d = DateTime.parse(iso.toString());
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
