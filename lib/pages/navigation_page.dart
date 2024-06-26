import 'dart:async';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/services.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:training_planner/navigation/HERENavigation.dart';
import 'package:training_planner/navigation/baseNavigation.dart';
import 'package:training_planner/navigation/openstreetmapNavigation.dart';
import 'package:training_planner/route.dart' as DHLRoute;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:here_sdk/mapview.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/RoutingExample.dart';
import 'package:training_planner/events/MapPanningEvent.dart';
import 'package:training_planner/events/NextStopLoadedEvent.dart';
import 'package:training_planner/events/RouteLoadedEvent.dart';
import 'package:training_planner/events/StopCompletedEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/style/style.dart';
import 'package:wakelock/wakelock.dart';

class NavigationPage extends StatefulWidget {
  @override
  _NavigationPageState createState() => _NavigationPageState();
  final DHLRoute.Route route;

  const NavigationPage({Key? key, required this.route}) : super(key: key);
}

class _NavigationPageState extends State<NavigationPage> {
  //RoutingExample? _routingExample;
  BaseNavigation? navigation;
  StreamSubscription? panGestureEvent;
  StreamSubscription? taskLoadedEvent;
  ActiveTask? activeTask = ActiveTask(1, "", 1, "", false, false);

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

    SystemChrome.setPreferredOrientations([]);
    Wakelock.enable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    AutoOrientation.portraitDownMode();

    _handleLocationPermission();

    panGestureEvent = eventBus.on<MapPanningEvent>().listen((event) {
      changeIsLookingAround(event.isPanning);
    });

    taskLoadedEvent = eventBus.on<NextStopLoadedEvent>().listen((event) {
      setState(() {
        activeTask = event.task;
      });
    });
  }

  void changeIsLookingAround(bool val) {
    setState(() {
      navigation?.isLookingAround = val;
    });
  }

  void _zoomIn() {
    eventBus.fire(ChangeZoomEvent(navigation!.currentZoom + 1));
  }

  void _zoomOut() {
    eventBus.fire(ChangeZoomEvent(navigation!.currentZoom - 1));
  }

  void _mockStopComplete() {
    eventBus.fire(StopCompletedEvent());
  }

  void _mockStopInComplete() {
    eventBus.fire(StopIncompletedEvent());
  }

  Future<bool> showExitPopup() async {
    return await showDialog(
          //show confirm dialogue
          //the return value will be from "Yes" or "No" options
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Terug'),
            content: Text('Terug naar vorig scherm?'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(false),
                //return false when click on "NO"
                child: Text('Nee'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                //return true when click on "Yes"
                child: Text('Ja'),
              ),
            ],
          ),
        ) ??
        false; //if showDialouge had returned null, then return false
  }

  @override
  Widget build(BuildContext context) {
    if (navigation == null) {
      navigation = HERENavigation(route: widget.route);
    }

    return WillPopScope(
      onWillPop: showExitPopup, //call function on back button press
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              InkWell(
                splashColor: Colors.blue,
                onLongPress: () => _mockStopInComplete(),
                child: FloatingActionButton(
                  heroTag: 'xx6',
                  onPressed: () => _mockStopComplete(),
                  child: Icon(Icons.check_circle),
                ),
              ),
              Visibility(
                visible:
                    navigation == null ? false : navigation!.isLookingAround,
                child: FloatingActionButton(
                  heroTag: 'xx7',
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.center_focus_strong),
                  onPressed: () => {
                    changeIsLookingAround(false),
                    eventBus.fire(FlyToEvent(navigation!.lastPosition))
                  },
                ),
              ),
              Padding(padding: EdgeInsets.all(5)),
              FloatingActionButton(
                heroTag: 'xx8',
                onPressed: () => _zoomOut(),
                child: Icon(Icons.zoom_out),
              ),
              Padding(padding: EdgeInsets.all(2)),
              FloatingActionButton(
                heroTag: 'xx9',
                onPressed: () => _zoomIn(),
                child: Icon(Icons.zoom_in),
              ),
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
            Expanded(
              child: Stack(
                children: [navigation!],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getLoadingScreen() {
    return LoadingAnimationWidget.flickr(
      leftDotColor: Style.titleColor,
      rightDotColor: Style.background,
      size: MediaQuery.of(context).size.width / 4,
    );
  }

  Widget _createNextDropInfoWidget() {
    if (navigation == null) return Padding(padding: EdgeInsets.all(0));

    return Container(
      decoration: BoxDecoration(color: Colors.white),
      height: 60,
      child: Column(
        children: [
          SizedBox(
            height: 5,
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
                            activeTask!.firstParcelNumber.toString() +
                            ' - ' +
                            activeTask!.lastParcelNumber.toString() +
                            '',
                        style: TextStyle(
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontSize: 25,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' ' + (activeTask!.getNumberOfPercels()).toString(),
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
                    activeTask!.fullAddress,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    panGestureEvent?.cancel();
    taskLoadedEvent?.cancel();
    Wakelock.disable();
    AutoOrientation.portraitUpMode();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }
}
