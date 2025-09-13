import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  final String customerId;

  const ProfilePage({super.key, required this.customerId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  DateTime selectedDate = DateTime.now();

  Future<Map<String, dynamic>?> _fetchCustomerData() async {
    final customerSnap = await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerId)
        .get();

    if (!customerSnap.exists) return null;

    final customer = customerSnap.data()!;

    // Fetch car details
    final carSnap = await FirebaseFirestore.instance
        .collection('cars')
        .doc(customer['carId'])
        .get();

    final car = carSnap.data();

    // Fetch appointments
    final appointmentSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: widget.customerId)
        .get();

    final appointments = appointmentSnap.docs.map((e) => e.data()).toList();

    return {
      'customer': customer,
      'car': car,
      'appointments': appointments,
    };
  }

  /// Calendar widget
  Widget _buildCalendar() {
    return CalendarDatePicker(
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      onDateChanged: (date) {
        setState(() {
          selectedDate = date;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Profile Manage"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchCustomerData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          }

          final data = snapshot.data!;
          final customer = data['customer'] as Map<String, dynamic>;
          final car = data['car'] as Map<String, dynamic>?;
          final appointments = data['appointments'] as List;

          int totalAppointmentsYear = appointments.length;
          int totalAppointmentsMonth = appointments
              .where((a) =>
          (a['date'] as Timestamp).toDate().month ==
              DateTime.now().month)
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile section
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${customer['id']} - ${customer['name']}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Text("Customer"),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 20),

                // Calendar
                _buildCalendar(),
                const SizedBox(height: 20),

                // Appointment stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          "Total Appointment (Current Month): $totalAppointmentsMonth time(s)"),
                      Text(
                          "Total Appointment (Current Year): $totalAppointmentsYear time(s)"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Car info
                if (car != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Car Information",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Plate Number: ${car['plateNumber']}"),
                        Text("Type: ${car['brand']}"),
                        Text("Model: ${car['model']}"),
                        Text("Year: ${car['year']}"),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Service History
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Service History",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ...appointments.map((a) {
                      DateTime d = (a['date'] as Timestamp).toDate();
                      return Card(
                        child: ListTile(
                          title: Text("ID: ${a['id']}"), // Show only ID
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Service Details"),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        "Service Type: ${a['serviceType'] ?? 'Unknown'}"),
                                    Text(
                                        "Date: ${d.day}/${d.month}/${d.year}"),
                                    Text("Status: ${a['status'] ?? 'N/A'}"),
                                    Text("Notes: ${a['notes'] ?? 'N/A'}"),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context),
                                    child: const Text("Close"),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
