import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<void> seedAppointments() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  final serviceTypes = [
    'Oil Change',
    'Brake Inspection',
    'Tire Replacement',
    'Battery Replacement',
    'Aircon Repair',
    'General Service',
    'Engine Tune-up'
  ];

  final statuses = [
    'Scheduled',
    'In Progress',
    'Completed',
    'Cancelled',
    'Pending'
  ];

  String generateNotes(String serviceType) {
    switch (serviceType) {
      case 'Oil Change':
        return 'Changed oil and oil filter';
      case 'Brake Inspection':
        return 'Checked brake pads and discs';
      case 'Tire Replacement':
        return 'Replaced front tires, checked alignment';
      case 'Battery Replacement':
        return 'Installed new battery and checked charging system';
      case 'Aircon Repair':
        return 'Replaced compressor and recharged refrigerant';
      case 'General Service':
        return 'Performed full service check-up';
      case 'Engine Tune-up':
        return 'Adjusted engine timing and replaced spark plugs';
      default:
        return 'Service completed';
    }
  }

  List<Map<String, dynamic>> appointments = [];

  for (int i = 1; i <= 50; i++) {
    String appointmentId = 'A${i.toString().padLeft(3, '0')}';
    String customerId = 'C${(random.nextInt(10) + 1).toString().padLeft(2, '0')}';
    String carId = 'V${(random.nextInt(10) + 1).toString().padLeft(3, '0')}';
    String serviceType = serviceTypes[random.nextInt(serviceTypes.length)];
    String status = statuses[random.nextInt(statuses.length)];

    DateTime randomDate = DateTime(
      2024,
      random.nextInt(9) + 1,
      random.nextInt(28) + 1,
      random.nextInt(8) + 8,
      random.nextInt(60),
    );

    appointments.add({
      'id': appointmentId,
      'customerId': customerId,
      'carId': carId,
      'date': Timestamp.fromDate(randomDate),
      'serviceType': serviceType,
      'status': status,
      'notes': generateNotes(serviceType),
    });
  }

  final batch = firestore.batch();
  for (var appointment in appointments) {
    final ref = firestore.collection('appointments').doc(appointment['id'] as String);
    batch.set(ref, appointment);
  }
  await batch.commit();
  print("50 Appointments seed");
}
