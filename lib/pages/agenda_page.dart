import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:training_planner/events/RefreshWeekEvent.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/pages/home_page.dart';
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
    String dropdownValue = 'Maandag';

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

      ShiftType type = ShiftType.Dagrit;
      if (shiftsSelected[1]) type = ShiftType.Avondrit;
      if (shiftsSelected[2]) type = ShiftType.Terugscannen;

      switch (type) {
        case ShiftType.Dagrit:
          dayOfWeek = dayOfWeek.add(Duration(hours: 10));
          break;
        case ShiftType.Avondrit:
          dayOfWeek = dayOfWeek.add(Duration(
              hours: dayOfWeek.weekday == 6 ? 15 : 17,
              minutes: dayOfWeek.weekday == 6 ? 30 : 0));
          break;
        case ShiftType.Terugscannen:
          dayOfWeek = dayOfWeek.add(
              Duration(hours: dayOfWeek.weekday == 6 ? 13 : 14, minutes: 30));
          break;
      }

      bool success =
          await shiftProvider.addShift(Shift(start: dayOfWeek, type: type));
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
  List<bool> shiftsSelected = [false, true, false];

  Future<void> showAddShiftDialog() async {
    dayIsSelected = [false, false, false, false, false, false, false];
    shiftsSelected = [false, true, false];

    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Terug"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = FlatButton(
      child: Text("Ok"),
      onPressed: () async {
        await addShiftsFromDialog();
        Navigator.pop(context);
      },
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Wanneer wil je werken?"),
            content: Row(children: [
              ToggleButtons(
                direction: Axis.vertical,
                children: <Widget>[
                  Padding(padding: const EdgeInsets.all(15), child: Text('Ma')),
                  Padding(padding: const EdgeInsets.all(15), child: Text('Di')),
                  Padding(padding: const EdgeInsets.all(15), child: Text('Wo')),
                  Padding(padding: const EdgeInsets.all(15), child: Text('Do')),
                  Padding(padding: const EdgeInsets.all(15), child: Text('Vr')),
                  Padding(padding: const EdgeInsets.all(15), child: Text('Za')),
                  Padding(padding: const EdgeInsets.all(15), child: Text('Zo')),
                ],
                onPressed: (int index) {
                  setState(() {
                    dayIsSelected[index] = !dayIsSelected[index];
                  });
                },
                isSelected: dayIsSelected,
              ),
              Padding(padding: const EdgeInsets.all(20)),
              ToggleButtons(
                direction: Axis.vertical,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.all(15), child: Text('Dagrit')),
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text('Avondrit')),
                  Padding(
                      padding: const EdgeInsets.all(15),
                      child: Text('Terugscan')),
                ],
                onPressed: (int index) {
                  setState(() {
                    shiftsSelected = [false, false, false];
                    shiftsSelected[index] = true;
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
