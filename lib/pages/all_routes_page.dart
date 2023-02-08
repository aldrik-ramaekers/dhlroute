import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:in_date_utils/in_date_utils.dart' as DateUtilities;
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/models/route_list.dart';
import 'package:training_planner/pages/navigation_page.dart';
import 'package:training_planner/route.dart' as DHLRoute;
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

    try {
      apiService.getRoutes().then((value) {
        setState(() => {routeInfo = value});
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route lijst kan niet worden geladen')));
    }
  }

  _startRoute(String tripkey) async {
    try {
      DHLRoute.Route? route = await apiService.getRoute(tripkey);

      if (route == null) {
        throw Exception();
      }

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NavigationPage(route: route)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route kan niet worden geladen')));
    }
  }

  List<Widget> createRoutesDataWidgets() {
    List<Widget> result = [];

    for (var route in routeInfo!.routes!) {
      result.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
        child: Container(
          decoration: BoxDecoration(
              color: Color.fromARGB(80, 0, 0, 0),
              border: Border.all(color: Color.fromARGB(160, 0, 0, 0)),
              borderRadius: BorderRadius.all(Radius.circular(4))),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      'Route ' + route.tripNumber.toString(),
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                    Text(
                      route.tripPdaStatusDescription ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                          fontSize: 16),
                    ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(0),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _startRoute(route.tripKey!);
                  },
                  child: Text('Bekijk'),
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
        child: Text('Geen routes beschikbaar'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkschema'),
        backgroundColor: Style.background,
        foregroundColor: Style.titleColor,
      ),
      body: Container(
        color: Colors.white,
        child: ShaderMask(
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
        ),
      ),
    );
  }
}
