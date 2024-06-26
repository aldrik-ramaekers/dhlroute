import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
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
import 'package:training_planner/navigation/baseNavigation.dart';
import 'package:training_planner/pages/navigation_page.dart';
import 'package:training_planner/services/iblacklist_provider_service.dart';
import 'route.dart' as DHLRoute;

import 'main.dart';

// A callback to notify the hosting widget.
typedef ShowDialogFunction = void Function(String title, String message);

class RoutingExample {
  Timer? timer;
  bool isLookingAround = false;
  double currentZoom = 20;
  HereMapController hereMapController;
  StreamSubscription? stopCompletedEvent;
  StreamSubscription? stopIncompletedEvent;

  List<MapPolyline> _routeSections = [];
  List<MapPolyline> _pathSections = [];
  List<DestinationPin> _parcelNumberPins = [];
  List<GeoCoordinates> _destinationCoords = [];
  List<ActiveTask> allTasks = [];

  int routeSectionCursor = 0;

  late DHLRoute.Route _route;
  late RoutingEngine _routingEngine;
  late GeoCoordinates lastPosition = GeoCoordinates(0, 0);
  late SearchOptions _searchOptions;
  late MapMarker mapMarker;

  List<BlacklistEntry> blacklist = [];

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

    _addCircle(GeoCoordinates(50.8434572, 5.7381166));

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
      updateHighlightedRouteSections();
      eventBus.fire(NextStopLoadedEvent(allTasks[routeSectionCursor]));
    });

    stopIncompletedEvent = eventBus.on<StopIncompletedEvent>().listen((e) {
      routeSectionCursor -= 1;
      if (routeSectionCursor < 0) routeSectionCursor = 0;
      updateHighlightedRouteSections(force: true);
      eventBus.fire(NextStopLoadedEvent(allTasks[routeSectionCursor]));
    });

    blacklistProvider.getBlacklist().then((value) => {blacklist = value});
  }

  void destroy() {
    stopCompletedEvent?.cancel();
    stopIncompletedEvent?.cancel();
    timer?.cancel();
  }

  void _updateLocation(Position value) {
    lastPosition = GeoCoordinates(value.latitude, value.longitude);
    mapMarker.coordinates = lastPosition;
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

  Widget _createWidget(DestinationPin pin, Color backgroundColor,
      {bool isDoublePlannedAddress = false}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        shape: BoxShape.rectangle,
        border: Border.all(
            color: isDoublePlannedAddress
                ? ui.Color.fromARGB(255, 255, 0, 0)
                : ui.Color.fromARGB(0, 0, 0, 0),
            width: 2),
      ),
      child: GestureDetector(
          child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 0, 0, 0),
              borderRadius: BorderRadius.circular(10),
              shape: BoxShape.rectangle,
            ),
            child: Text(
              pin.sequenceNumber.toString(),
              style: TextStyle(
                  fontSize: 20.0, color: Color.fromARGB(255, 255, 255, 255)),
            ),
          ),
          Container(
            padding: EdgeInsets.all(3),
            child: Text(
              pin.houseNumberWithExtra ?? 'Zie pakket',
              style: TextStyle(fontSize: 20.0),
            ),
          ),
        ],
      )),
    );
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

