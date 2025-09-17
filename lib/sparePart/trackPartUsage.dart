import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
            DataColumn(label: Text("Spare Part ID")),
            DataColumn(label: Text("Spare Part Name")),
            DataColumn(label: Text("Quantity Used")),
            DataColumn(label: Text("Used At")),
          ],
          rows: docs.map((usageDoc) {
            final usageData = usageDoc.data() as Map<String, dynamic>;
            final sparePartId = usageData['spare_part_id'] ?? '';
            final usageId = usageData['id'] ?? '';
            final quantity = usageData['quantity'] ?? 0;
            final usedAt = (usageData['usedAt'] as Timestamp).toDate();

            return DataRow(cells: [
              DataCell(Text(usageId)),
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
        child: Column(
          children: [
            // ===== Apply Calendar Button =====
            ElevatedButton(
              onPressed: () {
                setState(() {
                  showCalendar = !showCalendar;
                });
              },
              child: Text(showCalendar ? "Hide Calendar" : "Apply Calendar"),
            ),
            const SizedBox(height: 10),

            // ===== Calendar Picker =====
            if (showCalendar)
              Column(
                children: [
                  CalendarDatePicker(
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    onDateChanged: (picked) {
                      setState(() {
                        selectedDate = picked;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),

            // ===== Search Bar =====
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: showCalendar
                    ? "Search by usage ID, spare part ID or name"
                    : "Search by spare part ID or name",
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

            // ===== Reset Button =====
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Reset Filters"),
              onPressed: resetFilters,
            ),
            const SizedBox(height: 10),

            // ===== Usage Table =====
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getAllUsage(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No usage records found."));
                  }

                  List<QueryDocumentSnapshot> filteredDocs = snapshot.data!.docs;

                  // Apply calendar + search filter
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
                        final sparePartId =
                        (usage['spare_part_id'] ?? '').toString().toLowerCase();
                        final sparePartName =
                        (usage['spare_part_name'] ?? '').toString().toLowerCase();
                        return usageId.contains(searchQuery) ||
                            sparePartId.contains(searchQuery) ||
                            sparePartName.contains(searchQuery);
                      }).toList();
                    }
                  } else {
                    // Search bar filter
                    if (searchQuery.isNotEmpty) {
                      filteredDocs = filteredDocs.where((doc) {
                        final usage = doc.data() as Map<String, dynamic>;
                        final sparePartId =
                        (usage['spare_part_id'] ?? '').toString().toLowerCase();
                        final sparePartName =
                        (usage['spare_part_name'] ?? '').toString().toLowerCase();
                        return sparePartId.contains(searchQuery) ||
                            sparePartName.contains(searchQuery);
                      }).toList();
                    }
                  }

                  // Sort by usage ID
                  filteredDocs.sort((a, b) {
                    final idA = (a['id'] ?? '');
                    final idB = (b['id'] ?? '');
                    final numA = int.tryParse(idA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    final numB = int.tryParse(idB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                    return numA.compareTo(numB);
                  });

                  return buildUsageTable(filteredDocs);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
