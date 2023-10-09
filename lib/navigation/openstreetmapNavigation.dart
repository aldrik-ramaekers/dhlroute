import 'dart:async';
import 'package:flutter_map/flutter_map.dart' as FlutterMap;
import 'package:flutter_map/plugin_api.dart';
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
import 'package:latlong2/latlong.dart';

class OpenstreetmapNavigation extends BaseNavigation {
  OpenstreetmapNavigation({Key? key, required route})
      : super(key: key, route: route);

  @override
  _OpenstreetNavigationState createState() => _OpenstreetNavigationState();
}

class _OpenstreetNavigationState extends BaseNavigationState
    with OSMMixinObserver {
  late List<RoadInfo> roads;
  late FlutterMap.MapController controller;

  GlobalKey<ScaffoldState> _scaffoldKey =
      new GlobalKey(); //so we can call snackbar from anywhere

  late LatLng startPosition = LatLng(0, 0);
  @override
  void initState() {
    widget.routeSectionCursor = 0;
    widget.currentZoom = 10;
    controller = FlutterMap.MapController();

    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((value) {
      setState(() {
        startPosition = LatLng(value.latitude, value.longitude);
      });
    });

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

    mapIsReady(true);

    super.initState();
    //controller.addObserver(this);
  }

  @override
  Future<void> mapIsReady(bool isReady) async {
    if (widget.allTasks.length != 0) return;
    addRoute(widget.route);
  }

  @override
  Future<void> addRoute(DHLRoute.Route route) async {
    if (route.tasks == null) return;

    groupTasksIntoGroups(route);

    for (var item in widget.parcelNumberPins) {
      item.isDoublePlannedAddress = isAddressDoublePlanned(item);
    }

    eventBus.fire(NextStopLoadedEvent(widget.allTasks[0]));

    updateHighlightedRouteSections();
  }

  @override
  void dispose() {
    controller.dispose();
    widget.stopCompletedEvent?.cancel();
    widget.stopIncompletedEvent?.cancel();
    super.dispose();
  }

  var mapPointers = 0;
  var mapPosition;

  late List<FlutterMap.Marker> markers = [];

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
      child: Stack(
        children: [
          FlutterMap.FlutterMap(
            mapController: controller,
            options: MapOptions(
              center: startPosition,
              bounds: LatLngBounds(
                  LatLng(53.703101, 7.601818), LatLng(50.679237, 2.894101)),
            ),
            children: [
              FlutterMap.TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              FlutterMap.MarkerLayer(
                markers: markers,
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  void changeZoom(double newVal) async {
    if (newVal > 18) newVal = 18;
    if (newVal < 10) newVal = 10;
    widget.currentZoom = newVal;

    controller.moveAndRotate(controller.center, widget.currentZoom, 0.0);
  }

  @override
  createPinWidget(
      DestinationPin pin, Color color, DHLCoordinates coords) async {
    // poop
  }

  @override
  void flyTo(DHLCoordinates coords) async {
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    controller.moveAndRotate(
        LatLng(currentPosition.latitude, currentPosition.longitude),
        widget.currentZoom,
        0.0);
  }

  @override
  void updateHighlightedRouteSections({bool force = false}) async {
    int maxPins = 300;

    markers.clear();

    for (int i = widget.routeSectionCursor + maxPins;
        i >= widget.routeSectionCursor;
        i--) {
      if (i < 0 || i >= widget.parcelNumberPins.length) continue;

      DestinationPin pin = widget.parcelNumberPins.elementAt(i);
      Color color = Color.fromARGB(200, 0, 144, 138);
      if (i == widget.routeSectionCursor)
        color = Color.fromARGB(199, 143, 8, 31);
      if (i == widget.routeSectionCursor + 1)
        color = Color.fromARGB(197, 13, 36, 241);
      if (destinationPinIsInBlacklist(widget.parcelNumberPins[i])) {
        color = Color.fromRGBO(143, 8, 31, 0.78);
      }

      if (!shouldDoublePlannedAddressBeVisible(pin)) {
        continue;
      }

      markers.add(FlutterMap.Marker(
          point: LatLng(pin.coords.lattitude, pin.coords.longitude),
          width: 80,
          height: 34,
          builder: (ctx) => OverflowBox(
                child: Row(
                  children: [
                    createPin(pin, color,
                        isDoublePlannedAddress: pin.isDoublePlannedAddress),
                    Expanded(
                      child: Text(''),
                    ),
                  ],
                ),
              )));
    }

    setState(() {});
  }
}
