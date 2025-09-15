import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staff_detail_page.dart';

class StaffListPage extends StatelessWidget {
  const StaffListPage({Key? key}) : super(key: key);

  Future<void> _addStaff(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final hourlyRateController = TextEditingController();
    String role = 'Cashier'; // 默认值

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Add New Staff"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter name" : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                    validator: (v) =>
                    v == null || v.trim().isEmpty ? "Enter phone" : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(
                          value: 'Cashier', child: Text("Cashier")),
                      DropdownMenuItem(
                          value: 'Mechanic', child: Text("Mechanic")),
                    ],
                    onChanged: (v) => role = v!,
                  ),
                  TextFormField(
                    controller: hourlyRateController,
                    decoration:
                    const InputDecoration(labelText: "Hourly Rate"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Enter hourly rate";
                      }
                      final rate = double.tryParse(v);
                      if (rate == null) {
                        return "Hourly rate must be a number";
                      }
                      if (rate <= 0) {
                        return "Hourly rate must be greater than 0";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final name = nameController.text.trim();
                  final phone = phoneController.text.trim();
                  final hourlyRate =
                  double.parse(hourlyRateController.text.trim());

                  // 🔹 自动生成 ID
                  final prefix = role == 'Cashier' ? 'C' : 'M';
                  final snap = await FirebaseFirestore.instance
                      .collection('staff')
                      .where('role', isEqualTo: role)
                      .orderBy('id', descending: true)
                      .limit(1)
                      .get();

                  int nextNum = 1;
                  if (snap.docs.isNotEmpty) {
                    final lastId = snap.docs.first['id'] as String;
                    final numPart =
                        int.tryParse(lastId.substring(1)) ?? 0;
                    nextNum = numPart + 1;
                  }
                  final newId = "$prefix${nextNum.toString().padLeft(2, '0')}";

                  await FirebaseFirestore.instance
                      .collection('staff')
                      .doc(newId)
                      .set({
                    'id': newId,
                    'name': name,
                    'phone': phone,
                    'role': role,
                    'hourlyRate': hourlyRate,
                    'dateJoined': Timestamp.now(),
                  });

                  Navigator.pop(ctx);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editStaff(BuildContext context, String docId, Map<String, dynamic> data) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    final hourlyRateController = TextEditingController(text: (data['hourlyRate'] ?? '').toString());
    String role = data['role'] ?? 'Cashier';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Edit Staff"),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Enter name" : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: "Phone"),
                    validator: (v) => v == null || v.trim().isEmpty ? "Enter phone" : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: "Role"),
                    items: const [
                      DropdownMenuItem(value: 'Cashier', child: Text("Cashier")),
                      DropdownMenuItem(value: 'Mechanic', child: Text("Mechanic")),
                    ],
                    onChanged: (v) => role = v!,
                  ),
                  TextFormField(
                    controller: hourlyRateController,
                    decoration: const InputDecoration(labelText: "Hourly Rate"),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return "Enter hourly rate";
                      if (double.tryParse(v) == null) return "Must be a number";
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance.collection('staff').doc(docId).update({
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'role': role,
                    'hourlyRate': double.parse(hourlyRateController.text.trim()),
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteStaff(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this staff?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('staff').doc(docId).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Staff')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('staff').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;

          // 分组
          final cashiers = docs.where((d) => d['role'] == 'Cashier').toList();
          final mechanics = docs.where((d) => d['role'] == 'Mechanic').toList();

          Widget buildGroup(String title, List staffList, Color color) {
            if (staffList.isEmpty) return const SizedBox.shrink();
            return Card(
              margin: const EdgeInsets.all(8),
              elevation: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    color: color.withOpacity(0.2),
                    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  ),
                  Column(
                    children: staffList.map<Widget>((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = d['name'] ?? '';
                      final role = d['role'] ?? '';
                      final id = d['id'] ?? d.id;
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: color, child: Text(id)),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("$role\nPhone: ${d['phone']}"),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => StaffCalendarPage(staffId: d.id)),
                          );
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editStaff(context, d.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteStaff(context, d.id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            );
          }

          return ListView(
            children: [
              buildGroup("Cashiers", cashiers, Colors.green),
              buildGroup("Mechanics", mechanics, Colors.blue),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addStaff(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
