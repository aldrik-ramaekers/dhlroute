import 'dart:convert';
import 'dart:io';

import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/shift.dart';
import 'package:uuid/uuid.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:path_provider/path_provider.dart';

class LocalShiftProviderService extends IProgramProviderService {
  LocalShiftProviderService() {}

  Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile(String postfix) async {
    final path = await _localPath;
    String fullPath = '$path/shifts_' + postfix + '.json';
    File file = File(fullPath);

    bool exists = await file.exists();
    if (!exists) {
      print('creating ' + fullPath);
      await file.create();
      await file.writeAsString(jsonEncode([]));
    }

    return File(fullPath);
  }

  Future<void> writeShiftsToFile(List<Shift> shifts) async {
    try {
      for (var shift in shifts) {
        final file = await _localFile(
            DateUtilities.DateUtils.firstDayOfWeek(shift.start).toString());
        print(DateUtilities.DateUtils.firstDayOfWeek(shift.start).toString());
        String content = jsonEncode(shifts);
        print('writing content to ' + file.path + ' -- ' + content);
        await file.writeAsString(content);
      }
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
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
      print(stacktrace);
      print(e);
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
    Directory dir = await _localDir;
    var list = dir.listSync();
    for (var item in list) {
      if (!item.path.endsWith('.json') || !item.path.contains('shifts')) {
        continue;
      }

      final file = File(item.path);
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

    return result;
  }

  @override
  Future<void> deleteShift(Shift shift) async {
    List<Shift> savedShifts = await readShiftsFromFile(
        DateUtilities.DateUtils.firstDayOfWeek(shift.start));
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        savedShifts.remove(item);
        break;
      }
    }
    await writeShiftsToFile(savedShifts);
  }
}
