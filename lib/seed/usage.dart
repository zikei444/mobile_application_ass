import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

Future<void> seedSparePartUsage() async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  // Spare parts IDs
  final sparePartIds = ['P01', 'P02', 'P03', 'P04', 'P05'];

  // Number of usage records to create
  const int totalRecords = 20;

  for (int i = 0; i < totalRecords; i++) {
    // Auto-increment ID: U001, U002, ...
    final id = 'U${(i + 1).toString().padLeft(3, '0')}';

    // Randomly select spare part
    final sparePartId = sparePartIds[random.nextInt(sparePartIds.length)];

    // Random usage quantity
    final quantity = random.nextInt(20) + 1; // 1 to 20

    // Create usage record
    await firestore.collection('spare_part_usage').doc(id).set({
      'id': id,
      'spare_part_id': sparePartId,
      'quantity': quantity,
      'usedAt': Timestamp.fromDate(
        DateTime.now().subtract(Duration(days: random.nextInt(30))), // random date in past month
      ),
    });

    print('Created usage: $id, spare_part_id: $sparePartId, quantity: $quantity');
  }

  print('Spare part usage seeding completed!');
}

// Call this in main() or a script
void main() async {
  await seedSparePartUsage();
}
