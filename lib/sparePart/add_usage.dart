import 'package:cloud_firestore/cloud_firestore.dart';

class AddUsage {
  // Get next ID
  static Future<String> _generateUsageId() async {
    final snap = await FirebaseFirestore.instance
        .collection("spare_part_usage")
        .orderBy("id", descending: true)
        .limit(1)
        .get();

    int nextNum = 1;
    if (snap.docs.isNotEmpty) {
      final lastId = snap.docs.first['id'];
      final numericPart = lastId.replaceAll(RegExp(r'[^0-9]'), '');
      nextNum = int.parse(numericPart) + 1;
    }
    return "U${nextNum.toString().padLeft(3, '0')}";
  }

  // Create one usage record
  static Future<void> createUsage({
    required String invoiceId,
    required String sparePartId,
    required int quantity,
  }) async {
    final usageId = await _generateUsageId();

    await FirebaseFirestore.instance
        .collection("spare_part_usage")
        .doc(usageId)
        .set({
      "id": usageId,
      "invoice_id": invoiceId,
      "quantity": quantity,
      "spare_part_id": sparePartId,
      "usedAt": Timestamp.now(),
    });
  }

  static Future<void> createUsagesForInvoice(
      String invoiceId, List<Map<String, dynamic>> selectedParts) async {
    for (var p in selectedParts) {
      await createUsage(
        invoiceId: invoiceId,
        sparePartId: p['part_id'],
        quantity: p['quantity'],
      );
    }
  }
}
