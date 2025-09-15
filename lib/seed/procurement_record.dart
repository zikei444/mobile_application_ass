import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedProcurements() async {
  final firestore = FirebaseFirestore.instance;

  final procurements = [
    {
      'id': 'PR01',
      'item': 'Brake Pad',
      'quantity': 50,
      'totalCost': 50 * 80.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 8, 5, 10, 30, 15)),
    },
    {
      'id': 'PR02',
      'item': 'Oil Filter',
      'quantity': 100,
      'totalCost': 100 * 20.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 7, 20, 14, 15, 45)),
    },
    {
      'id': 'PR03',
      'item': 'Car Battery',
      'quantity': 20,
      'totalCost': 20 * 250.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 5, 10, 11, 20, 30)),
    },
    {
      'id': 'PR04',
      'item': 'Spark Plug',
      'quantity': 70,
      'totalCost': 70 * 10.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 6, 22, 9, 50, 0)),
    },
    {
      'id': 'PR05',
      'item': 'Air Filter',
      'quantity': 60,
      'totalCost': 60 * 25.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 8, 12, 16, 10, 20)),
    },
    {
      'id': 'PR06',
      'item': 'Brake Disc',
      'quantity': 40,
      'totalCost': 40 * 120.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 8, 8, 13, 25, 50)),
    },
    {
      'id': 'PR07',
      'item': 'Car Battery Plus',
      'quantity': 15,
      'totalCost': 15 * 300.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 5, 15, 10, 40, 10)),
    },
    {
      'id': 'PR08',
      'item': 'High Performance Spark Plug',
      'quantity': 80,
      'totalCost': 80 * 15.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 6, 25, 12, 0, 5)),
    },
  ];

  final batch = firestore.batch();
  for (var p in procurements) {
    final ref = firestore.collection('procurements').doc(p['id'] as String);
    batch.set(ref, p);
  }

  await batch.commit();
}
