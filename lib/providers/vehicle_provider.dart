import 'package:flutter/material.dart';

class VehicleProvider extends ChangeNotifier {
  final List<Map<String, String>> _vehicles = [];

  List<Map<String, String>> get vehicles => _vehicles;

  int get vehicleCount => _vehicles.length;

  void addVehicle(Map<String, String> vehicle) {
    _vehicles.add(vehicle);
    notifyListeners(); // update UI
  }
}
