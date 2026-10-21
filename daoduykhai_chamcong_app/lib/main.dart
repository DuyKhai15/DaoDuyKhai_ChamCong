import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/auth.dart';
import 'core/theme.dart';
import 'screens/login_screen.dart';
import 'screens/admin/staff_home.dart';
import 'screens/employee/employee_home.dart';

void main() => runApp(ChangeNotifierProvider(create: (_) => Auth()..load(), child: const App()));

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Chấm Công DaoDuyKhai',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: Consumer<Auth>(builder: (_, a, __) {
          if (a.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          if (a.token == null) return const LoginScreen();
          // 3. Phân quyền: mỗi vai trò vào một giao diện riêng
          switch (a.role) {
            case 'Admin':
            case 'QuanLy':
              return const StaffHome();
            default:
              return const EmployeeHome();
          }
        }),
      );
}
