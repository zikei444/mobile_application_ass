import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String customerId; // This should match 'id' in customers collection

  const ProfilePage({super.key, required this.customerId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Future<Map<String, dynamic>?> _fetchCustomerData() async {
    // ===== Fetch customer document =====
    final customerSnap = await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerId)
        .get();
    if (!customerSnap.exists) return null;

    final customer = customerSnap.data()!;

    // ===== Fetch all vehicles for this customer =====
    final vehicleQuery = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('customerId', isEqualTo: widget.customerId)
        .get();

    final vehicles = vehicleQuery.docs.map((doc) => doc.data()).toList();

    // ===== Fetch all appointments for this customer =====
    final appointmentSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: widget.customerId)
        .get();

    final appointments = appointmentSnap.docs
        .map((e) => e.data())
        .toList()
      ..sort((a, b) {
        final da = a['date'] as Timestamp?;
        final db = b['date'] as Timestamp?;
        return db?.compareTo(da ?? Timestamp.now()) ?? 0;
      });

    // ===== Determine last serviced date from latest completed appointment =====
    DateTime? lastServiced;
    final completedAppointments = appointments.where((a) =>
    (a['status']?.toString().toLowerCase() ?? '') == 'completed'
    ).toList();
    if (completedAppointments.isNotEmpty) {
      lastServiced = (completedAppointments.first['date'] as Timestamp).toDate();
    }

    return {
      'customer': customer,
      'vehicles': vehicles,
      'appointments': appointments,
      'lastServiced': lastServiced,
    };
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
          final vehicles = data['vehicles'] as List;
          final appointments = data['appointments'] as List;
          final lastServiced = data['lastServiced'] as DateTime?;

          // Appointment counts
          final totalAppointmentsYear = appointments.length;
          final totalAppointmentsMonth = appointments
              .where((a) =>
          (a['date'] as Timestamp?)?.toDate().month == DateTime.now().month)
              .length;

          // Last serviced date formatting
          String lastServicedStr = lastServiced != null
              ? DateFormat.yMMMMd().add_jm().format(lastServiced)
              : "N/A";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Customer Profile =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person, size: 48, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.customerId} - ${customer['name'] ?? 'No Name'}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text("Email: ${customer['email'] ?? 'N/A'}"),
                            Text("Phone: ${customer['phone'] ?? 'N/A'}"),
                            Text("Address: ${customer['address'] ?? 'N/A'}"),
                            Text("Last Serviced: $lastServicedStr"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ===== Appointment Summary =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Appointment (Current Month): $totalAppointmentsMonth time(s)",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                        "Total Appointment (Current Year): $totalAppointmentsYear time(s)",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                // ===== Vehicles Info =====
                if (vehicles.isNotEmpty)
                  ...vehicles.map((vehicle) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Vehicle Information",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text("Vehicle ID: ${vehicle['vehicle_id'] ?? 'N/A'}"),
                          Text("Plate Number: ${vehicle['plateNumber'] ?? 'N/A'}"),
                          Text("Type: ${vehicle['type'] ?? 'N/A'}"),
                          Text("Model: ${vehicle['model'] ?? 'N/A'}"),
                          Text("Kilometer: ${vehicle['kilometer'] ?? 'N/A'}"),
                          Text("Size: ${vehicle['size'] ?? 'N/A'}"),
                          Text(
                            "Created At: ${vehicle['createdAt'] is Timestamp ? DateFormat.yMMMd().add_jm().format((vehicle['createdAt'] as Timestamp).toDate()) : 'N/A'}",
                          ),
                        ],
                      ),
                    );
                  }),

                // ===== Appointment History =====
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Appointment History",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    if (appointments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text("No appointments found for this customer."),
                      )
                    else
                      ...appointments.map((a) {
                        final Timestamp? ts = a['date'] as Timestamp?;
                        DateTime d = ts?.toDate() ?? DateTime.now();

                        return Card(
                          child: ListTile(
                            title: Text("ID: ${a['id'] ?? 'N/A'}"),
                            subtitle: Text(
                                "Vehicle: ${a['vehicleId'] ?? 'N/A'}\nService: ${a['serviceType'] ?? 'N/A'}\nStatus: ${a['status'] ?? 'N/A'}"),
                            isThreeLine: true,
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text("Service Details"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("ID: ${a['id'] ?? 'N/A'}"),
                                      Text("Vehicle ID: ${a['vehicleId'] ?? 'N/A'}"),
                                      Text("Service Type: ${a['serviceType'] ?? 'N/A'}"),
                                      Text("Date: ${DateFormat.yMMMMd().add_jm().format(d)}"),
                                      Text("Status: ${a['status'] ?? 'N/A'}"),
                                      Text("Notes: ${a['notes'] ?? 'N/A'}"),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
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
