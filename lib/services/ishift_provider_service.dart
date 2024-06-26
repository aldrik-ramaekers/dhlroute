import 'dart:async';

import 'package:training_planner/shift.dart';

abstract class IProgramProviderService {
  Future<List<Shift>> getPastShifts();
  Future<List<Shift>> getShiftsForWeek(DateTime firstDayOfWeek);
  Future<void> updateShift(Shift shift);
  Future<bool> addShift(Shift shift);
  Future<void> deleteShift(Shift shift);
}
