import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> seedSparePartUsage() async {
  final firestore = FirebaseFirestore.instance;

  final invoiceSnap = await firestore.collection('invoice').get();
  final invoices = invoiceSnap.docs;

  int usageCounter = 1;

  // Generate track part usage record based on invoice created

  for (var inv in invoices) {
    final invoiceData = inv.data();
    final invoiceId = invoiceData['invoice_id'] ?? '';
    final createdDate = invoiceData['created_date'] as Timestamp? ?? Timestamp.now();
    final parts = (invoiceData['parts'] as List<dynamic>? ?? []);

    for (var p in parts) {
      final part = p as Map<String, dynamic>;
      final sparePartId = part['part_id'] ?? '';
      final quantity = part['quantity'] ?? 0;

      final usageId = "U${usageCounter.toString().padLeft(3, '0')}";

      await firestore.collection('spare_part_usage').doc(usageId).set({
        "id": usageId,
        "invoice_id": invoiceId,
        "spare_part_id": sparePartId,
        "quantity": quantity,
        "usedAt": createdDate, // use invoice created date
      });

      usageCounter++;
    }
  }

  print("Spare part usage seeding completed: $usageCounter records created.");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await seedSparePartUsage();
}
