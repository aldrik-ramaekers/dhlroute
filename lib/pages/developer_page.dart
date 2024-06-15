import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:training_planner/config/defaults.dart';
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
  bool canUseLocalAuth = false;

  @override
  initState() {
    super.initState();

    countLocalFiles().then((value) => {
          setState(() {
            file_count = value;
          })
        });

    localAuthService.canCheckBiometrics.then((bio) => {
          localAuthService
              .isDeviceSupported()
              .then((supported) => {canUseLocalAuth = bio && supported})
        });
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

  int file_count = 0;

  Future<int> countLocalFiles() async {
    if (shiftProvider is LocalShiftProviderService) {
      LocalShiftProviderService lsp =
          shiftProvider as LocalShiftProviderService;
      var fileList = await lsp.getStoredFileList();

      return fileList.length;
    } else {
      return 0;
    }
  }

  _toggleDebugMode() {
    setState(() {
      debug_mode = !debug_mode;
    });
  }

  File _createZipFile(String fileName) {
    final zipFilePath = fileName;
    final zipFile = File(zipFilePath);

    if (zipFile.existsSync()) {
      print("Deleting existing zip file: ${zipFile.path}");
      zipFile.deleteSync();
    }
    return zipFile;
  }

  _exportLocalFiles() async {
    List<String> result = [];
    Directory dir = await getApplicationDocumentsDirectory();
    var list = dir.listSync();
    for (var item in list) {
      if (item.path.endsWith('.json')) {
        result.add(item.path);
      }
    }

    if (await Permission.storage.request().isGranted) {
      String? path = await backupService.getDownloadPath();
      if (path != null) {
        path += 'backup.zip';
        var zip = _createZipFile(path);

        int onProgressCallCount1 = 0;
        try {
          await ZipFile.createFromDirectory(
            sourceDir: await getApplicationDocumentsDirectory(),
            zipFile: zip,
            recurseSubDirs: false,
            includeBaseDirectory: false,
            onZipping: (fileName, isDirectory, progress) {
              ++onProgressCallCount1;
              print('Zip #1:');
              print('progress: ${progress.toStringAsFixed(1)}%');
              print('name: $fileName');
              print('isDirectory: $isDirectory');
              return ZipFileOperation.includeItem;
            },
          );

          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Backup created')));
        } on PlatformException catch (e) {
          print(e);
        }
      }
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
              Text('Versie ' + program_version),
              Text('Bestanden: ' + file_count.toString()),
              ElevatedButton(
                  onPressed: _exportLocalFiles, child: Text('Export'))
              /*
              TextButton(
                  onPressed: () {
                    if (canUseLocalAuth) {
                      localAuthService
                          .authenticate(
                              localizedReason:
                                  'Weet je zeker dat je alle locale bestanden wilt verwijderen?')
                          .then((value) => {
                                if (value) {clearLocalFiles()}
                              })
                          .catchError((f) => {});
                    } else {
                      clearLocalFiles();
                    }
                  },
                  child: Text('Bestanden verwijderen')),
                  */
            ],
          ),
        ),
      ),
    );
  }
}
