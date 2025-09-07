import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_application_ass/vehicle/vehicle_details.dart';
import '../services/vehicle_service.dart';

class VehicleListPage extends StatelessWidget {
  const VehicleListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle List"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/addVehicle');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: VehicleService().getVehicles(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // only first load shows loader
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

              return ListTile(
                title: Text("${data['plate']} - ${data['type']}"),
                subtitle: Text("Model: ${data['model']} | KM: ${data['kilometer']}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VehicleDetailsPage(vehicle: data),
                    ),
                  );
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    VehicleService().deleteVehicle(userId, v.id);
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

//   @override
//   _VehicleListState createState() => _VehicleListState();
// }
//
// class _VehicleListState extends State<VehicleList> {
//   List<Map<String, String>> vehicles = [];
//
//   void _addVehicle(Map<String, String> vehicle) {
//     setState(() {
//       vehicles.add(vehicle);
//     });
//   }
//
//   void _deleteAllVehicles() {
//     setState(() {
//       vehicles.clear();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Top bar row
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Back button
//                   IconButton(
//                     icon: Icon(Icons.arrow_back),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//
//                   // Title
//                   Text(
//                     "Vehicle List",
//                     style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold
//                     ),
//                   ),
//
//                   // Buttons (Add + Delete)
//                   Row(
//                     children: [
//                       ElevatedButton.icon(
//                         icon: Icon(Icons.add),
//                         label: Text("Add"),
//                         onPressed: () async {
//                           final newVehicle = await Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => VehicleForm()),
//                           );
//                           if (newVehicle != null) {
//                             _addVehicle(newVehicle);
//                           }
//                         },
//                       ),
//                       SizedBox(width: 8),
//                       ElevatedButton.icon(
//                         icon: Icon(Icons.delete),
//                         label: Text("Delete"),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.red,
//                         ),
//                         onPressed: _deleteAllVehicles,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             Divider(),
//
//             // Vehicle list
//             Expanded(
//               child: vehicles.isEmpty
//                   ? Center(child: Text("No vehicles available"))
//                   : ListView.builder(
//                 itemCount: vehicles.length,
//                 itemBuilder: (context, index) {
//                   final v = vehicles[index];
//                   return ListTile(
//                     leading: Icon(Icons.directions_car),
//                     title: Text("${v['plate']} - ${v['type']}"),
//                     subtitle: Text(v['model'] ?? ""),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
