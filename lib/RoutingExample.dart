import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/animation.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/search.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:image/image.dart' as image;
import 'package:here_sdk/routing.dart' as here;
import 'package:training_planner/events/MapPanningEvent.dart';
import 'package:training_planner/events/NextStopLoadedEvent.dart';
import 'package:training_planner/events/StopCompletedEvent.dart';
import 'package:training_planner/pages/navigation_page.dart';
import 'route.dart' as DHLRoute;

import 'main.dart';

// A callback to notify the hosting widget.
typedef ShowDialogFunction = void Function(String title, String message);

class DestinationPin {
  final String text;
  final GeoCoordinates? coords;
  WidgetPin? pin;

  DestinationPin({this.text = '', this.coords});
}

class ActiveTask {
  final int firstParcelNumber;
  final String deliveryTimeBlock;
  final int lastParcelNumber;
  final String fullAddress;
  final bool needsSignature;
  final bool notAtNeighbors;

  ActiveTask(
      this.firstParcelNumber,
      this.deliveryTimeBlock,
      this.lastParcelNumber,
      this.fullAddress,
      this.needsSignature,
      this.notAtNeighbors);
}

class RoutingExample {
  Timer? timer;
  bool isLookingAround = false;
  double currentZoom = 20;
  HereMapController hereMapController;
  StreamSubscription? stopCompletedEvent;

  List<MapPolyline> _routeSections = [];
  List<MapPolyline> _pathSections = [];
  List<DestinationPin> _parcelNumberPins = [];
  List<GeoCoordinates> _destinationCoords = [];
  List<ActiveTask> allTasks = [];
  late ActiveTask activeTask;

  int routeSectionCursor = 0;

  late DHLRoute.Route _route;
  late RoutingEngine _routingEngine;
  late GeoCoordinates lastPosition = GeoCoordinates(0, 0);
  late SearchOptions _searchOptions;

  RoutingExample(HereMapController _hereMapController)
      : hereMapController = _hereMapController {
    activeTask = ActiveTask(0, "", 0, "", false, false);

    try {
      _routingEngine = RoutingEngine();
    } on InstantiationException {
      throw ("Initialization of RoutingEngine failed.");
    }

    _searchOptions = SearchOptions.withDefaults();
    _searchOptions.languageCode = LanguageCode.enUs;
    _searchOptions.maxItems = 5;

    //double distanceToEarthInMeters = currentZoom;
    //MapMeasure mapMeasureZoom =
    //    MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);
    _hereMapController.camera
        .lookAtPoint(GeoCoordinates(50.8434572, 5.7381166));
    _hereMapController.camera.zoomTo(currentZoom);

    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => _setLocationOnMap());

    _hereMapController.gestures.panListener = PanListener(
        (GestureState state, Point2D touchPoint, Point2D p2, double d) {
      isLookingAround = true;
      eventBus.fire(MapPanningEvent(true));
    });

