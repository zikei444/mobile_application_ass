import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'all_staff.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selected = DateTime.now();
  Map<String, Map<String, dynamic>> staffMap = {};

  @override
  void initState() {
    super.initState();
    _loadStaffs();
  }

  Future<void> _loadStaffs() async {
    final snap = await FirebaseFirestore.instance.collection('staff').get();
    final map = <String, Map<String, dynamic>>{};
    for (var s in snap.docs) {
      map[s.id] = s.data();
    }
    setState(() => staffMap = map);
  }


  @override
  Widget build(BuildContext context) {
    // beginning and end of the chosen day
    final start = DateTime(_selected.year, _selected.month, _selected.day);
    final end = start.add(const Duration(days: 1));
    // role 对应颜色
    final Map<String, Color> roleColors = {
      'Cashier': Colors.green,
      'Mechanic': Colors.blue,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'View All Staff',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffListPage()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Flutter built-in calendar widget
          CalendarDatePicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            initialDate: _selected,
            onDateChanged: (d) => setState(() => _selected = d),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                  .where('date', isLessThan: Timestamp.fromDate(end))
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No shift for this day'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    // 先把 docs 转成可排序的 List
                    final sortedDocs = [...docs];
                    sortedDocs.sort((a, b) {
                      final ra = staffMap[a['staffId']]?['role'] ?? '';
                      final rb = staffMap[b['staffId']]?['role'] ?? '';
                      return ra.compareTo(rb); // 依 role 字母顺序排
                    });

                    final d = sortedDocs[i].data() as Map<String, dynamic>;
                    final startTime = d['shiftStart'] ?? '';
                    final endTime   = d['shiftEnd'] ?? '';
                    final staffId   = d['staffId'] ?? '';

                    // 查 staffMap
                    final staffData = staffMap[staffId];
                    final name = staffData?['name'] ?? staffId;
                    final role = staffData?['role'] ?? '';

                    // role 映射到颜色
                    final color = roleColors[role] ?? Colors.grey;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.person, color: color),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text('$role • Shift: $startTime – $endTime'),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
