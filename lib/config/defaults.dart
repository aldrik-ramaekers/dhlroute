class ShiftType {
  String name;
  Duration startTime;
  Duration startTimeSturday;
  ShiftType(
      {required this.name,
      required this.startTime,
      required this.startTimeSturday});
}

class DefaultConfig {
  static List<ShiftType> shiftTypes = [
    ShiftType(
        name: 'Dagrit',
        startTime: Duration(hours: 10),
        startTimeSturday: Duration(hours: 10)),
    ShiftType(
        name: 'Avondrit',
        startTime: Duration(hours: 17),
        startTimeSturday: Duration(hours: 15, minutes: 30)),
    ShiftType(
        name: 'Terugscan',
        startTime: Duration(hours: 14, minutes: 30),
        startTimeSturday: Duration(hours: 13, minutes: 30)),
  ];
}
