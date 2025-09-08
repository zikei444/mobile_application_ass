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

  @override
  Widget build(BuildContext context) {
    // beginning and end of the chosen day
    final start = DateTime(_selected.year, _selected.month, _selected.day);
    final end = start.add(const Duration(days: 1));

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
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final startTime = d['shiftStart'] ?? '';
                    final endTime   = d['shiftEnd'] ?? '';
                    final staff = [d['staffId'] ?? ''];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text('Shift: ($startTime – $endTime)'),
                        subtitle: Text('Staff: ${staff.join(', ')}'),
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
