import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedCustomers() async {
  final firestore = FirebaseFirestore.instance;

  final customers = [
    {
      'id': 'C01',
      'name': 'John Lim',
      'phone': '012-3456789',
      'email': 'john.lim@example.com',
      'address': '12, Jalan Bukit Bintang, Kuala Lumpur',
      'carId': 'V001',
      'appointmentId': 'A001',
      'lastServiced': Timestamp.fromDate(DateTime(2024, 8, 20, 10, 0)),
      'dateJoined': Timestamp.fromDate(DateTime(2023, 5, 10, 14, 30)),
    },
    {
      'id': 'C02',
      'name': 'Melissa Tan',
      'phone': '013-9876543',
      'email': 'melissa.tan@example.com',
      'address': '88, Jalan Ampang, Kuala Lumpur',
      'carId': 'V002',
      'appointmentId': 'A002',
      'lastServiced': Timestamp.fromDate(DateTime(2024, 7, 15, 15, 30)),
      'dateJoined': Timestamp.fromDate(DateTime(2023, 6, 1, 9, 0)),
    },
    {
      'id': 'C03',
      'name': 'Alex Wong',
      'phone': '011-2233445',
      'email': 'alex.wong@example.com',
      'address': '5, Jalan Tun Razak, Kuala Lumpur',
      'carId': 'V003',
      'appointmentId': 'A003',
      'lastServiced': Timestamp.fromDate(DateTime(2024, 9, 5, 11, 15)),
      'dateJoined': Timestamp.fromDate(DateTime(2023, 7, 15, 11, 15)),
    },
    {
      'id': 'C04',
      'name': 'Siti Aminah',
      'phone': '014-5566778',
      'email': 'siti.aminah@example.com',
      'address': '21, Jalan Merdeka, Johor Bahru',
      'carId': 'V004',
      'appointmentId': 'A004',
      'lastServiced': Timestamp.fromDate(DateTime(2024, 6, 28, 16, 45)),
      'dateJoined': Timestamp.fromDate(DateTime(2023, 8, 25, 16, 45)),
    },
    {
      'id': 'C05',
      'name': 'Hafiz Rahman',
      'phone': '019-1122334',
      'email': 'hafiz.rahman@example.com',
      'address': '99, Jalan Penang, George Town',
      'carId': 'V005',
      'appointmentId': 'A005',
      'lastServiced': Timestamp.fromDate(DateTime(2024, 5, 10, 13, 20)),
      'dateJoined': Timestamp.fromDate(DateTime(2023, 9, 5, 13, 20)),
    },
  ];

  final batch = firestore.batch();
  for (var customer in customers) {
    final ref = firestore.collection('customers').doc(customer['id'] as String);
    batch.set(ref, customer);
  }
  await batch.commit();
  print("Customers seed");
}
