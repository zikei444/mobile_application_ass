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
                // Customer Info
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

                // Car Info
                FutureBuilder<DocumentSnapshot>(
                  future: firestore
                      .collection("cars")
                      .doc(customerData['carId'])
                      .get(),
                  builder: (context, carSnapshot) {
                    if (!carSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final carData =
                    carSnapshot.data!.data() as Map<String, dynamic>;

                    return Card(
                      child: ListTile(
                        title: Text("Plate: ${carData['plateNumber'] ?? ''}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Brand: ${carData['brand'] ?? ''}"),
                            Text("Model: ${carData['model'] ?? ''}"),
                            Text("Year: ${carData['year'] ?? ''}"),
                            Text("Color: ${carData['color'] ?? ''}"),
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

                // All Appointments
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

                        final clickable = status.toLowerCase() == "in progress" ||
                            status.toLowerCase() == "scheduled" ||
                            status.toLowerCase() == "pending";

                        String formattedDate =
                        appointmentData['date'] is Timestamp
                            ? DateFormat('yyyy-MM-dd – kk:mm').format(
                            (appointmentData['date'] as Timestamp)
                                .toDate())
                            : appointmentData['date'] ?? '';

                        return Card(
                          child: ListTile(
                            title: Text("Appointment ID: $appointmentId"),
                            subtitle: Text("Date: $formattedDate"),
                            trailing: Chip(
                              label: Text(
                                status,
                                style: const TextStyle(color: Colors.white),
                              ),
                              // ✅ Pending also shows orange
                              backgroundColor: clickable
                                  ? Colors.orange
                                  : status.toLowerCase() == "completed"
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onTap: clickable
                                ? () {
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
                            }
                                : null,
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

    String formattedDate = appointmentData['date'] is Timestamp
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
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await firestore
                        .collection("appointments")
                        .doc(appointmentId)
                        .update({"status": "Cancelled"});
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    await firestore
                        .collection("appointments")
                        .doc(appointmentId)
                        .update({"status": "Completed"});
                    Navigator.pop(context);
                  },
                  child: const Text("Complete"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
