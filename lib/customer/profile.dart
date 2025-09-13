import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatelessWidget {
  final String customerId;

  const Profile({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer Profile")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection("customers").doc(customerId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading profile"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Name: ${data['name'] ?? 'N/A'}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                Text("Email: ${data['email'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("Phone: ${data['phone'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("Address: ${data['address'] ?? 'N/A'}", style: const TextStyle(fontSize: 16)),
              ],
            ),
          );
        },
      ),
    );
  }
}
