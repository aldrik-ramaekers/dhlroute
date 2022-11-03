import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/mapview.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/RoutingExample.dart';
import 'package:training_planner/events/MapPanningEvent.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
            FloatingActionButton(
              onPressed: () => _zoomIn(),
              child: Icon(Icons.zoom_in),
            )
          ],
        ),
      ),
      body: Stack(
        children: [
          HereMap(onMapCreated: _onMapCreated),
        ],
      ),
    );
  }

  void _onMapCreated(HereMapController hereMapController) {
    hereMapController.mapScene.loadSceneForMapScheme(MapScheme.normalDay,
        (MapError? error) {
      if (error == null) {
        _routingExample = RoutingExample(hereMapController);
        _routingExample?.addRoute();
      } else {
        print("Map scene not loaded. MapError: " + error.toString());
      }
    });
  }

  @override
  void dispose() {
    // Free HERE SDK resources before the application shuts down.
    SDKNativeEngine.sharedInstance?.dispose();
    SdkContext.release();
    panGestureEvent?.cancel();

    _routingExample?.timer?.cancel();
    super.dispose();
  }

  // A helper method to show a dialog.
  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
