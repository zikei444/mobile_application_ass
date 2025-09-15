import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedCars() async {
  final firestore = FirebaseFirestore.instance;

  final cars = [
    {
      'id': 'V001',
      'brand': 'Toyota',
      'model': 'Vios',
      'year': 2020,
      'plateNumber': 'WXY 1234',
      'color': 'White',
    },
    {
      'id': 'V002',
      'brand': 'Honda',
      'model': 'Civic',
      'year': 2019,
      'plateNumber': 'ABC 5678',
      'color': 'Black',
    },
    {
      'id': 'V003',
      'brand': 'Perodua',
      'model': 'Myvi',
      'year': 2021,
      'plateNumber': 'JKA 9988',
      'color': 'Red',
    },
    {
      'id': 'V004',
      'brand': 'Proton',
      'model': 'X70',
      'year': 2022,
      'plateNumber': 'MNB 3344',
      'color': 'Grey',
    },
    {
      'id': 'V005',
      'brand': 'Nissan',
      'model': 'Almera',
      'year': 2018,
      'plateNumber': 'PKL 7777',
      'color': 'Silver',
    },
    {
      'id': 'V006',
      'brand': 'Mazda',
      'model': 'CX-5',
      'year': 2020,
      'plateNumber': 'QWE 4455',
      'color': 'Blue',
    },
    {
      'id': 'V007',
      'brand': 'BMW',
      'model': '320i',
      'year': 2021,
      'plateNumber': 'ZXC 1122',
      'color': 'Black',
    },
    {
      'id': 'V008',
      'brand': 'Mercedes',
      'model': 'C200',
      'year': 2019,
      'plateNumber': 'LMN 8899',
      'color': 'White',
    },
    {
      'id': 'V009',
      'brand': 'Ford',
      'model': 'Ranger',
      'year': 2022,
      'plateNumber': 'FGH 5566',
      'color': 'Orange',
    },
    {
      'id': 'V010',
      'brand': 'Hyundai',
      'model': 'Elantra',
      'year': 2020,
      'plateNumber': 'RTY 2233',
      'color': 'Grey',
    },
  ];

  final batch = firestore.batch();
  for (var car in cars) {
    final ref = firestore.collection('cars').doc(car['id'] as String);
    batch.set(ref, car);
  }
  await batch.commit();
  print("Cars seed");
}
