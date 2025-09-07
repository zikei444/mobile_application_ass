import 'package:flutter/material.dart';
import 'add_vehicle.dart';

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  // Temporary in-memory list (later can connect to Firebase)
  List<Map<String, String>> vehicles = [
    {"name": "Toyota Corolla", "plate": "ABC1234"},
    {"name": "Honda Civic", "plate": "XYZ5678"},
  ];

  void addVehicle(Map<String, String> vehicle) {
    setState(() {
      vehicles.add(vehicle);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle List"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: vehicles.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.directions_car),
            title: Text(vehicles[index]["name"]!),
            subtitle: Text("Plate: ${vehicles[index]["plate"]}"),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
        onPressed: () async {
          final newVehicle = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VehicleForm(),
            ),
          );

          if (newVehicle != null) {
            addVehicle(newVehicle);
          }
        },
      ),
    );
  }
}
