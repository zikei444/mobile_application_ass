import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/vehicle_service.dart';

class VehicleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleDetailsPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailsPage> createState() => _VehicleDetailsPageState();
}

class _VehicleDetailsPageState extends State<VehicleDetailsPage> {

  // ===== Fetch all appointments for this vehicle =====
  Future<List<Map<String, dynamic>>> _fetchVehicleAppointments() async {
    // Firestore query: get all appointments where vehicleId matches
    final appointmentSnap = await FirebaseFirestore.instance
        .collection('appointments')
        .where('vehicleId', isEqualTo: widget.vehicle['vehicle_id'])
        .get();

    // Convert QuerySnapshot to a list of maps and sort by date descending
    final vehicleAppointments = appointmentSnap.docs
        .map((e) => e.data()) // Get document data as Map
        .toList()
      ..sort((a, b) {
        final da = a['date'] as Timestamp?;
        final db = b['date'] as Timestamp?;
        return db?.compareTo(da ?? Timestamp.now()) ?? 0;
      });

    // Debug print to check how many appointments were found
    print("Found ${vehicleAppointments.length} appointments for vehicle ${widget
        .vehicle['id']}");

    return vehicleAppointments;
  }

  // ===== Helper widget to display vehicle detail row =====
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = widget.vehicle;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Vehicle Details Card with Plate Number as Title =====
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16), // spacing below
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFD1E3E2),//0xFF138146), // your green
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Plate Number Row with Edit Icon =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vehicle['plateNumber']?.toString() ?? "-",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87, // white for contrast
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => _showEditVehicleForm(vehicle),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ===== First Row: Type | Model | Kilometer =====
                  // ===== First Row: Type | Model | Kilometer =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Type: ${(vehicle['type'] ?? '-').toString()}",
                          style: const TextStyle(fontSize: 16, color: Colors.black54)),
                      Text("Model: ${(vehicle['model'] ?? '-').toString()}",
                          style: const TextStyle(fontSize: 16, color: Colors.black54)),
                      Text("KM: ${(vehicle['kilometer']?.toString() ?? '-')}",
                          style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ===== Second Row: Size | VIN =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Size: ${(vehicle['size'] ?? '-').toString()}",
                          style: const TextStyle(fontSize: 16, color: Colors.black54)),
                      Text("VIN: ${(vehicle['vin'] ?? '-').toString()}",
                          style: const TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),

                ],
              ),
            ),



            const SizedBox(height: 24),
            const Text(
              "Service History",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ===== Service History List =====
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchVehicleAppointments(),
              // fetch using exact customer-style method
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text("No service history found."),
                  );
                }

                final services = snapshot.data!;

                return Column(
                  children: services.map((service) {
                    final Timestamp? ts = service['date'] as Timestamp?;
                    final DateTime date = ts?.toDate() ?? DateTime.now();
                    final status = (service['status'] ?? 'In Progress')
                        .toString();

                    return Card(
                      child: ListTile(
                        title: Text(service['serviceType']?.toString() ?? "-"),
                        subtitle: Text(
                          "Date: ${DateFormat.yMMMMd().add_jm().format(date)}\n"
                              "Notes: ${service['notes']?.toString() ?? '-'}",
                        ),
                        trailing: Chip(
                          label: Text(
                            status,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: status.toLowerCase() == "completed"
                              ? Colors.green
                              : status.toLowerCase() == "cancelled"
                              ? Colors.red
                              : Colors.orange,
                        ),
                        onTap: () {
                          // ===== Show full service details in a dialog =====
                          showDialog(
                            context: context,
                            builder: (context) =>
                                AlertDialog(
                                  title: const Text("Service Details"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text("ID: ${service['id'] ?? 'N/A'}"),
                                      Text(
                                          "Service Type: ${service['serviceType'] ??
                                              'N/A'}"),
                                      Text("Date: ${DateFormat
                                          .yMMMMd()
                                          .add_jm()
                                          .format(date)}"),
                                      Text("Status: $status"),
                                      Text("Notes: ${service['notes'] ??
                                          'N/A'}"),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Close"),
                                    )
                                  ],
                                ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreyDetail(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200, // subtle grey background
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                // fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

// ===== Map of vehicle types and models =====
  final Map<String, List<String>> vehicleModels = {
    "Mercedes": ["C180", "C500"],
    "BMW": ["BMW1", "BMW2"],
  };

  void _showEditVehicleForm(Map<String, dynamic> vehicle) {
    final _plateController = TextEditingController(text: vehicle['plateNumber']);
    final _kmController = TextEditingController(text: vehicle['kilometer']?.toString());
    final _sizeController = TextEditingController(text: vehicle['size']?.toString());

    String? _selectedType = vehicle['type'];
    String? _selectedModel = vehicle['model'];

    showDialog(
      context: context,
      builder: (context) {
        final _formKey = GlobalKey<FormState>();

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Edit Vehicle Details"),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Plate Number row with label like display
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "Plate Number:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _plateController,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty ? "Enter plate number" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Type row
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "Type:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              items: vehicleModels.keys.map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (value) {
                                setStateDialog(() {
                                  _selectedType = value;
                                  _selectedModel = null;
                                });
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null ? "Select type" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Model row
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "Model:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _selectedModel,
                              items: _selectedType == null
                                  ? []
                                  : vehicleModels[_selectedType]!
                                  .map((model) => DropdownMenuItem(value: model, child: Text(model)))
                                  .toList(),
                              onChanged: (value) {
                                setStateDialog(() => _selectedModel = value);
                              },
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null ? "Select model" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kilometer row
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "Kilometer:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _kmController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty ? "Enter kilometer" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Size row
                      Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text(
                              "Size:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _sizeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value!.isEmpty ? "Enter size" : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Update Firestore
                      await VehicleService().updateVehicleByVehicleId(vehicle['vehicle_id'], {
                        'plateNumber': _plateController.text,
                        'type': _selectedType,
                        'model': _selectedModel,
                        'kilometer': int.tryParse(_kmController.text) ?? 0,
                        'size': int.tryParse(_sizeController.text) ?? 0,
                      });

                      // ✅ Update the local map so UI refreshes immediately
                      setState(() {
                        vehicle['plateNumber'] = _plateController.text;
                        vehicle['type'] = _selectedType;
                        vehicle['model'] = _selectedModel;
                        vehicle['kilometer'] = int.tryParse(_kmController.text) ?? 0;
                        vehicle['size'] = int.tryParse(_sizeController.text) ?? 0;
                      });

                      Navigator.pop(context); // close dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Vehicle details updated!")),
                      );
                    }
                  },
                  child: const Text("Save"),
                ),

              ],
            );
          },
        );
      },
    );
  }

}