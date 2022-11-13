import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

    var data = await shiftProvider.getShiftsForWeek(widget.mondayOfWeek);
    if (!mounted) return;
    setState(() {
      Duration hoursWorked = Duration();
      for (var item in data) {
        hoursWorked += item.getElapsedSessionTime();
      }

      weekItems = [
        AgendaWeekTitle(
          weekNr: widget.weekNr,
          mondayOfWeek: widget.mondayOfWeek,
          isCurrentWeek: widget.isCurrentWeek,
          hoursWorked: hoursWorked,
        ),
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    for (var item in getBackgrounds()) {
      precacheImage(AssetImage('assets/goals/' + item), context);
    }
  }

  @override
  void initState() {
    updateItems();

    eventbusSubscription = eventBus.on<RefreshWeekEvent>().listen((event) {
      updateItems();
    });
    super.initState();
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
          weekNr: widget.weekNr,
          mondayOfWeek: widget.mondayOfWeek,
          isCurrentWeek: widget.isCurrentWeek,
          hoursWorked: Duration(),
        ),
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

  List<String> getBackgrounds() {
    return ['1.png', '2.jpg', '3.jpeg', '4.jpg', '5.jpg'];
  }

  String getBackgroundImage() {
    var options = getBackgrounds();
    int nrToChoose = widget.weekNr % options.length;
    return options[nrToChoose];
  }

  Widget getData() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/goals/' + getBackgroundImage()),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
      ),
      child: getLoadingScreenOrDataList(),
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
      child: getData(),
    );
  }
}
