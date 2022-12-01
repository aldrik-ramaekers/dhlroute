import 'package:training_planner/config/defaults.dart';

class LogService {
  static void log(dynamic data) {
    if (debug_mode) {
      print(data);
    }
  }
}
