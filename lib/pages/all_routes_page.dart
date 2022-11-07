import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/models/route_list.dart';
import 'package:training_planner/route.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/style/style.dart';
import 'package:training_planner/utils/date.dart';
import 'package:training_planner/widgets/agenda_week.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AllRoutesPage extends StatefulWidget {
  @override
  _AllRoutesPageState createState() => _AllRoutesPageState();

  const AllRoutesPage({Key? key}) : super(key: key);
}

class _AllRoutesPageState extends State<AllRoutesPage> {
  RouteList? routeInfo;
  @override
  initState() {
    super.initState();
    debugPrint('XDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD!!!');
    apiService.getRoutes().then((value) => {
          setState(() => {routeInfo = value})
        });
  }

  List<Widget> createRoutesDataWidgets() {
    List<Widget> result = [];

    for (var route in routeInfo!.routes!) {
      result.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Style.logbookEntryBorder),
              color: Style.logbookEntryBackground,
              borderRadius: BorderRadius.all(Radius.circular(8))),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.tripNumber.toString(),
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ));
    }

    return result;
  }

  Widget getDataList() {
    var monthDataWidgets = createRoutesDataWidgets();
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

  Widget getLoadingScreenOrDataList() {
    if (routeInfo != null) {
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
