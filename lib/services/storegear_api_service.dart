import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:training_planner/config/defaults.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/models/login_request.dart';
import 'package:training_planner/models/login_response.dart';
import 'package:training_planner/models/route_list.dart';
import 'package:training_planner/route.dart';
import 'package:training_planner/services/backup_helper_service.dart';
import 'package:training_planner/services/istoregear_api_service.dart';
import 'package:training_planner/route.dart' as DHLRoute;
import 'package:training_planner/services/mock_route_provider_service.dart';
import 'package:uuid/uuid.dart';

class StoregearApiService extends IStoregearApiService {
  String apiKey = '';

  @override
  Future<LoginResponse> login(LoginRequest req) async {
    if (debug_mode) {
      return LoginResponse();
    }

    final response = await http.post(
        Uri.parse('https://storegear-app.dhlparcel.nl/delivery/v1/users/login?env_type=PROD'),
        headers: {'X-REQ-UUID': Uuid().v1()},
        body: jsonEncode(req));

    try {
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        
        LoginResponse res = LoginResponse.fromJson(jsonDecode(response.body));
        apiKey = res.apiKey!;
        return res;
      } else {
        throw Exception('Failed login');
      }
    }
    catch (ex) {
      backupService.writeStringToFile(response.body, 'failed_login.txt');
      throw Exception('Failed to load route');
    }
  }

  _getMockRouteList() {
    return RouteList.fromJson(jsonDecode('''
{ "routes": [ { "timeframe_key": "15994", "trip_key": "20315994", "trip_number": "10", "trip_pda_status": "5", "trip_pda_status_description": "Rit overgedragen", "trip_sequence_number": "1", "number_in_trip": "135", "plate": "VTG-69-R", "damage_registration": true, "eva": "10:43", "trip_date": "19/4/2023", "first_address_lat": "50.8919767278786", "first_address_lng": "5.74122752631296", "started": "true", "all_tasks_finished": "false", "start_km": "5273", "end_km": null, "tasks_enriched": "true", "in_trip_scan_finished": null, "eva_added": null, "trip_start_request_sent": "true" } ] }
'''));
  }

  @override
  Future<RouteList> getRoutes() async {
    if (debug_mode) {
      return _getMockRouteList();
    }

    final response = await http.get(
        Uri.parse('https://storegear-app.dhlparcel.nl/delivery/v1/routes'),
        headers: {'X-API-KEY': apiKey, 'X-REQ-UUID': Uuid().v1()});

    try {
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.

        var content = jsonDecode(response.body);
        if (content["message"] != null) {
          return RouteList(routes: []);
        }
        return RouteList.fromJson(content);
      } else {
        throw Exception('Failed to load routes');
      }
    }
    catch (ex) {
      backupService.writeStringToFile(response.body, 'failed_routelist.txt');
      throw Exception('Failed to load route');
    }
  }

  @override
  Future<DHLRoute.Route?> getRoute(String tripkey) async {
    if (debug_mode) {
      return MockRouteProviderService().getRoute(int.parse(tripkey));
    }

    final response = await http.get(
        Uri.parse(
            'https://storegear-app.dhlparcel.nl/delivery/v1/routes/' + tripkey.toString()),
        headers: {'X-API-KEY': apiKey, 'X-REQ-UUID': Uuid().v1()});

    try {
      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.

        var content = jsonDecode(response.body);
        if (content["message"] != null) {
          return null;
        }
        return RouteInfo.fromJson(content).route;
      } else {
        throw Exception('Failed to load route');
      }
    }
    catch (ex) {
      backupService.writeStringToFile(response.body, 'failed_route.txt');
      throw Exception('Failed to load route');
    }
  }
}
