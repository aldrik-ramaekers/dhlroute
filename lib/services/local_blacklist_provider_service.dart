import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:training_planner/pages/logbook_page.dart';
import 'package:training_planner/services/iblacklist_provider_service.dart';
import 'package:training_planner/services/log_service.dart';

class LocalBlacklistProviderService extends IBlacklistProviderService {
  Future<Directory> get _localDir async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _localFile() async {
    final path = await _localPath;
    String fullPath = '$path/blacklist.json';
    File file = File(fullPath);

    bool exists = await file.exists();
    if (!exists) {
      LogService.log('creating ' + fullPath);
      await file.create();
      await file.writeAsString(jsonEncode([]));
    }

    return File(fullPath);
  }

  @override
  Future<List<BlacklistEntry>> getBlacklist() async {
    var file = await _localFile();
    var data = await file.readAsString();
    final Iterable iterable = await jsonDecode(data);
    List<BlacklistEntry> parsedData = List<BlacklistEntry>.from(
        iterable.map((model) => BlacklistEntry.fromJson(model)));
    LogService.log('read ' + data);
    return parsedData;
  }

  @override
  Future<void> addToBlacklist(BlacklistEntry data) async {
    var file = await _localFile();

    List<BlacklistEntry> dataToStore = await getBlacklist();
    dataToStore.add(BlacklistEntry(data.postalcodeNumeric, data.postalcodeAplha,
        data.houseNumber, data.houseNumberExtra));

    LogService.log('writing ' + jsonEncode(dataToStore));
    file.writeAsString(jsonEncode(dataToStore));
  }
}
