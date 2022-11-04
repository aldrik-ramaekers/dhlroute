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
import 'package:training_planner/pages/navigation_page.dart';
import 'route.dart' as DHLRoute;

import 'main.dart';

// A callback to notify the hosting widget.
typedef ShowDialogFunction = void Function(String title, String message);

class RoutingExample {
  Timer? timer;
  bool isLookingAround = false;
  double currentZoom = 20;
  HereMapController hereMapController;
  List<MapPolyline> _routeSections = [];
  int routeSectionCursor = 0;

  late DHLRoute.Route _route;
  late RoutingEngine _routingEngine;
  late GeoCoordinates lastPosition = GeoCoordinates(0, 0);
  late SearchOptions _searchOptions;

  RoutingExample(HereMapController _hereMapController)
      : hereMapController = _hereMapController {
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
    var widgetPin = hereMapController.pinWidget(
        _createWidget(text, Color.fromARGB(200, 0, 144, 138)), coords);
    widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
  }

  Future<void> addRoute(DHLRoute.Route route) async {
    if (route.tasks == null) return;
    _route = route;

    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    GeoCoordinates routeStartCoords =
        GeoCoordinates(currentPosition.latitude, currentPosition.longitude);

    List<Waypoint> waypoints = [Waypoint.withDefaults(routeStartCoords)];

    GeoCoordinates previousCoords = routeStartCoords;
    for (final item in route.tasks!) {
      var destinationGeoCoordinates = GeoCoordinates(
          double.parse(item.addressLatitude!),
          double.parse(item.addressLongitude!));

      if (item.groupFirst == 'false') continue;

      waypoints.add(Waypoint.withDefaults(destinationGeoCoordinates));
      showAnchoredMapViewPin(
          destinationGeoCoordinates, item.deliverySequenceNumber.toString());

      previousCoords = destinationGeoCoordinates;
    }

    PedestrianOptions f = PedestrianOptions.withDefaults();
    f.routeOptions.alternatives = 0;
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
  }

  _showLineToHouse(Section section, GeoCoordinates houseCoords) {
    GeoPolyline routeGeoPolyline = section.geometry;

    GeoPolyline walkLine =
        GeoPolyline([routeGeoPolyline.vertices.last, houseCoords]);
    MapPolyline walkPathPolyline =
        MapPolyline(walkLine, 8, Color.fromARGB(160, 255, 20, 20));
    hereMapController.mapScene.addMapPolyline(walkPathPolyline);

    //_routeSections.add(walkPathPolyline);
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
    for (int i = 0; i < _routeSections.length; i++) {
      MapPolyline section = _routeSections.elementAt(i);
      int maxSections = 5;

      // previous section
      if (i == routeSectionCursor - 1) {
        section.lineColor = Color.fromARGB(160, 168, 113, 108);
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
      } else {
        section.lineColor = Color.fromARGB(0, 255, 255, 255);
      }
    }
  }
}