import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:training_planner/pages/add_shift_page.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/style/style.dart';
import 'package:training_planner/utils/date.dart';
import 'package:training_planner/widgets/agenda_week.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AgendaPage extends StatefulWidget {
  final int agendaWeekNr;

  @override
  _AgendaPageState createState() => _AgendaPageState();

  const AgendaPage({Key? key, required this.agendaWeekNr}) : super(key: key);
}

class _AgendaPageState extends State<AgendaPage> {
  int weekToStartAt = 0;
  List<Widget> weeks = [];
  List<int> weekNrs = [];
  List<DateTime> dateTimes = [];
  int currentSelectedPageIndex = 0;
  int currentSelectedPageNr = 0;
  DateTime currentSelectedWeek = DateTime.now();

  @override
  initState() {
    super.initState();

    weekToStartAt = widget.agendaWeekNr;
    weeks = getWeeks();

    currentSelectedPageIndex = weekToStartAt;
    currentSelectedPageNr = weekNrs[weekToStartAt];
    currentSelectedWeek = dateTimes[weekToStartAt];
  }

  List<Widget> getWeeks() {
    List<Widget> result = [];
    List<int> weekNrs = [];
    DateTime startDate =
        DateUtilities.DateUtils.firstDayOfWeek(DateTime(2020, 1, 1));
    DateTime today = DateTime.now();
    DateTime firstDayOfCurrentWeek =
        DateUtilities.DateUtils.firstDayOfWeek(today);
    int difference = today.difference(startDate).inDays;

    int totalWeeks = (difference / 7.0).ceil() + 4;

    for (int i = 0; i < totalWeeks; i++) {
      DateTime mondayOfWeek = startDate.add(Duration(days: 7 * i));
      int weekNr = DateUtilities.DateUtils.getWeekNumber(mondayOfWeek);

      bool isCurrentWeek = false;
      if (mondayOfWeek == firstDayOfCurrentWeek) {
        if (weekToStartAt == 0) weekToStartAt = i;
        isCurrentWeek = true;
      }

      result.add(
        AgendaWeek(
          weekNr: weekNr,
          mondayOfWeek: mondayOfWeek,
          isCurrentWeek: isCurrentWeek,
        ),
      );
      weekNrs.add(weekNr);
      dateTimes.add(mondayOfWeek);
    }
    this.weekNrs = weekNrs;

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: CarouselSlider(
          options: CarouselOptions(
            onPageChanged: (index, _) {
              currentSelectedPageIndex = index;
              currentSelectedPageNr = weekNrs[index];
              currentSelectedWeek = dateTimes[index];
            },
            height: MediaQuery.of(context).size.height - 163,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: false,
            initialPage: weekToStartAt, // Week nr
          ),
          items: getWeeks(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddShiftPage(
                      pageNr: currentSelectedPageNr,
                      pageIndex: currentSelectedPageIndex,
                      mondayOfWeek: currentSelectedWeek,
                    )),
          );
        },
        backgroundColor: Style.titleColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
