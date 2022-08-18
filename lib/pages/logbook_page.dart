import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/main.dart';
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
}

class _LogbookPageState extends State<LogbookPage> {
  List<MonthData>? months;

  void updateMonthData(MonthData month, Shift shift) {
    month.shifts.add(shift);
    month.calculateData();
  }

  void sortShifts(List<Shift> shifts) {
    months = [];
    for (var shift in shifts) {
      DateTime firstDayOfMonth =
          DateUtilities.DateUtils.firstDayOfMonth(shift.start);

      bool found = false;
      for (var month in months!) {
        if (month.firstDayOfMonth == firstDayOfMonth) {
          updateMonthData(month, shift);
          found = true;
        }
      }

      if (!found) {
        months!
            .add(MonthData(firstDayOfMonth: firstDayOfMonth, shifts: [shift]));
      }
    }

    months!.sort((a, b) => b.firstDayOfMonth.compareTo(a.firstDayOfMonth));
  }

  @override
  initState() {
    super.initState();

    shiftProvider.getPastShifts().then(
          (value) => setState(
            () {
              List<Shift> allShifts = value;
              sortShifts(allShifts);
            },
          ),
        );
  }

  List<Widget> createMonthDataWidgets() {
    List<Widget> result = [];

    for (var month in months!) {
      result.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(255, 140, 140, 180)),
              color: Color.fromARGB(255, 180, 180, 200),
              borderRadius: BorderRadius.all(Radius.circular(8))),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateHelper.getMonthName(month.firstDayOfMonth.month) +
                      ' ' +
                      month.firstDayOfMonth.year.toString(),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Padding(padding: EdgeInsets.only(left: 5, bottom: 5, right: 5)),
                Text('Gewerkt: ' +
                    month.totalWorkedTime.inHours.toString() +
                    ' uur'),
                Text('Verdiend: €' +
                    month.expectedSalary.toStringAsFixed(2) +
                    ' (schatting)'),
                Padding(padding: EdgeInsets.only(left: 5, bottom: 5, right: 5)),
              ],
            ),
          ),
        ),
      ));
    }

    return result;
  }

  Widget getDataList() {
    var monthDataWidgets = createMonthDataWidgets();
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
      child: getLoadingScreenOrDataList(),
    );
  }
}
