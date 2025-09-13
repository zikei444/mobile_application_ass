import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'interaction.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  Map<String, bool> activeStatus = {};
  bool loadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      loadingAppointments = true;
    });

    final snapshot = await FirebaseFirestore.instance.collection('appointments').get();
    final Map<String, bool> tempStatus = {};

    for (var doc in snapshot.docs) {
      final customerId = doc['customerId']?.toString().trim() ?? '';
      final status = doc['status']?.toString().trim() ?? '';
      if (customerId.isNotEmpty && (status == 'In Progress' || status == 'Scheduled')) {
        tempStatus[customerId] = true;
      }
    }

    setState(() {
      activeStatus = tempStatus;
      loadingAppointments = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search by ID or Name",
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
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("customers").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading customers"));
                }
                if (snapshot.connectionState == ConnectionState.waiting || loadingAppointments) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = snapshot.data!.docs;

                final filteredCustomers = customers.where((doc) {
                  final name = (doc['name'] ?? "").toString().toLowerCase();
                  final id = doc.id.toLowerCase();
                  return name.contains(searchQuery) || id.contains(searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return const Center(child: Text("No customers found"));
                }

                return ListView.builder(
                  itemCount: filteredCustomers.length,
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
                    final hasActive = activeStatus[customer.id] ?? false;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: Stack(
                          children: [
                            const Icon(Icons.person, color: Colors.blue, size: 40),
                            if (hasActive)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(customer['name'] ?? "No Name", overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          "Email: ${customer['email'] ?? 'N/A'}\nPhone: ${customer['phone'] ?? 'N/A'}",
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: const Text("View Profile"),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(customerId: customer.id),
                                        ),
                                      );
                                      _loadAppointments(); // refresh after return
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.chat),
                                    title: const Text("Manage Interaction"),
                                    onTap: () async {
                                      Navigator.pop(context);
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InteractionPage(customerId: customer.id),
                                        ),
                                      );
                                      _loadAppointments(); // refresh after return
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
