import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'procurement.dart';

class TrackPartUsage extends StatefulWidget {
  const TrackPartUsage({super.key});

  @override
  State<TrackPartUsage> createState() => _TrackPartUsageState();
}

class _TrackPartUsageState extends State<TrackPartUsage> {
  DateTime? selectedDate;
  bool showRecent = true;

  /// Fetch recent 3 records
  Stream<QuerySnapshot> getRecentRecords() {
    return FirebaseFirestore.instance
        .collection('procurements')
        .orderBy('dateOrdered', descending: true)
        .limit(3)
        .snapshots();
  }

  /// Fetch records by date (start of day to end of day)
  Stream<QuerySnapshot> getRecordsByDate(DateTime date) {
    DateTime startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('procurements')
        .where('dateOrdered', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateOrdered', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('dateOrdered', descending: true)
        .snapshots();
  }

  /// Helper to build record list
  Widget buildRecordList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return const Center(child: Text("None"));
    }

    return ListView(
      shrinkWrap: true,
      children: snapshot.data!.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final date = (data['dateOrdered'] as Timestamp).toDate();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(data['item'] ?? 'No Item'),
            subtitle: Text(
              "ID: ${data['id']} | Supplier: ${data['supplier']}",
            ),
            trailing: Text(
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}",
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot>? recordStream;

    if (showRecent) {
      recordStream = getRecentRecords();
    } else if (selectedDate != null) {
      recordStream = getRecordsByDate(selectedDate!);
    } else {
      recordStream = getRecentRecords();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Part Usage"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// Calendar picker
            CalendarDatePicker(
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              onDateChanged: (picked) {
                setState(() {
                  selectedDate = picked;
                  showRecent = false;
                });
              },
            ),

            /// Selected date label
            if (selectedDate != null && !showRecent)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  "Selected Date: ${selectedDate!.toLocal().toString().split(' ')[0]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

            /// Show Recent button (closer to calendar)
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Show Recent Records"),
              onPressed: () {
                setState(() {
                  selectedDate = null;
                  showRecent = true;
                });
              },
            ),

            /// Record list right after button
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: recordStream,
                builder: (context, snapshot) {
                  return buildRecordList(snapshot);
                },
              ),
            ),

            /// Bottom navigation buttons
            Column(
              children: [
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TrackPartUsage(),
                      ),
                    );
                  },
                  child: const Text('Track Part Usage'),
                ),
                const SizedBox(height: 15),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Procurement(),
                      ),
                    );
                  },
                  child: const Text('Procurement Requests'),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
