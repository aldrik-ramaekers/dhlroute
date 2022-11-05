import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:training_planner/config/defaults.dart';
import 'package:training_planner/config/old_data.dart';
import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/services/log_service.dart';
import 'package:training_planner/shift.dart';
import 'package:uuid/uuid.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:path_provider/path_provider.dart';

class LocalShiftProviderService extends IProgramProviderService {
  Future<void> loadOldData() async {
    int count = old_data_dates.length;

    for (int i = 0; i < count; i++) {
      var dateTmp = DateFormat('dd/MM/yyyy').parse(old_data_dates[i]);
      var outputFormat = DateFormat('yyyy-MM-dd');

      String date = outputFormat.format(dateTmp);
      String start = old_start_times[i].trim();
      String end = old_end_times[i].trim();

      ShiftType type = DefaultConfig.shiftTypes[0];

      DateTime startDate = DateTime.parse(date + ' ' + start);
      DateTime endDate = DateTime.parse(date + ' ' + end);

      if (startDate.hour > 15) type = DefaultConfig.shiftTypes[1];
      if (startDate.hour > 12 && startDate.hour < 15)
        type = DefaultConfig.shiftTypes[2];

      LogService.log(startDate.toString() + ' -> ' + endDate.toString());
      await addShift(Shift(
          start: startDate, type: type.name, end: endDate, payRate: 13.75));
    }
  }

  LocalShiftProviderService() {
    getPastShifts()
        .then((value) async => {if (value.isEmpty) await loadOldData()});
  }

  Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<List<String>> getStoredFileList() async {
    List<String> result = [];
    Directory dir = await _localDir;
    var list = dir.listSync();
    for (var item in list) {
      if (!item.path.endsWith('.json') || !item.path.contains('shifts')) {
        continue;
      }

      result.add(item.path);
    }

    return result;
  }

  Future<File> _localFile(String postfix) async {
    final path = await _localPath;
    String fullPath = '$path/shifts_' + postfix + '.json';
    File file = File(fullPath);

    bool exists = await file.exists();
    if (!exists) {
      LogService.log('creating ' + fullPath);
      await file.create();
      await file.writeAsString(jsonEncode([]));
    }

    return File(fullPath);
  }

  Future<void> writeShiftsToFile(List<Shift> shifts) async {
    try {
      if (shifts.isNotEmpty) {
        final file = await _localFile(
            DateUtilities.DateUtils.firstDayOfWeek(shifts.first.start)
                .toString());
        LogService.log(
            DateUtilities.DateUtils.firstDayOfWeek(shifts.first.start)
                .toString());
        String content = jsonEncode(shifts);
        LogService.log('writing content to ' + file.path + ' -- ' + content);
        await file.writeAsString(content);
      }
    } catch (e, stacktrace) {
      LogService.log(stacktrace);
      LogService.log(e);
    }
  }

  Future<List<Shift>> readShiftsFromFile(DateTime startOfWeek) async {
    try {
      final file = await _localFile(startOfWeek.toString());
      final contents = await file.readAsString();
      final Iterable iterable = await jsonDecode(contents);
      List<Shift> data =
          List<Shift>.from(iterable.map((model) => Shift.fromJson(model)));

      return data;
    } catch (e, stacktrace) {
      LogService.log(stacktrace);
      LogService.log(e);
      return [];
    }
  }

  @override
  Future<void> updateShift(Shift shift) async {
    List<Shift> savedShifts = await readShiftsFromFile(
        DateUtilities.DateUtils.firstDayOfWeek(shift.start));
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        item.isActive = shift.isActive;
        item.start = shift.start;
        item.end = shift.end;
        item.type = shift.type;
        break;
      }
    }
    await writeShiftsToFile(savedShifts);
  }

  @override
  Future<bool> addShift(Shift shift) async {
    List<Shift> savedShifts = await readShiftsFromFile(
        DateUtilities.DateUtils.firstDayOfWeek(shift.start));
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        return false;
      }
    }

    savedShifts.add(shift);
    await writeShiftsToFile(savedShifts);
    return true;
  }

  @override
  Future<List<Shift>> getPastShifts() async {
    List<Shift> shifts = [];
    var list = await getStoredFileList();
    for (var item in list) {
      final file = File(item);
      final contents = await file.readAsString();
      final Iterable iterable = await jsonDecode(contents);
      List<Shift> data =
          List<Shift>.from(iterable.map((model) => Shift.fromJson(model)));
      shifts.addAll(data);
    }

    shifts.sort((a, b) => a.start.compareTo(b.start));

    return shifts;
  }

  @override
  Future<List<Shift>> getShiftsForWeek(DateTime firstDayOfWeek) async {
    var items = await readShiftsFromFile(
        DateUtilities.DateUtils.firstDayOfWeek(firstDayOfWeek));
    List<Shift> result = [];

    for (var item in items) {
      if (DateUtilities.DateUtils.firstDayOfWeek(item.start) ==
          firstDayOfWeek) {
        result.add(item);
      }
    }

    result.sort((a, b) => a.start.compareTo(b.start));

    return result;
  }

  @override
  Future<void> deleteShift(Shift shift) async {
    DateTime firstDayOfWeek =
        DateUtilities.DateUtils.firstDayOfWeek(shift.start);

    List<Shift> savedShifts = await readShiftsFromFile(firstDayOfWeek);
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        savedShifts.remove(item);
        break;
      }
    }

    if (savedShifts.isEmpty) {
      final file = await _localFile(firstDayOfWeek.toString());
      await file.delete();
    }

    await writeShiftsToFile(savedShifts);
  }
}
