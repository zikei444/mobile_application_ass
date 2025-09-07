import 'package:flutter/material.dart';
import 'add_vehicle.dart';

class VehicleDetailsPage extends StatelessWidget {
  final String id;
  final String type;
  final String plate;

  const VehicleDetailsPage({
    super.key,
    required this.id,
    required this.type,
    required this.plate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(plate)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Car Information",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Card(
              child: ListTile(
                title: Text("Plate: $plate"),
                subtitle: Text(
                    "Type: $type\nModel: c180\nSize: 100,000\nKilometer: 100,000"),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Service History",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            _serviceHistory("Inspection", "John", "Closed"),
            _serviceHistory("Tire Change", "Bryan", "Open"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final newVehicle = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VehicleForm(),
            ),
          );

          if (newVehicle != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("New vehicle details added!")),
            );
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Add New Details"),
      ),
    );
  }

  Widget _serviceHistory(String service, String staff, String status) {
    return Card(
      child: ListTile(
        title: Text(service),
        subtitle: Text("By $staff"),
        trailing: Chip(label: Text(status)),
      ),
    );
  }
}
