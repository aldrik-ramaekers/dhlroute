import 'dart:io';

import 'package:flutter/material.dart';
import 'package:training_planner/events/RefreshWeekEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/services/local_shift_provider_service.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/style/style.dart';

class DeveloperPage extends StatefulWidget {
  @override
  _DeveloperPageState createState() => _DeveloperPageState();

  const DeveloperPage({Key? key}) : super(key: key);
}

class _DeveloperPageState extends State<DeveloperPage> {
  @override
  initState() {
    super.initState();
  }

  void clearLocalFiles() async {
    if (shiftProvider is LocalShiftProviderService) {
      LocalShiftProviderService lsp =
          shiftProvider as LocalShiftProviderService;
      var fileList = await lsp.getStoredFileList();

      for (var item in fileList) {
        await File(item).delete();
      }

      eventBus.fire(RefreshWeekEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instellingen'),
        backgroundColor: Style.background,
        foregroundColor: Style.titleColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              TextButton(
                  onPressed: () async => clearLocalFiles(),
                  child: Text('Bestanden verwijderen')),
            ],
          ),
        ),
      ),
    );
  }
}