// if address is double planned and there is a stop before this one.
  bool shouldDoublePlannedAddressBeVisible(DestinationPin taskToCheck) {
    if (!taskToCheck.isDoublePlannedAddress) return true;
    for (int i = routeSectionCursor; i < _parcelNumberPins.length; i++) {
      var item = _parcelNumberPins[i];

      if (item == taskToCheck) {
        return true; // first one of the double planned addresses is visible.
      }
      if (item.coords.compare(taskToCheck.coords)) {
        return false;
      }
    }

    return true;
  }

  bool isAddressDoublePlanned(DestinationPin taskToCheck) {
    for (final item in _parcelNumberPins) {
      if (item == taskToCheck) continue;
      if (item.coords.compare(taskToCheck.coords)) return true;
    }

    return false;
  }

  void groupTasksIntoGroups(DHLRoute.Route route) {
    bool isFirst = true;
    for (final item in route.tasks!) {
      //debugPrint(item.deliverySequenceNumber.toString());

      if (item.addressLatitude == null || item.addressLongitude == null) {
        // Skip adressen die fout zijn ingegeven.
        // Hier moeten we nog iets voor vinden om bestuurder te laten weten
        continue;
      }

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

      _parcelNumberPins.add(
        DestinationPin(
            numberOfParcels: 0,
            sequenceNumber: int.parse(item.deliverySequenceNumber!),
            coords: DHLCoordinates(destinationGeoCoordinates.latitude,
                destinationGeoCoordinates.longitude),
            isDoublePlannedAddress: false,
            postalcodeNumeric: item.postalCodeNumeric,
            postalcodeAlpha: item.postalCodeAlpha,
            houseNumberWithExtra:
                item.houseNumber! + (item.houseNumberAddition ?? ''),
            pid: item.pid),
      );
      _destinationCoords.add(destinationGeoCoordinates);

      int sequenceNumber = int.parse(item.deliverySequenceNumber!);
      int groupLastSequenceNumber = int.parse(item.deliverySequenceNumber!);
      if (item.groupSize != null) {
        groupLastSequenceNumber += int.parse(item.groupSize!) - 1;
      }

      String addrToDisplay = (item.street ?? "").toUpperCase() +
          " " +
          (item.houseNumber ?? "") +
          (item.houseNumberAddition ?? "");

      var groupedTask = ActiveTask(
          sequenceNumber,
          item.timeframe!,
          groupLastSequenceNumber,
          addrToDisplay,
          item.indicationSignatureRequired == true,
          item.indicationNotAtNeighbours == true);

      if (isFirst) {
        eventBus.fire(NextStopLoadedEvent(groupedTask));
        isFirst = false;
      }
      allTasks.add(groupedTask);
    }
  }

  Future<void> addRoute(DHLRoute.Route route) async {
    if (route.tasks == null) return;
    _route = route;

    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    GeoCoordinates routeStartCoords =
        GeoCoordinates(currentPosition.latitude, currentPosition.longitude);

    List<Waypoint> waypoints = [Waypoint.withDefaults(routeStartCoords)];

    groupTasksIntoGroups(route);

    for (var item in _parcelNumberPins) {
      waypoints.add(Waypoint.withDefaults(GeoCoordinates(
          item.coords?.lattitude ?? 0, item.coords?.longitude ?? 0)));
    }

    for (var item in _parcelNumberPins) {
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

  bool destinationPinIsInBlacklist(DestinationPin pin) {
    try {
      for (int i = 0; i < blacklist.length; i++) {
        if (pin.postalcodeNumeric == blacklist[i].postalcodeNumeric &&
            pin.postalcodeAlpha!.toLowerCase() ==
                blacklist[i].postalcodeAplha &&
            pin.houseNumberWithExtra!.toLowerCase() ==
                (blacklist[i].houseNumber.toString() +
                    blacklist[i].houseNumberExtra.toLowerCase())) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  WidgetPin? createPinWidget(
      DestinationPin pin, Color color, GeoCoordinates coords) {
    return hereMapController.pinWidget(
        _createWidget(pin, color,
            isDoublePlannedAddress: pin.isDoublePlannedAddress),
        coords);
  }

  void updateHighlightedRouteSections({bool force = false}) {
    int maxPins = 300;

    for (int i = _parcelNumberPins.length - 1; i >= 0; i--) {
      DestinationPin pin = _parcelNumberPins.elementAt(i);

      Color color = Color.fromARGB(200, 0, 144, 138);
      if (i == routeSectionCursor) color = Color.fromARGB(199, 143, 8, 31);
      if (i == routeSectionCursor + 1) color = Color.fromARGB(197, 13, 36, 241);
      if (destinationPinIsInBlacklist(_parcelNumberPins[i])) {
        color = ui.Color.fromRGBO(143, 8, 31, 0.78);
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
        var widgetPin = createPinWidget(pin, color, _destinationCoords[i]);
        widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
        pin.pin = widgetPin;
      } else {
        pin.pin?.unpin();
        pin.pin = null;
      }

      if (i == routeSectionCursor || i == routeSectionCursor + 1) {
        var widgetPin = createPinWidget(pin, color, _destinationCoords[i]);
        widgetPin?.anchor = Anchor2D.withHorizontalAndVertical(0.5, 0.5);
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
