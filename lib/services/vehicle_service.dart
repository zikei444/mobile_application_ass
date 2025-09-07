import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addVehicle(String userId, Map<String, dynamic> vehicle) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .add(vehicle);
  }

  Stream<QuerySnapshot> getVehicles(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .snapshots();
  }

  Future<void> deleteVehicle(String userId, String vehicleId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicles')
        .doc(vehicleId)
        .delete();
  }
}
