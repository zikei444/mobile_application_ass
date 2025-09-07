import 'package:flutter/material.dart';
import '../vehicle/vehicle_list.dart';


class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int vehicleCount = 3;   // later fetch from database
  int customerCount = 5;  // later fetch from database
  int staffCount = 2;     // later fetch from database
  int sparePartCount = 7; // later fetch from database

  final List<Map<String, dynamic>> dashboardItems = [];

  @override
  void initState() {
    super.initState();

    // Initialize dashboard buttons
    dashboardItems.addAll([
      {
        'label': 'Vehicles',
        'icon': Icons.directions_car,
        'count': () => vehicleCount,
        'page': VehicleList(),
      },
      {
        'label': 'Customers',
        'icon': Icons.person,
        'count': () => customerCount,
        //'page': CustomerList(),
      },
      {
        'label': 'Staff',
        'icon': Icons.people,
        'count': () => staffCount,
       // 'page': StaffList(),
      },
      {
        'label': 'Spare Parts',
        'icon': Icons.build,
        'count': () => sparePartCount,
        //'page': SparePartList(),
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: dashboardItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final item = dashboardItems[index];
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['page']),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item['icon'], size: 40),
                  SizedBox(height: 10),
                  Text(
                    item['label'],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Total: ${item['count']()}",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
