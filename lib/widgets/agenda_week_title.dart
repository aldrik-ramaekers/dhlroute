import 'package:flutter/material.dart';
import 'package:training_planner/utils/date.dart';
import '../style/style.dart';

class AgendaWeekTitle extends StatefulWidget {
  final int weekNr;
  final DateTime mondayOfWeek;
  final bool isCurrentWeek;

  const AgendaWeekTitle({
    Key? key,
    required this.weekNr,
    required this.mondayOfWeek,
    required this.isCurrentWeek,
  }) : super(key: key);

  @override
  _AgendaWeekTitleState createState() => _AgendaWeekTitleState();
}

class _AgendaWeekTitleState extends State<AgendaWeekTitle> {
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
