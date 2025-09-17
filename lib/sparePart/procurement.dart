import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spare_part_dashboard.dart';
import 'trackPartUsage.dart';

class Procurement extends StatefulWidget {
  const Procurement({super.key});

  @override
  State<Procurement> createState() => _ProcurementState();
}

class _ProcurementState extends State<Procurement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _parts = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  String getStockLevel(int quantity) {
    if (quantity >= 200) return 'maximum';
    if (quantity >= 150) return 'average';
    if (quantity >= 70) return 'minimum';
    return 'danger';
  }

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'average':
        return Colors.green;
      case 'minimum':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadParts() async {
    QuerySnapshot snapshot = await _firestore.collection('spare_parts').get();

    List<Map<String, dynamic>> parts = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['docId'] = doc.id;
      return data;
    }).toList();

    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      parts = parts.where((p) {
        return (p['id'] ?? '').toLowerCase().contains(query) ||
            (p['name'] ?? '').toLowerCase().contains(query) ||
            (p['category'] ?? '').toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _parts = parts;
    });
  }

  Future<void> _showOrderDialog(Map<String, dynamic> part) async {
    final TextEditingController qtyController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Order ${part['name']}'),
          content: TextField(
            controller: qtyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter quantity to order',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyController.text.trim());
                if (qty != null && qty > 0) {
                  Navigator.pop(context, qty);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid number')),
                  );
                }
              },
              child: const Text('Order'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      _orderPart(part, result);
    }
  }

  /// Create a new procurement ID
  Future<String> _generateProcurementId() async {
    final snapshot = await _firestore
        .collection('procurements')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return 'PR01';

    final latestId = snapshot.docs.first['id'] as String;
    final number = int.parse(latestId.replaceAll(RegExp(r'[^0-9]'), '')) + 1;
    return 'PR${number.toString().padLeft(2, '0')}';
  }

  Future<void> _orderPart(Map<String, dynamic> part, int orderQty) async {
    final docId = part['docId'];
    final currentQuantity = (part['quantity'] ?? 0) as int;
    final newQuantity = currentQuantity + orderQty;
    final newLastRestock = Timestamp.now();
    final newLevel = getStockLevel(newQuantity);

    try {
      // Update spare_parts
      await _firestore.collection('spare_parts').doc(docId).update({
        'quantity': newQuantity,
        'lastRestock': newLastRestock,
        'level': newLevel,
      });

      // Create procurement record
      final newId = await _generateProcurementId();
      final double unitCost = (part['unitCost'] ?? 0.0) * 1.0; // ensure double
      await _firestore.collection('procurements').doc(newId).set({
        'id': newId,
        'item': part['name'] ?? '',
        'quantity': orderQty,
        'totalCost': orderQty * unitCost,
        'dateOrdered': Timestamp.now(),
      });

      await _loadParts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ordered ${part['name']}: +$orderQty added.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: $e')),
      );
    }
  }

  void _handleOrderButton(Map<String, dynamic> part) {
    final level = (part['level'] ?? '').toString().toLowerCase();
    if (level == 'maximum') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The stock reached maximum quantity !')),
      );
    } else {
      _showOrderDialog(part);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spare Parts Control')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------- Procurement Request -----------------
              const Text(
                'Procurement Request',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by ID / Name / Category',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                    _loadParts();
                  });
                },
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Spare_Parts ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Supplier')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Order')),
                  ],
                  rows: _parts.map((part) {
                    final level = (part['level'] ?? '').toString().toLowerCase();
                    return DataRow(cells: [
                      DataCell(Text(part['id'] ?? '')),
                      DataCell(Text(part['name'] ?? '')),
                      DataCell(Text(part['supplier'] ?? '')),
                      DataCell(Text(part['quantity']?.toString() ?? '0')),
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getLevelColor(level),
                            ),
                            onPressed: () => _handleOrderButton(part),
                            child: const Text('Order', textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),

              const SizedBox(height: 40),

              // ---------------- Procurement Records -----------------
              const Text(
                'Procurement Records',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('procurements')
                    .orderBy('id', descending: false) // arranged by id
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Text('No procurement records found.');
                  }
                  final docs = snapshot.data!.docs;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Quantity')),
                        DataColumn(label: Text('Total Cost (RM)')),
                        DataColumn(label: Text('Date Ordered')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final date = (data['dateOrdered'] as Timestamp).toDate();
                        return DataRow(cells: [
                          DataCell(Text(data['id'] ?? '')),
                          DataCell(Text(data['item'] ?? '')),
                          DataCell(Text('${data['quantity']}')),
                          DataCell(Text('${data['totalCost']}')),
                          DataCell(Text(
                            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
                                '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                          )),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // ---------------- Navigation Buttons -----------------
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade300),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TrackPartUsage()),
                  );
                },
                child: const Text('Track Part Usage'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade300),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SparePartDashboard()),
                  );
                },
                child: const Text('Spare Part Control'),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
