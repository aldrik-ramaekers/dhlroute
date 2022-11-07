import 'package:training_planner/services/istoregear_api_service.dart';

class AuthenticationService {
  bool isAuthenticated = false;
  String apiKey = '';
  String storedPNumber = '639174';
  String storedDaycode = '424';

  Future<bool> authenticate(String username, String password) async {
    isAuthenticated = true;
    apiKey = 'test';
    storedPNumber = username;
    storedDaycode = password;
    return true;
  }
}
