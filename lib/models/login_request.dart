class LoginRequest {
  String? username;
  String? password;
  String? pdaSoftwareVersion;
  String? deviceImei;
  String? deviceName;
  String? deviceIdentifier;

  LoginRequest(
      {this.username,
      this.password,
      this.pdaSoftwareVersion,
      this.deviceImei,
      this.deviceName,
      this.deviceIdentifier});

  LoginRequest.fromJson(Map<String, dynamic> json) {
    username = json['username'];
    password = json['password'];
    pdaSoftwareVersion = json['pda_software_version'];
    deviceImei = json['device_imei'];
    deviceName = json['device_name'];
    deviceIdentifier = json['device_identifier'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['username'] = this.username;
    data['password'] = this.password;
    data['pda_software_version'] = this.pdaSoftwareVersion;
    data['device_imei'] = this.deviceImei;
    data['device_name'] = this.deviceName;
    data['device_identifier'] = this.deviceIdentifier;
    return data;
  }
}
