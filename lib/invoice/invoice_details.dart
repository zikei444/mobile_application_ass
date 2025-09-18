import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceDetailsPage extends StatefulWidget {
  final String invoiceId;

  const InvoiceDetailsPage({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailsPage> createState() => _InvoiceDetailsPageState();
}

class _InvoiceDetailsPageState extends State<InvoiceDetailsPage> {
  Map<String, dynamic>? invoiceData;
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? staffData;
  bool isEditing = false;

  double paymentReceived = 0;
  String paymentMethod = "cash";

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    final snap = await FirebaseFirestore.instance
        .collection("invoice")
        .doc(widget.invoiceId)
        .get();
    final data = snap.data();
    if (data == null) return;

    final vehicleQuery = await FirebaseFirestore.instance
        .collection("vehicles")
        .where("vehicle_id", isEqualTo: data['vehicle_id'])
        .limit(1)
        .get();

    final staffSnap = await FirebaseFirestore.instance
        .collection("staff")
        .doc(data['handled_by'])
        .get();

    setState(() {
      invoiceData = data;
      vehicleData = vehicleQuery.docs.isNotEmpty
          ? vehicleQuery.docs.first.data() as Map<String, dynamic>
          : null;
      staffData = staffSnap.data();
      paymentReceived = (data['payment_receive'] as num).toDouble();
      paymentMethod = data['payment_method'] ?? "cash";
    });
  }

  double get outstanding =>
      (invoiceData?['total'] as num? ?? 0) - paymentReceived;

  String get status {
    if (paymentReceived == 0) return "unpaid";
    if (paymentReceived < (invoiceData?['total'] as num? ?? 0))
      return "partial";
    return "paid";
  }

  Future<void> _updateInvoice() async {
    await FirebaseFirestore.instance
        .collection("invoice")
        .doc(widget.invoiceId)
        .update({
          "payment_receive": paymentReceived,
          "payment_method": paymentMethod,
          "outstanding": outstanding,
          "status": status,
        });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invoice updated successfully")),
    );

    setState(() => isEditing = false);
  }

  Future<void> _deleteInvoice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this invoice?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection("invoice")
          .doc(widget.invoiceId)
          .delete();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invoice deleted")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (invoiceData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final parts = (invoiceData?['parts'] as List<dynamic>? ?? [])
        .map((e) => e as Map<String, dynamic>)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(invoiceData?['service_type'] ?? "Invoice Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top info row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Vehicle ID: ${invoiceData?['vehicle_id'] ?? '-'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Plate: ${vehicleData?['plateNumber'] ?? '-'}"),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Invoice ID: ${invoiceData?['invoice_id'] ?? '-'}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Created: ${invoiceData?['created_date']?.toDate().toString().substring(0, 10) ?? '-'}",
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Text(
              "GreenStem, Block A, A-3-3A, \nAtivo Plaza, Bandar Sri Damansara, \n52200 Kuala Lumpur, Selangor",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              "Parts",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Table with scroll
            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  columnWidths: const {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                    4: FlexColumnWidth(2),
                  },
                  children: [
                    const TableRow(
                      decoration: BoxDecoration(color: Colors.grey),
                      children: [
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "ID",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Name",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Qty",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Unit Price",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(4),
                          child: Text(
                            "Price",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...parts.map((p) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(p['part_id'] ?? '-'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(p['name'] ?? '-'),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text("${p['quantity'] ?? 0}"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text("RM${p['price'] ?? 0}"),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text("RM${p['total'] ?? 0}"),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Total: RM${invoiceData?['total'] ?? 0}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),

            const SizedBox(height: 16),
            Text(
              "Invoice Prepared By: ${invoiceData?['handled_by'] ?? '-'} - ${staffData?['name'] ?? '-'}",
            ),
            const SizedBox(height: 4),

            isEditing
                ? TextFormField(
                    initialValue: paymentReceived.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Payment Received",
                    ),
                    onChanged: (v) {
                      double entered = double.tryParse(v) ?? 0;
                      // validation: paymentReceived 不能超过 total
                      if (entered > (invoiceData?['total'] ?? 0)) {
                        entered = (invoiceData?['total'] ?? 0).toDouble();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Payment received cannot exceed total",
                            ),
                          ),
                        );
                      }
                      setState(() {
                        paymentReceived = entered;
                      });
                    },
                  )
                : Text("Payment Received: RM$paymentReceived"),

            Text("Outstanding: RM$outstanding"),

            isEditing
                ? DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: "Payment Method",
                    ),
                    items: const [
                      DropdownMenuItem(value: "cash", child: Text("Cash")),
                      DropdownMenuItem(value: "card", child: Text("Card")),
                      DropdownMenuItem(
                        value: "transfer",
                        child: Text("Transfer"),
                      ),
                      DropdownMenuItem(
                        value: "E-Wallet",
                        child: Text("E-Wallet"),
                      ),
                    ],
                    onChanged: (v) =>
                        setState(() => paymentMethod = v ?? "cash"),
                  )
                : Text("Payment Method: $paymentMethod"),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isEditing)
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
                    onPressed: () => setState(() => isEditing = true),
                    child: const Text("Edit"),
                  ),
                if (isEditing)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _updateInvoice,
                    child: const Text("Save"),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // ✅ Delete = red
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _deleteInvoice,
                  child: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
