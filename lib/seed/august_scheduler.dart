import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedAugustSchedule() async {
  final firestore = FirebaseFirestore.instance;

  final cashiers = ['C01', 'C02'];
  final mechanics = ['M01', 'M02', 'M03', 'M04'];

  DateTime start = DateTime(2025, 8, 1);
  DateTime end = DateTime(2025, 8, 31);
  int cashierIndex = 0;
  int mechIndex = 0;

  final batch = firestore.batch();

  for (DateTime d = start; d.isBefore(end.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
    // skip Sundays
    if (d.weekday == DateTime.sunday) continue;

    for (int shift = 0; shift < 2; shift++) {
      final shiftStart = shift == 0 ? '09:00' : '13:00';
      final shiftEnd = shift == 0 ? '15:00' : '19:00';

      // pick cashier
      final cashier = cashiers[cashierIndex % cashiers.length];
      cashierIndex++;

      // pick 2 mechanics
      final mech1 = mechanics[mechIndex % mechanics.length];
      mechIndex++;
      final mech2 = mechanics[mechIndex % mechanics.length];
      mechIndex++;

      for (var staffId in [cashier, mech1, mech2]) {
        final doc = firestore.collection('schedules').doc();
        batch.set(doc, {
          'staffId': staffId,
          'date': Timestamp.fromDate(d),
          'shiftStart': shiftStart,
          'shiftEnd': shiftEnd,
          'status': 'working',
        });
      }
    }
  }

  await batch.commit();
  print("August schedule seeded");
}