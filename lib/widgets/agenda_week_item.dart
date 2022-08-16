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
  const AgendaWeekItem({
    Key? key,
    required this.shift,
  }) : super(key: key);

  @override
  _ExerciseEntryState createState() => _ExerciseEntryState();
}

class _ExerciseEntryState extends State<AgendaWeekItem> {
  String shiftTypeName = '';
  String shiftTime = '';
  String shiftTimeEnd = '';
  bool canUseLocalAuth = false;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _showOngoingNotification() async {
    if (widget.shift.isDone()) return;

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('channel_1', 'Actieve Sessie',
            channelDescription: '3:45 => \$50',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            icon: 'dhl',
            showProgress: true,
            onlyAlertOnce: true,
            maxProgress: 100,
            channelAction: AndroidNotificationChannelAction.update,
            progress: widget.shift.getPercentage(),
            color: Style.background,
            autoCancel: false);
    NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    String elapsedTime =
        "${widget.shift.getElapsedSessionTime().inHours.toString().padLeft(2, '0')}:${(widget.shift.getElapsedSessionTime().inMinutes % 60).toString().padLeft(2, '0')}";

    await flutterLocalNotificationsPlugin.show(
        0,
        'Sessie actief',
        '⏱ ' +
            elapsedTime +
            ' => €' +
            widget.shift.getMoneyForActiveSession().toStringAsFixed(2),
        platformChannelSpecifics);
  }

  void initState() {
    super.initState();

    auth.canCheckBiometrics.then((bio) => {
          auth
              .isDeviceSupported()
              .then((supported) => {canUseLocalAuth = bio && supported})
        });

    setState(() {
      switch (widget.shift.type) {
        case ShiftType.Avondrit:
          shiftTypeName = 'Avondrit';
          break;
        case ShiftType.Dagrit:
          shiftTypeName = 'Dagrit';
          break;
        case ShiftType.Terugscannen:
          shiftTypeName = 'Terugscannen';
          break;
      }

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
          auth
              .authenticate(
                  localizedReason: 'Weet je zeker dat je wilt eindigen?')
              .then((value) => {
                    if (value)
                      {
                        setState(() {
                          widget.shift.setIsActive(false);
                          shiftProvider.updateShift(widget.shift);
                          stopNotificationForActiveSession();
                        })
                      }
                  })
              .catchError((f) => {});
        },
        child: Text('Einde'));
  }

  Future requestStartAndEndTimeForShift() async {
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

    widget.shift.start = DateTime(
        widget.shift.start.year,
        widget.shift.start.month,
        widget.shift.start.day,
        startTime.hour,
        startTime.minute);

    widget.shift.end = DateTime(
        widget.shift.start.year,
        widget.shift.start.month,
        widget.shift.start.day,
        endTime.hour,
        endTime.minute);

    shiftProvider.updateShift(widget.shift);
  }

  Widget createCompleteOldShiftButton() {
    return TextButton(
        onPressed: () => {
              requestStartAndEndTimeForShift().then((e) => {setState(() {})})
            },
        child: Text('Invullen'));
  }

  Widget createShiftModifyButton() {
    if (!widget.shift.getIsActive() && widget.shift.canStart()) {
      return createStartShiftButton();
    } else if (widget.shift.getIsActive()) {
      return createStopShiftButton();
    } else if (widget.shift.shiftIsOpenButBeforeToday()) {
      return createCompleteOldShiftButton();
    }

    return Padding(padding: const EdgeInsets.all(0));
  }

  @override
  Widget build(BuildContext context) {
    Widget startShiftWidget = createShiftModifyButton();
    TextStyle endDateTextStyle = TextStyle(color: Colors.black);

    if (!widget.shift.isDone()) {
      endDateTextStyle = TextStyle(color: Color.fromARGB(80, 0, 0, 0));
    }

    setStartAndEndTime();

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
                width: double.infinity,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                padding: EdgeInsets.all(0),
                child: Padding(
                  padding: EdgeInsets.only(right: 5),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: widget.shift.getStatusColor(),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8))),
                        height: 48.0,
                        width: 32.0,
                        child: widget.shift.getStatusIcon(),
                      ),
                      Container(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          DateHelper.getWeekdayName(widget.shift.start.weekday),
                          style: Style.listItemTitletextBold,
                        ),
                        width: 35,
                      ),
                      Container(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black),
                            children: [
                              TextSpan(text: ' | ' + shiftTime),
                              TextSpan(
                                  text: shiftTimeEnd, style: endDateTextStyle)
                            ],
                          ),
                        ),
                        width: 95,
                      ),
                      Container(
                        child: Text(
                          '| ' + shiftTypeName,
                        ),
                        width: 100,
                      ),
                      startShiftWidget,
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
