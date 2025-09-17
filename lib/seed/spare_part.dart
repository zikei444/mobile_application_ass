import 'package:cloud_firestore/cloud_firestore.dart';

String getStockLevel(int quantity) {
  if (quantity >= 200) return 'maximum';
  if (quantity >= 150) return 'average';
  if (quantity >= 70) return 'minimum';
  return 'danger';
}

Future<void> seedSpareParts() async {
  final firestore = FirebaseFirestore.instance;

  final spareParts = [
    {
      'id': 'P01',
      'name': 'Brake Pad',
      'category': 'Brakes',
      'quantity': 220,
      'cost': 80.0,
      'price': 120.0,
      'supplier': 'Auto Supply Co.',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 8, 5, 10, 30, 15)),
    },
    {
      'id': 'P02',
      'name': 'Oil Filter',
      'category': 'Engine',
      'quantity': 160,
      'cost': 20.0,
      'price': 35.0,
      'supplier': 'Filter World',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 7, 20, 14, 15, 45)),
    },
    {
      'id': 'P03',
      'name': 'Spark Plug',
      'category': 'Ignition',
      'quantity': 90,
      'cost': 10.0,
      'price': 18.0,
      'supplier': 'IgnitePro',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 6, 22, 9, 50, 0)),
    },
    {
      'id': 'P04',
      'name': 'Air Filter',
      'category': 'Engine',
      'quantity': 45,
      'cost': 25.0,
      'price': 40.0,
      'supplier': 'Filter World',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 8, 12, 16, 10, 20)),
    },
    {
      'id': 'P05',
      'name': 'Car Battery',
      'category': 'Electrical',
      'quantity': 30,
      'cost': 250.0,
      'price': 350.0,
      'supplier': 'Battery Hub',
      'lastRestock': Timestamp.fromDate(DateTime(2024, 5, 10, 11, 20, 30)),
    },
  ];

  final batch = firestore.batch();
  for (var part in spareParts) {
    final ref = firestore.collection('spare_parts').doc(part['id'] as String);
    batch.set(ref, {
      ...part,
      'level': getStockLevel(part['quantity'] as int),
      'unitCost': part['cost'],
    });
  }

  await batch.commit();
}
