import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'staff_detail_page.dart';

class StaffListPage extends StatelessWidget {
  const StaffListPage({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Staff')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('staff').snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          return ListView(
            children: docs.map((d) {
              final name = d['name'] ?? '';
              final role = d['role'] ?? '';
              return ListTile(
                title: Text(name),
                subtitle: Text(role),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StaffDetailPage(staffId: d.id),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
