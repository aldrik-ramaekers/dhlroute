import 'dart:async';
import 'dart:io';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:training_planner/services/iroute_provider_service.dart';
import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/services/log_service.dart';
import 'package:training_planner/services/messaging_service.dart';
import 'package:training_planner/services/mock_route_provider_service.dart';
import 'package:training_planner/services/mock_shift_provider_service.dart';
import 'package:training_planner/services/local_shift_provider_service.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/style/style.dart';
import 'pages/home_page.dart';
import 'package:local_auth/local_auth.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';

void main() {
  _initializeHERESDK();
  WidgetsFlutterBinding.ensureInitialized();
  configureNotifications();
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    // tja..
  });
}

void _initializeHERESDK() async {
  // Needs to be called before accessing SDKOptions to load necessary libraries.
  SdkContext.init(IsolateOrigin.main);

  // Set your credentials for the HERE SDK.
  String accessKeyId = "7AOr--BqzFzBELeBUXypqQ";
  String accessKeySecret =
      "27yrhnsn-in-FVLWie-DKmS44XWsyIVIhgkhbdZB5glP9vyY3dIuZDBq23LvH-UwslyRCHt7vkgJtwADxxq-AQ";
  SDKOptions sdkOptions =
      SDKOptions.withAccessKeySecret(accessKeyId, accessKeySecret);

  try {
    await SDKNativeEngine.makeSharedInstance(sdkOptions);
  } on InstantiationException {
    throw Exception("Failed to initialize the HERE SDK.");
  }
}

final IRouteProviderService routeProvider = MockRouteProviderService();
final IProgramProviderService shiftProvider = LocalShiftProviderService();
final LocalAuthentication auth = LocalAuthentication();
final MessagingService messageService = MessagingService();
final SettingsService settingsService = SettingsService();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

EventBus eventBus = EventBus();

void configureNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('dhl');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String? payload) async {
    if (payload != null) {
      LogService.log('notification payload: $payload');
    }
  });
}

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
