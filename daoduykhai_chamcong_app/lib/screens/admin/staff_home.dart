import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth.dart';
import '../../core/theme.dart';
import 'crud_screen.dart';
import 'admin_pages.dart';

/// Giao diện quản trị: Admin thấy đầy đủ, QuanLy chỉ thấy phần giám sát.
class StaffHome extends StatefulWidget {
  const StaffHome({super.key});
  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _P {
  final String title;
  final IconData icon;
  final Widget page;
  _P(this.title, this.icon, this.page);
}

class _StaffHomeState extends State<StaffHome> {
  int idx = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    final isAdmin = auth.role == 'Admin';
    final pages = <_P>[
      _P('Tổng quan', Icons.dashboard, const SummaryPage()),
      if (isAdmin)
        _P(
          'Nhân viên',
          Icons.people,
          CrudScreen(
            endpoint: '/employees',
            icon: Icons.person,
            fields: const [
              FieldDef('fullName', 'Họ và tên'),
              FieldDef('username', 'Tên đăng nhập'),
              FieldDef('email', 'Email'),
              FieldDef('phone', 'Số điện thoại', required: false),
              FieldDef('password', 'Mật khẩu', kind: 'password'),
              FieldDef('role', 'Vai trò', kind: 'role'),
              FieldDef('departmentId', 'Phòng ban', kind: 'lookup', lookup: '/departments', required: false),
              FieldDef('shiftId', 'Ca làm việc', kind: 'lookup', lookup: '/shifts', required: false),
              FieldDef('isActive', 'Đang hoạt động', kind: 'bool'),
            ],
            titleOf: (e) => '${e['fullName']}',
            subtitleOf: (e) => '${e['username']} • ${e['role']} • ${e['department']?['name'] ?? 'Chưa có phòng'}${e['isActive'] == true ? '' : ' • KHÓA'}',
          ),
        )
      else
        _P(
          'Nhân viên',
          Icons.people,
          CrudScreen(
            endpoint: '/employees',
            canEdit: false,
            icon: Icons.person,
            fields: const [],
            titleOf: (e) => '${e['fullName']}',
            subtitleOf: (e) => '${e['username']} • ${e['role']} • ${e['department']?['name'] ?? 'Chưa có phòng'}',
          ),
        ),
      if (isAdmin)
        _P(
          'Phòng ban',
          Icons.apartment,
          CrudScreen(
            endpoint: '/departments',
            icon: Icons.apartment,
            fields: const [FieldDef('name', 'Tên phòng ban'), FieldDef('description', 'Mô tả', required: false)],
            titleOf: (e) => '${e['name']}',
            subtitleOf: (e) => '${e['description'] ?? ''}',
          ),
        ),
      if (isAdmin)
        _P(
          'Ca làm việc',
          Icons.schedule,
          CrudScreen(
            endpoint: '/shifts',
            icon: Icons.schedule,
            fields: const [FieldDef('name', 'Tên ca'), FieldDef('startTime', 'Giờ bắt đầu', kind: 'time'), FieldDef('endTime', 'Giờ kết thúc', kind: 'time')],
            titleOf: (e) => '${e['name']}',
            subtitleOf: (e) => '${e['startTime'].toString().substring(0, 5)} - ${e['endTime'].toString().substring(0, 5)}',
          ),
        ),
      _P('Chấm công', Icons.fact_check, AttendanceAdminPage(canEdit: isAdmin)),
      _P('Duyệt nghỉ phép', Icons.event_busy, const LeaveReviewPage()),
      _P('Báo cáo tháng', Icons.bar_chart, const ReportPage()),
      _P('QR chấm công động', Icons.qr_code_2, const QrDisplayPage()),
    ];
    if (idx >= pages.length) idx = 0;

    return Scaffold(
      appBar: AppBar(title: Text(pages[idx].title)),
      drawer: Drawer(
        child: ListView(padding: EdgeInsets.zero, children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(gradient: kGradient),
            currentAccountPicture: CircleAvatar(backgroundColor: Colors.white, child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.supervisor_account, color: kPurple, size: 32)),
            accountName: Text('${auth.user?['fullName']}'),
            accountEmail: Text('${isAdmin ? 'Trang quản trị' : 'Quản lý'} • ${auth.user?['email']}'),
          ),
          for (var i = 0; i < pages.length; i++)
            ListTile(
              leading: Icon(pages[i].icon, color: i == idx ? kPurple : null),
              title: Text(pages[i].title),
              selected: i == idx,
              selectedTileColor: kPurpleLight,
              onTap: () {
                setState(() => idx = i);
                Navigator.pop(context);
              },
            ),
          const Divider(),
          ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Đăng xuất'), onTap: () => auth.logout()),
        ]),
      ),
      body: KeyedSubtree(key: ValueKey(pages[idx].title), child: pages[idx].page),
    );
  }
}
