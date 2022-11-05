import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:training_planner/events/RouteLoadedEvent.dart';
import 'package:training_planner/pages/agenda_page.dart';
import 'package:training_planner/pages/developer_page.dart';
import 'package:training_planner/pages/logbook_page.dart';
import 'package:training_planner/pages/navigation_page.dart';
import 'package:training_planner/pages/settings_page.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/style/style.dart';

class DeliveryLoginPage extends StatefulWidget {
  @override
  _DeliveryLoginPageState createState() => _DeliveryLoginPageState();

  const DeliveryLoginPage({Key? key}) : super(key: key);
}

class _DeliveryLoginPageState extends State<DeliveryLoginPage> {
  final pnumberController = TextEditingController();
  final daycodeController = TextEditingController();

  @override
  initState() {
    super.initState();

    pnumberController.text = remoteAuthService.storedPNumber;
    daycodeController.text = remoteAuthService.storedDaycode;
  }

  _attemptLogin() async {
    bool success = await remoteAuthService.authenticate(
        pnumberController.text, daycodeController.text);
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NavigationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
        ),
        Expanded(
          child: Column(
            children: [
              Padding(padding: EdgeInsets.all(50)),
              TextField(
                decoration: InputDecoration(labelText: "pnummer"),
                keyboardType: TextInputType.number,
                controller: pnumberController,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
              ),
              Padding(padding: EdgeInsets.all(10)),
              TextField(
                decoration: InputDecoration(labelText: "dagcode"),
                keyboardType: TextInputType.number,
                controller: daycodeController,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
              ),
              Padding(padding: EdgeInsets.all(10)),
              OutlinedButton(
                  onPressed: () => _attemptLogin(), child: Text('Inloggen'))
            ],
          ),
        ),
        Container(
          width: 50,
        ),
      ],
    );
  }
}
