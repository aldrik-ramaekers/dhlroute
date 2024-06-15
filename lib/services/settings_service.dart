import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:training_planner/services/log_service.dart';

class Settings {
  double salary;
  String version;

  Settings({required this.salary, required this.version});

  Settings.fromJson(Map<String, dynamic> json)
      : salary = double.parse(json['salary']), version = json['version'];

  Map<String, dynamic> toJson() {
    return {
      'salary': salary.toStringAsFixed(2),
      'version': version,
    };
  }
}

class DefaultSettings extends Settings {
  DefaultSettings() : super(salary: 14.5, version: '1.13.7-prod');

  DefaultSettings.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'salary': salary.toStringAsFixed(2),
      'version': version,
    };
  }
}

class SettingsService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    File file = File('$path/settings.json');

    bool exists = await file.exists();
    if (!exists) {
      LogService.log('created settings.json');
      await file.create();
      await file.writeAsString(jsonEncode(DefaultSettings()));
    }

    return File('$path/settings.json');
  }

  Future<void> writeSettingsToFile(Settings settings) async {
    try {
      final file = await _localFile;
      String content = jsonEncode(settings);
      LogService.log('writing to file: ' + content);
      await file.writeAsString(content);
    } catch (e, stacktrace) {
      LogService.log(stacktrace);
      LogService.log(e);
    }
  }

  Future<Settings> readSettingsFromFile() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      LogService.log('read from file: ' + contents);
      var raw = await jsonDecode(contents);
      var settings = Settings.fromJson(raw);
      return settings;
    } catch (e, stacktrace) {
      LogService.log(stacktrace);
      LogService.log(e);
      writeSettingsToFile(DefaultSettings());
      return DefaultSettings();
    }
  }
}
