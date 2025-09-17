import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedInvoices() async {
  final firestore = FirebaseFirestore.instance;

  // 可选的 service type
  final serviceTypes = ["Tyre Service", "Battery Service", "General Service"];

  // 现有 staff（只选 cashier）
  final cashiers = ["C01", "C02"];

  // 现有车辆
  final vehicles = ["V001", "V002", "V003", "V004", "V005"];

  // spare_parts 数据
  final spareParts = [
    {"id": "P01", "name": "Brake Pad", "category": "Brakes", "price": 120},
    {"id": "P02", "name": "Oil Filter", "category": "Engine", "price": 35},
    {"id": "P03", "name": "Spark Plug", "category": "Ignition", "price": 18},
    {"id": "P04", "name": "Air Filter", "category": "Engine", "price": 40},
    {"id": "P05", "name": "Car Battery", "category": "Electrical", "price": 350},
  ];

  final statuses = ["unpaid", "paid", "partial"];
  final paymentMethods = ["Cash", "Card", "E-Wallet"];

  for (int i = 1; i <= 20; i++) {
    final invoiceId = "INV${i.toString().padLeft(3, '0')}";
    final createdDate =
    DateTime.now().subtract(Duration(days: i * 2)); // 不同日期

    // 随机选 cashier & vehicle
    final handledBy = cashiers[i % cashiers.length];
    final vehicleId = vehicles[i % vehicles.length];

    // 随机 service type
    final serviceType = serviceTypes[i % serviceTypes.length];

    // 随机选 1–3 个 parts
    final parts = <Map<String, dynamic>>[];
    int total = 0;
    for (int j = 0; j < (1 + (i % 3)); j++) {
      final part = spareParts[(i + j) % spareParts.length];
      final qty = (1 + (i + j) % 4);
      final partTotal = (part["price"] as int) * qty;
      total += partTotal;
      parts.add({
        "part_id": part["id"],
        "name": part["name"],
        "category": part["category"],
        "price": part["price"],
        "quantity": qty,
        "total": partTotal,
      });
    }

    final status = statuses[i % statuses.length];
    final paymentMethod = paymentMethods[i % paymentMethods.length];

    int paymentReceive;
    int outstanding;

    if (status == "paid") {
      paymentReceive = total;
      outstanding = 0;
    } else if (status == "unpaid") {
      paymentReceive = 0;
      outstanding = total;
    } else {
      paymentReceive = (total * 0.5).round();
      outstanding = total - paymentReceive;
    }

    await firestore.collection("invoice").doc(invoiceId).set({
      "invoice_id": invoiceId,
      "created_date": createdDate,
      "handled_by": handledBy,
      "vehicle_id": vehicleId,
      "service_type": serviceType,
      "status": status,
      "payment_method": paymentMethod,
      "parts": parts,
      "total": total,
      "payment_receive": paymentReceive,
      "outstanding": outstanding,
    });
  }

  print("✅ Seeded 20 invoices with service_type and parts!");
}
