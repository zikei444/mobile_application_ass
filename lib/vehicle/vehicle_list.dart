import 'package:flutter/material.dart';
import 'add_vehicle.dart';

class VehicleList extends StatefulWidget {
  @override
  _VehicleListState createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  List<Map<String, String>> vehicles = [];

  void _addVehicle(Map<String, String> vehicle) {
    setState(() {
      vehicles.add(vehicle);
    });
  }

  void _deleteAllVehicles() {
    setState(() {
      vehicles.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Title
                  Text(
                    "Vehicle List",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold
                    ),
                  ),

                  // Buttons (Add + Delete)
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: Icon(Icons.add),
                        label: Text("Add"),
                        onPressed: () async {
                          final newVehicle = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => VehicleForm()),
                          );
                          if (newVehicle != null) {
                            _addVehicle(newVehicle);
                          }
                        },
                      ),
                      SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: Icon(Icons.delete),
                        label: Text("Delete"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _deleteAllVehicles,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Divider(),

            // Vehicle list
            Expanded(
              child: vehicles.isEmpty
                  ? Center(child: Text("No vehicles available"))
                  : ListView.builder(
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  return ListTile(
                    leading: Icon(Icons.directions_car),
                    title: Text("${v['plate']} - ${v['type']}"),
                    subtitle: Text(v['model'] ?? ""),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
