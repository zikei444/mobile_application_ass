import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile.dart';
import 'interaction.dart';
import 'add_customer.dart';

class CustomerList extends StatefulWidget {
  const CustomerList({super.key});

  @override
  State<CustomerList> createState() => _CustomerListState();
}

class _CustomerListState extends State<CustomerList> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Customer List")),
      body: Column(
        children: [
          // ===== Search and Add Button =====
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.blue, size: 30),
                  tooltip: "Add Customer",
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCustomerPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ===== Customer List =====
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("customers").snapshots(),
              builder: (context, customerSnap) {
                if (customerSnap.hasError) {
                  return const Center(child: Text("Error loading customers"));
                }
                if (customerSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final customers = customerSnap.data!.docs;

                // Filter customers by search query
                final filteredCustomers = customers.where((doc) {
                  final name = (doc['name'] ?? "").toString().toLowerCase();
                  final id = doc.id.toLowerCase();
                  return name.contains(searchQuery) || id.contains(searchQuery);
                }).toList();

                if (filteredCustomers.isEmpty) {
                  return const Center(child: Text("No customers found"));
                }

                // ===== Stream active appointments =====
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
                  builder: (context, appointmentSnap) {
                    Set<String> activeCustomerIds = {};

                    if (appointmentSnap.hasData) {
                      for (var doc in appointmentSnap.data!.docs) {
                        final customerId = doc['customerId']?.toString().trim() ?? '';
                        final status = (doc['status']?.toString().trim() ?? '').toLowerCase();
                        if (customerId.isNotEmpty &&
                            (status == 'in progress' ||
                                status == 'scheduled' ||
                                status == 'pending')) {
                          activeCustomerIds.add(customerId);
                        }
                      }
                    }

                    return ListView.builder(
                      itemCount: filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = filteredCustomers[index];
                        final hasActive = activeCustomerIds.contains(customer.id);

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
                            title: Text(customer['name'] ?? "No Name"),
                            subtitle: Text("Email: ${customer['email'] ?? 'N/A'}\nPhone: ${customer['phone'] ?? 'N/A'}"),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Arrow button for details
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onPressed: () async {
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
                                                    builder: (context) => ProfilePage(
                                                      customerId: customer.id,
                                                    ),
                                                  ),
                                                );
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
                                                    builder: (context) =>
                                                        InteractionPage(customerId: customer.id),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                                // Delete button
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Delete Customer"),
                                        content: const Text("Are you sure you want to delete this customer?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await FirebaseFirestore.instance
                                          .collection('customers')
                                          .doc(customer.id)
                                          .delete();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Customer deleted")),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
