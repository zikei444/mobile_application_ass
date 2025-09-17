import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../vehicle/vehicle_list.dart';
import '../workScheduler/schedule.dart';
import '../sparePart/spare_part_dashboard.dart';
import '../customer/customerList.dart';
import '../widgets/base_page.dart';

class Dashboard extends StatefulWidget {
  final String userEmail; // passed from login
  const Dashboard({super.key, required this.userEmail});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int vehicleCount = 0;
  int customerCount = 0;
  int staffCount = 0;
  int sparePartCount = 0;

  Map<String, Map<String, dynamic>> staffMap = {}; // cache staff data

  final List<Map<String, dynamic>> dashboardItems = [];

  final Map<String, Color> roleColors = {
    'Cashier': Colors.green,
    'Mechanic': Colors.blue,
    'Admin': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadStaff();

    // Dashboard buttons
    dashboardItems.addAll([
      {
        'label': 'Vehicles',
        'icon': Icons.directions_car,
        'count': () => vehicleCount,
        'page': const VehicleListPage(),
      },
      {
        'label': 'Customers',
        'icon': Icons.person,
        'count': () => customerCount,
        'page': const CustomerList(),
      },
      {
        'label': 'Schedules',
        'icon': Icons.schedule,
        'count': () => staffCount,
        'page': const CalendarPage(),
      },
      {
        'label': 'Spare Parts',
        'icon': Icons.build,
        'count': () => sparePartCount,
        'page': const SparePartDashboard(),
      },
    ]);
  }

  /// 🔹 Load counts using aggregate queries
  Future<void> _loadCounts() async {
    final staffCountQuery =
    await FirebaseFirestore.instance.collection('staff').count().get();
    final vehicleCountQuery =
    await FirebaseFirestore.instance.collection('vehicles').count().get();
    final customerCountQuery =
    await FirebaseFirestore.instance.collection('customers').count().get();
    final sparePartCountQuery =
    await FirebaseFirestore.instance.collection('spareParts').count().get();

    setState(() {
      staffCount = staffCountQuery.count!;
      vehicleCount = vehicleCountQuery.count!;
      customerCount = customerCountQuery.count!;
      sparePartCount = sparePartCountQuery.count!;
    });
  }

  /// 🔹 Preload staff into a map
  Future<void> _loadStaff() async {
    final staffSnap =
    await FirebaseFirestore.instance.collection('staff').get();
    setState(() {
      staffMap = {
        for (var s in staffSnap.docs) s.id: s.data() as Map<String, dynamic>
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final todayStart =
    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return BasePage(
      title: "Dashboard",
      child: Column(
        children: [
          // --- Top Dashboard (grid of buttons) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dashboardItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final item = dashboardItems[index];
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
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
                      const SizedBox(height: 10),
                      Text(
                        item['label'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Total: ${item['count']()}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // --- Job Schedules for Today ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Job Schedules for Today",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalendarPage()),
                    );
                  },
                  child: const Text("View Schedule"),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('date',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
                  .where('date', isLessThan: Timestamp.fromDate(todayEnd))
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No schedules today'));
                }

                // sort schedules by role
                final sortedDocs = [...docs];
                sortedDocs.sort((a, b) {
                  final ra = staffMap[a['staffId']]?['role'] ?? '';
                  final rb = staffMap[b['staffId']]?['role'] ?? '';
                  return ra.compareTo(rb);
                });

                return ListView.builder(
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, i) {
                    final d = sortedDocs[i].data() as Map<String, dynamic>;
                    final staffId = d['staffId'] ?? '';
                    final startTime = d['shiftStart'] ?? '';
                    final endTime = d['shiftEnd'] ?? '';

                    final staffData = staffMap[staffId];
                    final name = staffData?['name'] ?? staffId;
                    final role = staffData?['role'] ?? '';
                    final color = roleColors[role] ?? Colors.grey;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withOpacity(0.2),
                          child: Icon(Icons.person, color: color),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('$role • Shift: $startTime – $endTime'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
