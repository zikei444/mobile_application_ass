import 'package:flutter/material.dart';

class VehicleDetailsPage extends StatelessWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Plate Number: ${vehicle['plate']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Type: ${vehicle['type']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Model: ${vehicle['model']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Kilometer: ${vehicle['kilometer']}", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text("Size: ${vehicle['size']}", style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
