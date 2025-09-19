import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mobile_application_ass/sparePart/procurement.dart';
import 'package:mobile_application_ass/sparePart/spare_part_dashboard.dart';

class TrackPartUsage extends StatefulWidget {
  const TrackPartUsage({super.key});

  @override
  State<TrackPartUsage> createState() => _TrackPartUsageState();
}

class _TrackPartUsageState extends State<TrackPartUsage> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  DateTime? selectedDate;
  bool showCalendar = false;

  Stream<QuerySnapshot> getAllUsage() {
    return FirebaseFirestore.instance
        .collection('spare_part_usage')
        .orderBy('usedAt', descending: true)
        .snapshots();
  }

  Future<Map<String, dynamic>?> getSparePartInfo(String sparePartId) async {
    final doc = await FirebaseFirestore.instance
        .collection('spare_parts')
        .doc(sparePartId)
        .get();
    if (doc.exists) return doc.data();
    return null;
  }

  void resetFilters() {
    setState(() {
      searchQuery = "";
      searchController.clear();
      selectedDate = null;
      showCalendar = false;
    });
  }

  Widget buildUsageTable(List<QueryDocumentSnapshot> docs) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text("Usage ID")),
            DataColumn(label: Text("Invoice ID")),
            DataColumn(label: Text("Spare Part ID")),
            DataColumn(label: Text("Spare Part Name")),
            DataColumn(label: Text("Quantity Used")),
            DataColumn(label: Text("Used At")),
          ],
          rows: docs.map((usageDoc) {
            final usageData = usageDoc.data() as Map<String, dynamic>;
            final sparePartId = usageData['spare_part_id'] ?? '';
            final usageId = usageData['id'] ?? '';
            final invoiceId = usageData['invoice_id'] ?? '';
            final quantity = usageData['quantity'] ?? 0;
            final usedAt = (usageData['usedAt'] as Timestamp).toDate();

            return DataRow(cells: [
              DataCell(Text(usageId)),
              DataCell(Text(invoiceId)),
              DataCell(Text(sparePartId)),
              DataCell(FutureBuilder<Map<String, dynamic>?>(
                future: getSparePartInfo(sparePartId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Text("Loading...");
                  }
                  return Text(snapshot.data?['name'] ?? 'N/A');
                },
              )),
              DataCell(Text(quantity.toString())),
              DataCell(Text(DateFormat('yyyy-MM-dd').format(usedAt))),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Track Spare Part Usage")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    showCalendar = !showCalendar;
                  });
                },
                child: Text(showCalendar ? "Hide Calendar" : "Apply Calendar"),
              ),
              const SizedBox(height: 10),

              if (showCalendar)
                Column(
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: Colors.green,
                          onPrimary: Colors.white,
                          onSurface: Colors.black,
                        ),
                      ),
                      child: CalendarDatePicker(
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        onDateChanged: (picked) {
                          setState(() {
                            selectedDate = picked;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),

              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: showCalendar
                      ? "Search by Invoice ID or spare part ID"
                      : "Search by invoice ID or spare part ID",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text("Reset Filters"),
                onPressed: resetFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: getAllUsage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No usage records found."));
                  }

                  List<QueryDocumentSnapshot> filteredDocs = snapshot.data!.docs;

                  if (showCalendar) {
                    if (selectedDate != null) {
                      filteredDocs = filteredDocs.where((doc) {
                        final usedAt = (doc['usedAt'] as Timestamp).toDate();
                        return usedAt.year == selectedDate!.year &&
                            usedAt.month == selectedDate!.month &&
                            usedAt.day == selectedDate!.day;
                      }).toList();
                    }

                    if (searchQuery.isNotEmpty) {
                      filteredDocs = filteredDocs.where((doc) {
                        final usage = doc.data() as Map<String, dynamic>;
                        final usageId =
                        (usage['id'] ?? '').toString().toLowerCase();
                        final invoiceId =
                        (usage['invoice_id'] ?? '').toString().toLowerCase();
                        final sparePartId =
                        (usage['spare_part_id'] ?? '').toString().toLowerCase();
                        final sparePartName =
                        (usage['spare_part_name'] ?? '').toString().toLowerCase();
                        return usageId.contains(searchQuery) ||
                            invoiceId.contains(searchQuery) ||
                            sparePartId.contains(searchQuery) ||
                            sparePartName.contains(searchQuery);
                      }).toList();
                    }
                  } else {
                    if (searchQuery.isNotEmpty) {
                      filteredDocs = filteredDocs.where((doc) {
                        final usage = doc.data() as Map<String, dynamic>;
                        final invoiceId =
                        (usage['invoice_id'] ?? '').toString().toLowerCase();
                        final sparePartId =
                        (usage['spare_part_id'] ?? '').toString().toLowerCase();
                        final sparePartName =
                        (usage['spare_part_name'] ?? '').toString().toLowerCase();
                        return invoiceId.contains(searchQuery) ||
                            sparePartId.contains(searchQuery) ||
                            sparePartName.contains(searchQuery);
                      }).toList();
                    }
                  }

                  filteredDocs.sort((a, b) {
                    final idA = (a['id'] ?? '');
                    final idB = (b['id'] ?? '');
                    final numA =
                        int.tryParse(idA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    final numB =
                        int.tryParse(idB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    return numA.compareTo(numB);
                  });

                  return buildUsageTable(filteredDocs);
                },
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Procurement()),
                    );
                  },
                  child: const Text('Procurements'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SparePartDashboard()),
                    );
                  },
                  child: const Text('Spare Part Control'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
