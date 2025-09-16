import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  String? handledBy;
  String? vehicleId;
  String? paymentMethod = "cash";
  String serviceType = "";
  double paymentReceived = 0;
  List<Map<String, dynamic>> selectedParts = [];

  double get total =>
      selectedParts.fold(0, (sum, p) => sum + (p['total'] as double));

  double get outstanding => total - paymentReceived;

  String get status {
    if (paymentReceived == 0) return "unpaid";
    if (paymentReceived < total) return "partial";
    return "paid";
  }

  Future<String> _generateInvoiceId() async {
    final snap = await FirebaseFirestore.instance
        .collection("invoice")
        .orderBy("invoice_id", descending: true)
        .limit(1)
        .get();

    int nextNum = 1;
    if (snap.docs.isNotEmpty) {
      final lastId = snap.docs.first['invoice_id']; // e.g. "INV020"
      final numericPart = lastId.replaceAll(RegExp(r'[^0-9]'), '');
      nextNum = int.parse(numericPart) + 1;
    }

    return "INV${nextNum.toString().padLeft(3, '0')}";
  }

  Future<void> _addInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    // ❌ 验证 Payment Received 不能超过 total
    if (paymentReceived > total) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment cannot exceed total")),
      );
      return;
    }

    final invoiceId = await _generateInvoiceId();

    await FirebaseFirestore.instance.collection("invoice").doc(invoiceId).set({
      "invoice_id": invoiceId,
      "created_date": Timestamp.now(),
      "handled_by": handledBy,
      "vehicle_id": vehicleId,
      "service_type": serviceType,
      "parts": selectedParts,
      "payment_method": paymentMethod,
      "payment_receive": paymentReceived,
      "outstanding": outstanding,
      "status": status,
      "total": total,
    });

    // 🔹 更新库存
    for (var p in selectedParts) {
      final partDoc =
      FirebaseFirestore.instance.collection("spare_parts").doc(p['part_id']);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(partDoc);
        if (!snap.exists) return;
        final currentStock = (snap['quantity'] as num).toInt();
        transaction.update(partDoc, {
          "quantity": currentStock - (p['quantity'] as int),
        });
      });
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invoice added successfully")),
      );
    }
  }

  void _addPart(Map<String, dynamic> part, int qty) {
    final unitPrice = (part['price'] as num).toDouble();
    final stock = (part['quantity'] as num).toInt();

    // 检查当前已选数量
    final existingIndex =
    selectedParts.indexWhere((p) => p['part_id'] == part['id']);
    int alreadySelectedQty =
    existingIndex != -1 ? selectedParts[existingIndex]['quantity'] as int : 0;

    // ✅ 验证总数量不能超过库存
    if (qty + alreadySelectedQty > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text("Quantity exceeds stock (Available: $stock, Already selected: $alreadySelectedQty)")),
      );
      return;
    }

    setState(() {
      if (existingIndex != -1) {
        // 🔹 已经选过 → 更新数量和总价
        final newQty = alreadySelectedQty + qty;
        selectedParts[existingIndex]['quantity'] = newQty;
        selectedParts[existingIndex]['total'] = unitPrice * newQty;
      } else {
        // 🔹 没选过 → 新增
        selectedParts.add({
          "part_id": part['id'],
          "name": part['name'],
          "category": part['category'],
          "price": unitPrice,
          "quantity": qty,
          "total": unitPrice * qty,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Invoice")),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handled By (Cashiers only)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("staff")
                    .where("role", isEqualTo: "Cashier")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final cashiers = snap.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Handled By"),
                    value: handledBy,
                    items: cashiers.map((c) {
                      final id = (c['id'] ?? '').toString();
                      final name = (c['name'] ?? '').toString();
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text("$id - $name"),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => handledBy = v),
                    validator: (v) =>
                    v == null ? "Please select cashier" : null,
                  );
                },
              ),

              // Vehicle
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("cars").snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final cars = snap.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Vehicle"),
                    value: vehicleId,
                    items: cars.map((c) {
                      final id = (c['id'] ?? '').toString();
                      final plate = (c['plateNumber'] ?? '').toString();
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text("$id - $plate"),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => vehicleId = v),
                    validator: (v) =>
                    v == null ? "Please select vehicle" : null,
                  );
                },
              ),

              // Service Type
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: "Service Type"),
                onChanged: (v) => serviceType = v,
                validator: (v) =>
                v == null || v.isEmpty ? "Enter service type" : null,
              ),

              // Parts selection
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("spare_parts")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final parts = snap.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Add Parts",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...parts.map((p) {
                        final part = p.data() as Map<String, dynamic>;
                        final partId = part['id'];
                        final name = part['name'];
                        final stock = part['quantity'];
                        return ListTile(
                          title: Text("$partId - $name (Stock: $stock)"),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              final qtyController = TextEditingController();
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text("Quantity for $name"),
                                  content: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: "Quantity",
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        final qty =
                                            int.tryParse(qtyController.text) ??
                                                0;
                                        if (qty > 0) {
                                          _addPart(part, qty);
                                        }
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text("Add"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      if (selectedParts.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: selectedParts.asMap().entries.map((entry) {
                            final index = entry.key;
                            final p = entry.value;
                            return ListTile(
                              title: Text("${p['name']} (x${p['quantity']})"),
                              subtitle: Text("Unit: RM${p['price']}"),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text("RM${p['total']}"),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        selectedParts.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: "Payment Method"),
                items: const [
                  DropdownMenuItem(value: "cash", child: Text("Cash")),
                  DropdownMenuItem(value: "card", child: Text("Card")),
                  DropdownMenuItem(value: "transfer", child: Text("Transfer")),
                ],
                onChanged: (v) => setState(() => paymentMethod = v),
              ),

              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Payment Received",
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setState(() {
                    paymentReceived = double.tryParse(v) ?? 0;
                  });
                },
              ),

              const SizedBox(height: 20),
              Text(
                "Total: RM$total",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Outstanding: RM$outstanding"),
              Text("Status: $status"),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addInvoice,
                child: const Text("Add Invoice"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
