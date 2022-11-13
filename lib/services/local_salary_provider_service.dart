import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:training_planner/pages/logbook_page.dart';
import 'package:training_planner/services/log_service.dart';

class IncomeData {
  final DateTime firstDayOfMonth;
  final double income;

  IncomeData(this.firstDayOfMonth, this.income);

  IncomeData.fromJson(Map<String, dynamic> json)
      : firstDayOfMonth = DateTime.parse(json['firstDayOfMonth']),
        income = double.parse(json['income']);

  Map<String, dynamic> toJson() {
    return {
      'firstDayOfMonth': firstDayOfMonth.toIso8601String(),
      'income': income.toStringAsFixed(2),
    };
  }
}

class LocalSalaryProviderService {
  Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile() async {
    final path = await _localPath;
    String fullPath = '$path/income.json';
    File file = File(fullPath);

    bool exists = await file.exists();
    if (!exists) {
      LogService.log('creating ' + fullPath);
      await file.create();
      await file.writeAsString(jsonEncode([]));
    }

    return File(fullPath);
  }

  Future<List<IncomeData>> getSavedIncome() async {
    var file = await _localFile();
    var data = await file.readAsString();
    final Iterable iterable = await jsonDecode(data);
    List<IncomeData> parsedData = List<IncomeData>.from(
        iterable.map((model) => IncomeData.fromJson(model)));
    LogService.log('read ' + data);
    return parsedData;
  }

  Future<void> writeSavedIncome(List<MonthData> data) async {
    var file = await _localFile();

    List<IncomeData> dataToStore = [];
    for (var item in data) {
      dataToStore.add(IncomeData(item.firstDayOfMonth, item.actualSalary));
    }
    LogService.log('writing ' + jsonEncode(dataToStore));
    file.writeAsString(jsonEncode(dataToStore));
  }
}
