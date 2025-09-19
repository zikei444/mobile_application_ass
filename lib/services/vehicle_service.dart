import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleService {
  final CollectionReference vehicles =
  FirebaseFirestore.instance.collection('vehicles');

  Future<void> addVehicle({
    required String customerId,
    required String vehicleId,
    required String plateNumber,
    required String type,
    required String model,
    required int kilometer,
    required int size,
    required String vin,
  }) async {
    await vehicles.doc(vehicleId).set({
      'vehicle_id' : vehicleId,
      'customerId' : customerId,
      'plateNumber': plateNumber,
      'type': type,
      'model': model,
      'kilometer': kilometer,
      'size': size,
      'vin': vin,
      'createdAt': FieldValue.serverTimestamp(),
    });

  }

  Stream<QuerySnapshot> getVehicles() {
    return vehicles.orderBy('createdAt', descending: true).snapshots();
  }

  /// =========================
  /// UPDATE: Update an existing vehicle by string ID
  /// =========================
  /// Update a vehicle by its vehicle_id field
  /// [vehicleId] is the custom vehicle_id in the document
  /// [data] is the map of updated values
  Future<void> updateVehicleByVehicleId(
      String vehicleId, Map<String, dynamic> data) async {
    try {
      // 1️⃣ Query Firestore for the document with the matching vehicleId
      final snapshot = await vehicles
          .where('vehicle_id', isEqualTo: vehicleId)
          .get();

      if (snapshot.docs.isEmpty) {
        // No matching document found
        print("No vehicle found with vehicle_id: $vehicleId");
        return;
      }

      // 2️⃣ Use the first matching document (assuming vehicle_id is unique)
      final docRef = snapshot.docs.first.reference;

      // 3️⃣ Update the document with new data
      await docRef.update(data);

      print("Vehicle updated successfully: $vehicleId");
    } catch (e) {
      print("Error updating vehicle: $e");
    }
  }


  /// =========================
  /// DELETE VEHICLE BY vehicle_id
  /// =========================
  Future<void> deleteVehicle(String vehicleId) async {
    // Find document with this vehicle_id
    final snapshot = await vehicles.where('vehicle_id', isEqualTo: vehicleId).limit(1).get();
    if (snapshot.docs.isEmpty) return; // nothing to delete

    final docId = snapshot.docs.first.id;
    await vehicles.doc(docId).delete();
  }
  Future<void> deleteAllVehicles() async {
    final snapshot = await vehicles.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

}
