import 'dart:async';
import 'package:here_sdk/routing.dart' as here;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/gestures.dart';
import 'package:here_sdk/mapview.dart';
import 'package:here_sdk/routing.dart';
import 'package:here_sdk/search.dart';
import 'package:training_planner/events/MapPanningEvent.dart';
import 'package:training_planner/events/NextStopLoadedEvent.dart';
import 'package:training_planner/events/RouteLoadedEvent.dart';
import 'package:training_planner/events/StopCompletedEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/navigation/baseNavigation.dart';
import 'package:training_planner/pages/navigation_page.dart';
import 'package:training_planner/route.dart';
import '../route.dart' as DHLRoute;

class HERENavigation extends BaseNavigation {
  HERENavigation({Key? key, required route}) : super(key: key, route: route);

  @override
  _HERENavigationState createState() => _HERENavigationState();
}

class _HERENavigationState extends BaseNavigationState {
  late HereMapController hereMapController;

  List<MapPolyline> _routeSections = [];
  List<MapPolyline> _pathSections = [];

  late RoutingEngine _routingEngine;
  late SearchOptions _searchOptions;
  late MapMarker mapMarker;

  Future<Uint8List> _loadFileAsUint8List(String assetPathToFile) async {
    // The path refers to the assets directory as specified in pubspec.yaml.
    ByteData fileData = await rootBundle.load(assetPathToFile);
    return Uint8List.view(fileData.buffer);
  }

  Future<void> _addCircle(GeoCoordinates geoCoordinates) async {
    Uint8List imagePixelData = await _loadFileAsUint8List('assets/package.png');
    MapImage circleMapImage =
        MapImage.withPixelDataAndImageFormat(imagePixelData, ImageFormat.png);
    mapMarker = MapMarker(geoCoordinates, circleMapImage);
    hereMapController.mapScene.addMapMarker(mapMarker);
  }

  @override
  Widget build(BuildContext context) {
    return HereMap(onMapCreated: _onMapCreated);
  }

  void _updateLocation(Position value) {
    widget.lastPosition = DHLCoordinates(value.latitude, value.longitude);
    mapMarker.coordinates = GeoCoordinates(value.latitude, value.longitude);
    flyTo(DHLCoordinates(value.latitude, value.longitude));
  }

  void _setLocationOnMap() {
    if (!widget.isLookingAround) {
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then(
              (value) => {if (!widget.isLookingAround) _updateLocation(value)});
    }
  }

  void initialize() {
    try {
      _routingEngine = RoutingEngine();
    } on InstantiationException {
      throw ("Initialization of RoutingEngine failed.");
    }

    _searchOptions = SearchOptions.withDefaults();
    _searchOptions.languageCode = LanguageCode.enUs;
    _searchOptions.maxItems = 5;

    hereMapController.camera.lookAtPoint(GeoCoordinates(50.8434572, 5.7381166));
    hereMapController.camera.zoomTo(widget.currentZoom);

    _addCircle(GeoCoordinates(50.8434572, 5.7381166));

    widget.timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => _setLocationOnMap());

    hereMapController.gestures.panListener = PanListener(
        (GestureState state, Point2D touchPoint, Point2D p2, double d) {
      widget.isLookingAround = true;
      eventBus.fire(MapPanningEvent(true));
    });

    widget.stopCompletedEvent = eventBus.on<StopCompletedEvent>().listen((e) {
      routeSectionCursor += 1;
      if (routeSectionCursor >= widget.allTasks.length) {
        routeSectionCursor = widget.allTasks.length - 1;
      }
      updateHighlightedRouteSections();
      eventBus.fire(NextStopLoadedEvent(widget.allTasks[routeSectionCursor]));
    });

    widget.stopIncompletedEvent =
        eventBus.on<StopIncompletedEvent>().listen((e) {
      routeSectionCursor -= 1;
      if (routeSectionCursor < 0) routeSectionCursor = 0;
      updateHighlightedRouteSections(force: true);
      eventBus.fire(NextStopLoadedEvent(widget.allTasks[routeSectionCursor]));
    });

