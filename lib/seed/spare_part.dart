import 'package:cloud_firestore/cloud_firestore.dart';

String getStockLevel(int quantity) {
  if (quantity >= 200) {
    return 'maximum';
  } else if (quantity >= 150) {
    return 'average';
  } else if (quantity >= 70) {
    return 'minimum';
  } else {
    return 'danger';
  }
}

Future<void> seedSpareParts() async {
  final firestore = FirebaseFirestore.instance;

  final spareParts = [
    {
      'id': 'P01',
      'name': 'Brake Pad',
      'category': 'Brakes',
      'quantity': 220,
      'supplier': 'Auto Supply Co.',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 8, 1, 10, 30)),
    },
    {
      'id': 'P02',
      'name': 'Oil Filter',
      'category': 'Engine',
      'quantity': 160,
      'supplier': 'Filter World',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 7, 15, 14, 15)),
    },
    {
      'id': 'P03',
      'name': 'Spark Plug',
      'category': 'Ignition',
      'quantity': 90,
      'supplier': 'IgnitePro',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 6, 20, 9, 45)),
    },
    {
      'id': 'P04',
      'name': 'Air Filter',
      'category': 'Engine',
      'quantity': 45,
      'supplier': 'Filter World',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 8, 10, 16, 5)),
    },
    {
      'id': 'P05',
      'name': 'Car Battery',
      'category': 'Electrical',
      'quantity': 30,
      'supplier': 'Battery Hub',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 5, 5, 11, 20)),
    },
  ];

  final batch = firestore.batch();
  for (var part in spareParts) {
    final ref = firestore.collection('spare_parts').doc(part['id'] as String);
    final updatedPart = {
      ...part,
      'level': getStockLevel(part['quantity'] as int),
    };
    batch.set(ref, updatedPart);
  }

  await batch.commit();
  print("Spare parts seeded successfully");
}
