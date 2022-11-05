import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/mapview.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/RoutingExample.dart';
import 'package:training_planner/events/MapPanningEvent.dart';
import 'package:training_planner/events/NextStopLoadedEvent.dart';
import 'package:training_planner/events/StopCompletedEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/style/style.dart';
import 'package:training_planner/utils/date.dart';
import 'package:training_planner/widgets/agenda_week.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:here_sdk/core.dart';
import 'package:here_sdk/core.engine.dart';
import 'package:here_sdk/core.errors.dart';
import 'package:here_sdk/mapview.dart';

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();

  const NavigationPage({Key? key}) : super(key: key);
}

class _NavigationPageState extends State<NavigationPage> {
  RoutingExample? _routingExample;
  StreamSubscription? panGestureEvent;
  StreamSubscription? taskLoadedEvent;
  ActiveTask? activeTask;

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location services are disabled. Please enable the services')));
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')));
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Location permissions are permanently denied, we cannot request permissions.')));
      return false;
    }
    return true;
  }

  @override
  initState() {
    super.initState();

    _handleLocationPermission();

    panGestureEvent = eventBus.on<MapPanningEvent>().listen((event) {
      changeIsLookingAround(event.isPanning);
    });

    taskLoadedEvent = eventBus.on<NextStopLoadedEvent>().listen((event) {
      setState(() {});
    });
  }

  void changeIsLookingAround(bool val) {
    setState(() {
      _routingExample?.isLookingAround = val;
    });
  }

  void _zoomIn() {
    _routingExample?.changeZoom(_routingExample!.currentZoom + 1);
  }

  void _zoomOut() {
    _routingExample?.changeZoom(_routingExample!.currentZoom - 1);
  }

  void _mockStopComplete() {
    eventBus.fire(StopCompletedEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FloatingActionButton(
                onPressed: () => _mockStopComplete(),
                child: Icon(Icons.check_circle),
              ),
              Visibility(
                visible: _routingExample == null
                    ? false
                    : _routingExample!.isLookingAround,
                child: FloatingActionButton(
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.center_focus_strong),
                  onPressed: () => {
                    changeIsLookingAround(false),
                    _routingExample?.flyTo(_routingExample!.lastPosition)
                  },
                ),
              ),
              Padding(padding: EdgeInsets.all(5)),
              FloatingActionButton(
                onPressed: () => _zoomOut(),
                child: Icon(Icons.zoom_out),
              ),
              Padding(padding: EdgeInsets.all(2)),
              FloatingActionButton(
                onPressed: () => _zoomIn(),
                child: Icon(Icons.zoom_in),
              )
            ],
          ),
        ),
        body: Column(
          children: [
            _createNextDropInfoWidget(),
            Container(
              decoration: BoxDecoration(color: Colors.black),
              height: 2,
            ),
            Expanded(child: HereMap(onMapCreated: _onMapCreated)),
          ],
        ));
  }

  Widget _createNextDropInfoWidget() {
    if (_routingExample == null) return Padding(padding: EdgeInsets.all(0));

    return Container(
      decoration: BoxDecoration(color: Colors.white),
      height: 80,
      child: Column(
        children: [
          SizedBox(
            height: 10,
          ),
          Container(
            height: 50,
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: <TextSpan>[
                      TextSpan(
                        text: '[' +
                            _routingExample!.activeTask.firstParcelNumber
                                .toString() +
                            ' - ' +
                            _routingExample!.activeTask.lastParcelNumber
                                .toString() +
                            '',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 25,
                        ),
                      ),
                      TextSpan(
                        text: ' ' +
                            (_routingExample!.activeTask.lastParcelNumber -
                                    _routingExample!
                                        .activeTask.firstParcelNumber +
                                    1)
                                .toString(),
                        style: TextStyle(
                          color: Color.fromARGB(150, 0, 0, 0),
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: ']',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 25,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(padding: EdgeInsets.all(5)),
                Expanded(
                  child: Text(
                    _routingExample!.activeTask.fullAddress,
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 20,
            padding: EdgeInsets.only(left: 10, right: 10),
            child: Row(children: [
              Text(_routingExample!.activeTask.deliveryTimeBlock)
            ]),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError? error) {
      if (error == null) {
        _routingExample = RoutingExample(hereMapController);
        routeProvider.getRoute(0).then((value) {
          _routingExample?.addRoute(value);
        });
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  @override
  void dispose() {
    // Free HERE SDK resources before the application shuts down.
    //SDKNativeEngine.sharedInstance?.dispose();
    //SdkContext.release();
    panGestureEvent?.cancel();
    taskLoadedEvent?.cancel();
    _routingExample?.destroy();
    super.dispose();
  }
}