    stopCompletedEvent = eventBus.on<StopCompletedEvent>().listen((e) {
      routeSectionCursor += 1;
      if (routeSectionCursor >= allTasks.length) {
        routeSectionCursor = allTasks.length - 1;
      }
      activeTask = allTasks[routeSectionCursor];
      updateHighlightedRouteSections();
      eventBus.fire(NextStopLoadedEvent());
    });
  }

  void destroy() {
    stopCompletedEvent?.cancel();
    timer?.cancel();
  }

  void _updateLocation(Position value) {
    lastPosition = GeoCoordinates(value.latitude, value.longitude);
    flyTo(GeoCoordinates(value.latitude, value.longitude));
  }

  void _setLocationOnMap() {
    if (!isLookingAround) {
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then((value) => {if (!isLookingAround) _updateLocation(value)});
    }
  }

  void changeZoom(double newVal) {
    if (newVal > 20) newVal = 20;
    if (newVal < 13) newVal = 13;
    currentZoom = newVal;
    hereMapController.camera.zoomTo(currentZoom);
  }

  void flyTo(GeoCoordinates geoCoordinates) {
    /*
    GeoCoordinatesUpdate geoCoordinatesUpdate =
        GeoCoordinatesUpdate.fromGeoCoordinates(geoCoordinates);
    double bowFactor = 0;

    MapCameraAnimation animation = MapCameraAnimationFactory.flyTo(
        geoCoordinatesUpdate, bowFactor, Duration(milliseconds: 0));
    _hereMapController.camera.startAnimation(animation);*/

    //double distanceToEarthInMeters = currentZoom;
    //MapMeasure mapMeasureZoom =
    //    MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

    double bearingInDegress = 0;
    double tiltInDegress = 0;
    GeoOrientationUpdate orientation =
        GeoOrientationUpdate(bearingInDegress, tiltInDegress);

    hereMapController.camera.lookAtPointWithGeoOrientationAndMeasure(
        GeoCoordinates(geoCoordinates.latitude, geoCoordinates.longitude),
        orientation,
        MapMeasure(MapMeasureKind.zoomLevel, currentZoom));
  }

  Widget _createWidget(String label, Color backgroundColor) {
    return Container(
      padding: EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Color.fromARGB(0, 0, 0, 120)),
      ),
      child: GestureDetector(
        child: Text(
          label,
          style: TextStyle(fontSize: 10.0),
        ),
      ),
    );
  }

  void showAnchoredMapViewPin(GeoCoordinates coords, String text) {
    _parcelNumberPins.add(DestinationPin(text: text, coords: coords));
  }

  DHLRoute.Task _findTaskWithLowestSequenceNumberInGroup(
      DHLRoute.Route route, List<String> groupPids) {
    List<DHLRoute.Task> tasksFound = [];

    for (final item in route.tasks!) {
      if (groupPids.contains(item.pid)) tasksFound.add(item);
    }

    tasksFound.sort((e1, e2) => int.parse(e1.deliverySequenceNumber!)
        .compareTo(int.parse(e2.deliverySequenceNumber!)));
    return tasksFound.first;
  }

  Future<void> addRoute(DHLRoute.Route route) async {
    if (route.tasks == null) return;
    _route = route;

    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    GeoCoordinates routeStartCoords =
        GeoCoordinates(currentPosition.latitude, currentPosition.longitude);

    List<Waypoint> waypoints = [Waypoint.withDefaults(routeStartCoords)];

    bool isFirst = true;
    for (final item in route.tasks!) {
      var destinationGeoCoordinates = GeoCoordinates(
          double.parse(item.addressLatitude!),
          double.parse(item.addressLongitude!));

      if (item.isIntervention != 'true' &&
          item.groupSize != null &&
          item.groupPids != null &&
          int.parse(item.groupSize!) > 1) {
        var firstTaskInGroup =
            _findTaskWithLowestSequenceNumberInGroup(route, item.groupPids!);
        if (firstTaskInGroup != item) {
          continue;
        }
      }

      waypoints.add(Waypoint.withDefaults(destinationGeoCoordinates));

      _parcelNumberPins.add(DestinationPin(
          text: item.deliverySequenceNumber.toString(),
          coords: destinationGeoCoordinates));
      _destinationCoords.add(destinationGeoCoordinates);
      debugPrint(item.deliverySequenceNumber);

      int sequenceNumber = int.parse(item.deliverySequenceNumber!);
      int groupLastSequenceNumber = int.parse(item.deliverySequenceNumber!);
      if (item.groupSize != null) {
        groupLastSequenceNumber += int.parse(item.groupSize!) - 1;
      }
      var groupedTask = ActiveTask(
          sequenceNumber,
          item.timeframe!,
          groupLastSequenceNumber,
          item.fullAddressForNavigation!,
          item.indicationSignatureRequired == true,
          item.indicationNotAtNeighbours == true);

      if (isFirst) {
        activeTask = groupedTask;
        isFirst = false;
      }
      allTasks.add(groupedTask);
    }

    PedestrianOptions f = PedestrianOptions.withDefaults();
    f.routeOptions.alternatives = 0;
    f.routeOptions.enableTrafficOptimization = false;
    f.routeOptions.optimizationMode = OptimizationMode.fastest;

    _routingEngine.calculatePedestrianRoute(waypoints, f,
        (RoutingError? routingError, List<here.Route>? routeList) async {
      if (routingError == null) {
        here.Route route = routeList!.first;

        _showRouteOnMap(route);

        for (int i = 0; i < route.sections.length; i++) {
          _showLineToHouse(route.sections.elementAt(i),
              waypoints.elementAt(i + 1).coordinates);
        }

        updateHighlightedRouteSections();
      } else {
        var error = routingError.toString();
      }
    });

    eventBus.fire(NextStopLoadedEvent());
  }

  _showLineToHouse(Section section, GeoCoordinates houseCoords) {
    GeoPolyline routeGeoPolyline = section.geometry;

    GeoPolyline walkLine =
        GeoPolyline([routeGeoPolyline.vertices.last, houseCoords]);
    MapPolyline walkPathPolyline =
        MapPolyline(walkLine, 8, Color.fromARGB(160, 255, 20, 20));
    hereMapController.mapScene.addMapPolyline(walkPathPolyline);

    _pathSections.add(walkPathPolyline);
  }

  _showRouteOnMap(here.Route route) {
    double widthInPixels = 15;

    for (int i = 0; i < route.sections.length; i++) {
      Section section = route.sections.elementAt(i);
      GeoPolyline routeGeoPolyline = section.geometry;

      MapPolyline routeMapPolyline = MapPolyline(
          routeGeoPolyline, widthInPixels, Color.fromARGB(160, 0, 144, 138));
      hereMapController.mapScene.addMapPolyline(routeMapPolyline);

      _routeSections.add(routeMapPolyline);
    }
  }

  void updateHighlightedRouteSections() {
    // Show the next 20 parcel pins, to let the delivery driver decide on possible detours.
    int maxPins = 20;
    for (int i = 0; i < _parcelNumberPins.length; i++) {
      DestinationPin pin = _parcelNumberPins.elementAt(i);

      if (i > routeSectionCursor && i < routeSectionCursor + maxPins) {
        if (pin.pin != null) continue;
        var widgetPin = hereMapController.pinWidget(
            _createWidget(pin.text, Color.fromARGB(200, 0, 144, 138)),
            _destinationCoords[i]);
        widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
        pin.pin = widgetPin;
      } else {
        pin.pin?.unpin();
        pin.pin = null;
      }

      // Highlight current destination.
      if (i == routeSectionCursor) {
        var widgetPin = hereMapController.pinWidget(
            _createWidget(pin.text, ui.Color.fromARGB(199, 143, 8, 31)),
            _destinationCoords[i]);
        widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
        pin.pin = widgetPin;
      }
    }

    // Show the next 5 sections as to not clutter the screen.
    int maxSections = 5;
    for (int i = 0; i < _routeSections.length; i++) {
      MapPolyline section = _routeSections.elementAt(i);
      MapPolyline path = _pathSections.elementAt(i);

      // previous section
      if (i == routeSectionCursor - 1) {
        section.lineColor = Color.fromARGB(160, 168, 113, 108);
        path.lineColor = Color.fromARGB(0, 255, 255, 255);
      }
      // current and next 5 sections
      else if (i >= routeSectionCursor &&
          i < routeSectionCursor + maxSections) {
        section.lineColor = Color.fromARGB(
            (255 - ((255 / (maxSections + 1)) * (i - routeSectionCursor)))
                .toInt(),
            0,
            144,
            138);
        path.lineColor = Color.fromARGB(160, 255, 0, 0);
      } else {
        section.lineColor = Color.fromARGB(0, 255, 255, 255);
        path.lineColor = Color.fromARGB(0, 255, 255, 255);
      }
    }
  }
}
