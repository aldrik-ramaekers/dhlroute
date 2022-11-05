class AuthenticationService {
  bool isAuthenticated = false;
  String apiKey = '';

  Future<bool> authenticate(String username, String password) async {
    isAuthenticated = true;
    apiKey = 'test';
    return true;
  }
}
