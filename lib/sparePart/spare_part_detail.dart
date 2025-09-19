import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'procurement.dart';
import 'trackPartUsage.dart';
import 'package:intl/intl.dart';

class SparePartDetail extends StatefulWidget {
  final String category;
  const SparePartDetail({super.key, required this.category});

  @override
  State<SparePartDetail> createState() => _SparePartDetailState();
}

class _SparePartDetailState extends State<SparePartDetail> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _parts = [];
  String _searchText = '';
  int levelCount = 0;

  @override
  void initState() {
    super.initState();
    _loadParts();
  }

  Future<void> _loadParts() async {
    QuerySnapshot snapshot = await _firestore.collection('spare_parts').get();

    List<Map<String, dynamic>> allParts =
    snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    List<Map<String, dynamic>> filtered = allParts.where((p) {
      final qty = p['quantity'] ?? 0;
      switch (widget.category) {
        case 'maximum':
          return qty >= 100;
        case 'average':
          return qty >= 50 && qty < 100;
        case 'minimum':
          return qty >= 20 && qty < 50;
        case 'danger':
          return qty < 20;
        default:
          return false;
      }
    }).toList();

    if (_searchText.isNotEmpty) {
      final query = _searchText.toLowerCase();
      filtered = filtered.where((p) {
        return (p['id'] ?? '').toLowerCase().contains(query) ||
            (p['name'] ?? '').toLowerCase().contains(query) ||
            (p['category'] ?? '').toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _parts = filtered;
      levelCount = filtered.length;
    });
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
      builder: (_) => AlertDialog(
        title: const Text('Add Spare Part'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: quantityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
              TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || categoryCtrl.text.trim().isEmpty) return;

              final qty = int.tryParse(quantityCtrl.text.trim()) ?? 0;
              final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
              final cost = double.tryParse(costCtrl.text.trim()) ?? 0;

              String level;
              if (qty >= 100) level = 'maximum';
              else if (qty >= 50) level = 'average';
              else if (qty >= 20) level = 'minimum';
              else level = 'danger';

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
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
              TextField(controller: quantityCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
              TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier')),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price')),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cost')),
              const SizedBox(height: 8),
              const Text('*Level and Last Restock cannot be edited', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    switch (widget.category) {
      case 'maximum':
        return Colors.blue;
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

  String _getDisplayText() {
    switch (widget.category) {
      case 'maximum':
        return 'Max';
      case 'average':
        return 'Avg';
      case 'minimum':
        return 'Min';
      default:
        return 'Danger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_getDisplayText()} Spare Parts')),
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
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                width: 100,
                decoration: BoxDecoration(
                  color: _getLevelColor().withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(levelCount.toString(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_getDisplayText(), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text('*Click on number to look for detail parts',
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by ID / Name / Category',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchText = value);
                _loadParts();
              },
            ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Spare Part'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _showAddPartDialog,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 400,
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
                    rows: _parts.map((part) {
                      final ts = part['lastRestock'] as Timestamp?;
                      final lastRestock = ts != null
                          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                          DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch))
                          : '';
                      return DataRow(cells: [
                        DataCell(Text(part['id'] ?? '')),
                        DataCell(Text(part['name'] ?? '')),
                        DataCell(Text(part['category'] ?? '')),
                        DataCell(Text(part['quantity']?.toString() ?? '0')),
                        DataCell(Text(part['supplier'] ?? '')),
                        DataCell(Text('${part['price'] ?? 0}')),
                        DataCell(Text('${part['cost'] ?? 0}')),
                        DataCell(Text(part['level'] ?? '')),
                        DataCell(Text(lastRestock)),
                        DataCell(Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showEditDialog(part)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text('Are you sure you want to delete ${part['name']}?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel')),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red.shade300),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await _firestore.collection('spare_parts').doc(part['id']).delete();
                                  _loadParts();
                                }
                              },
                            ),
                          ],
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                                              foregroundColor: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackPartUsage())),
              child: const Text('Track Part Usage'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green,
                                              foregroundColor: Colors.white),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const Procurement())),
              child: const Text('Procurement'),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
