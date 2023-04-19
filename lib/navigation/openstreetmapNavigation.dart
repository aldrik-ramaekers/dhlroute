import 'dart:async';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:training_planner/events/MapPanningEvent.dart';
import 'package:training_planner/events/NextStopLoadedEvent.dart';
import 'package:training_planner/events/RouteLoadedEvent.dart';
import 'package:training_planner/events/StopCompletedEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/navigation/baseNavigation.dart';
import 'package:training_planner/pages/navigation_page.dart';
import 'package:training_planner/route.dart';
import '../route.dart' as DHLRoute;

class OpenstreetmapNavigation extends BaseNavigation {
  OpenstreetmapNavigation({Key? key, required route})
      : super(key: key, route: route);

  @override
  _OpenstreetNavigationState createState() => _OpenstreetNavigationState();
}

class _OpenstreetNavigationState extends BaseNavigationState
    with OSMMixinObserver {
  late List<RoadInfo> roads;
  late MapController controller;

  @override
  void initState() {
    widget.routeSectionCursor = 0;
    widget.currentZoom = 10;
    controller = MapController(
        initMapWithUserPosition: true,
        areaLimit: BoundingBox(
          east: 7.601818,
          north: 53.703101,
          south: 50.679237,
          west: 2.894101,
        ));

    widget.isLookingAround = true;
    eventBus.fire(MapPanningEvent(true));

    widget.stopCompletedEvent = eventBus.on<StopCompletedEvent>().listen((e) {
      widget.routeSectionCursor += 1;
      if (widget.routeSectionCursor >= widget.allTasks.length) {
        widget.routeSectionCursor = widget.allTasks.length - 1;
      }
      updateHighlightedRouteSections();
      eventBus.fire(
          NextStopLoadedEvent(widget.allTasks[widget.routeSectionCursor]));
    });

    widget.stopIncompletedEvent =
        eventBus.on<StopIncompletedEvent>().listen((e) {
      widget.routeSectionCursor -= 1;
      if (widget.routeSectionCursor < 0) widget.routeSectionCursor = 0;
      updateHighlightedRouteSections(force: true);
      eventBus.fire(
          NextStopLoadedEvent(widget.allTasks[widget.routeSectionCursor]));
    });

    blacklistProvider
        .getBlacklist()
        .then((value) => {widget.blacklist = value});

    super.initState();
    controller.addObserver(this);

    addRoute(widget.route);
  }

  @override
  Future<void> mapIsReady(bool isReady) async {
    addRoute(widget.route);
  }

  @override
  Future<void> addRoute(DHLRoute.Route route) async {
    print(
        "ASGOPDJS_GH DS*()FHY DS()UFHY) DSU(FHY)DSU( FH)DSUHF)UDS HF)UDSUHF ");
    if (route.tasks == null) return;

    print("234");

    GeoPoint routeStartCoords = await controller.myLocation();

    List<GeoPoint> waypoints = [routeStartCoords];
    //List<MultiRoadConfiguration> configs = [];

    groupTasksIntoGroups(route);
    /*
    GeoPoint prevCoord = routeStartCoords;
    for (var item in widget.parcelNumberPins) {
      GeoPoint point = GeoPoint(
          latitude: item.coords.lattitude, longitude: item.coords.longitude);

      waypoints.add(point);

      //configs.add(MultiRoadConfiguration(
      //  startPoint: prevCoord,
      //  destinationPoint: point,
      //));

      prevCoord = point;
    }

    for (var item in widget.parcelNumberPins) {
      item.isDoublePlannedAddress = isAddressDoublePlanned(item);
    }
*/
    /*
    roads = await controller.drawMultipleRoad(
      configs,
      commonRoadOption: MultiRoadOption(
        roadWidth: 10,
        roadColor: Colors.blue,
      ),
    );
    */

    eventBus.fire(NextStopLoadedEvent(widget.allTasks[0]));

    updateHighlightedRouteSections();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  var mapPointers = 0;
  var mapPosition;

  void onMoveStart() {
    widget.isLookingAround = true;
    eventBus.fire(MapPanningEvent(true));
  }

  void onMoveEnd() {}

  @override
  Widget build(BuildContext context) {
    return Listener(
        onPointerDown: (details) {
          if (mapPointers == 0) onMoveStart();
          mapPointers++;
        },
        onPointerUp: (details) {
          mapPointers--;
          if (mapPointers == 0) onMoveEnd();
        },
        behavior: HitTestBehavior.deferToChild,
        child: OSMFlutter(
          controller: controller,
          trackMyPosition: true,
          initZoom: widget.currentZoom,
          minZoomLevel: 2,
          maxZoomLevel: 18,
          stepZoom: 1.0,
          userLocationMarker: UserLocationMaker(
            personMarker: MarkerIcon(
              assetMarker: AssetMarker(
                  image: AssetImage('assets/package.png'),
                  scaleAssetImage: 1.0),
            ),
            directionArrowMarker: MarkerIcon(
              assetMarker: AssetMarker(
                  image: AssetImage('assets/package.png'),
                  scaleAssetImage: 1.0),
            ),
          ),
          roadConfiguration: RoadOption(
            roadColor: Colors.yellowAccent,
          ),
          markerOption: MarkerOption(
            defaultMarker: MarkerIcon(
              icon: Icon(
                Icons.person_pin_circle,
                color: Colors.blue,
                size: 56,
              ),
            ),
          ),
        ));
  }

  @override
  void changeZoom(double newVal) async {
    if (newVal > 18) newVal = 18;
    if (newVal < 10) newVal = 10;
    widget.currentZoom = newVal;
    await controller.setZoom(zoomLevel: newVal);
  }

  @override
  createPinWidget(
      DestinationPin pin, Color color, DHLCoordinates coords) async {
    await controller.addMarker(
        GeoPoint(
            latitude: pin.coords.lattitude, longitude: pin.coords.longitude),
        markerIcon: MarkerIcon(
          iconWidget: Container(
            height: 65,
            width: 150,
            child: createPin(pin, color,
                isDoublePlannedAddress: pin.isDoublePlannedAddress),
          ),
        ),
        angle: 0);
  }

  @override
  void flyTo(DHLCoordinates coords) async {
    await controller.enableTracking(
      enableStopFollow: false,
    );
  }

  @override
  void updateHighlightedRouteSections({bool force = false}) {
    int maxPins = 300;

    for (int i = widget.parcelNumberPins.length - 1; i >= 0; i--) {
      DestinationPin pin = widget.parcelNumberPins.elementAt(i);

      Color color = Color.fromARGB(200, 0, 144, 138);
      if (i == widget.routeSectionCursor)
        color = Color.fromARGB(199, 143, 8, 31);
      if (i == widget.routeSectionCursor + 1)
        color = Color.fromARGB(197, 13, 36, 241);
      if (destinationPinIsInBlacklist(widget.parcelNumberPins[i])) {
        color = Color.fromRGBO(143, 8, 31, 0.78);
      }

      bool forceUpdateThisPin = force &&
          (i > widget.routeSectionCursor - 3 &&
              i < widget.routeSectionCursor + 3);

      /*
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
      }*/

      if (i == widget.routeSectionCursor ||
          i == widget.routeSectionCursor + 1) {
        var widgetPin =
            createPinWidget(pin, color, widget.destinationCoords[i]);
        pin.pin = widgetPin;
      }
    }
  }
}
