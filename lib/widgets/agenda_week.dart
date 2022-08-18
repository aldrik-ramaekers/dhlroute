import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/events/RefreshWeekEvent.dart';
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
  List<Widget>? weekItems;
  StreamSubscription? eventbusSubscription;

  void updateItems() async {
    setState(() {
      weekItems = null;
    });

    var data = await shiftProvider.getShiftsForWeek(this.widget.mondayOfWeek);
    if (!mounted) return;
    setState(() {
      weekItems = [
        AgendaWeekTitle(
            weekNr: this.widget.weekNr,
            mondayOfWeek: this.widget.mondayOfWeek,
            isCurrentWeek: this.widget.isCurrentWeek),
        Padding(
          padding: const EdgeInsets.all(10),
        )
      ];

      for (var item in data) {
        weekItems!.add(new AgendaWeekItem(
          shift: item,
          updateParent: updateItems,
        ));
      }

      if (data.isEmpty) {
        weekItems!.add(Center(child: Text('Geen werktijden')));
      }

      weekItems!.add(Padding(
        padding: const EdgeInsets.all(50),
      ));
    });
  }

  @override
  void initState() {
    super.initState();
    updateItems();

    eventbusSubscription = eventBus.on<RefreshWeekEvent>().listen((event) {
      updateItems();
    });
  }

  @override
  void dispose() {
    eventbusSubscription?.cancel();
    super.dispose();
  }

  Widget getDataList() {
    return SafeArea(
      child: CustomScrollView(
        physics: null,
        slivers: [
          SliverPadding(padding: EdgeInsets.only(top: 20)),
          SliverList(
              delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              return weekItems![index];
            },
            childCount: weekItems!.length,
          )),
          SliverPadding(padding: EdgeInsets.only(top: 20)),
        ],
      ),
    );
  }

  Widget getLoadingScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
        ),
        AgendaWeekTitle(
            weekNr: this.widget.weekNr,
            mondayOfWeek: this.widget.mondayOfWeek,
            isCurrentWeek: this.widget.isCurrentWeek),
        Padding(
          padding: const EdgeInsets.all(10),
        ),
        LoadingAnimationWidget.flickr(
          leftDotColor: Style.titleColor,
          rightDotColor: Style.background,
          size: MediaQuery.of(context).size.width / 4,
        )
      ],
    );
  }

  Widget getLoadingScreenOrDataList() {
    if (weekItems != null) {
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
