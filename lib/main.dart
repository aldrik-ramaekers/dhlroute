import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/services/messaging_service.dart';
import 'package:training_planner/services/mock_shift_provider_service.dart';
import 'package:training_planner/services/local_shift_provider_service.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/style/style.dart';
import 'pages/home_page.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // tja..
  });
}

final IProgramProviderService shiftProvider = LocalShiftProviderService();
final LocalAuthentication auth = LocalAuthentication();
final MessagingService messageService = MessagingService();
final SettingsService settingsService = SettingsService();

EventBus eventBus = EventBus();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DHL HourTracker',
      theme: ThemeData(
        backgroundColor: Style.background,
      ),
      home: HomePage(
        agendaWeekNr: 0,
      ),
      builder: (context, widget) {
        Widget error = const Text('...rendering error...');
        if (widget is Scaffold || widget is Navigator) {
          error = Scaffold(body: Center(child: error));
        }
        ErrorWidget.builder = (errorDetails) => error;
        if (widget != null) return widget;
        throw ('widget is null');
      },
    );
  }
}
