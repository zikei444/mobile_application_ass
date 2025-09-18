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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      "Add New Staff",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // ✅ Theme color
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter name" : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter phone" : null,
                    ),
                    const SizedBox(height: 12),

                    // Role Dropdown
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(
                        labelText: "Role",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Cashier',
                          child: Text("Cashier"),
                        ),
                        DropdownMenuItem(
                          value: 'Mechanic',
                          child: Text("Mechanic"),
                        ),
                      ],
                      onChanged: (v) => role = v!,
                    ),
                    const SizedBox(height: 12),

                    // Hourly Rate
                    TextFormField(
                      controller: hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: "Hourly Rate",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
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
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // ✅ Green theme
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              final name = nameController.text.trim();
                              final phone = phoneController.text.trim();
                              final hourlyRate = double.parse(
                                hourlyRateController.text.trim(),
                              );

                              // 🔹 Auto-generate ID
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
                              final newId =
                                  "$prefix${nextNum.toString().padLeft(2, '0')}";

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
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editStaff(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: data['name'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    final hourlyRateController = TextEditingController(
      text: (data['hourlyRate'] ?? '').toString(),
    );
    String role = data['role'] ?? 'Cashier';
    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // ✅ Rounded corners
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      "Edit Staff",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green, // ✅ Green title
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Name
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        labelStyle: TextStyle(color: Colors.grey),
                        floatingLabelStyle: TextStyle(
                          color: Colors.green,
                        ), // ✅ Label green when focused
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter name" : null,
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: "Phone",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        floatingLabelStyle: TextStyle(color: Colors.green),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? "Enter phone" : null,
                    ),
                    const SizedBox(height: 12),

                    // Role Dropdown
                    TextFormField(
                      initialValue: role,
                      decoration: const InputDecoration(
                        labelText: "Role",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        floatingLabelStyle: TextStyle(color: Colors.green),
                      ),
                      enabled: false, // read-only
                    ),
                    const SizedBox(height: 12),

                    // Hourly Rate
                    TextFormField(
                      controller: hourlyRateController,
                      decoration: const InputDecoration(
                        labelText: "Hourly Rate",
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                        floatingLabelStyle: TextStyle(color: Colors.green),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return "Enter hourly rate";
                        if (double.tryParse(v) == null)
                          return "Must be a number";
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green, // ✅ Green button
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              await FirebaseFirestore.instance
                                  .collection('staff')
                                  .doc(docId)
                                  .update({
                                    'name': nameController.text.trim(),
                                    'phone': phoneController.text.trim(),
                                    'role': role,
                                    'hourlyRate': double.parse(
                                      hourlyRateController.text.trim(),
                                    ),
                                  });
                              Navigator.pop(ctx);
                            }
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteStaff(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // ✅ rounded corners
        ),
        title: const Text(
          "Confirm Delete",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete this staff?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // ✅ red for delete
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
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
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
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
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  Column(
                    children: staffList.map<Widget>((d) {
                      final data = d.data() as Map<String, dynamic>;
                      final name = d['name'] ?? '';
                      final role = d['role'] ?? '';
                      final id = d['id'] ?? d.id;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Text(id),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("$role\nPhone: ${d['phone']}"),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffCalendarPage(staffId: d.id),
                            ),
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
                  ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addStaff(context),
        backgroundColor: Colors.green, // ✅ green theme
        foregroundColor: Colors.white, // ✅ white icon/text
        icon: const Icon(Icons.add),
        label: const Text("Add Staff"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // ✅ smoother look
        ),
      ),
    );
  }
}
