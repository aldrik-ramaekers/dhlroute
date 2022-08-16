import 'package:flutter/material.dart';
import 'package:training_planner/pages/agenda_page.dart';
import 'package:training_planner/pages/home_page.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/style/style.dart';

class AddShiftPage extends StatefulWidget {
  final int pageNr;
  final int pageIndex;
  final DateTime mondayOfWeek;
  @override
  _AddShiftPageState createState() => _AddShiftPageState();

  const AddShiftPage({
    Key? key,
    required this.pageNr,
    required this.pageIndex,
    required this.mondayOfWeek,
  }) : super(key: key);
}

class _AddShiftPageState extends State<AddShiftPage> {
  @override
  initState() {
    super.initState();
  }

  String dropdownValue = 'Maandag';
  List<bool> isSelected = [false, true, false];

  void addShift() {
    DateTime startDate = widget.mondayOfWeek;
    switch (dropdownValue) {
      case 'Maandag':
        startDate = startDate.add(Duration(days: 0));
        break;
      case 'Dinsdag':
        startDate = startDate.add(Duration(days: 1));
        break;
      case 'Woensdag':
        startDate = startDate.add(Duration(days: 2));
        break;
      case 'Donderdag':
        startDate = startDate.add(Duration(days: 3));
        break;
      case 'Vrijdag':
        startDate = startDate.add(Duration(days: 4));
        break;
      case 'Zaterdag':
        startDate = startDate.add(Duration(days: 5));
        break;
      case 'Zondag':
        startDate = startDate.add(Duration(days: 6));
        break;
    }

    ShiftType type = ShiftType.Dagrit;
    if (isSelected[1]) type = ShiftType.Avondrit;
    if (isSelected[2]) type = ShiftType.Terugscannen;

    switch (type) {
      case ShiftType.Dagrit:
        startDate = startDate.add(Duration(hours: 10));
        break;
      case ShiftType.Avondrit:
        startDate = startDate.add(Duration(
            hours: startDate.weekday == 6 ? 15 : 17,
            minutes: startDate.weekday == 6 ? 30 : 0));
        break;
      case ShiftType.Terugscannen:
        startDate = startDate.add(
            Duration(hours: startDate.weekday == 6 ? 13 : 14, minutes: 30));
        break;
    }

    shiftProvider.addShift(Shift(start: startDate, type: type));

    Navigator.pop(context, true);

    // Previous page will not refresh without this.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => HomePage(agendaWeekNr: widget.pageIndex)),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Toevoegen aan planning #' + widget.pageNr.toString()),
          backgroundColor: Style.background,
          foregroundColor: Style.titleColor,
        ),
        body: Center(
            child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(20)),
            Container(
              width: 200,
              child: DropdownButton<String>(
                value: dropdownValue,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.black),
                underline: Container(
                  height: 2,
                  color: Colors.black,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
                items: <String>[
                  'Maandag',
                  'Dinsdag',
                  'Woensdag',
                  'Donderdag',
                  'Vrijdag',
                  'Zaterdag',
                  'Zondag'
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
            Padding(padding: const EdgeInsets.all(20)),
            ToggleButtons(
              children: <Widget>[
                Padding(
                    padding: const EdgeInsets.all(15), child: Text('Dagrit')),
                Padding(
                    padding: const EdgeInsets.all(15), child: Text('Avondrit')),
                Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text('Terugscan')),
              ],
              onPressed: (int index) {
                setState(() {
                  isSelected[index] = !isSelected[index];
                });
              },
              isSelected: isSelected,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
            ),
            TextButton(onPressed: () => {addShift()}, child: Text('Toevoegen')),
          ],
        )));
  }
}
