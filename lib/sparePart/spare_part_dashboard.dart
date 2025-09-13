import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'spare_part_detail.dart';
import 'procurement.dart';
import 'trackPartUsage.dart';
import 'package:mobile_application_ass/customer/customerList.dart';


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
    QuerySnapshot snapshot = await _firestore.collection('spare_parts').get();

    List<Map<String, dynamic>> parts = snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
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

  Future<int> _getCountByLevel(String level) async {
    QuerySnapshot snapshot = await _firestore
        .collection('spare_parts')
        .where('level', isEqualTo: level)
        .get();
    return snapshot.size;
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
              MaterialPageRoute(
                builder: (_) => SparePartDetail(category: levelKey),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  snapshot.data.toString(),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(displayText, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spare Parts Control')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Row of Level Buttons
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
                  _loadParts();
                });
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

            // Space to move buttons up
            const SizedBox(height: 30),

            // Bottom Buttons
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
