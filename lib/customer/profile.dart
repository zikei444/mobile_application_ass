import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  final String customerId;

  const ProfilePage({super.key, required this.customerId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<Map<String, dynamic>?> _fetchCustomerData() async {
    // Fetch customer document
    final customerSnap = await FirebaseFirestore.instance
        .collection('customers')
        .doc(widget.customerId)
        .get();
    if (!customerSnap.exists) return null;

    final customer = customerSnap.data()!;

    // Fetch all vehicles for this customer
    final vehicleQuery = await FirebaseFirestore.instance
        .collection('vehicles')
        .where('customerId', isEqualTo: widget.customerId)
        .get();

    final vehicles = vehicleQuery.docs.map((doc) => doc.data()).toList();

    // Fetch all appointments for this customer
    final appointmentSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('customerId', isEqualTo: widget.customerId)
        .get();

    final appointments = appointmentSnap.docs.map((e) => e.data()).toList()
      ..sort((a, b) {
        final da = a['date'] as Timestamp?;
        final db = b['date'] as Timestamp?;
        return db?.compareTo(da ?? Timestamp.now()) ?? 0;
      });

    // Determine last serviced date from latest completed appointment
    DateTime? lastServiced;
    final completedAppointments = appointments
        .where((a) =>
    (a['status']?.toString().toLowerCase() ?? '') == 'completed')
        .toList();
    if (completedAppointments.isNotEmpty) {
      lastServiced =
          (completedAppointments.first['date'] as Timestamp).toDate();
    }

    return {
      'customer': customer,
      'vehicles': vehicles,
      'appointments': appointments,
      'lastServiced': lastServiced,
    };
  }

  /// Pop-up dialog to edit customer fields
  void _showEditDialog(Map<String, dynamic> customer) {
    final nameCtrl = TextEditingController(text: customer['name'] ?? '');
    final emailCtrl = TextEditingController(text: customer['email'] ?? '');
    final phoneCtrl = TextEditingController(text: customer['phone'] ?? '');
    final addressCtrl = TextEditingController(text: customer['address'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update Firestore with lastEdited timestamp
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(widget.customerId)
                  .update({
                'name': nameCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'address': addressCtrl.text.trim(),
                'lastEdited': FieldValue
                    .serverTimestamp(),
              });
              if (mounted) {
                Navigator.pop(context);
                setState(() {}); // refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Customer updated')),
                );
              }
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
      appBar: AppBar(title: const Text("Customer Profile Manage")),
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
          (a['date'] as Timestamp?)?.toDate().month ==
              DateTime.now().month)
              .length;

          String lastServicedStr = lastServiced != null
              ? DateFormat.yMMMMd().add_jm().format(lastServiced)
              : "N/A";

          String lastEditedStr = "N/A";
          if (customer['lastEdited'] is Timestamp) {
            lastEditedStr = DateFormat.yMMMMd().add_jm()
                .format((customer['lastEdited'] as Timestamp).toDate());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Profile
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Edit button
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit Customer',
                          onPressed: () => _showEditDialog(customer),
                        ),
                      ),
                      // Customer info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person,
                              size: 48, color: Colors.blue),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.customerId} - ${customer['name'] ?? 'No Name'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text("Email: ${customer['email'] ?? 'N/A'}"),
                                Text("Phone: ${customer['phone'] ?? 'N/A'}"),
                                Text("Address: ${customer['address'] ?? 'N/A'}"),
                                Text("Last Serviced: $lastServicedStr"),
                                Text("Last Edited: $lastEditedStr"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Appointment Summary
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

                // Vehicles Info
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
                          Text(
                              "Plate Number: ${vehicle['plateNumber'] ?? 'N/A'}"),
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

                // Appointment History
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
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text("ID: ${a['id'] ?? 'N/A'}"),
                                      Text(
                                          "Vehicle ID: ${a['vehicleId'] ?? 'N/A'}"),
                                      Text(
                                          "Service Type: ${a['serviceType'] ?? 'N/A'}"),
                                      Text(
                                          "Date: ${DateFormat.yMMMMd().add_jm().format(d)}"),
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
