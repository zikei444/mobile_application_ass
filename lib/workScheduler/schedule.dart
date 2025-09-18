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

  // add schedule
  Future<void> _openAddScheduleDialog() async {
    String? selectedStaffId;
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 40,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      "Add Schedule",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // dropdown: staff list
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: "Select Staff",
                        labelStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
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
                    const SizedBox(height: 16),

                    // pick start time
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                timePickerTheme: const TimePickerThemeData(
                                  dialBackgroundColor: Colors.white,
                                  dialHandColor: Colors.green,
                                  entryModeIconColor: Colors.green,
                                  hourMinuteColor: Colors.green,
                                  hourMinuteTextColor: Colors.white,
                                ),
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green,
                                  // header, selected time
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black, // unselected text
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (t != null) setStateDialog(() => startTime = t);
                      },
                      label: Text(
                        startTime == null
                            ? "Pick Start Time"
                            : "Start: ${startTime!.format(context)}",
                      ),
                    ),

                    const SizedBox(height: 12),

                    // pick end time
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.access_time),
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                timePickerTheme: const TimePickerThemeData(
                                  dialBackgroundColor: Colors.white,
                                  dialHandColor: Colors.green,
                                  entryModeIconColor: Colors.green,
                                  hourMinuteColor: Colors.green,
                                  hourMinuteTextColor: Colors.white,
                                ),
                                colorScheme: ColorScheme.light(
                                  primary: Colors.green,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (t != null) setStateDialog(() => endTime = t);
                      },
                      label: Text(
                        endTime == null
                            ? "Pick End Time"
                            : "End: ${endTime!.format(context)}",
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            if (selectedStaffId != null &&
                                startTime != null &&
                                endTime != null) {
                              // convert to minutes for comparison
                              int startMinutes =
                                  startTime!.hour * 60 + startTime!.minute;
                              int endMinutes =
                                  endTime!.hour * 60 + endTime!.minute;

                              if (endMinutes <= startMinutes) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "End time must be after start time",
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return; // stop execution
                              }

                              final startStr = startTime!.format(context);
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
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please fill all fields"),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    // color for different role
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
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.green,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ),
            child: CalendarDatePicker(
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              initialDate: _selected,
              onDateChanged: (d) => setState(() => _selected = d),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where(
                    'date',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                  )
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
                    // convert to list and sort
                    final sortedDocs = [...docs];
                    sortedDocs.sort((a, b) {
                      final ra = staffMap[a['staffId']]?['role'] ?? '';
                      final rb = staffMap[b['staffId']]?['role'] ?? '';
                      return ra.compareTo(rb); // show cashier first
                    });

                    final d = sortedDocs[i].data() as Map<String, dynamic>;
                    final startTime = d['shiftStart'] ?? '';
                    final endTime = d['shiftEnd'] ?? '';
                    final staffId = d['staffId'] ?? '';

                    // check staffMap
                    final staffData = staffMap[staffId];
                    final name = staffData?['name'] ?? staffId;
                    final role = staffData?['role'] ?? '';

                    // role : color match
                    final color = roleColors[role] ?? Colors.grey;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.person, color: color),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text('$role • Shift: $startTime – $endTime'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StaffCalendarPage(staffId: staffId),
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
        label: const Text(
          "Add Schedule",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
