import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spare_part_dashboard.dart';

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

  Future<void> _loadParts() async {
    QuerySnapshot snapshot = await _firestore.collection('spare_parts').get();

    List<Map<String, dynamic>> parts = snapshot.docs
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['docId'] = doc.id;
      return data;
    })
        .toList();

    if (_searchText.isNotEmpty) {
      parts = parts.where((p) {
        final query = _searchText.toLowerCase();
        return (p['id'] ?? '').toLowerCase().contains(query) ||
            (p['name'] ?? '').toLowerCase().contains(query) ||
            (p['category'] ?? '').toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _parts = parts;
    });
  }

  Future<void> _orderPart(Map<String, dynamic> part) async {
    final docId = part['docId'];
    final currentQuantity = (part['quantity'] ?? 0) as int;
    final newQuantity = currentQuantity + 10;
    final newLastRestock = Timestamp.now();
    final newLevel = getStockLevel(newQuantity);

    try {
      await _firestore.collection('spare_parts').doc(docId).update({
        'quantity': newQuantity,
        'lastRestock': newLastRestock,
        'level': newLevel,
      });

      await _loadParts();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ordered ${part['name']}: quantity increased by 10')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating quantity: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spare Parts Control')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // center vertically
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    // Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Supplier')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Order')),
                        ],
                        rows: _parts.map((part) {
                          return DataRow(cells: [
                            DataCell(Text(part['id'] ?? '')),
                            DataCell(Text(part['name'] ?? '')),
                            DataCell(Text(part['supplier'] ?? '')),
                            DataCell(Text(part['quantity']?.toString() ?? '0')),
                            DataCell(
                              SizedBox(
                                width: 80,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                  onPressed: () => _orderPart(part),
                                  child: const Text('Order', textAlign: TextAlign.center),
                                ),
                              ),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {},
              child: const Text('Track Part Usage'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SparePartDashboard(),
                  ),
                );
              },
              child: const Text('Spare Part Control'),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
