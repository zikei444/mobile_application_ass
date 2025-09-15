import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class StaffCalendarPage extends StatefulWidget {
  final String staffId;
  const StaffCalendarPage({Key? key, required this.staffId}) : super(key: key);

  @override
  State<StaffCalendarPage> createState() => _StaffCalendarPageState();
}

class _StaffCalendarPageState extends State<StaffCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  double _allTimeHours = 0;
  Map<String, dynamic>? _staffInfo;
  Map<DateTime, List<Map<String, dynamic>>> _events = {}; // day -> shifts

  @override
  void initState() {
    super.initState();
    _loadStaffInfo(); //拉资料
    _loadMonthEvents(_focusedDay);
    _loadAllTimeHours(); // 算总小时
  }

  Future<void> _loadAllTimeHours() async {
    final snap = await FirebaseFirestore.instance
        .collection('schedules')
        .where('staffId', isEqualTo: widget.staffId.trim())
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      final data = doc.data();
      final startStr = data['shiftStart'] ?? '';
      final endStr = data['shiftEnd'] ?? '';
      final s = startStr.split(':'), e = endStr.split(':');
      if (s.length == 2 && e.length == 2) {
        final sH = int.tryParse(s[0]) ?? 0, sM = int.tryParse(s[1]) ?? 0;
        final eH = int.tryParse(e[0]) ?? 0, eM = int.tryParse(e[1]) ?? 0;
        total += DateTime(0, 1, 1, eH, eM)
            .difference(DateTime(0, 1, 1, sH, sM))
            .inMinutes / 60.0;
      }
    }
    setState(() => _allTimeHours = total);
  }

  Future<void> _loadStaffInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('staff')
        .doc(widget.staffId)
        .get();
    if (doc.exists) {
      // print('>>> staff data = ${doc.data()}');
      setState(() => _staffInfo = doc.data());
    }
  }

  void _loadMonthEvents(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final snap = await FirebaseFirestore.instance
        .collection('schedules')
        .where('staffId', isEqualTo: widget.staffId.trim())
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    // print('>>> loaded ${snap.docs.length} docs for ${widget.staffId}');
    final map = <DateTime, List<Map<String, dynamic>>>{};

    for (var doc in snap.docs) {
      final data = doc.data();
      data['docId'] = doc.id;
      final ts = data['date'] as Timestamp;
      final d = ts.toDate();
      // no min & sec
      final key = DateTime(d.year, d.month, d.day);
      print('add event key=$key, start=${data['shiftStart']}');
      map.putIfAbsent(key, () => []).add(data);
    }
    setState(() {
      _events = map;
      _selectedDay = DateTime.now();
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedShifts = _getEventsForDay(_selectedDay ?? _focusedDay);

    // compute total hours
    double totalHours = 0;
    for (final s in selectedShifts) {
      final start = (s['shiftStart'] ?? '') as String;
      final end = (s['shiftEnd'] ?? '') as String;
      final sParts = start.split(':');
      final eParts = end.split(':');
      if (sParts.length == 2 && eParts.length == 2) {
        final sH = int.tryParse(sParts[0]) ?? 0;
        final sM = int.tryParse(sParts[1]) ?? 0;
        final eH = int.tryParse(eParts[0]) ?? 0;
        final eM = int.tryParse(eParts[1]) ?? 0;
        totalHours += DateTime(0, 1, 1, eH, eM)
            .difference(DateTime(0, 1, 1, sH, sM))
            .inMinutes /
            60.0;
      }
    }

    return Scaffold(

      appBar: AppBar(
          title: const Text('Staff Schedule'),
        actions: [
          OutlinedButton(
            onPressed: _openAddScheduleDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.green),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add Schedule',
              style: TextStyle(color: Colors.green, fontSize: 16),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddScheduleDialog,   // 加schedule
        child: const Icon(Icons.schedule),
      ),
      body: Column(
        children: [
          if (_staffInfo != null) _buildStaffHeader(), // 顶部资料
          Expanded(
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2023, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                  _selectedDay != null &&
                      DateTime(day.year, day.month, day.day) ==
                          DateTime(_selectedDay!.year, _selectedDay!.month,
                              _selectedDay!.day),
                  eventLoader: (day) => _getEventsForDay(day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    _loadMonthEvents(focusedDay);
                  },
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: selectedShifts.isEmpty
                      ? const Center(child: Text('No shift for this day'))
                      : ListView(
                    padding: const EdgeInsets.all(12),
                    children: selectedShifts.map((s) {
                      final ts = s['date'] as Timestamp;
                      final dayStr = DateFormat('dd/MM/yyyy').format(ts.toDate());
                      final start = s['shiftStart'] ?? '';
                      final end = s['shiftEnd'] ?? '';
                      final status = s['status'] ?? '';
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.schedule, color: Colors.blue),
                          title: Text('$dayStr  ($status)',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Shift Time: $start – $end'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Schedule'),
                                  content: Text('Are you sure you want to delete the shift on $dayStr?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true && s['docId'] != null) {
                                await FirebaseFirestore.instance
                                    .collection('schedules')
                                    .doc(s['docId'])
                                    .delete();

                                _loadMonthEvents(_focusedDay); // 刷新界面
                                _loadAllTimeHours();
                              }
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffHeader() {
    final name = _staffInfo?['name'] ?? '';
    final role = _staffInfo?['role'] ?? '';
    final phone = _staffInfo?['phone'] ?? '';
    final id = _staffInfo?['id'] ?? widget.staffId;
    final hourlyRate = _staffInfo?['hourlyRate'] ?? 0;
    final joined = _staffInfo?['dateJoined'] is Timestamp
        ? DateFormat('dd/MM/yyyy').format(
        (_staffInfo!['dateJoined'] as Timestamp).toDate())
        : '';

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$name  ($role)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('ID: $id'),
            Text('Phone: $phone'),
            Text('Joined: $joined'),
            Text('Hourly Rate: RM${hourlyRate.toString()}'),
            const SizedBox(height: 6),
            Text('All-time total hours: ${_allTimeHours.toStringAsFixed(1)} h',
                style: const TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSchedule(
      DateTime date, TimeOfDay start, TimeOfDay end) async {
    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    await FirebaseFirestore.instance.collection('schedules').add({
      'staffId': widget.staffId,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'shiftStart': startStr,
      'shiftEnd': endStr,
      'status': 'working',
    });

    // 重新加载当前月 & 总小时
    _loadMonthEvents(_focusedDay);
    _loadAllTimeHours();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Schedule added')));
  }

  void _openAddScheduleDialog() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay? start, end;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text('Shift Start: ${start?.format(ctx) ?? '--:--'}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (t != null) setState(() => start = t);
                    },
                  ),
                  ListTile(
                    title: Text('Shift End: ${end?.format(ctx) ?? '--:--'}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 17, minute: 0),
                      );
                      if (t != null) setState(() => end = t);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (start != null && end != null) {
                      _saveSchedule(
                        selectedDate,
                        start!,
                        end!,
                      );
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}



