class LoginResponse {
  String? apiKey;
  String? username;
  String? depotNumber;
  String? dayCode;
  String? envType;
  String? vdrJwtToken;

  LoginResponse(
      {this.apiKey,
      this.username,
      this.depotNumber,
      this.dayCode,
      this.envType,
      this.vdrJwtToken});

  LoginResponse.fromJson(Map<String, dynamic> json) {
    apiKey = json['api_key'];
    username = json['username'];
    depotNumber = json['depot_number'];
    dayCode = json['day_code'];
    envType = json['env_type'];
    vdrJwtToken = json['vdr_jwt_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['api_key'] = this.apiKey;
    data['username'] = this.username;
    data['depot_number'] = this.depotNumber;
    data['day_code'] = this.dayCode;
    data['env_type'] = this.envType;
    data['vdr_jwt_token'] = this.vdrJwtToken;
    return data;
  }
}
