import 'package:training_planner/navigation/baseNavigation.dart';

class StopCompletedEvent {}

class StopIncompletedEvent {}

class ChangeZoomEvent {
  double zoom;
  ChangeZoomEvent(this.zoom);
}

class FlyToEvent {
  DHLCoordinates coords;
  FlyToEvent(this.coords);
}
