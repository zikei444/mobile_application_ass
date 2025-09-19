import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'spare_part_detail.dart';
import 'procurement.dart';
import 'trackPartUsage.dart';

class SparePartDashboard extends StatefulWidget {
  const SparePartDashboard({super.key});

  @override
  State<SparePartDashboard> createState() => _SparePartDashboardState();
}

class _SparePartDashboardState extends State<SparePartDashboard> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _parts = [];
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    final snapshot = await _firestore.collection('spare_parts').get();
    List<Map<String, dynamic>> parts =
    snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();

    if (_searchText.isNotEmpty) {
      final q = _searchText.toLowerCase();
      parts = parts.where((p) {
        return (p['id'] ?? '').toLowerCase().contains(q) ||
            (p['name'] ?? '').toLowerCase().contains(q) ||
            (p['category'] ?? '').toLowerCase().contains(q);
      }).toList();
    }
    setState(() => _parts = parts);
  }

  Future<int> _getCountByLevel(String level) async {
    final snap =
    await _firestore.collection('spare_parts').where('level', isEqualTo: level).get();
    return snap.size;
  }

  Widget _levelButton(String levelKey, String displayText, Color color) {
    return FutureBuilder<int>(
      future: _getCountByLevel(levelKey),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SparePartDetail(category: levelKey)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 100,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text('${snapshot.data}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(displayText, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _generateNextId() async {
    final snap = await _firestore.collection('spare_parts').get();
    int maxNum = 0;
    for (var doc in snap.docs) {
      final id = (doc.data() as Map<String, dynamic>)['id'] ?? '';
      final numPart = int.tryParse(id.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numPart != null && numPart > maxNum) maxNum = numPart;
    }
    final next = maxNum + 1;
    return 'P${next.toString().padLeft(2, '0')}';
  }

  void _showAddPartDialog() {
    final nameCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final quantityCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Add Spare Part'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name')),
                TextField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Category')),
                TextField(
                    controller: quantityCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity')),
                TextField(
                    controller: supplierCtrl,
                    decoration: const InputDecoration(labelText: 'Supplier')),
                TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price')),
                TextField(
                    controller: costCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cost')),
              ],
            ),
          ),
          actions: [
            TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              child: const Text('Save'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                                              foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || categoryCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name and Category required')));
                  return;
                }

                final qty = int.tryParse(quantityCtrl.text.trim()) ?? 0;
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                final cost = double.tryParse(costCtrl.text.trim()) ?? 0;

                String level;
                if (qty >= 100) {
                  level = 'maximum';
                } else if (qty >= 50) {
                  level = 'average';
                } else if (qty >= 20) {
                  level = 'minimum';
                } else {
                  level = 'danger';
                }

                final newId = await _generateNextId();

                await _firestore.collection('spare_parts').doc(newId).set({
                  'id': newId,
                  'name': nameCtrl.text.trim(),
                  'category': categoryCtrl.text.trim(),
                  'quantity': qty,
                  'supplier': supplierCtrl.text.trim(),
                  'price': price,
                  'cost': cost,
                  'lastRestock': FieldValue.serverTimestamp(),
                  'level': level,
                });

                Navigator.pop(context);
                _loadParts();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('New spare part added successfully'),
                    duration: Duration(seconds: 2)));
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(Map<String, dynamic> part) {
    final nameCtrl = TextEditingController(text: part['name']);
    final categoryCtrl = TextEditingController(text: part['category']);
    final quantityCtrl = TextEditingController(text: part['quantity'].toString());
    final supplierCtrl = TextEditingController(text: part['supplier']);
    final priceCtrl = TextEditingController(text: part['price'].toString());
    final costCtrl = TextEditingController(text: part['cost'].toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit ${part['id']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
              TextField(
                  controller: quantityCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity')),
              TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier')),
              TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price')),
              TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cost')),
              const SizedBox(height: 8),
              const Text('*Level and Last Restock cannot be edited',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                                            foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.collection('spare_parts').doc(part['id']).update({
                'name': nameCtrl.text.trim(),
                'category': categoryCtrl.text.trim(),
                'quantity': int.tryParse(quantityCtrl.text.trim()) ?? part['quantity'],
                'supplier': supplierCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? part['price'],
                'cost': double.tryParse(costCtrl.text.trim()) ?? part['cost'],
              });
              Navigator.pop(context);
              _loadParts();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Spare part updated successfully'), duration: Duration(seconds: 2)));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spare Parts Control')),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _levelButton('maximum', 'Max', Colors.blue),
                _levelButton('average', 'Avg', Colors.green),
                _levelButton('minimum', 'Min', Colors.orange),
                _levelButton('danger', 'Danger', Colors.red),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '*Click on number to look for detail parts',
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Spare Part'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _showAddPartDialog,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by ID / Name / Category',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _searchText = v;
                  _loadParts();
                });
              },
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 400, // fixed height to avoid overflow
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ID')),
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Quantity')),
                      DataColumn(label: Text('Supplier')),
                      DataColumn(label: Text('Price')),
                      DataColumn(label: Text('Cost')),
                      DataColumn(label: Text('Level')),
                      DataColumn(label: Text('Last Restock')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows: _parts.map((p) {
                      final ts = p['lastRestock'] as Timestamp?;
                      final lastRestock = ts != null
                          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                          DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch))
                          : '';
                      return DataRow(cells: [
                        DataCell(Text(p['id'] ?? '')),
                        DataCell(Text(p['name'] ?? '')),
                        DataCell(Text(p['category'] ?? '')),
                        DataCell(Text('${p['quantity'] ?? 0}')),
                        DataCell(Text(p['supplier'] ?? '')),
                        DataCell(Text('${p['price'] ?? 0}')),
                        DataCell(Text('${p['cost'] ?? 0}')),
                        DataCell(Text(p['level'] ?? '')),
                        DataCell(Text(lastRestock)),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: Text(
                                          'Are you sure you want to delete ${p['name']}?'),
                                      actions: [
                                        TextButton(
                                          style: TextButton.styleFrom(foregroundColor: Colors.grey),
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _firestore
                                        .collection('spare_parts')
                                        .doc(p['id'])
                                        .delete();
                                    _loadParts();
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                        content: Text('Spare part deleted successfully'),
                                        duration: Duration(seconds: 2)));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                                              foregroundColor: Colors.white),
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => const TrackPartUsage()));
              },
              child: const Text('Track Part Usage'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                                              foregroundColor: Colors.white),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const Procurement()));
              },
              child: const Text('Procurement'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
