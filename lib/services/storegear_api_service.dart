import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:training_planner/models/login_request.dart';
import 'package:training_planner/models/login_response.dart';
import 'package:training_planner/models/route_list.dart';
import 'package:training_planner/route.dart';
import 'package:training_planner/services/istoregear_api_service.dart';

class StoregearApiService extends IStoregearApiService {
  String apiKey = '';

  @override
  Future<LoginResponse> login(LoginRequest req) async {
    final response = await http.post(
        Uri.parse('http://dhlapis.com/delivery/v1/users/login?env_type=PROD'),
        body: jsonEncode(req));
    debugPrint(jsonEncode(req));
    debugPrint(response.body);
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
{
    "routes": [
        {
            "timeframe_key": "96870",
            "trip_key": "18996870",
            "trip_number": "9",
            "trip_pda_status": "5",
            "trip_pda_status_description": "Rit overgedragen",
            "trip_sequence_number": "1",
            "number_in_trip": "139",
            "plate": "VND-37-B",
            "damage_registration": true,
            "eva": "11:11",
            "trip_date": "4/11/2022",
            "first_address_lat": "50.8996568140536",
            "first_address_lng": "5.75238472757395",
            "started": "true",
            "all_tasks_finished": "false",
            "start_km": "24704",
            "end_km": null,
            "tasks_enriched": "true",
            "in_trip_scan_finished": "true",
            "eva_added": "true",
            "trip_start_request_sent": "true"
        }
    ]
}
'''));
  }

  @override
  Future<RouteList> getRoutes() async {
    return _getMockRouteList();

    debugPrint('WE GOT HERE!!! ' + apiKey);
    final response = await http.get(
        Uri.parse('http://dhlapis.com/delivery/v1/routes'),
        headers: {'X-API-KEY': apiKey});

    debugPrint(response.body);
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.

      var content = jsonDecode(response.body);
      if (content["message"] != null) {
        return RouteList(routes: []);
      }
      debugPrint('amogus');
      return RouteList.fromJson(content);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load routes');
    }
  }
}
