import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedJulySchedule() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  // 你的 staff 列表
  final cashiers = ['C01', 'C02'];
  final mechanics = ['M01', 'M02', 'M03', 'M04'];

  DateTime start = DateTime(2025, 7, 1);
  DateTime end = DateTime(2025, 7, 31);

  final batch = firestore.batch();

  for (DateTime d = start;
  d.isBefore(end.add(const Duration(days: 1)));
  d = d.add(const Duration(days: 1))) {
    // 跳过周日
    if (d.weekday == DateTime.sunday) continue;

    for (int shift = 0; shift < 2; shift++) {
      final shiftStart = shift == 0 ? '09:00' : '13:00';
      final shiftEnd = shift == 0 ? '15:00' : '19:00';

      // 随机选 cashier
      final cashier = cashiers[random.nextInt(cashiers.length)];

      // 随机选两个 mechanics (去重)
      final mechPool = [...mechanics]..shuffle(random);
      final mech1 = mechPool[0];
      final mech2 = mechPool[1];

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
  print("July schedule seeded");
}