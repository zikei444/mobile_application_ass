import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StaffDetailPage extends StatefulWidget {
  final String staffId;
  const StaffDetailPage({Key? key, required this.staffId}) : super(key: key);

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final dayStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final dayEnd   = dayStart.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Detail')),
      body: FutureBuilder<DocumentSnapshot>(
        future: db.collection('staff').doc(widget.staffId).get(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final data = snap.data!.data() as Map<String, dynamic>? ?? {};
          final name = data['name'] ?? '';
          final role = data['role'] ?? '';
          final hourly = (data['hourlyRate'] ?? 0).toString();
          final joined = (data['dateJoined'] as Timestamp?)?.toDate();

          return Column(
            children: [
              ListTile(
                title: Text(name, style: const TextStyle(fontSize: 20)),
                subtitle: Text(role),
                trailing: Text('RM$hourly/hr'),
              ),
              if (joined != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Joined: ${DateFormat.yMMMd().format(joined)}'),
                ),
              const Divider(),

              // --- Date picker bar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    }),
                  ),
                  Text(DateFormat.yMMMMd().format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    }),
                  ),
                ],
              ),

              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: db
                      .collection('schedules')
                      .where('staffId', isEqualTo: widget.staffId)
                      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
                      .where('date', isLessThan: Timestamp.fromDate(dayEnd))
                      .snapshots(),
                  builder: (context, shiftSnap) {
                    if (!shiftSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final docs = shiftSnap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text('No shift for this day'));
                    }

                    double totalHours = 0;
                    final tiles = docs.map((d) {
                      final ts = d['date'] as Timestamp;
                      final day = DateFormat.yMMMd().format(ts.toDate());
                      final start = d['shiftStart'] ?? '';
                      final end   = d['shiftEnd'] ?? '';
                      final status = d['status'] ?? '';

                      // compute hours
                      final sParts = start.split(':');
                      final eParts = end.split(':');
                      if (sParts.length == 2 && eParts.length == 2) {
                        final sHour = int.tryParse(sParts[0]) ?? 0;
                        final sMin  = int.tryParse(sParts[1]) ?? 0;
                        final eHour = int.tryParse(eParts[0]) ?? 0;
                        final eMin  = int.tryParse(eParts[1]) ?? 0;
                        final startDt = DateTime(0, 1, 1, sHour, sMin);
                        final endDt   = DateTime(0, 1, 1, eHour, eMin);
                        final diff = endDt.difference(startDt).inMinutes / 60.0;
                        totalHours += diff;
                      }

                      return ListTile(
                        title: Text('$day  ($status)'),
                        subtitle: Text('Shift: $start – $end'),
                      );
                    }).toList();

                    return Column(
                      children: [
                        Expanded(child: ListView(children: tiles)),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Total workload today: ${totalHours.toStringAsFixed(1)} hrs',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
