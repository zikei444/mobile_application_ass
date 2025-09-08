import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedStaff() async {
  final firestore = FirebaseFirestore.instance;

  final staff = [
    {
      'id': 'C01',
      'name': 'Alice Tan',
      'role': 'Cashier',
      'phone': '019-9236842',
      'dateJoined': Timestamp.fromDate(DateTime(2024, 1, 15)),
      'hourlyRate': 12.5,
    },
    {
      'id': 'C02',
      'name': 'Brian Lee',
      'role': 'Cashier',
      'phone': '013-2692722',
      'dateJoined': Timestamp.fromDate(DateTime(2024, 5, 10)),
      'hourlyRate': 12.5,
    },
    {
      'id': 'M01',
      'name': 'Chong Wei',
      'role': 'Mechanic',
      'phone': '011-33233333',
      'dateJoined': Timestamp.fromDate(DateTime(2023, 9, 1)),
      'hourlyRate': 15.0,
    },
    {
      'id': 'M02',
      'name': 'Johnson Tan',
      'role': 'Mechanic',
      'phone': '013-3432333',
      'dateJoined': Timestamp.fromDate(DateTime(2023, 9, 1)),
      'hourlyRate': 19.0,
    },
    {
      'id': 'M03',
      'name': 'Jackson Lim',
      'role': 'Mechanic',
      'phone': '014-3195233',
      'dateJoined': Timestamp.fromDate(DateTime(2023, 9, 1)),
      'hourlyRate': 14.0,
    },
    {
      'id': 'M04',
      'name': 'Jasper Cheng',
      'role': 'Mechanic',
      'phone': '012-3338745',
      'dateJoined': Timestamp.fromDate(DateTime(2023, 9, 1)),
      'hourlyRate': 15.0,
    },
  ];

  final batch = firestore.batch();
  for (var s in staff) {
    final ref = firestore.collection('staff').doc(s['id'] as String);
    batch.set(ref, s);
  }
  await batch.commit();
  print("Staff seeded");
}