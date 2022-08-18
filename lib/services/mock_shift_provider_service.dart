import 'package:training_planner/services/ishift_provider_service.dart';
import 'package:training_planner/shift.dart';
import 'package:uuid/uuid.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;

class MockShiftProviderService extends IProgramProviderService {
  List<Shift> savedShifts = [];

  MockShiftProviderService() {
    List<Shift> shifts = [];

    shifts.add(
      Shift(
          end: DateTime(2022, 8, 8, 20, 30),
          start: DateTime(2022, 8, 8, 16, 30),
          type: ShiftType.Avondrit,
          payRate: 13.75),
    );

    shifts.add(Shift(
        end: DateTime(2022, 8, 6, 20, 30),
        start: DateTime(2022, 8, 6, 16, 30),
        type: ShiftType.Avondrit,
        payRate: 13.75));

    shifts.add(Shift(
        end: DateTime(2022, 8, 5, 20, 30),
        start: DateTime(2022, 8, 5, 16, 30),
        type: ShiftType.Avondrit,
        payRate: 13.75));

    shifts.add(Shift(
        start: DateTime(2022, 8, 4, 16, 30),
        type: ShiftType.Avondrit,
        payRate: 13.75));

    shifts.add(Shift(
        end: DateTime(2022, 8, 1, 17, 30),
        start: DateTime(2022, 8, 1, 9, 30),
        type: ShiftType.Dagrit,
        payRate: 13.75));

    shifts.add(Shift(
        start: DateTime(2022, 8, 22, 9, 30),
        type: ShiftType.Dagrit,
        payRate: 13.75));

    shifts.add(Shift(
        start: DateTime.now().subtract(Duration(hours: 2)),
        type: ShiftType.Dagrit,
        payRate: 13.75));

    savedShifts = shifts;
  }

  @override
  Future<void> updateShift(Shift shift) async {
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        item.isActive = shift.isActive;
        item.start = item.start;
        item.end = item.end;
        item.type = item.type;
        break;
      }
    }
  }

  @override
  Future<bool> addShift(Shift shift) async {
    for (var item in savedShifts) {
      if (DateUtilities.DateUtils.isSameDay(shift.start, item.start)) {
        return false;
      }
    }
    savedShifts.add(shift);
    return true;
  }

  @override
  Future<List<Shift>> getPastShifts() async {
    List<Shift> shifts = savedShifts;
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
    savedShifts.remove(shift);
  }
}
