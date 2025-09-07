import 'package:flutter/material.dart';

class AddVehiclePage extends StatelessWidget {
  const AddVehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    final plateController = TextEditingController();
    final typeController = TextEditingController();
    final modelController = TextEditingController();
    final kmController = TextEditingController();
    final sizeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: plateController, decoration: const InputDecoration(labelText: "Plate Number")),
            TextField(controller: typeController, decoration: const InputDecoration(labelText: "Type")),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: "Model")),
            TextField(controller: kmController, decoration: const InputDecoration(labelText: "Kilometer")),
            TextField(controller: sizeController, decoration: const InputDecoration(labelText: "Size")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Later: Save to database
                Navigator.pop(context);
              },
              child: const Text("Submit"),
            )
          ],
        ),
      ),
    );
  }
}
