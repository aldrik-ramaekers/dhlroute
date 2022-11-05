String program_version = '0.4';
bool debug_output = false;

class ShiftType {
  String name;
  Duration startTime;
  Duration startTimeSaturday;
  Duration expectedDuration;
  ShiftType(
      {required this.name,
      required this.startTime,
      required this.startTimeSaturday,
      required this.expectedDuration});
}

class DefaultConfig {
  static List<ShiftType> shiftTypes = [
    ShiftType(
        name: 'Dagrit',
        startTime: Duration(hours: 10),
        startTimeSaturday: Duration(hours: 10),
        expectedDuration: Duration(hours: 6, minutes: 30)),
    ShiftType(
        name: 'Avondrit',
        startTime: Duration(hours: 17),
        startTimeSaturday: Duration(hours: 15, minutes: 30),
        expectedDuration: Duration(hours: 4)),
    ShiftType(
        name: 'Terugscan',
        startTime: Duration(hours: 14, minutes: 30),
        startTimeSaturday: Duration(hours: 13, minutes: 30),
        expectedDuration: Duration(hours: 7)),
  ];

  static ShiftType getShiftByName(String name) {
    var result = shiftTypes.where((element) => element.name == name);
    if (result.isEmpty) throw Exception('Type werkvorm bestaat niet [$name].');
    return result.first;
  }
}
