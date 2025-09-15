import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_application_ass/workScheduler/staff_detail_page.dart';

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

  Future<void> _openAddScheduleDialog() async {
    String? selectedStaffId;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Schedule"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // dropdown: staff list
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Select Staff"),
                    items: staffMap.entries.map((e) {
                      final staffId = e.key;
                      final name = e.value['name'] ?? staffId;
                      final role = e.value['role'] ?? '';
                      return DropdownMenuItem(
                        value: staffId,
                        child: Text("$name ($role)"),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() => selectedStaffId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // pick start time
                  ElevatedButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) setStateDialog(() => startTime = t);
                    },
                    child: Text(startTime == null
                        ? "Pick Start Time"
                        : "Start: ${startTime!.format(context)}"),
                  ),

                  const SizedBox(height: 8),

                  // pick end time
                  ElevatedButton(
                    onPressed: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (t != null) setStateDialog(() => endTime = t);
                    },
                    child: Text(endTime == null
                        ? "Pick End Time"
                        : "End: ${endTime!.format(context)}"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedStaffId != null &&
                        startTime != null &&
                        endTime != null) {
                      final startStr =
                      startTime!.format(context); // e.g. 09:00 AM
                      final endStr = endTime!.format(context);

                      await FirebaseFirestore.instance
                          .collection('schedules')
                          .add({
                        'staffId': selectedStaffId,
                        'date': Timestamp.fromDate(_selected),
                        'shiftStart': startStr,
                        'shiftEnd': endStr,
                        'status': 'working',
                      });

                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StaffCalendarPage(staffId: staffId),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddScheduleDialog,
        label: const Text("Add Schedule"),
        icon: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
