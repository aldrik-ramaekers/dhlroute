import 'dart:async';
import 'package:flutter/material.dart';
import 'package:training_planner/events/NextStopLoadedEvent.dart';
import 'package:training_planner/events/StopCompletedEvent.dart';
import 'package:training_planner/main.dart';

import '../route.dart' as DHLRoute;
import 'package:training_planner/services/iblacklist_provider_service.dart';

class DestinationPin {
  final String text;
  final int sequenceNumber;
  final DHLCoordinates coords;
  final String? postalcodeNumeric;
  final String? postalcodeAlpha;
  final String? houseNumberWithExtra;
  dynamic pin; // however the map source defines a pin.
  bool isDoublePlannedAddress;

  DestinationPin(
      {this.text = '',
      required this.coords,
      required this.sequenceNumber,
      required this.isDoublePlannedAddress,
      required this.postalcodeNumeric,
      required this.postalcodeAlpha,
      required this.houseNumberWithExtra});
}

class DHLCoordinates {
  double lattitude;
  double longitude;

  DHLCoordinates(this.lattitude, this.longitude);

  bool compare(DHLCoordinates other) {
    return other.lattitude == lattitude && other.longitude == longitude;
  }
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

abstract class BaseNavigation extends StatefulWidget {
  bool doneLoading = false;
  Timer? timer;
  bool isLookingAround = false;
  double currentZoom = 20;
  DHLCoordinates lastPosition = DHLCoordinates(0, 0);

  StreamSubscription? stopCompletedEvent;
  StreamSubscription? stopIncompletedEvent;

  List<ActiveTask> allTasks = [];
  List<BlacklistEntry> blacklist = [];
  List<DestinationPin> parcelNumberPins = [];
  List<DHLCoordinates> destinationCoords = [];
  final DHLRoute.Route route;

  BaseNavigation({Key? key, required this.route}) : super(key: key);
}

abstract class BaseNavigationState extends State<BaseNavigation> {
  int routeSectionCursor = 0;

  StreamSubscription? changeZoomEvent;
  StreamSubscription? flyToEvent;

  BaseNavigationState() {
    changeZoomEvent = eventBus.on<ChangeZoomEvent>().listen((event) {
      changeZoom(event.zoom);
    });

    flyToEvent = eventBus.on<FlyToEvent>().listen((event) {
      flyTo(event.coords);
    });
  }

  void flyTo(DHLCoordinates coords);
  void changeZoom(double newVal);
  Future<void> addRoute(DHLRoute.Route route);
  void updateHighlightedRouteSections({bool force = false});
  dynamic createPinWidget(
      DestinationPin pin, Color color, DHLCoordinates coords);

  Widget createPin(DestinationPin pin, Color backgroundColor,
      {bool isDoublePlannedAddress = false}) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        shape: BoxShape.rectangle,
        border: Border.all(
            color: isDoublePlannedAddress
                ? Color.fromARGB(255, 255, 0, 0)
                : Color.fromARGB(0, 0, 0, 0),
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

  bool isAddressDoublePlanned(DestinationPin taskToCheck) {
    for (final item in widget.parcelNumberPins) {
      if (item == taskToCheck) continue;
      if (item.coords.compare(taskToCheck.coords)) return true;
    }

    return false;
  }

  // if address is double planned and there is a stop before this one.
  bool shouldDoublePlannedAddressBeVisible(DestinationPin taskToCheck) {
    if (!taskToCheck.isDoublePlannedAddress) return true;
    for (int i = routeSectionCursor; i < widget.parcelNumberPins.length; i++) {
      var item = widget.parcelNumberPins[i];

      if (item == taskToCheck) {
        return true; // first one of the double planned addresses is visible.
      }
      if (item.coords.compare(taskToCheck.coords)) {
        return false;
      }
    }

    return true;
  }

  DHLRoute.Task findTaskWithLowestSequenceNumberInGroup(
      DHLRoute.Route route, List<String> groupPids) {
    List<DHLRoute.Task> tasksFound = [];

    for (final item in route.tasks!) {
      if (groupPids.contains(item.pid)) tasksFound.add(item);
    }

    tasksFound.sort((e1, e2) => int.parse(e1.deliverySequenceNumber!)
        .compareTo(int.parse(e2.deliverySequenceNumber!)));
    return tasksFound.first;
  }

  bool destinationPinIsInBlacklist(DestinationPin pin) {
    try {
      for (int i = 0; i < widget.blacklist.length; i++) {
        if (pin.postalcodeNumeric == widget.blacklist[i].postalcodeNumeric &&
            pin.postalcodeAlpha!.toLowerCase() ==
                widget.blacklist[i].postalcodeAplha &&
            pin.houseNumberWithExtra!.toLowerCase() ==
                (widget.blacklist[i].houseNumber.toString() +
                    widget.blacklist[i].houseNumberExtra.toLowerCase())) {
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void destroyNavigation() {
    widget.stopCompletedEvent?.cancel();
    widget.stopIncompletedEvent?.cancel();
    changeZoomEvent?.cancel();
    flyToEvent?.cancel();
    widget.timer?.cancel();
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

  void groupTasksIntoGroups(DHLRoute.Route route) {
    bool isFirst = true;
    for (final item in route.tasks!) {
      //debugPrint(item.deliverySequenceNumber.toString());

      if (item.addressLatitude == null || item.addressLongitude == null) {
        // Skip adressen die fout zijn ingegeven.
        // Hier moeten we nog iets voor vinden om bestuurder te laten weten
        continue;
      }

      var destinationGeoCoordinates = DHLCoordinates(
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

      widget.parcelNumberPins.add(
        DestinationPin(
            sequenceNumber: int.parse(item.deliverySequenceNumber!),
            text: item.deliverySequenceNumber.toString() +
                ' = ' +
                item.houseNumber! +
                (item.houseNumberAddition != null
                    ? item.houseNumberAddition!
                    : ''),
            coords: DHLCoordinates(destinationGeoCoordinates.lattitude,
                destinationGeoCoordinates.longitude),
            isDoublePlannedAddress: false,
            postalcodeNumeric: item.postalCodeNumeric,
            postalcodeAlpha: item.postalCodeAlpha,
            houseNumberWithExtra:
                item.houseNumber! + (item.houseNumberAddition ?? '')),
      );
      widget.destinationCoords.add(destinationGeoCoordinates);

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
      widget.allTasks.add(groupedTask);
    }
  }
}
