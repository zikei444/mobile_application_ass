import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/vehicle_service.dart';

class VehicleForm extends StatefulWidget {
  const VehicleForm({super.key});

  @override
  State<VehicleForm> createState() => _VehicleFormState();
}

class _VehicleFormState extends State<VehicleForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _kmController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();

  String? _selectedType;
  String? _selectedModel;
  String? _selectedCustomerId;

  // Vehicle type & models mapping
  final Map<String, List<String>> vehicleModels = {
    "Mercedes": ["C180", "C500"],
    "BMW": ["BMW1", "BMW2"],
  };

  /// Generate the next vehicle_id in the format V001, V002, ...
  Future<String> _generateVehicleId() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vehicles')
        .orderBy('vehicle_id', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return 'V001';
    }

    final lastId = snapshot.docs.first['vehicle_id'] as String;
    final numPart = int.tryParse(lastId.substring(1)) ?? 0;
    final nextNum = numPart + 1;
    return 'V${nextNum.toString().padLeft(3, '0')}';
  }

  /// Fetch all customer IDs for dropdown
  Future<List<String>> _fetchCustomerIds() async {
    final snapshot = await FirebaseFirestore.instance.collection('customers').get();
    return snapshot.docs.map((doc) => doc.id).toList(); // use doc.id
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Vehicle"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: FutureBuilder<List<String>>(
            future: _fetchCustomerIds(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading customers'));
              }

              final customerIds = snapshot.data ?? [];

              return ListView(
                children: [
                  // Plate Number
                  TextFormField(
                    controller: _plateController,
                    decoration: const InputDecoration(
                      labelText: "Plate Number",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                    value!.isEmpty ? "Enter plate number" : null,
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: "Vehicle Type",
                      border: OutlineInputBorder(),
                    ),
                    items: vehicleModels.keys.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value;
                        _selectedModel = null; // reset model
                      });
                    },
                    validator: (value) =>
                    value == null ? "Select vehicle type" : null,
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Model Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedModel,
                    decoration: const InputDecoration(
                      labelText: "Vehicle Model",
                      border: OutlineInputBorder(),
                    ),
                    items: _selectedType == null
                        ? []
                        : vehicleModels[_selectedType]!.map((model) {
                      return DropdownMenuItem(
                          value: model, child: Text(model));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedModel = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? "Select vehicle model" : null,
                  ),
                  const SizedBox(height: 16),

                  // Kilometer
                  TextFormField(
                    controller: _kmController,
                    decoration: const InputDecoration(
                      labelText: "Kilometer",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) =>
                    value!.isEmpty ? "Enter kilometer" : null,
                  ),
                  const SizedBox(height: 16),

                  // Size
                  TextFormField(
                    controller: _sizeController,
                    decoration: const InputDecoration(
                      labelText: "Size",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) => value!.isEmpty ? "Enter size" : null,
                  ),
                  const SizedBox(height: 16),

                  // Customer ID Dropdown (with name)
                  DropdownButtonFormField<String>(
                    value: _selectedCustomerId,
                    decoration: const InputDecoration(
                      labelText: "Select Customer",
                      border: OutlineInputBorder(),
                    ),
                    items: customerIds.map((id) {
                      return DropdownMenuItem(
                        value: id,
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('customers')
                              .doc(id)
                              .get(),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return Text(id);
                            }
                            if (!snap.hasData || !snap.data!.exists) {
                              return Text(id);
                            }
                            final name = snap.data!['name'] ?? '';
                            return Text("$id - $name");
                          },
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomerId = value;
                      });
                    },
                    validator: (value) =>
                    value == null ? "Select customer" : null,
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          final vehicleId = await _generateVehicleId();

                          await VehicleService().addVehicle(
                            vehicle_id: vehicleId,
                            plateNumber: _plateController.text,
                            type: _selectedType!,
                            model: _selectedModel!,
                            kilometer: int.parse(_kmController.text),
                            size: int.parse(_sizeController.text),
                            customerId: _selectedCustomerId!,
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Vehicle Added!")),
                          );

                          Navigator.pop(context);
                        }
                      }
                    },
                    child: const Text("Save Vehicle"),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
