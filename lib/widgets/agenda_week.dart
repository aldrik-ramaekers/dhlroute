import 'package:flutter/material.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/style/style.dart';
import 'package:training_planner/utils/date.dart';
import 'package:training_planner/widgets/agenda_week_item.dart';
import 'package:training_planner/widgets/agenda_week_title.dart';

class AgendaWeek extends StatefulWidget {
  final int weekNr;
  final DateTime mondayOfWeek;
  final bool isCurrentWeek;

  @override
  _AgendaWeekState createState() => _AgendaWeekState();

  AgendaWeek({
    Key? key,
    required this.weekNr,
    required this.mondayOfWeek,
    required this.isCurrentWeek,
  }) : super(key: key);
}

class _AgendaWeekState extends State<AgendaWeek> {
  List<Widget> weekItems = [];

  void updateItems() {
    setState(() {
      shiftProvider
          .getShiftsForWeek(this.widget.mondayOfWeek)
          .then((value) => setState(() {
                weekItems = [
                  AgendaWeekTitle(
                      weekNr: this.widget.weekNr,
                      mondayOfWeek: this.widget.mondayOfWeek,
                      isCurrentWeek: this.widget.isCurrentWeek),
                  Padding(
                    padding: const EdgeInsets.all(10),
                  )
                ];

                for (var item in value) {
                  weekItems.add(new AgendaWeekItem(
                    shift: item,
                    updateParent: updateItems,
                  ));
                }

                weekItems.add(Padding(
                  padding: const EdgeInsets.all(50),
                ));
              }));
    });
  }

  @override
  void initState() {
    super.initState();
    updateItems();
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
      child: SafeArea(
        child: CustomScrollView(
          physics: null,
          slivers: [
            SliverPadding(padding: EdgeInsets.only(top: 20)),
            SliverList(
                delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return weekItems[index];
              },
              childCount: weekItems.length,
            )),
            SliverPadding(padding: EdgeInsets.only(top: 20)),
          ],
        ),
      ),
    );
  }
}
