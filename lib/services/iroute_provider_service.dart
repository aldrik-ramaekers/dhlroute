import 'dart:async';

import 'package:training_planner/route.dart';

abstract class IRouteProviderService {
  Future<Route> getRoute(int number);
}
