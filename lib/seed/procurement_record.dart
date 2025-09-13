import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedProcurements() async {
  final firestore = FirebaseFirestore.instance;

  final procurements = [
    {
      'id': 'PR01',
      'supplier': 'Auto Supply Co.',
      'item': 'Brake Pad',
      'quantity': 50,
      'unitPrice': 80.0,
      'totalCost': 50 * 80.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 8, 5, 10, 30, 15)),
    },
    {
      'id': 'PR02',
      'supplier': 'Filter World',
      'item': 'Oil Filter',
      'quantity': 100,
      'unitPrice': 20.0,
      'totalCost': 100 * 20.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 7, 20, 14, 15, 45)),
    },
    {
      'id': 'PR03',
      'supplier': 'Battery Hub',
      'item': 'Car Battery',
      'quantity': 20,
      'unitPrice': 250.0,
      'totalCost': 20 * 250.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 5, 10, 11, 20, 30)),
    },
    {
      'id': 'PR04',
      'supplier': 'IgnitePro',
      'item': 'Spark Plug',
      'quantity': 70,
      'unitPrice': 10.0,
      'totalCost': 70 * 10.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 6, 22, 9, 50, 0)),
    },
    {
      'id': 'PR05',
      'supplier': 'Filter World',
      'item': 'Air Filter',
      'quantity': 60,
      'unitPrice': 25.0,
      'totalCost': 60 * 25.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 8, 12, 16, 10, 20)),
    },
    {
      'id': 'PR06',
      'supplier': 'Auto Supply Co.',
      'item': 'Brake Disc',
      'quantity': 40,
      'unitPrice': 120.0,
      'totalCost': 40 * 120.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 8, 8, 13, 25, 50)),
    },
    {
      'id': 'PR07',
      'supplier': 'Battery Hub',
      'item': 'Car Battery Plus',
      'quantity': 15,
      'unitPrice': 300.0,
      'totalCost': 15 * 300.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 5, 15, 10, 40, 10)),
    },
    {
      'id': 'PR08',
      'supplier': 'IgnitePro',
      'item': 'High Performance Spark Plug',
      'quantity': 80,
      'unitPrice': 15.0,
      'totalCost': 80 * 15.0,
      'dateOrdered': Timestamp.fromDate(DateTime(2024, 6, 25, 12, 0, 5)),
    },
  ];

  final batch = firestore.batch();
  for (var procurement in procurements) {
    final ref = firestore.collection('procurements').doc(procurement['id'] as String);
    batch.set(ref, procurement);
  }

  await batch.commit();
  print("Procurement data seeded successfully with 8 records!");
}
