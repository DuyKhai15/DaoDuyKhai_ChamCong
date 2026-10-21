import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

// ---------- Tổng quan ----------
class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});
  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  Map? s;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      s = await Api.get('/attendance/summary-today');
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (s == null) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(14), children: [
        const Text('Hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPurpleDark)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          children: [
            StatCard('Tổng nhân viên', '${s!['totalEmployees']}', Icons.people),
            StatCard('Đã chấm công', '${s!['present']}', Icons.check_circle, color: Colors.green),
            StatCard('Đi trễ', '${s!['late']}', Icons.alarm, color: Colors.orange),
            StatCard('Nghỉ phép', '${s!['onLeave']}', Icons.beach_access, color: Colors.blue),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.pending_actions, color: kPurple),
            title: Text('${s!['pendingLeaves']} đơn nghỉ phép đang chờ duyệt'),
          ),
        ),
      ]),
    );
  }
}

// ---------- Danh sách chấm công ----------
class AttendanceAdminPage extends StatefulWidget {
  final bool canEdit;
  const AttendanceAdminPage({super.key, required this.canEdit});
  @override
  State<AttendanceAdminPage> createState() => _AttendanceAdminPageState();
}

class _AttendanceAdminPageState extends State<AttendanceAdminPage> {
  DateTime date = DateTime.now();
  List items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      items = (await Api.get('/attendance?date=$d')) as List;
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _edit(Map a) async {
    final note = TextEditingController(text: a['note'] ?? '');
    String status = a['status'];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Sửa: ${a['fullName']}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              value: status,
              items: const [DropdownMenuItem(value: 'DungGio', child: Text('Đúng giờ')), DropdownMenuItem(value: 'DiTre', child: Text('Đi trễ'))],
              onChanged: (v) => setS(() => status = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: note, decoration: const InputDecoration(labelText: 'Ghi chú')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
          ],
        ),
      ),
    );
    if (ok == true) {
      try {
        await Api.put('/attendance/${a['id']}', {'status': status, 'note': note.text});
        _load();
      } catch (e) {
        if (mounted) toast(context, '$e', error: true);
      }
    }
  }

  Future<void> _del(Map a) async {
    if (!await confirm(context, 'Xóa bản ghi chấm công của ${a['fullName']}?')) return;
    try {
      await Api.delete('/attendance/${a['id']}');
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.calendar_month),
            label: Text('Ngày ${date.day}/${date.month}/${date.year}'),
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime(2024), lastDate: DateTime.now());
              if (d != null) {
                date = d;
                _load();
              }
            },
          ),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const Center(child: Text('Không có dữ liệu chấm công'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final a = items[i] as Map;
                        final late = (a['lateMinutes'] ?? 0) > 0;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          elevation: 0,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: late ? Colors.orange.shade100 : Colors.green.shade100, child: Icon(late ? Icons.alarm : Icons.check, color: late ? Colors.orange : Colors.green)),
                            title: Text('${a['fullName']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('Vào ${hhmm(a['checkInTime'])} • Ra ${hhmm(a['checkOutTime'])} • ${a['method']}\n${late ? 'Trễ ${a['lateMinutes']} phút' : 'Đúng giờ'} • ${a['workHours']}h${a['note'] != null ? '\nGhi chú: ${a['note']}' : ''}'),
                            isThreeLine: true,
                            trailing: widget.canEdit
                                ? Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(icon: const Icon(Icons.edit, color: kPurple), onPressed: () => _edit(a)),
                                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _del(a)),
                                  ])
                                : null,
                          ),
                        );
                      },
                    ),
        ),
      ]);
}

// ---------- Duyệt nghỉ phép ----------
class LeaveReviewPage extends StatefulWidget {
  const LeaveReviewPage({super.key});
  @override
  State<LeaveReviewPage> createState() => _LeaveReviewPageState();
}

class _LeaveReviewPageState extends State<LeaveReviewPage> {
  List items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      items = (await Api.get('/leaves')) as List;
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _review(Map l, String st) async {
    try {
      await Api.put('/leaves/${l['id']}/review', {'status': st});
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (items.isEmpty) return const Center(child: Text('Chưa có đơn nghỉ phép'));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (_, i) {
          final l = items[i] as Map;
          final pending = l['status'] == 'ChoDuyet';
          return Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${l['fullName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${ddmmyyyy(l['fromDate'])} → ${ddmmyyyy(l['toDate'])}'),
                Text('Lý do: ${l['reason']}'),
                const SizedBox(height: 6),
                if (pending)
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => _review(l, 'TuChoi'), child: const Text('Từ chối'))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton(onPressed: () => _review(l, 'DaDuyet'), child: const Text('Duyệt'))),
                  ])
                else
                  Chip(label: Text(l['status'] == 'DaDuyet' ? 'Đã duyệt' : 'Từ chối'), backgroundColor: l['status'] == 'DaDuyet' ? Colors.green.shade100 : Colors.red.shade100),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ---------- Báo cáo tháng ----------
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  int month = DateTime.now().month, year = DateTime.now().year;
  List items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      items = (await Api.get('/attendance/report?month=$month&year=$year')) as List;
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                value: month,
                decoration: const InputDecoration(labelText: 'Tháng'),
                items: [for (var m = 1; m <= 12; m++) DropdownMenuItem(value: m, child: Text('Tháng $m'))],
                onChanged: (v) {
                  month = v!;
                  _load();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<int>(
                value: year,
                decoration: const InputDecoration(labelText: 'Năm'),
                items: [for (var y = DateTime.now().year; y >= DateTime.now().year - 3; y--) DropdownMenuItem(value: y, child: Text('$y'))],
                onChanged: (v) {
                  year = v!;
                  _load();
                },
              ),
            ),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const Center(child: Text('Không có dữ liệu'))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final r = items[i] as Map;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          elevation: 0,
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: kPurpleLight, child: Text('${r['days']}', style: const TextStyle(color: kPurple, fontWeight: FontWeight.bold))),
                            title: Text('${r['fullName']}'),
                            subtitle: Text('${r['days']} ngày công • ${r['totalHours']} giờ\nĐi trễ ${r['lateCount']} lần (${r['lateMinutes']} phút)'),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
        ),
      ]);
}

// ---------- QR động ----------
class QrDisplayPage extends StatefulWidget {
  const QrDisplayPage({super.key});
  @override
  State<QrDisplayPage> createState() => _QrDisplayPageState();
}

class _QrDisplayPageState extends State<QrDisplayPage> {
  String? token;
  int left = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetch();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (left <= 1) {
        _fetch();
      } else if (mounted) {
        setState(() => left--);
      }
    });
  }

  Future<void> _fetch() async {
    try {
      final r = await Api.get('/qr/current');
      if (mounted) setState(() {
        token = r['token'];
        left = r['expiresIn'];
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
        child: token == null
            ? const CircularProgressIndicator()
            : Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Nhân viên quét mã này để chấm công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: kPurple.withOpacity(.2), blurRadius: 20)]),
                  child: QrImageView(data: token!, size: 250, eyeStyle: const QrEyeStyle(color: kPurpleDark, eyeShape: QrEyeShape.square), dataModuleStyle: const QrDataModuleStyle(color: kPurple, dataModuleShape: QrDataModuleShape.square)),
                ),
                const SizedBox(height: 16),
                Text('Tự đổi mã sau $left giây', style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 6),
                SizedBox(width: 200, child: LinearProgressIndicator(value: left / 30, color: kPurple, backgroundColor: kPurpleLight)),
              ]),
      );
}
