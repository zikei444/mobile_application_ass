import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InteractionPage extends StatelessWidget {
  final String customerId;
  const InteractionPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Interaction"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection("customers").doc(customerId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final customerData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== Customer Info =====
                Card(
                  child: ListTile(
                    title: Text(customerData['name'] ?? ''),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Phone: ${customerData['phone'] ?? ''}"),
                        Text("Email: ${customerData['email'] ?? ''}"),
                        Text("Address: ${customerData['address'] ?? ''}"),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Vehicle Info
                FutureBuilder<QuerySnapshot>(
                  future: firestore
                      .collection("vehicles")
                      .where("customerId", isEqualTo: customerId)
                      .limit(1)
                      .get(),
                  builder: (context, vehicleSnap) {
                    if (!vehicleSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (vehicleSnap.data!.docs.isEmpty) {
                      return const Text("No vehicle found.");
                    }

                    final carData = vehicleSnap.data!.docs.first.data()
                    as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text("Plate: ${carData['plateNumber'] ?? ''}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Type: ${carData['type'] ?? ''}"),
                            Text("Model: ${carData['model'] ?? ''}"),
                            Text("Kilometer: ${carData['kilometer'] ?? ''}"),
                            Text("Size: ${carData['size'] ?? ''}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),
                const Text(
                  "Appointments",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Appointments Stream
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection("appointments")
                      .where("customerId", isEqualTo: customerId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No appointments found.");
                    }

                    final appointments = snapshot.data!.docs;
                    return Column(
                      children: appointments.map((doc) {
                        final appointmentData =
                        doc.data() as Map<String, dynamic>;
                        final appointmentId = doc.id;
                        final status =
                        (appointmentData['status'] ?? 'In Progress')
                            .toString();
                        final formattedDate =
                        appointmentData['date'] is Timestamp
                            ? DateFormat('yyyy-MM-dd – kk:mm').format(
                            (appointmentData['date'] as Timestamp)
                                .toDate())
                            : appointmentData['date'] ?? '';

                        return Card(
                          child: ListTile(
                            title: Text("Appointment ID: $appointmentId"),
                            subtitle: Text("Date: $formattedDate"),
                            trailing: SizedBox(
                              width: 150,
                              height: 40,
                              child: Center(
                                child: Chip(
                                  label: Text(
                                    status,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor:
                                  status.toLowerCase() == "completed"
                                      ? Colors.green
                                      : status.toLowerCase() == "cancelled"
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AppointmentDetailPage(
                                    customerId: customerId,
                                    appointmentId: appointmentId,
                                    appointmentData: appointmentData,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AppointmentDetailPage extends StatelessWidget {
  final String customerId;
  final String appointmentId;
  final Map<String, dynamic> appointmentData;

  const AppointmentDetailPage({
    super.key,
    required this.customerId,
    required this.appointmentId,
    required this.appointmentData,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final status = (appointmentData['status'] ?? 'In Progress').toString();

    final formattedDate = appointmentData['date'] is Timestamp
        ? DateFormat('yyyy-MM-dd – kk:mm')
        .format((appointmentData['date'] as Timestamp).toDate())
        : appointmentData['date'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Appointment Detail")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Appointment ID: $appointmentId",
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Service Type: ${appointmentData['serviceType'] ?? ''}"),
            const SizedBox(height: 8),
            Text("Date: $formattedDate"),
            const SizedBox(height: 8),
            Text("Notes: ${appointmentData['notes'] ?? ''}"),
            const SizedBox(height: 8),
            Text("Status: $status"),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildActionButtons(context, firestore, status),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(
      BuildContext context, FirebaseFirestore firestore, String status) {
    final lowerStatus = status.toLowerCase();
    final buttons = <Widget>[];

    Future<void> updateStatus(String newStatus) async {
      await firestore
          .collection("appointments")
          .doc(appointmentId)
          .update({"status": newStatus});
      Navigator.pop(context);
    }

    if (lowerStatus == "pending") {
      buttons.addAll([
        _actionBtn("Cancel", Colors.red, () => updateStatus("Cancelled")),
        _actionBtn("Complete", Colors.green, () => updateStatus("Completed")),
        _actionBtn("Scheduled", Colors.orange, () => updateStatus("Scheduled")),
      ]);
    } else if (lowerStatus == "scheduled") {
      buttons.addAll([
        _actionBtn("Cancel", Colors.red, () => updateStatus("Cancelled")),
        _actionBtn("Complete", Colors.green, () => updateStatus("Completed")),
        _actionBtn("In Progress", Colors.orange,
                () => updateStatus("In Progress")),
      ]);
    } else if (lowerStatus == "in progress") {
      buttons.addAll([
        _actionBtn("Cancel", Colors.red, () => updateStatus("Cancelled")),
        _actionBtn("Complete", Colors.green, () => updateStatus("Completed")),
      ]);
    } else if (lowerStatus == "cancelled" || lowerStatus == "completed") {
      buttons.add(
        _actionBtn("Close", Colors.grey, () => Navigator.pop(context)),
      );
    }

    return buttons;
  }

  Widget _actionBtn(String text, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: color,
                                      foregroundColor: Colors.white,
                                      fixedSize: const Size(150, 40)),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}
