import 'package:flutter/material.dart';

class BasePage extends StatelessWidget {
  final String title;
  final Widget child;

  const BasePage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "Hello, Staff", // 🔹 later replace with logged-in user name
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),

      // 🔹 Universal side navigation menu
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                "Workshop Menu",
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/dashboard");
              },
            ),
            ListTile(
              leading: const Icon(Icons.car_repair),
              title: const Text("Vehicles"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/vehicles");
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Services"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/services");
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text("Customers"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/customers");
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
