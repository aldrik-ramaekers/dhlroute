import 'dart:async';

class BlacklistEntry {
  String postalcodeNumeric;
  String postalcodeAplha;
  int houseNumber;
  String houseNumberExtra;

  BlacklistEntry(this.postalcodeNumeric, this.postalcodeAplha, this.houseNumber,
      this.houseNumberExtra);

  BlacklistEntry.fromJson(Map<String, dynamic> json)
      : postalcodeNumeric = json['postalcodeNumeric'],
        postalcodeAplha = json['postalcodeAplha'],
        houseNumber = json['houseNumber'],
        houseNumberExtra = json['houseNumberExtra'];

  Map<String, dynamic> toJson() {
    return {
      'postalcodeNumeric': postalcodeNumeric,
      'postalcodeAplha': postalcodeAplha,
      'houseNumber': houseNumber,
      'houseNumberExtra': houseNumberExtra,
    };
  }
}

abstract class IBlacklistProviderService {
  Future<List<BlacklistEntry>> getBlacklist();
  Future<void> addToBlacklist(BlacklistEntry data);
}
