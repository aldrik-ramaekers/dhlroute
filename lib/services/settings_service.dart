import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class Settings {
  double salary;

  Settings({required this.salary});

  Settings.fromJson(Map<String, dynamic> json)
      : salary = double.parse(json['salary']);

  Map<String, dynamic> toJson() {
    return {
      'salary': salary.toStringAsFixed(2),
    };
  }
}

class DefaultSettings extends Settings {
  DefaultSettings() : super(salary: 13.75);

  DefaultSettings.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'salary': salary.toStringAsFixed(2),
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
      print('created settings.json');
      await file.create();
      await file.writeAsString(jsonEncode(DefaultSettings()));
    }

    return File('$path/settings.json');
  }

  Future<void> writeSettingsToFile(Settings settings) async {
    try {
      final file = await _localFile;
      String content = jsonEncode(settings);
      print('writing to file: ' + content);
      await file.writeAsString(content);
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
    }
  }

  Future<Settings> readSettingsFromFile() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      print('read from file: ' + contents);
      var raw = await jsonDecode(contents);
      var settings = Settings.fromJson(raw);
      return settings;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
      writeSettingsToFile(DefaultSettings());
      return DefaultSettings();
    }
  }
}
