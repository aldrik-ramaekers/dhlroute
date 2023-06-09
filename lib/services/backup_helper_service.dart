import 'dart:io';

import 'package:path_provider/path_provider.dart';

class BackupHelperService {
  Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = Directory('/storage/emulated/0/Download/');
        if (!await directory.exists())
          directory = await getExternalStorageDirectory();
      }
    } catch (err, stack) {
      print("Cannot get download folder path");
    }
    return directory?.path;
  }

  Future<void> writeStringToFile(String content, String filename) async {
    String? fullpath = await getDownloadPath();
    if (fullpath != null) {
      fullpath += filename;
      File file = File(fullpath);
      file.writeAsString(content);
    }
  }
}
