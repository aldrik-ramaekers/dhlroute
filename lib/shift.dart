import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;

enum ShiftType {
  Dagrit,
  Avondrit,
  Terugscannen,
}

class Shift {
  DateTime start;
  DateTime? end;
  ShiftType type;
  bool isActive = false;

  Shift({this.end = null, required this.start, required this.type});

  Widget getStatusIcon() {
    if (end == null &&
        start.isBefore(DateTime.now()) &&
        !DateUtilities.DateUtils.isSameDay(start, DateTime.now())) {
      return Icon(Icons.pending);
    }
    if (getIsActive() && end == null) {
      return Padding(
        child: CircularProgressIndicator(
          strokeWidth: 1,
          color: Colors.white,
        ),
        padding:
            const EdgeInsets.only(top: 18, left: 10, right: 10, bottom: 18),
      );
    }
    if (canStart()) {
      return Icon(Icons.today);
    }
    if (!getIsActive() && end == null) {
      return Icon(Icons.cabin);
    }
    if (end != null) {
      return Icon(Icons.check);
    }

    return Icon(Icons.question_answer);
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
      int percentage = (elapsed.inMinutes ~/ totalMinutes.inMinutes);
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

  Color getStatusColor() {
    if (end == null &&
        start.isBefore(DateTime.now()) &&
        !DateUtilities.DateUtils.isSameDay(start, DateTime.now())) {
      return Colors.orange;
    }
    if (getIsActive() && end == null) {
      return Colors.grey;
    }
    if (!getIsActive() && end == null) {
      return Colors.red;
    }
    if (end != null) {
      return Colors.green;
    }

    return Colors.pink;
  }
}
