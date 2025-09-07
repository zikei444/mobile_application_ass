import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryBox("52", "Jobs"),
                _summaryBox("52", "Vehicle"),
                _summaryBox("52", "Spare Parts"),
                _summaryBox("52", "Customer"),
              ],
            ),
            const SizedBox(height: 20),

            const Text("Job Schedule List For Today", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            _jobSchedule("C01 - Cashier1", "Cashier", "9am - 3pm"),
            _jobSchedule("M01 - Mechanics1", "Mechanics", "9am - 3pm"),

            const SizedBox(height: 20),
            const Text("Low Stock Notification", style: TextStyle(fontWeight: FontWeight.bold)),

            _lowStockRow("Engine", "15"),
            _lowStockRow("Tayar", "15"),
          ],
        ),
      ),
    );
  }

  Widget _summaryBox(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label),
      ],
    );
  }

  Widget _jobSchedule(String name, String role, String time) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(name),
        subtitle: Text(role),
        trailing: Text(time),
      ),
    );
  }

  Widget _lowStockRow(String product, String qty) {
    return ListTile(
      title: Text(product),
      trailing: Text(qty),
    );
  }
}
