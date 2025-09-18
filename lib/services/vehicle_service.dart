import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleService {
  final CollectionReference vehicles =
  FirebaseFirestore.instance.collection('vehicles');

  Future<void> addVehicle({
    required String customerId,
    required String vehicle_id,
    required String plateNumber,
    required String type,
    required String model,
    required int kilometer,
    required int size,
  }) async {
    await vehicles.add({
      'vehicle_id' : vehicle_id,
      'customerId' : customerId,
      'plateNumber': plateNumber,
      'type': type,
      'model': model,
      'kilometer': kilometer,
      'size': size,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getVehicles() {
    return vehicles.orderBy('createdAt', descending: true).snapshots();
  }
  Future<void> deleteVehicle(String id) async {
    await vehicles.doc(id).delete();
  }
  Future<void> deleteAllVehicles() async {
    final snapshot = await vehicles.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

}
