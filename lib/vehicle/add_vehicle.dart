import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Vehicle type & models mapping
  final Map<String, List<String>> vehicleModels = {
    "Mercedes": ["C180", "C500", "E200"],
    "BMW": ["BMW 1", "BMW 2", "BMW X5"],
    "Toyota": ["Vios", "Corolla", "Camry"],
  };

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
          child: ListView(
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

              // Vehicle Model Dropdown (depends on type)
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

              // Kilometer (digits only)
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

              // Size (digits only)
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
              const SizedBox(height: 20),

              // Save Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, {
                      "plate": _plateController.text,
                      "type": _selectedType!,
                      "model": _selectedModel!,
                      "kilometer": _kmController.text,
                      "size": _sizeController.text,
                    });
                  }
                },
                child: const Text("Save Vehicle"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
