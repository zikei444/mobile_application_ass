import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'procurement.dart';
import 'trackPartUsage.dart';

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
    QuerySnapshot snapshot =
    await _firestore.collection('spare_parts').get();

    List<Map<String, dynamic>> allParts = snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    // Filter by level category
    List<Map<String, dynamic>> filtered = allParts.where((p) {
      final qty = p['quantity'] ?? 0;
      switch (widget.category) {
        case 'maximum':
          return qty >= 200;
        case 'average':
          return qty >= 150 && qty < 200;
        case 'minimum':
          return qty >= 70 && qty < 150;
        case 'danger':
          return qty < 50;
        default:
          return false;
      }
    }).toList();

    // Search filter
    if (_searchText.isNotEmpty) {
      filtered = filtered.where((p) {
        final query = _searchText.toLowerCase();
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

  Widget _levelButton(String displayText, Color color, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 70,
      decoration: BoxDecoration(
        color: color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(displayText, style: const TextStyle(fontSize: 12)),
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
        return 'danger';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_getDisplayText()} Spare Parts')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _levelButton(_getDisplayText(), _getLevelColor(), levelCount),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '*Click on number to look for detail parts',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 10),

            // Search Box
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by ID / Name / Category',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
                _loadParts();
              },
            ),
            const SizedBox(height: 10),

            // Table
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Category')),
                    DataColumn(label: Text('Quantity')),
                    DataColumn(label: Text('Supplier')),
                  ],
                  rows: _parts.map((part) {
                    return DataRow(cells: [
                      DataCell(Text(part['id'] ?? '')),
                      DataCell(Text(part['name'] ?? '')),
                      DataCell(Text(part['category'] ?? '')),
                      DataCell(Text(part['quantity']?.toString() ?? '0')),
                      DataCell(Text(part['supplier'] ?? '')),
                    ]);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Navigation Buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade300),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackPartUsage(),
                  ),
                );              },
              child: const Text('Track Part Usage'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade300),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Procurement(),
                  ),
                );              },
              child: const Text('Procurement Requests'),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
