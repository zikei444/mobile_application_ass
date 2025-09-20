import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_application_ass/vehicle/add_vehicle.dart';
import 'package:mobile_application_ass/vehicle/vehicle_details.dart';
import '../services/vehicle_service.dart';

class VehicleListPage extends StatefulWidget {
  const VehicleListPage({super.key});

  @override
  State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
  String searchQuery = "";
  // String filterType = "All";
  String sortBy = "plateNumber";
  bool ascending = true;
  String brandFilter = "All"; // default shows all vehicles

  List<Map<String, dynamic>> _vehicles = [];
// Vehicle type & models mapping
  final Map<String, List<String>> vehicleModels = {
    "Mercedes": ["C180", "C500"],
    "BMW": ["BMW1", "BMW2"],
  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Vehicle List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add Vehicle",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehicleForm()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: "Delete All Vehicles",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Confirm Delete"),
                  content: const Text("Delete all vehicles? This cannot be undone."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await VehicleService().deleteAllVehicles();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search Vehicle",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Vehicle List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: VehicleService().getVehicles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No vehicles found."));
                }

                // Convert to List<Map<String, dynamic>> for easier filtering/sorting
                _vehicles = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

                // Apply search filter
                var filteredVehicles = _vehicles.where((data) {
                  return data['plateNumber'].toString().toLowerCase().contains(searchQuery) ||
                      data['model'].toString().toLowerCase().contains(searchQuery) ||
                      data['type'].toString().toLowerCase().contains(searchQuery);
                }).toList();


                // Apply brand filter
                if (brandFilter != "All") {
                  List<String> allowedModels = vehicleModels[brandFilter] ?? [];
                  filteredVehicles = filteredVehicles.where((data) {
                    final brand = (data['brand'] ?? "").toString().trim();
                    final model = (data['model'] ?? "").toString().trim();
                    return brand == brandFilter && allowedModels.contains(model);
                  }).toList();
                }

                // Apply sorting
                filteredVehicles.sort((a, b) {
                  var aValue = a[sortBy] ?? "";
                  var bValue = b[sortBy] ?? "";
                  if (sortBy == "kilometer") {
                    aValue = int.tryParse(aValue.toString()) ?? 0;
                    bValue = int.tryParse(bValue.toString()) ?? 0;
                  }
                  return ascending
                      ? aValue.toString().compareTo(bValue.toString())
                      : bValue.toString().compareTo(aValue.toString());
                });

                return ListView.builder(
                  itemCount: filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final data = filteredVehicles[index];
                    final vehicleId = data['vehicle_id'] as String;
                    return ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: Text("${data['plateNumber']} - ${data['type']}"),
                      subtitle: Text("Model: ${data['model']} | KM: ${data['kilometer']}"),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => VehicleDetailsPage(vehicle: data)),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Confirm Delete"),
                              content: const Text("Delete this vehicle? This cannot be undone."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await VehicleService().deleteVehicle(vehicleId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Vehicle deleted successfully")),
                            );
                          }
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
