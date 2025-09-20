import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../invoice/invoiceList.dart';
import '../services/auth_service.dart';
import '../vehicle/vehicle_list.dart';
import '../workScheduler/schedule.dart';
import '../sparePart/spare_part_dashboard.dart';
import '../customer/customerList.dart';


class Dashboard extends StatefulWidget {
  final String userEmail; // pass the email from login
  const Dashboard({super.key, required this.userEmail});

  @override
  State<Dashboard> createState() => _DashboardState();
}


class _DashboardState extends State<Dashboard> {
  int vehicleCount = 0;   // later fetch from database
  int customerCount = 0;  // later fetch from database
  int staffCount = 0;     // later fetch from database
  int sparePartCount = 0; // later fetch from database
  String selectedFilter = 'All';
  int completedCount = 0;
  int pendingCount = 0;
  // --- Map role -> color (for schedule cards) ---
  final Map<String, Color> roleColors = {
    'Cashier': Colors.green,
    'Mechanic': Colors.blue,
  };
  // --- Dashboard modules definition ---
  final List<Map<String, dynamic>> dashboardItems = [];

  // 🔹 Fetch counts once when page loads
  Future<void> _loadCounts() async {
    final vehicleSnap =
    await FirebaseFirestore.instance.collection('vehicles').get();
    final customerSnap =
    await FirebaseFirestore.instance.collection('customers').get();
    final staffSnap =
    await FirebaseFirestore.instance.collection('staff').get();
    final spareSnap =
    await FirebaseFirestore.instance.collection('spare_parts').get();

    setState(() {
      vehicleCount = vehicleSnap.size;
      customerCount = customerSnap.size;
      staffCount = staffSnap.size;
      sparePartCount = spareSnap.size;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCounts(); // load counts from Firestore
  }

  @override
  Widget build(BuildContext context) {
    // today day start and end for schedule filtering
    final todayStart = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return Scaffold(
      // --- Drawer Menu ---
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
              decoration: const BoxDecoration(  color: Colors.white),
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
              leading: const Icon(Icons.receipt_long),
              title: const Text('Invoices'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InvoiceManagementPage()),
                );
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
      // FIX: body must be ONE widget → wrap in Column
            // --- Top Dashboard (grid of 4 buttons) ---

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Dashboard (grid of 4 buttons) ---
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildDashboardCard(Icons.directions_car, "Vehicles", "$vehicleCount", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => VehicleListPage()));
                  }),
                  _buildDashboardCard(Icons.people, "Customers", "$customerCount", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CustomerList()));
                  }),
                  _buildDashboardCard(Icons.schedule, "Schedules", "Total Staff: $staffCount", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CalendarPage()));
                  }),
                  _buildDashboardCard(Icons.build, "Spare Parts", "$sparePartCount", () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SparePartDashboard()));
                  }),
                  ],

              ),
            ),

            // --- Job Schedules for Today Section ---


// --- Upcoming Job Schedules ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Upcoming Job Schedules",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CalendarPage()),
                      );
                    },
                    child: const Text("View All"),
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('schedules')
                  .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
                  .orderBy('date', descending: false)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('No upcoming schedules'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final d = docs[i].data() as Map<String, dynamic>;
                    final staffId = d['staffId'] ?? '';
                    final date = (d['date'] as Timestamp).toDate();
                    final startTime = d['shiftStart'] ?? '';
                    final endTime = d['shiftEnd'] ?? '';
                    final status = d['status'] ?? 'Pending';

                    // 🔹 Lookup staff details
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('staff')
                          .doc(staffId)
                          .get(),
                      builder: (context, staffSnap) {
                        if (!staffSnap.hasData) {
                          return const ListTile(title: Text("Loading staff..."));
                        }
                        final staffData = staffSnap.data!.data() as Map<String, dynamic>?;
                        final staffName = staffData?['name'] ?? staffId;
                        final staffRole = staffData?['role'] ?? 'Unknown';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            leading: Icon(
                              Icons.event,
                              color: status == 'Completed' ? Colors.green : Colors.orange,
                            ),
                            title: Text("Job on ${date.toLocal().toString().split(' ')[0]}"),
                            subtitle: Text(
                              "Staff: $staffName\n"
                                  "Role: $staffRole\n"
                                  "Shift: $startTime – $endTime",
                            ),
                            trailing: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Completed' ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )

        // ),
           ],
        ),
      ),
   );

  }
  // Helper widget to build cards
  Widget _buildDashboardCard(IconData icon, String title, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color: const Color(0xFFD1E3E2),
        elevation: 4,
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.black87),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,  color: Colors.black87 )),// text color
              const SizedBox(height: 8),
              Text('$count', style: const TextStyle(fontSize: 24,  color: Colors.black87)), // text color
            ],
          ),
        ),
      ),
    );
  }
}
