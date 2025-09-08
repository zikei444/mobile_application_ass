import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_application_ass/providers/vehicle_provider.dart';
import 'package:mobile_application_ass/seed/august_scheduler.dart';
import 'package:mobile_application_ass/seed/staff_seed.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'login/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // required for async in main

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await seedStaff();
  // print('staff collection created');
  //
  // await seedAugustSchedule();
  // print('schedule collection created');


  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => VehicleProvider()),
    ],
    child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Login()
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'Firebase Demo',
  //     home: Scaffold(
  //       appBar: AppBar(title: const Text('Firebase Initialized')),
  //       body: const Center(child: Text('Hello Firebase')),
  //     ),
  //   );
  // }
}
