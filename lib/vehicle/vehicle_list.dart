import 'package:flutter/material.dart';
import 'package:mobile_application_ass/vehicle/vehicle_details.dart';

import 'add_vehicle.dart';


class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AddVehiclePage()));
            },
            child: const Text("Add Vehicle"),
          )
        ],
      ),
      body: ListView(
        children: [
          _vehicleItem(context, "#89567", "Mercedes Benz", "AVS 2044"),
          _vehicleItem(context, "#89568", "BMW", "BMS 2021"),
        ],
      ),
    );
  }

  Widget _vehicleItem(BuildContext context, String id, String type, String plate) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_car, size: 40),
        title: Text(type),
        subtitle: Text(plate),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleDetailsPage(
            id: id, type: type, plate: plate,
          )));
        },
      ),
    );
  }
}
