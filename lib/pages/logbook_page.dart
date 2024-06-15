import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/services/local_salary_provider_service.dart';
import 'package:training_planner/services/log_service.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/style/style.dart';
import 'package:training_planner/utils/date.dart';
import 'package:training_planner/widgets/agenda_week.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LogbookPage extends StatefulWidget {
  @override
  _LogbookPageState createState() => _LogbookPageState();

  const LogbookPage({Key? key}) : super(key: key);
}

class MonthData {
  DateTime firstDayOfMonth;
  List<Shift> shifts;
  Duration totalWorkedTime = Duration();
  double expectedSalary = 0;
  double actualSalary = 0;

  void calculateData() {
    totalWorkedTime = Duration();
    expectedSalary = 0;
    for (var shift in shifts) {
      totalWorkedTime += shift.getElapsedSessionTime();
      expectedSalary += shift.getEarnedMoney();
    }
  }

  MonthData({required this.firstDayOfMonth, required this.shifts}) {
    calculateData();
  }

  double calculateHourlyRate() {
    if (totalWorkedTime.inMinutes == 0) return 0;
    return actualSalary / (totalWorkedTime.inMinutes / 60.0);
  }
}

class _LogbookPageState extends State<LogbookPage> {
  List<MonthData>? months;
  List<IncomeData>? income;

  void updateMonthData(MonthData month, Shift shift) {
    month.shifts.add(shift);
    month.calculateData();
  }

  void sortShifts(List<Shift> shifts) {

    months = [];
    for (var shift in shifts) {
      DateTime yearJanFirst = DateUtilities.DateTimeUtils.firstDayOfYear(shift.start);
      List<DateTime> blockStartTimes = [];
      late DateTime shiftBlock;

      for (int i = 0; i < 13; i++) {
        blockStartTimes.add(yearJanFirst);
        yearJanFirst = yearJanFirst.add(Duration(days: 28));
        if (yearJanFirst.compareTo(shift.start) >= 1) {
          shiftBlock = blockStartTimes.last;
          break;
        }
      }

      bool found = false;
      for (var month in months!) {
        if (month.firstDayOfMonth == shiftBlock) {
          updateMonthData(month, shift);
          found = true;
        }
      }

      if (!found) {
        months!
            .add(MonthData(firstDayOfMonth: shiftBlock, shifts: [shift]));
      }
    }

    months!.sort((a, b) => b.firstDayOfMonth.compareTo(a.firstDayOfMonth));
  }

  @override
  initState() {
    super.initState();

    shiftProvider.getPastShifts().then((value) async {
      income = await incomeProvider.getSavedIncome();
      if (mounted) {
        setState(
          () {
            List<Shift> allShifts = value;
            sortShifts(allShifts);
          },
        );
      }
    });
  }

  List<Widget> createMonthDataWidgets() {
    List<Widget> result = [];

    for (var month in months!) {
      for (var inc in income!) {
        if (inc.firstDayOfMonth == month.firstDayOfMonth) {
          month.actualSalary = inc.income;
          break;
        }
      }

      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Style.logbookEntryBorder),
                color: Style.logbookEntryBackground,
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        month.firstDayOfMonth.day.toString() +"/"+ month.firstDayOfMonth.month.toString()+"/"+ month.firstDayOfMonth.year.toString() + " -> " +
                        month.firstDayOfMonth.add(Duration(days: 28)).day.toString() +"/"+ month.firstDayOfMonth.add(Duration(days: 28)).month.toString()+"/"+ month.firstDayOfMonth.add(Duration(days: 28)).year.toString(),
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                          padding:
                              EdgeInsets.only(left: 5, bottom: 5, right: 5)),
                      Text('Gewerkt: ' +
                          month.totalWorkedTime.inHours.toString() +
                          ' uur'),
                      Text('Verwacht: €' +
                          month.expectedSalary.toStringAsFixed(2)),
                      Padding(
                          padding:
                              EdgeInsets.only(left: 5, bottom: 5, right: 5)),
                    ],
                  ),
                  Padding(padding: EdgeInsets.all(10)),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      Padding(
                          padding:
                              EdgeInsets.only(left: 5, bottom: 5, right: 5)),
                      Padding(
                          padding:
                              EdgeInsets.only(left: 5, bottom: 5, right: 5)),
                    ],
                  ),
                  Expanded(
                    child: Text(''),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return result;
  }

  Widget getDataList() {
    var monthDataWidgets = createMonthDataWidgets();
    if (monthDataWidgets.isEmpty) {
      return Center(
        child: Text('Geen data beschikbaar'),
      );
    }

    return SafeArea(
      child: CustomScrollView(
        physics: null,
        slivers: [
          SliverPadding(padding: EdgeInsets.only(top: 20)),
          SliverList(
              delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return monthDataWidgets[index];
            },
            childCount: monthDataWidgets.length,
          )),
          SliverPadding(padding: EdgeInsets.only(top: 20)),
        ],
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

  Widget getData() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: getLoadingScreenOrDataList(),
    );
  }

  Widget getLoadingScreenOrDataList() {
    if (months != null) {
      return getDataList();
    } else {
      return getLoadingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Style.background,
            Colors.transparent,
            Colors.transparent,
            Style.background
          ],
          stops: [
            0.0,
            0.05,
            0.95,
            1.0
          ], // 10% purple, 80% transparent, 10% purple
        ).createShader(rect);
      },
      blendMode: BlendMode.dstOut,
      child: getData(),
    );
  }

  Future requestMonthInfo(MonthData month) async {
    TextEditingController controller = TextEditingController();
    controller.text = month.actualSalary.toString();

    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Terug"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Opslaan"),
      onPressed: () async {
        month.actualSalary = double.parse(controller.text);
        for (var m in months!) {
          if (m.firstDayOfMonth == month.firstDayOfMonth) {
            m.actualSalary = double.parse(controller.text);
          }
        }
        await incomeProvider.writeSavedIncome(months!);

        setState(() {});
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text("Inkomen invullen"),
      actions: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Inkomen',
          ),
          keyboardType: TextInputType.number,
        ),
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
