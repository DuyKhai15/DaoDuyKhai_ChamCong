import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api.dart';
import '../../core/auth.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'check_service.dart';

/// Dashboard của nhân viên: Trang chủ | Lịch sử | Nghỉ phép | Cá nhân
class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});
  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  int idx = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const _HomeTab(), const _HistoryTab(), const _LeaveTab(), const _ProfileTab()];
    return Scaffold(
      body: IndexedStack(index: idx, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        indicatorColor: kPurpleLight,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: kPurple), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.history), selectedIcon: Icon(Icons.history, color: kPurple), label: 'Lịch sử'),
          NavigationDestination(icon: Icon(Icons.event_busy_outlined), selectedIcon: Icon(Icons.event_busy, color: kPurple), label: 'Nghỉ phép'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: kPurple), label: 'Cá nhân'),
        ],
      ),
    );
  }
}

// ================= Trang chủ =================
class _HomeTab extends StatefulWidget {
  const _HomeTab();
  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map? today;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      today = await Api.get('/attendance/today');
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() {});
  }

  Future<void> _check(String method) async {
    final rec = today?['record'];
    if (rec != null && rec['checkOutTime'] != null) return toast(context, 'Hôm nay bạn đã hoàn tất chấm công');
    final isIn = rec == null;
    setState(() => busy = true);
    try {
      final msg = await CheckService.run(context, isIn: isIn, method: method);
      if (mounted) toast(context, msg);
      await _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => busy = false);
  }

  Widget _method(String label, IconData icon, String method) => Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: busy ? null : () => _check(method),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: kPurple.withOpacity(.12), blurRadius: 10)]),
            child: Column(children: [
              CircleAvatar(radius: 26, backgroundColor: kPurpleLight, child: Icon(icon, color: kPurple, size: 28)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Auth>().user;
    final rec = today?['record'];
    final shift = today?['shift'];
    String status;
    Color color;
    if (rec == null) {
      status = 'Chưa check-in';
      color = Colors.white70;
    } else if (rec['checkOutTime'] == null) {
      status = 'Đang làm việc';
      color = Colors.lightGreenAccent;
    } else {
      status = 'Đã hoàn tất hôm nay';
      color = Colors.amberAccent;
    }
    final now = DateTime.now();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(padding: EdgeInsets.zero, children: [
        GradientHeader(
          child: SafeArea(
            bottom: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Xin chào,', style: const TextStyle(color: Colors.white70)),
              Text('${user?['fullName']}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text('${user?['department']?['name'] ?? ''}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(.15), borderRadius: BorderRadius.circular(16)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${now.day}/${now.month}/${now.year}  •  ${shift != null ? 'Ca ${shift['startTime'].toString().substring(0, 5)} - ${shift['endTime'].toString().substring(0, 5)}' : 'Chưa có ca'}', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Icon(Icons.circle, size: 12, color: color),
                    const SizedBox(width: 8),
                    Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Vào: ${hhmm(rec?['checkInTime'])}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                    Text('Ra: ${hhmm(rec?['checkOutTime'])}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ]),
                  if (rec != null && (rec['lateMinutes'] ?? 0) > 0) Text('Đi trễ ${rec['lateMinutes']} phút', style: const TextStyle(color: Colors.orangeAccent)),
                ]),
              ),
            ]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(rec == null ? 'Chọn cách CHECK-IN' : (rec['checkOutTime'] == null ? 'Chọn cách CHECK-OUT' : 'Hoàn tất chấm công'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: kPurpleDark)),
            const SizedBox(height: 12),
            Row(children: [
              _method('Vị trí GPS', Icons.my_location, 'GPS'),
              const SizedBox(width: 10),
              _method('Quét QR', Icons.qr_code_scanner, 'QR'),
              const SizedBox(width: 10),
              _method('Vân tay', Icons.fingerprint, 'BIOMETRIC'),
            ]),
            if (busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator(color: kPurple)),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.shield, color: kPurple),
                title: const Text('Chống gian lận'),
                subtitle: Text('Phải ở trong bán kính ${today?['radius'] ?? 200} m quanh công ty • QR đổi mỗi 30 giây • Chặn Fake GPS'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ================= Lịch sử =================
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
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
      items = (await Api.get('/attendance/my?month=$month&year=$year')) as List;
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalH = items.fold<double>(0, (s, e) => s + ((e['workHours'] ?? 0) as num).toDouble());
    final lateN = items.where((e) => (e['lateMinutes'] ?? 0) > 0).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử chấm công')),
      body: Column(children: [
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
            Expanded(child: Text('${items.length} ngày • ${totalH.toStringAsFixed(1)}h\nĐi trễ $lateN lần', style: const TextStyle(fontWeight: FontWeight.w600, color: kPurpleDark))),
          ]),
        ),
        Expanded(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const Center(child: Text('Chưa có dữ liệu'))
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
                            title: Text(ddmmyyyy(a['date'])),
                            subtitle: Text('Vào ${hhmm(a['checkInTime'])} • Ra ${hhmm(a['checkOutTime'])} • ${a['method']}'),
                            trailing: Text(late ? 'Trễ ${a['lateMinutes']}p' : 'Đúng giờ', style: TextStyle(color: late ? Colors.orange : Colors.green, fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}

// ================= Nghỉ phép (CRUD của nhân viên) =================
class _LeaveTab extends StatefulWidget {
  const _LeaveTab();
  @override
  State<_LeaveTab> createState() => _LeaveTabState();
}

class _LeaveTabState extends State<_LeaveTab> {
  List items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      items = (await Api.get('/leaves/my')) as List;
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _create() async {
    DateTime from = DateTime.now(), to = DateTime.now();
    final reason = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Tạo đơn nghỉ phép', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPurple)),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Từ ngày: ${from.day}/${from.month}/${from.year}'),
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: from, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setS(() {
                    from = d;
                    if (to.isBefore(from)) to = from;
                  });
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Đến ngày: ${to.day}/${to.month}/${to.year}'),
                onPressed: () async {
                  final d = await showDatePicker(context: ctx, initialDate: to, firstDate: from, lastDate: DateTime.now().add(const Duration(days: 365)));
                  if (d != null) setS(() => to = d);
                },
              ),
              const SizedBox(height: 8),
              TextField(controller: reason, decoration: const InputDecoration(labelText: 'Lý do')),
              const SizedBox(height: 14),
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gửi đơn')),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await Api.post('/leaves', {'fromDate': from.toIso8601String(), 'toDate': to.toIso8601String(), 'reason': reason.text});
      if (mounted) toast(context, 'Đã gửi đơn nghỉ phép');
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  Future<void> _delete(Map l) async {
    if (!await confirm(context, 'Xóa đơn nghỉ phép này?')) return;
    try {
      await Api.delete('/leaves/${l['id']}');
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Đơn nghỉ phép')),
        floatingActionButton: FloatingActionButton(onPressed: _create, child: const Icon(Icons.add)),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const Center(child: Text('Bạn chưa có đơn nghỉ phép nào'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final l = items[i] as Map;
                      final st = l['status'];
                      final c = st == 'DaDuyet' ? Colors.green : (st == 'TuChoi' ? Colors.red : Colors.orange);
                      return Card(
                        elevation: 0,
                        child: ListTile(
                          title: Text('${ddmmyyyy(l['fromDate'])} → ${ddmmyyyy(l['toDate'])}'),
                          subtitle: Text('${l['reason']}'),
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(st == 'DaDuyet' ? 'Đã duyệt' : (st == 'TuChoi' ? 'Từ chối' : 'Chờ duyệt'), style: TextStyle(color: c, fontWeight: FontWeight.bold)),
                            if (st == 'ChoDuyet') InkWell(onTap: () => _delete(l), child: const Icon(Icons.delete_outline, color: Colors.red, size: 20)),
                          ]),
                        ),
                      );
                    },
                  ),
      );
}

// ================= Cá nhân =================
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    final u = auth.user ?? {};
    Widget row(IconData i, String l, String? v) => ListTile(leading: Icon(i, color: kPurple), title: Text(l, style: const TextStyle(fontSize: 12, color: Colors.black54)), subtitle: Text(v ?? '-', style: const TextStyle(fontSize: 16)));
    return ListView(padding: EdgeInsets.zero, children: [
      GradientHeader(
        child: SafeArea(
          child: Column(children: [
            const CircleAvatar(radius: 40, backgroundColor: Colors.white, child: Icon(Icons.person, size: 48, color: kPurple)),
            const SizedBox(height: 10),
            Text('${u['fullName']}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('@${u['username']}', style: const TextStyle(color: Colors.white70)),
          ]),
        ),
      ),
      row(Icons.email, 'Email', u['email']),
      row(Icons.phone, 'Số điện thoại', u['phone']),
      row(Icons.apartment, 'Phòng ban', u['department']?['name']),
      row(Icons.schedule, 'Ca làm việc', u['shift'] != null ? '${u['shift']['name']} (${u['shift']['startTime'].toString().substring(0, 5)} - ${u['shift']['endTime'].toString().substring(0, 5)})' : null),
      const Divider(),
      Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton.icon(icon: const Icon(Icons.logout, color: Colors.red), label: const Text('Đăng xuất', style: TextStyle(color: Colors.red)), onPressed: () => auth.logout()),
      ),
    ]);
  }
}
