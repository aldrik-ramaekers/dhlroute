import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/animation.dart';
import 'package:here_sdk/gestures.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:image/image.dart' as image;
import 'package:here_sdk/routing.dart' as here;
import 'package:training_planner/events/MapPanningEvent.dart';
import 'package:training_planner/pages/navigation_page.dart';

import 'main.dart';

// A callback to notify the hosting widget.
typedef ShowDialogFunction = void Function(String title, String message);

class RoutingExample {
  Timer? timer;
  bool isLookingAround = false;
  double currentZoom = 20;
  HereMapController hereMapController;
  List<MapPolyline> _mapPolylines = [];
  late RoutingEngine _routingEngine;
  late GeoCoordinates lastPosition = GeoCoordinates(0, 0);

  RoutingExample(HereMapController _hereMapController)
      : hereMapController = _hereMapController {
    try {
      _routingEngine = RoutingEngine();
    } on InstantiationException {
      throw ("Initialization of RoutingEngine failed.");
    }

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
  }

  Future<Uint8List> _loadFileAsUint8List(String fileName) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load('assets/' + fileName);
    return Uint8List.view(fileData.buffer);
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
    debugPrint('XDDDD' + currentZoom.toString());
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

  void showAnchoredMapViewPin(GeoCoordinates coords) {
    var widgetPin = hereMapController.pinWidget(
        _createWidget("43", Color.fromARGB(200, 0, 144, 138)), coords);
    widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
  }

  Future<void> addRoute() async {
    var startGeoCoordinates = GeoCoordinates(50.8434572, 5.7381166);
    var destinationGeoCoordinates = GeoCoordinates(50.8474741, 5.7330341);
    var startWaypoint = Waypoint.withDefaults(startGeoCoordinates);
    startWaypoint.type = WaypointType.stopover;
    var destinationWaypoint = Waypoint.withDefaults(destinationGeoCoordinates);
    destinationWaypoint.type = WaypointType.stopover;

    List<Waypoint> waypoints = [startWaypoint, destinationWaypoint];

    _routingEngine.calculateCarRoute(waypoints, CarOptions.withDefaults(),
        (RoutingError? routingError, List<here.Route>? routeList) async {
      if (routingError == null) {
        // When error is null, then the list guaranteed to be not null.
        here.Route route = routeList!.first;
        _showRouteOnMap(route, destinationGeoCoordinates);
      } else {
        var error = routingError.toString();
      }
    });

    showAnchoredMapViewPin(destinationGeoCoordinates);
  }

  _showRouteOnMap(here.Route route, GeoCoordinates destCoords) {
    GeoPolyline routeGeoPolyline = route.geometry;
    double widthInPixels = 15;

    // Line of route
    MapPolyline routeMapPolyline = MapPolyline(
        routeGeoPolyline, widthInPixels, Color.fromARGB(160, 0, 144, 138));
    hereMapController.mapScene.addMapPolyline(routeMapPolyline);

    // Line from road to house
    GeoPolyline walkLine =
        GeoPolyline([routeGeoPolyline.vertices.last, destCoords]);
    MapPolyline walkPathPolyline =
        MapPolyline(walkLine, 8, Color.fromARGB(160, 255, 20, 20));
    hereMapController.mapScene.addMapPolyline(walkPathPolyline);

    _mapPolylines.add(walkPathPolyline);
    _mapPolylines.add(routeMapPolyline);
  }
}
