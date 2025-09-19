import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_application_ass/sparePart/add_usage.dart';

class AddInvoicePage extends StatefulWidget {
  const AddInvoicePage({super.key});

  @override
  State<AddInvoicePage> createState() => _AddInvoicePageState();
}

class _AddInvoicePageState extends State<AddInvoicePage> {
  final _formKey = GlobalKey<FormState>();

  String? handledBy;
  String? vehicleId;
  String? paymentMethod = "cash";  // default cash
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

  // Function to generate invoice id automatically +1
  Future<String> _generateInvoiceId() async {
    final snap = await FirebaseFirestore.instance
        .collection("invoice")
        .orderBy("invoice_id", descending: true)
        .limit(1)
        .get();

    int nextNum = 1;
    if (snap.docs.isNotEmpty) {
      final lastId = snap.docs.first['invoice_id'];
      final numericPart = lastId.replaceAll(RegExp(r'[^0-9]'), '');
      nextNum = int.parse(numericPart) + 1;
    }

    return "INV${nextNum.toString().padLeft(3, '0')}";
  }

  // add new invoice to database
  Future<void> _addInvoice() async {
    if (!_formKey.currentState!.validate()) return;

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

    // part usage
    await AddUsage.createUsagesForInvoice(invoiceId, selectedParts);


    for (var p in selectedParts) {
      final partDoc = FirebaseFirestore.instance
          .collection("spare_parts")
          .doc(p['part_id']);
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

  // add part, if user adding same part, accumulate it
  void _addPart(Map<String, dynamic> part, int qty) {
    final unitPrice = (part['price'] as num).toDouble();
    final stock = (part['quantity'] as num).toInt();

    final existingIndex = selectedParts.indexWhere(
      (p) => p['part_id'] == part['id'],
    );
    int alreadySelectedQty = existingIndex != -1
        ? selectedParts[existingIndex]['quantity'] as int
        : 0;

    if (qty + alreadySelectedQty > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Quantity exceeds stock (Available: $stock, Already selected: $alreadySelectedQty)",
          ),
        ),
      );
      return;
    }

    setState(() {
      if (existingIndex != -1) {
        final newQty = alreadySelectedQty + qty;
        selectedParts[existingIndex]['quantity'] = newQty;
        selectedParts[existingIndex]['total'] = unitPrice * newQty;
      } else {
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

  InputDecoration _greenInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green, width: 2),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
      ),
      border: const OutlineInputBorder(),
      isDense: true,
    );
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
              // Handled By
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("staff")
                    .where("role", isEqualTo: "Cashier")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final cashiers = snap.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: _greenInputDecoration("Handled By"),
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

              const SizedBox(height: 12),

              // Vehicle
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("vehicles")
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  final vehicles = snap.data!.docs;
                  vehicles.sort((a, b) => a.id.compareTo(b.id));

                  return DropdownButtonFormField<String>(
                    decoration: _greenInputDecoration("Vehicle"),
                    value: vehicleId,
                    items: vehicles.map((c) {
                      final id = c.id;
                      final plate = (c['plateNumber'] ?? 'Vehicle No Longer Exist in System').toString();
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

              const SizedBox(height: 12),
              TextFormField(
                decoration: _greenInputDecoration("Service Type"),
                onChanged: (v) => serviceType = v,
                validator: (v) =>
                    v == null || v.isEmpty ? "Enter service type" : null,
              ),

              const SizedBox(height: 16),

              // Parts
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
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () async {
                              final qtyController = TextEditingController();
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  title: Text(
                                    "Quantity for $name",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  content: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: _greenInputDecoration(
                                      "Quantity",
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors
                                            .grey[700],
                                      ),
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
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
                decoration: _greenInputDecoration("Payment Method"),
                items: const [
                  DropdownMenuItem(value: "cash", child: Text("Cash")),
                  DropdownMenuItem(value: "card", child: Text("Card")),
                  DropdownMenuItem(value: "transfer", child: Text("Transfer")),
                ],
                onChanged: (v) => setState(() => paymentMethod = v),
              ),

              const SizedBox(height: 12),
              TextFormField(
                decoration: _greenInputDecoration("Payment Received"),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
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
