import 'package:flutter/material.dart';
import 'package:training_planner/utils/date.dart';
import '../style/style.dart';

class AgendaWeekTitle extends StatefulWidget {
  final int weekNr;
  final DateTime mondayOfWeek;
  final bool isCurrentWeek;
  final Duration hoursWorked;

  const AgendaWeekTitle(
      {Key? key,
      required this.weekNr,
      required this.mondayOfWeek,
      required this.isCurrentWeek,
      required this.hoursWorked})
      : super(key: key);

  @override
  _AgendaWeekTitleState createState() => _AgendaWeekTitleState();
}

class _AgendaWeekTitleState extends State<AgendaWeekTitle> {
  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    return "${twoDigits(duration.inHours)}h ${twoDigitMinutes}m";
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            this.widget.isCurrentWeek
                ? Icon(Icons.today)
                : Padding(padding: const EdgeInsets.all(12)),
            Center(
              child: Text(
                  " Week #" +
                      this.widget.weekNr.toString() +
                      " | " +
                      this.widget.mondayOfWeek.day.toString() +
                      " " +
                      DateHelper.getMonthName(this.widget.mondayOfWeek.month) +
                      " " +
                      this.widget.mondayOfWeek.year.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  )),
            ),
          ]),
    ]);
  }
}
