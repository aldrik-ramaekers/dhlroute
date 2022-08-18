import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;

enum ShiftType {
  Dagrit,
  Avondrit,
  Terugscannen,
}

enum ShiftStatus {
  OldOpen,
  Closed,
  Open,
  Active,
  Invalid,
}

class Shift {
  DateTime start;
  DateTime? end;
  ShiftType type;
  double payRate;
  bool isActive = false;

  Shift(
      {this.end = null,
      required this.start,
      required this.type,
      required this.payRate});

  Shift.fromJson(Map<String, dynamic> json)
      : start = DateTime.parse(json['start']),
        end = json['end'] == null ? null : DateTime.tryParse(json['end']),
        type = ShiftType.values.firstWhere((e) => e.toString() == json['type']),
        isActive = json['isActive'] == 'true',
        payRate = double.parse(json['payRate']);

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end?.toIso8601String(),
      'type': type.toString(),
      'isActive': isActive.toString(),
      'payRate': payRate.toStringAsFixed(2),
    };
  }

  Widget getStatusIcon() {
    ShiftStatus status = getShiftStatus();
    switch (status) {
      case ShiftStatus.Active:
        return Padding(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
          padding:
              const EdgeInsets.only(top: 18, left: 10, right: 10, bottom: 18),
        );
      case ShiftStatus.OldOpen:
        return Icon(Icons.pending);
      case ShiftStatus.Open:
        return canStart() ? Icon(Icons.today) : Icon(Icons.cabin);
      case ShiftStatus.Closed:
        return Icon(Icons.check);
      case ShiftStatus.Invalid:
        return Icon(Icons.public_off_outlined);
    }
  }

  bool canStart() {
    if (DateUtilities.DateUtils.isSameDay(DateTime.now(), start) &&
        end == null &&
        !isActive) {
      return true;
    }
    return false;
  }

  bool getIsActive() {
    return this.isActive;
  }

  bool isDone() {
    return this.end != null;
  }

  DateTime expectedEndTime() {
    switch (type) {
      case ShiftType.Avondrit:
        return start.add(Duration(hours: 5));
      case ShiftType.Dagrit:
        return start.add(Duration(hours: 8));
      case ShiftType.Terugscannen:
        return start.add(Duration(hours: 8));
    }
  }

  Duration getElapsedSessionTime() {
    if (getIsActive()) {
      return DateTime.now().difference(start);
    }
    if (isDone()) {
      return end?.difference(start) ?? Duration();
    }

    return expectedEndTime().difference(start);
  }

  double getMinutePayRate() {
    return 0.22916666;
  }

  bool shiftIsOpenButBeforeToday() {
    return end == null &&
        start.isBefore(DateTime.now()) &&
        !DateUtilities.DateUtils.isSameDay(start, DateTime.now());
  }

  double getEarnedMoney() {
    DateTime? endToCalculate = end;
    endToCalculate ??= expectedEndTime();

    if (start.weekday == 6) {
      return endToCalculate.difference(start).inMinutes *
          getMinutePayRate() *
          1.35;
    }
    if (start.weekday == 7) {
      return endToCalculate.difference(start).inMinutes *
          getMinutePayRate() *
          2;
    }
    return endToCalculate.difference(start).inMinutes * getMinutePayRate();
  }

  double getMoneyForActiveSession() {
    if (getIsActive()) {
      Duration elapsed = DateTime.now().difference(start);

      return elapsed.inMinutes * getMinutePayRate();
    }
    return 0;
  }

  int getPercentage() {
    if (getIsActive()) {
      Duration totalMinutes = expectedEndTime().difference(start);
      Duration elapsed = DateTime.now().difference(start);
      int percentage =
          ((elapsed.inMinutes / totalMinutes.inMinutes) * 100).toInt();
      if (percentage < 0) percentage = 0;
      if (percentage > 100) percentage = 100;
      return percentage;
    }
    return 0;
  }

  void setIsActive(bool active) {
    isActive = active;
    if (active) {
      start = DateTime.now();
    } else {
      end = DateTime.now();
    }
  }

  ShiftStatus getShiftStatus() {
    if (shiftIsOpenButBeforeToday()) {
      return ShiftStatus.OldOpen;
    }
    if (getIsActive() && end == null) {
      return ShiftStatus.Active;
    }
    if (!getIsActive() && end == null) {
      return ShiftStatus.Open;
    }
    if (end != null) {
      return ShiftStatus.Closed;
    }

    return ShiftStatus.Invalid;
  }

  Color getStatusColor() {
    ShiftStatus status = getShiftStatus();
    switch (status) {
      case ShiftStatus.Active:
        return Colors.grey;
      case ShiftStatus.OldOpen:
        return Colors.orange;
      case ShiftStatus.Open:
        return Colors.red;
      case ShiftStatus.Closed:
        return Colors.green;
      case ShiftStatus.Invalid:
        return Colors.pink;
    }
  }
}
