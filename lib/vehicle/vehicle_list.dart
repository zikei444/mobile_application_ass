import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_application_ass/vehicle/add_vehicle.dart';
import 'package:mobile_application_ass/vehicle/vehicle_details.dart';
import '../services/vehicle_service.dart';

class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

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
      body: StreamBuilder<QuerySnapshot>(
        stream: VehicleService().getVehicles(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No vehicles found."));
          }

          final vehicles = snapshot.data!.docs;

          return ListView.builder(
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final v = vehicles[index];
              final data = v.data() as Map<String, dynamic>;
              final vehicleId = data['vehicle_id'] as String; // use vehicle_id
              return ListTile(
                leading: const Icon(Icons.directions_car),
                title: Text("${data['plateNumber']} - ${data['type']}"),
                subtitle: Text("Model: ${data['model']} | KM: ${data['kilometer']}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleDetailsPage(vehicle: data ),
                    ),
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
                      await VehicleService().deleteVehicle(vehicleId); // pass custom vehicle_id
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
    );
  }
}
