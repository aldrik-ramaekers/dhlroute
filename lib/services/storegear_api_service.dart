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

  @override
  Future<RouteList> getRoutes() async {
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
        content = jsonEncode(RouteList());
      }

      return RouteList.fromJson(content);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to load routes');
    }
  }
}
