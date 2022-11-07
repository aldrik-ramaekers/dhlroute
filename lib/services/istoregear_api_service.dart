import 'package:training_planner/models/login_request.dart';
import 'package:training_planner/models/login_response.dart';
import 'package:training_planner/models/route_list.dart';
import 'package:training_planner/route.dart';

abstract class IStoregearApiService {
  Future<LoginResponse> login(LoginRequest req);
  Future<RouteList> getRoutes();
}
