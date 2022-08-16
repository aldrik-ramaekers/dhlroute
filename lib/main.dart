import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/services/mock_program_provider_service.dart';
import 'package:training_planner/services/program_provider_service.dart';
import 'pages/home_page.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MyApp());
}

IProgramProviderService shiftProvider = ShiftProviderService();
final LocalAuthentication auth = LocalAuthentication();

EventBus eventBus = EventBus();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DHL HourTracker',
      theme: ThemeData(
        backgroundColor: Color.fromARGB(255, 255, 204, 0),
      ),
      home: HomePage(
        agendaWeekNr: 0,
      ),
    );
  }
}
