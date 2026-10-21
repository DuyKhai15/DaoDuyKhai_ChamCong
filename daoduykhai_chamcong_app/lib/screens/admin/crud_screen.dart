import 'package:flutter/material.dart';
import '../../core/api.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

/// Màn hình CRUD dùng chung (Nhân viên, Phòng ban, Ca làm...) - cấu hình bằng danh sách FieldDef.
class FieldDef {
  final String key, label;
  final String kind; // text | number | password | bool | role | lookup | time
  final String? lookup; // endpoint nếu kind = lookup
  final bool required;
  const FieldDef(this.key, this.label, {this.kind = 'text', this.lookup, this.required = true});
}

class CrudScreen extends StatefulWidget {
  final String endpoint;
  final List<FieldDef> fields;
  final String Function(Map) titleOf;
  final String Function(Map) subtitleOf;
  final IconData icon;
  final bool canEdit;
  const CrudScreen({
    super.key,
    required this.endpoint,
    required this.fields,
    required this.titleOf,
    required this.subtitleOf,
    this.icon = Icons.list,
    this.canEdit = true,
  });
  @override
  State<CrudScreen> createState() => _CrudScreenState();
}

class _CrudScreenState extends State<CrudScreen> {
  List items = [];
  final lookups = <String, List>{};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      items = (await Api.get(widget.endpoint)) as List;
      for (final f in widget.fields.where((f) => f.kind == 'lookup')) {
        lookups[f.lookup!] = (await Api.get(f.lookup!)) as List;
      }
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  Widget _field(FieldDef f, Map<String, dynamic> v, StateSetter setS, bool isNew) {
    final req = f.required && !(f.kind == 'password' && !isNew);
    String? validator(String? x) => (req && (x == null || x.trim().isEmpty)) ? 'Bắt buộc nhập' : null;
    switch (f.kind) {
      case 'bool':
        return SwitchListTile(title: Text(f.label), value: v[f.key] == true, onChanged: (x) => setS(() => v[f.key] = x));
      case 'role':
        return DropdownButtonFormField<String>(
          value: v[f.key],
          decoration: InputDecoration(labelText: f.label),
          items: const [
            DropdownMenuItem(value: 'Admin', child: Text('Admin (Quản trị)')),
            DropdownMenuItem(value: 'QuanLy', child: Text('Quản lý')),
            DropdownMenuItem(value: 'NhanVien', child: Text('Nhân viên')),
          ],
          onChanged: (x) => setS(() => v[f.key] = x),
        );
      case 'lookup':
        return DropdownButtonFormField<dynamic>(
          value: (lookups[f.lookup] ?? []).any((e) => e['id'] == v[f.key]) ? v[f.key] : null,
          decoration: InputDecoration(labelText: f.label),
          items: [
            const DropdownMenuItem(value: null, child: Text('-- Không chọn --')),
            ...(lookups[f.lookup] ?? []).map((e) => DropdownMenuItem(value: e['id'], child: Text(e['name'].toString()))),
          ],
          onChanged: (x) => setS(() => v[f.key] = x),
        );
      case 'time':
        return InkWell(
          onTap: () async {
            final cur = (v[f.key] ?? '08:00').toString().split(':');
            final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: int.parse(cur[0]), minute: int.parse(cur[1])));
            if (t != null) setS(() => v[f.key] = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          },
          child: InputDecorator(
            decoration: InputDecoration(labelText: f.label, suffixIcon: const Icon(Icons.access_time)),
            child: Text(v[f.key]?.toString() ?? 'Chọn giờ'),
          ),
        );
      default:
        return TextFormField(
          initialValue: v[f.key]?.toString(),
          obscureText: f.kind == 'password',
          keyboardType: f.kind == 'number' ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: f.label + (f.kind == 'password' && !isNew ? ' (bỏ trống nếu không đổi)' : '')),
          validator: validator,
          onChanged: (x) => v[f.key] = x,
        );
    }
  }

  Future<void> _form([Map? item]) async {
    final values = <String, dynamic>{for (final f in widget.fields) f.key: item?[f.key]};
    for (final f in widget.fields) {
      if (f.kind == 'bool' && values[f.key] == null) values[f.key] = true;
      if (f.kind == 'role' && values[f.key] == null) values[f.key] = 'NhanVien';
      if (f.kind == 'time') values[f.key] = values[f.key] == null ? '08:00' : values[f.key].toString().substring(0, 5);
      if (f.kind == 'password') values[f.key] = null;
    }
    final formKey = GlobalKey<FormState>();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(item == null ? 'Thêm mới' : 'Cập nhật', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPurple)),
                const SizedBox(height: 14),
                for (final f in widget.fields) Padding(padding: const EdgeInsets.only(bottom: 12), child: _field(f, values, setS, item == null)),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                  },
                  child: const Text('Lưu'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
    if (ok != true) return;
    final body = <String, dynamic>{};
    for (final f in widget.fields) {
      final v = values[f.key];
      switch (f.kind) {
        case 'number':
        case 'lookup':
          body[f.key] = (v == null || v.toString().isEmpty) ? null : (v is num ? v : num.tryParse(v.toString()));
          break;
        case 'time':
          body[f.key] = '$v:00';
          break;
        case 'password':
          body[f.key] = (v == null || v.toString().isEmpty) ? null : v;
          break;
        default:
          body[f.key] = v;
      }
    }
    try {
      if (item == null) {
        await Api.post(widget.endpoint, body);
      } else {
        await Api.put('${widget.endpoint}/${item['id']}', body);
      }
      if (mounted) toast(context, 'Lưu thành công');
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  Future<void> _delete(Map item) async {
    if (!await confirm(context, 'Xóa "${widget.titleOf(item)}"?')) return;
    try {
      await Api.delete('${widget.endpoint}/${item['id']}');
      if (mounted) toast(context, 'Đã xóa');
      _load();
    } catch (e) {
      if (mounted) toast(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: widget.canEdit ? FloatingActionButton(onPressed: () => _form(), child: const Icon(Icons.add)) : null,
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: items.isEmpty
                    ? ListView(children: const [SizedBox(height: 120), Center(child: Text('Chưa có dữ liệu'))])
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final it = items[i] as Map;
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: kPurpleLight, child: Icon(widget.icon, color: kPurple)),
                              title: Text(widget.titleOf(it), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(widget.subtitleOf(it)),
                              onTap: widget.canEdit ? () => _form(it) : null,
                              trailing: widget.canEdit
                                  ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _delete(it))
                                  : null,
                            ),
                          );
                        },
                      ),
              ),
      );
}
