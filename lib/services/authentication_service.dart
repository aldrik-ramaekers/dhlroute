class AuthenticationService {
  bool isAuthenticated = false;
  String apiKey = '';
  String storedPNumber = '';
  String storedDaycode = '';

  Future<bool> authenticate(String username, String password) async {
    isAuthenticated = true;
    apiKey = 'test';
    storedPNumber = username;
    storedDaycode = password;
    return true;
  }
}