    blacklistProvider
        .getBlacklist()
        .then((value) => {widget.blacklist = value});
  }

  void _onMapCreated(HereMapController hereMapController) async {
    this.hereMapController = hereMapController;
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError? error) {
      if (error == null) {
        initialize();
        addRoute(widget.route).then((value) {
          widget.doneLoading = true;
        });
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  @override
  Future<void> addRoute(DHLRoute.Route route) async {
    if (route.tasks == null) return;

    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    GeoCoordinates routeStartCoords =
        GeoCoordinates(currentPosition.latitude, currentPosition.longitude);

    List<Waypoint> waypoints = [Waypoint.withDefaults(routeStartCoords)];

    groupTasksIntoGroups(route);

    for (var item in widget.parcelNumberPins) {
      waypoints.add(Waypoint.withDefaults(
          GeoCoordinates(item.coords.lattitude, item.coords.longitude)));
    }

    for (var item in widget.parcelNumberPins) {
      item.isDoublePlannedAddress = isAddressDoublePlanned(item);
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

  @override
  void changeZoom(double newVal) {
    if (newVal > 20) newVal = 20;
    if (newVal < 13) newVal = 13;
    widget.currentZoom = newVal;
    hereMapController.camera.zoomTo(widget.currentZoom);
  }

  @override
  void flyTo(DHLCoordinates coords) {
    double bearingInDegress = 0;
    double tiltInDegress = 0;
    GeoOrientationUpdate orientation =
        GeoOrientationUpdate(bearingInDegress, tiltInDegress);

    hereMapController.camera.lookAtPointWithGeoOrientationAndMeasure(
        GeoCoordinates(coords.lattitude, coords.longitude),
        orientation,
        MapMeasure(MapMeasureKind.zoomLevel, widget.currentZoom));
  }

  @override
  dynamic createPinWidget(
      DestinationPin pin, Color color, DHLCoordinates coords) {
    var pp = hereMapController.pinWidget(
        createPin(pin, color,
            isDoublePlannedAddress: pin.isDoublePlannedAddress),
        GeoCoordinates(coords.lattitude, coords.longitude));
    pp?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
    return pp;
  }

  @override
  void dispose() {
    destroyNavigation();
    super.dispose();
  }

  @override
  void updateHighlightedRouteSections({bool force = false}) {
    int maxPins = 300;

    for (int i = widget.parcelNumberPins.length - 1; i >= 0; i--) {
      DestinationPin pin = widget.parcelNumberPins.elementAt(i);

      Color color = Color.fromARGB(200, 0, 144, 138);
      if (i == routeSectionCursor) color = Color.fromARGB(199, 143, 8, 31);
      if (i == routeSectionCursor + 1) color = Color.fromARGB(197, 13, 36, 241);
      if (destinationPinIsInBlacklist(widget.parcelNumberPins[i])) {
        color = Color.fromRGBO(143, 8, 31, 0.78);
      }

      bool forceUpdateThisPin =
          force && (i > routeSectionCursor - 3 && i < routeSectionCursor + 3);

      if (!shouldDoublePlannedAddressBeVisible(pin)) {
        pin.pin?.unpin();
        pin.pin = null;
        continue;
      }

      if (i > routeSectionCursor + 1 && i < routeSectionCursor + maxPins) {
        if (forceUpdateThisPin) {
          pin.pin?.unpin();
          pin.pin = null;
        } else if (pin.pin != null) {
          continue;
        }
        var widgetPin =
            createPinWidget(pin, color, widget.destinationCoords[i]);
        pin.pin = widgetPin;
      } else {
        pin.pin?.unpin();
        pin.pin = null;
      }

      if (i == routeSectionCursor || i == routeSectionCursor + 1) {
        var widgetPin =
            createPinWidget(pin, color, widget.destinationCoords[i]);
        pin.pin = widgetPin;
      }
    }

    // Show the next 5 sections as to not clutter the screen.
    int maxSections = 5;
    int maxWalkPaths = 300;
    for (int i = _routeSections.length - 1; i >= 0; i--) {
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
      } else {
        section.lineColor = Color.fromARGB(0, 255, 255, 255);
      }

      if (i >= routeSectionCursor && i < routeSectionCursor + maxWalkPaths) {
        path.lineColor = Color.fromARGB(160, 255, 0, 0);
      } else {
        path.lineColor = Color.fromARGB(0, 255, 255, 255);
      }
    }
  }
}
