import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:training_planner/events/RouteLoadedEvent.dart';
import 'package:training_planner/models/login_request.dart';
import 'package:training_planner/models/login_response.dart';
import 'package:training_planner/pages/agenda_page.dart';
import 'package:training_planner/pages/all_routes_page.dart';
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
  final versionController = TextEditingController();
  @override
  initState() {
    super.initState();

    pnumberController.text = '639174';
    daycodeController.text = '424';
    versionController.text = "..";

    settingsService.readSettingsFromFile().then((value) => {
      setState(() => {
        versionController.text = value.version
      })
    });
  }

  _attemptLogin() async {
    try {
      LoginResponse res = await apiService.login(LoginRequest(
          username: pnumberController.text,
          password: daycodeController.text,
          pdaSoftwareVersion: versionController.text,
          deviceImei: "990010902435339",
          deviceName: "Sussyamongus A11",
          deviceIdentifier: "990010902435339"));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AllRoutesPage()),
      );
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gegevens kloppen niet')));
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
              TextField(
                decoration: InputDecoration(labelText: "Versie"),
                keyboardType: TextInputType.text,
                controller: versionController,
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
