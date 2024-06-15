import 'dart:async';
import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:training_planner/services/backup_helper_service.dart';
import 'package:training_planner/services/iblacklist_provider_service.dart';
import 'package:training_planner/services/iroute_provider_service.dart';
import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/services/istoregear_api_service.dart';
import 'package:training_planner/services/local_blacklist_provider_service.dart';
import 'package:training_planner/services/local_salary_provider_service.dart';
import 'package:training_planner/services/log_service.dart';
import 'package:training_planner/services/messaging_service.dart';
import 'package:training_planner/services/mock_route_provider_service.dart';
import 'package:training_planner/services/mock_shift_provider_service.dart';
import 'package:training_planner/services/local_shift_provider_service.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/services/storegear_api_service.dart';
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
  SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown])
      .then((value) {
    configureNotifications();
    runApp(const MyApp());
  });
}

void _initializeHERESDK() async {
  // Needs to be called before accessing SDKOptions to load necessary libraries.
  SdkContext.init(IsolateOrigin.main);
}

final IRouteProviderService routeProvider = MockRouteProviderService();
final IProgramProviderService shiftProvider = LocalShiftProviderService();
final LocalAuthentication localAuthService = LocalAuthentication();
final MessagingService messageService = MessagingService();
final SettingsService settingsService = SettingsService();
final IStoregearApiService apiService = StoregearApiService();
final LocalSalaryProviderService incomeProvider = LocalSalaryProviderService();
final IBlacklistProviderService blacklistProvider =
    LocalBlacklistProviderService();
final BackupHelperService backupService = BackupHelperService();

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
      title: 'Bessems HourTracker',
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
