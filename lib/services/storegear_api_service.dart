import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:training_planner/config/defaults.dart';
import 'package:training_planner/models/login_request.dart';
import 'package:training_planner/models/login_response.dart';
import 'package:training_planner/models/route_list.dart';
import 'package:training_planner/route.dart';
import 'package:training_planner/services/istoregear_api_service.dart';
import 'package:training_planner/route.dart' as DHLRoute;
import 'package:training_planner/services/mock_route_provider_service.dart';

class StoregearApiService extends IStoregearApiService {
  String apiKey = '';

  @override
  Future<LoginResponse> login(LoginRequest req) async {
    if (debug_mode) {
      return LoginResponse();
    }

    final response = await http.post(
        Uri.parse('http://dhlapis.com/delivery/v1/users/login?env_type=PROD'),
        body: jsonEncode(req));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      LoginResponse res = LoginResponse.fromJson(jsonDecode(response.body));
      apiKey = res.apiKey!;
      return res;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed login');
    }
  }

  _getMockRouteList() {
    return RouteList.fromJson(jsonDecode('''
{ "routes": [ { "timeframe_key": "62395", "trip_key": "19762395", "trip_number": "1", "trip_pda_status": "5", "trip_pda_status_description": "Rit overgedragen", "trip_sequence_number": "1", "number_in_trip": "2", "plate": "VTG-69-R", "damage_registration": true, "eva": "09:04", "trip_date": "6/2/2023", "first_address_lat": "50.9182446706206", "first_address_lng": "5.79150644329668", "started": "true", "all_tasks_finished": "true", "start_km": "458", "end_km": "511", "tasks_enriched": "true", "in_trip_scan_finished": "true", "eva_added": "true", "trip_start_request_sent": "true" }, { "timeframe_key": "62410", "trip_key": "19762410", "trip_number": "10", "trip_pda_status": "5", "trip_pda_status_description": "Rit overgedragen", "trip_sequence_number": "1", "number_in_trip": "120", "plate": "VTG-69-R", "damage_registration": true, "eva": "11:04", "trip_date": "6/2/2023", "first_address_lat": "50.8987460739383", "first_address_lng": "5.73347116865626", "started": "true", "all_tasks_finished": "false", "start_km": "511", "end_km": null, "tasks_enriched": "true", "in_trip_scan_finished": "true", "eva_added": "true", "trip_start_request_sent": "true" } ] }
'''));
  }

  @override
  Future<RouteList> getRoutes() async {
    if (debug_mode) {
      return _getMockRouteList();
    }

    final response = await http.get(
        Uri.parse('http://dhlapis.com/delivery/v1/routes'),
        headers: {'X-API-KEY': apiKey});

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      var content = jsonDecode(response.body);
      if (content["message"] != null) {
        return RouteList(routes: []);
      }
      return RouteList.fromJson(content);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load routes');
    }
  }

  @override
  Future<DHLRoute.Route?> getRoute(String tripkey) async {
    if (debug_mode) {
      return MockRouteProviderService().getRoute(int.parse(tripkey));
    }

    final response = await http.get(
        Uri.parse(
            'http://dhlapis.com/delivery/v1/routes/' + tripkey.toString()),
        headers: {'X-API-KEY': apiKey});

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      var content = jsonDecode(response.body);
      if (content["message"] != null) {
        return null;
      }
      return RouteInfo.fromJson(content).route;
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load route');
    }
  }
}
