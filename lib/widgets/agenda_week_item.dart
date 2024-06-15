import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/utils/date.dart';
import '../style/style.dart';

class AgendaWeekItem extends StatefulWidget {
  final Shift shift;
  final Function updateParent;

  const AgendaWeekItem({
    Key? key,
    required this.shift,
    required this.updateParent,
  }) : super(key: key);

  @override
  _ExerciseEntryState createState() => _ExerciseEntryState();
}

class _ExerciseEntryState extends State<AgendaWeekItem> {
  String shiftTypeName = '';
  String shiftTime = '';
  String shiftTimeEnd = '';
  bool canUseLocalAuth = false;

  Future<void> _showOngoingNotification() async {
    if (widget.shift.isDone()) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('sussymogus', 'Actieve Sessie',
            channelDescription: 'poopies',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: 'dhl',
            channelAction: AndroidNotificationChannelAction.update);
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        0, 'Sessie actief', 'hallo', platformChannelSpecifics,
        payload: 'item x');
  }

  void initState() {
    super.initState();

    localAuthService.canCheckBiometrics.then((bio) => {
          localAuthService
              .isDeviceSupported()
              .then((supported) => {canUseLocalAuth = bio && supported})
        });

    setState(() {
      shiftTypeName = widget.shift.type;
      setStartAndEndTime();
    });
  }

  void setStartAndEndTime() {
    shiftTime =
        "${widget.shift.start.hour.toString().padLeft(2, '0')}:${widget.shift.start.minute.toString().padLeft(2, '0')}";

    DateTime? expectedEndTime = widget.shift.expectedEndTime();
    if (widget.shift.isDone()) {
      expectedEndTime = widget.shift.end;
    }

    shiftTimeEnd = ' - ' +
        "${expectedEndTime?.hour.toString().padLeft(2, '0')}:${expectedEndTime?.minute.toString().padLeft(2, '0')}";
  }

  Timer? updateNotificationTimer;
  void showNotificationForActiveSession() {
    _showOngoingNotification();
    updateNotificationTimer = Timer.periodic(
        Duration(seconds: 10), (Timer t) => _showOngoingNotification());
  }

  void stopNotificationForActiveSession() {
    updateNotificationTimer?.cancel();
    flutterLocalNotificationsPlugin.cancelAll();
  }

  Widget createStartShiftButton() {
    return TextButton(
        onPressed: () => {
              setState(() {
                widget.shift.setIsActive(true);
                shiftProvider.updateShift(widget.shift);
                setStartAndEndTime();
                showNotificationForActiveSession();
              })
            },
        child: Text('Begin'));
  }

  Widget createStopShiftButton() {
    return TextButton(
        onPressed: () {
          if (canUseLocalAuth) {
            localAuthService
                .authenticate(
                    localizedReason: 'Weet je zeker dat je wilt eindigen?')
                .then((value) => {
                      if (value && mounted)
                        {
                          setState(() {
                            widget.shift.setIsActive(false);
                            shiftProvider.updateShift(widget.shift);
                            stopNotificationForActiveSession();
                          })
                        }
                    })
                .catchError((f) => {});
          } else {
            setState(() {
              widget.shift.setIsActive(false);
              shiftProvider.updateShift(widget.shift);
              stopNotificationForActiveSession();
            });
          }
        },
        child: Text('Einde'));
  }

  Future requestStartAndEndTimeForShift() async {
    bool alsoAskForEndTime =
        widget.shift.getShiftStatus() == ShiftStatus.OldOpen ||
            widget.shift.getShiftStatus() == ShiftStatus.Closed ||
            widget.shift.canStart();

    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      helpText: 'Begin tijd',
      initialTime: TimeOfDay(
          hour: widget.shift.start.hour, minute: widget.shift.start.minute),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (startTime == null) {
      return;
    }

    if (alsoAskForEndTime) {
      final TimeOfDay? endTime = await showTimePicker(
        context: context,
        helpText: 'Eind tijd',
        initialTime: TimeOfDay(
            hour: widget.shift.expectedEndTime().hour,
            minute: widget.shift.expectedEndTime().minute),
        initialEntryMode: TimePickerEntryMode.input,
      );

      if (endTime == null) {
        return;
      }

      widget.shift.end = DateTime(
          widget.shift.start.year,
          widget.shift.start.month,
          widget.shift.start.day,
          endTime.hour,
          endTime.minute);
    }

    widget.shift.start = DateTime(
        widget.shift.start.year,
        widget.shift.start.month,
        widget.shift.start.day,
        startTime.hour,
        startTime.minute);

    await shiftProvider.updateShift(widget.shift);
  }

  Widget createCompleteOldShiftButton() {
    return TextButton(
        onPressed: () => {
              requestStartAndEndTimeForShift().then((e) => {setState(() {})})
            },
        child: Text('Invullen'));
  }

  Widget createOldShiftInfoText() {
    final p = widget.shift.getElapsedSessionTime();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text("${p.inHours}h ${p.inMinutes.remainder(60)}m"),
        Text(
          '€' + widget.shift.getEarnedMoney().toStringAsFixed(2),
        ),
      ],
    );
  }

  Widget createShiftModifyButton() {
    if (!widget.shift.getIsActive() && widget.shift.canStart()) {
      return createStartShiftButton();
    } else if (widget.shift.getIsActive()) {
      return createStopShiftButton();
    } else if (widget.shift.shiftIsOpenButBeforeToday()) {
      return createCompleteOldShiftButton();
    } else if (widget.shift.isDone()) {
      return createOldShiftInfoText();
    }

    return Padding(padding: const EdgeInsets.all(0));
  }

  void showDeleteShiftModal() {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Terug"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Verwijderen"),
      onPressed: () async {
        await shiftProvider.deleteShift(widget.shift);
        Navigator.pop(context);
        widget.updateParent();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Verwijderen"),
      content: Text("Werktijd verwijderen uit schema?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget startShiftWidget = createShiftModifyButton();
    TextStyle endDateTextStyle = TextStyle(color: Style.listEntryStandardColor);

    if (!widget.shift.isDone()) {
      endDateTextStyle = TextStyle(color: Style.listEntryTransparentColor);
    }

    setStartAndEndTime();

    double widthOfItem = MediaQuery.of(context).size.width - 20;
    double heightOfItem = 48;
    double widthOfIcon = 32;
    double widthOfWeekday = 45;
    double widthOfDates = 95;
    double widthOfAction = 90;

    double remaining = widthOfItem -
        widthOfIcon -
        widthOfWeekday -
        widthOfDates -
        widthOfAction -
        20; // padding
    double widthOfShiftType = remaining;

    Widget shiftData = Container(
        child: Text(
          '| ',
        ),
        width: widthOfShiftType);
    if (widthOfShiftType < 50) {
      shiftData = Padding(padding: const EdgeInsets.all(0));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
      child: Container(
        decoration: const BoxDecoration(
            color: Style.listEntryBackground,
            borderRadius: BorderRadius.all(Radius.circular(8))),
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: widthOfItem,
                height: heightOfItem,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                padding: EdgeInsets.all(0),
                child: Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Row(
                    children: [
                      GestureDetector(
                        onLongPress: () {
                          showDeleteShiftModal();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                              color: widget.shift.getStatusColor(),
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8))),
                          height: heightOfItem,
                          width: widthOfIcon,
                          child: widget.shift.getStatusIcon(),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              DateHelper.getWeekdayName(
                                  widget.shift.start.weekday),
                              style: Style.listItemTitletextBold,
                            ),
                            Text(
                              "${widget.shift.start.day.toString().padLeft(2, '0')}e",
                            ),
                          ],
                        ),
                        width: widthOfWeekday,
                      ),
                      GestureDetector(
                        onLongPress: () {
                          requestStartAndEndTimeForShift()
                              .then((e) => {if (mounted) setState(() {})});
                        },
                        child: Container(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Style.listEntryStandardColor),
                              children: [
                                TextSpan(text: ' | ' + shiftTime),
                                TextSpan(
                                    text: shiftTimeEnd, style: endDateTextStyle)
                              ],
                            ),
                          ),
                          width: widthOfDates,
                        ),
                      ),
                      shiftData,
                      Container(
                        child: Align(
                          child: startShiftWidget,
                          alignment: Alignment.centerRight,
                        ),
                        width: widthOfAction,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
