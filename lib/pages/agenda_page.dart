import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:training_planner/config/defaults.dart';
import 'package:training_planner/events/RefreshWeekEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/pages/home_page.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/style/style.dart';
import 'package:training_planner/utils/date.dart';
import 'package:training_planner/widgets/agenda_week.dart';

class AgendaPage extends StatefulWidget {
  final int agendaWeekNr;

  @override
  _AgendaPageState createState() => _AgendaPageState();

  const AgendaPage({Key? key, required this.agendaWeekNr}) : super(key: key);
}

class _AgendaPageState extends State<AgendaPage> {
  int currentSelectedPageIndex = 0;

  @override
  initState() {
    super.initState();
    currentSelectedPageIndex = getStartPageIndex();
  }

  Future<void> addShiftsFromDialog() async {
    DateTime startDate = getWeek(currentSelectedPageIndex).mondayOfWeek;

    for (int i = 0; i < 7; i++) {
      DateTime dayOfWeek = startDate;
      if (!dayIsSelected[i]) continue;

      switch (i) {
        case 0:
          dayOfWeek = startDate.add(Duration(days: 0));
          break;
        case 1:
          dayOfWeek = startDate.add(Duration(days: 1));
          break;
        case 2:
          dayOfWeek = startDate.add(Duration(days: 2));
          break;
        case 3:
          dayOfWeek = startDate.add(Duration(days: 3));
          break;
        case 4:
          dayOfWeek = startDate.add(Duration(days: 4));
          break;
        case 5:
          dayOfWeek = startDate.add(Duration(days: 5));
          break;
        case 6:
          dayOfWeek = startDate.add(Duration(days: 6));
          break;
      }

      ShiftType type = DefaultConfig.shiftTypes[currentSelectedShiftIndex];
      dayOfWeek = dayOfWeek.add(
          dayOfWeek.weekday != 6 ? type.startTime : type.startTimeSaturday);

      Settings settings = await settingsService.readSettingsFromFile();

      bool success = await shiftProvider.addShift(
          Shift(start: dayOfWeek, type: type.name, payRate: settings.salary));
      if (!success) {
        messageService.showMessage(
            context,
            '\'' +
                DateHelper.getWeekdayNameFull(dayOfWeek.weekday) +
                '\' is al ingepland');
      }
    }
  }

  List<bool> dayIsSelected = [false, false, false, false, false, false, false];
  List<bool> shiftsSelected =
      DefaultConfig.shiftTypes.map((e) => false).toList();
  int currentSelectedShiftIndex = 0;

  Future<void> showAddShiftDialog() async {
    dayIsSelected = [false, false, false, false, false, false, false];
    shiftsSelected = DefaultConfig.shiftTypes.map((e) => false).toList();
    currentSelectedShiftIndex = 1;

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Terug"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Ok"),
      onPressed: () async {
        await addShiftsFromDialog();
        Navigator.pop(context);
      },
    );

    double availableHeight = MediaQuery.of(context).size.height;
    bool splitDays = false;
    if (availableHeight < 640) {
      splitDays = true;
    }

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Wanneer wil je werken?"),
            content: Row(children: [
              !splitDays
                  ? (ToggleButtons(
                      direction: Axis.vertical,
                      children: [1, 2, 3, 4, 5, 6, 7]
                          .map((weekdayIndex) =>
                              Text(DateHelper.getWeekdayName(weekdayIndex)))
                          .toList(),
                      onPressed: (int index) {
                        setState(() {
                          dayIsSelected[index] = !dayIsSelected[index];
                        });
                      },
                      isSelected: dayIsSelected,
                    ))
                  : (ToggleButtons(
                      direction: Axis.vertical,
                      children: [1, 2, 3, 4]
                          .map((weekdayIndex) =>
                              Text(DateHelper.getWeekdayName(weekdayIndex)))
                          .toList(),
                      onPressed: (int index) {
                        setState(() {
                          dayIsSelected[index] = !dayIsSelected[index];
                        });
                      },
                      isSelected: dayIsSelected.getRange(0, 4).toList(),
                    )),
              splitDays
                  ? (ToggleButtons(
                      direction: Axis.vertical,
                      children: [5, 6, 7]
                          .map((weekdayIndex) =>
                              Text(DateHelper.getWeekdayName(weekdayIndex)))
                          .toList(),
                      onPressed: (int index) {
                        setState(() {
                          dayIsSelected[index + 4] = !dayIsSelected[index + 4];
                        });
                      },
                      isSelected: dayIsSelected.getRange(4, 7).toList(),
                    ))
                  : (Padding(padding: const EdgeInsets.all(20))),
              ToggleButtons(
                direction: Axis.vertical,
                children: <Widget>[
                  for (int i = 0; i < DefaultConfig.shiftTypes.length; i++)
                    Padding(
                        padding: const EdgeInsets.all(0),
                        child: Text(DefaultConfig.shiftTypes[i].name)),
                ],
                onPressed: (int index) {
                  setState(() {
                    shiftsSelected =
                        DefaultConfig.shiftTypes.map((e) => false).toList();
                    shiftsSelected[index] = true;
                    currentSelectedShiftIndex = index;
                  });
                },
                isSelected: shiftsSelected,
              ),
            ]),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
      },
    );
  }

  DateTime getStartWeek() {
    return DateTime(2000, 1, 1);
  }

  int getStartPageIndex() {
    if (widget.agendaWeekNr != 0) return widget.agendaWeekNr;
    Duration diff = DateTime.now().difference(getStartWeek());
    int index = diff.inDays ~/ 7;

    if (getWeek(index).mondayOfWeek !=
        DateUtilities.DateUtils.firstDayOfWeek(DateTime.now())) {
      return index + 1;
    }
    return index;
  }

  int getMaxNumberOfWeeksToDisplay() {
    DateTime start = getStartWeek();
    DateTime end = DateTime.now().add(Duration(days: 365));

    return end.difference(start).inDays ~/ 7;
  }

  AgendaWeek getWeek(int index) {
    DateTime weekday = getStartWeek().add(Duration(days: index * 7));
    DateTime mondayOfWeek = DateUtilities.DateUtils.firstDayOfWeek(weekday);
    DateTime mondayOfCurrentWeek =
        DateUtilities.DateUtils.firstDayOfWeek(DateTime.now());

    return AgendaWeek(
      weekNr: DateUtilities.DateUtils.getWeekNumber(mondayOfWeek),
      mondayOfWeek: mondayOfWeek,
      isCurrentWeek:
          DateUtilities.DateUtils.isSameDay(mondayOfWeek, mondayOfCurrentWeek),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: CarouselSlider.builder(
          options: CarouselOptions(
            onPageChanged: (index, _) {
              currentSelectedPageIndex = index;
            },
            height: MediaQuery.of(context).size.height - 163,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: false,
            initialPage: getStartPageIndex(), // Week nr
          ),
          itemCount: getMaxNumberOfWeeksToDisplay(),
          itemBuilder: (context, index, realIndex) => getWeek(index),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showAddShiftDialog();
          eventBus.fire(RefreshWeekEvent());
        },
        backgroundColor: Style.titleColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
