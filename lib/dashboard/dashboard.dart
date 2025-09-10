import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../vehicle/vehicle_list.dart';
import '../workScheduler/schedule.dart';
import '../sparePart/spare_part_dashboard.dart';


class Dashboard extends StatefulWidget {
  final String userEmail; // pass the email from login
  const Dashboard({super.key, required this.userEmail});

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
    _loadStaffCount();

    // Initialize dashboard buttons
    dashboardItems.addAll([
      {
        'label': 'Vehicles',
        'icon': Icons.directions_car,
        'count': () => vehicleCount,
        'page': VehicleListPage(),
      },
      {
        'label': 'Customers',
        'icon': Icons.person,
        'count': () => customerCount,
        //'page': CustomerList(),
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
        'page': SparePartDashboard(),
      },
    ]);
  }

  Future<void> _loadStaffCount() async {
    final snap = await FirebaseFirestore.instance.collection('staff').get();
    setState(() {
      staffCount = snap.size; // total staff
    });
  }

  @override
  Widget build(BuildContext context) {

    // today day start and end
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    final Map<String, Color> roleColors = {
      'Cashier': Colors.green,
      'Mechanic': Colors.blue,
    };
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("Welcome!"),
              accountEmail: Text(widget.userEmail),
              currentAccountPicture: CircleAvatar(
                child: Text(widget.userEmail[0].toUpperCase()),
              ),
              decoration: const BoxDecoration(color: Colors.blue),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: const Text('Vehicles'),
              onTap: () {
                Navigator.pushNamed(context, '/vehicles');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await AuthService().signout(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text("HOME"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                widget.userEmail,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // --- Top Dashboard (grid of 4 buttons) ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true, // important for Column
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
                    if (item['page'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => item['page']),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'], size: 40),
                      const SizedBox(height: 10),
                      Text(
                        item['label'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      item['label'] == 'Schedules'
                          ? StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance.collection('staff').snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Text("Total Staff: ...",
                                style: TextStyle(fontSize: 14));
                          }
                          final staffCount = snapshot.data!.size;
                          return Text("Total Staff: $staffCount",
                              style: const TextStyle(fontSize: 14));
                        },
                      )
                          : Text(
                        "Total: ${item['count']()}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // --- Job Schedules for Today section ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Job Schedules for Today",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
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

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance.collection('staff').get(),
                  builder: (context, staffSnap) {
                    if (!staffSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final staffMap = {
                      for (var s in staffSnap.data!.docs) s.id: s.data() as Map<String, dynamic>
                    };

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
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}