import 'dart:convert';
import 'dart:io';

import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/shift.dart';
import 'package:uuid/uuid.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:path_provider/path_provider.dart';

class LocalShiftProviderService extends IProgramProviderService {
  LocalShiftProviderService() {}

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    File file = File('$path/shifts.json');

    bool exists = await file.exists();
    if (!exists) {
      print('created shifts.json');
      await file.create();
      await writeShiftsFromFile([]);
    }

    return File('$path/shifts.json');
  }

  Future<void> writeShiftsFromFile(List<Shift> shifts) async {
    try {
      final file = await _localFile;
      String content = jsonEncode(shifts);
      await file.writeAsString(content);
      print('Writing to file: ' + content);
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
    }
  }

  Future<List<Shift>> readShiftsFromFile() async {
    try {
      final file = await _localFile;
      final contents = await file.readAsString();
      final Iterable iterable = await jsonDecode(contents);
      List<Shift> data =
          List<Shift>.from(iterable.map((model) => Shift.fromJson(model)));
      print('Read from file: ' + contents);

      return data;
    } catch (e, stacktrace) {
      print(stacktrace);
      print(e);
      return [];
    }
  }

  @override
  Future<void> updateShift(Shift shift) async {
    List<Shift> savedShifts = await readShiftsFromFile();
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        item.isActive = shift.isActive;
        item.start = shift.start;
        item.end = shift.end;
        item.type = shift.type;
        break;
      }
    }
    await writeShiftsFromFile(savedShifts);
  }

  @override
  Future<bool> addShift(Shift shift) async {
    List<Shift> savedShifts = await readShiftsFromFile();
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        return false;
      }
    }

    savedShifts.add(shift);
    await writeShiftsFromFile(savedShifts);
    return true;
  }

  @override
  Future<List<Shift>> getPastShifts() async {
    List<Shift> shifts = await readShiftsFromFile();
    shifts.sort((a, b) => a.start.compareTo(b.start));

    return shifts;
  }

  @override
  Future<List<Shift>> getShiftsForWeek(DateTime firstDayOfWeek) async {
    var items = await getPastShifts();
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
    List<Shift> savedShifts = await readShiftsFromFile();
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        savedShifts.remove(item);
        break;
      }
    }
    await writeShiftsFromFile(savedShifts);
  }
}
