import 'package:flutter/material.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/style/style.dart';

class SettingsPage extends StatefulWidget {
  final Settings settings;

  @override
  _SettingsPageState createState() => _SettingsPageState();

  const SettingsPage({Key? key, required this.settings}) : super(key: key);
}

class _SettingsPageState extends State<SettingsPage> {
  final versionController = TextEditingController();

  @override
  initState() {
    super.initState();

    versionController.text = widget.settings.version;
  }

  Future<void> saveSettings() async {
    settingsService.writeSettingsToFile(widget.settings);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instellingen'),
        backgroundColor: Style.background,
        foregroundColor: Style.titleColor,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            children: [
              TextFormField(
                keyboardType: TextInputType.number,
                initialValue: widget.settings.salary.toStringAsFixed(2),
                onChanged: (value) =>
                    {widget.settings.salary = double.parse(value)},
                decoration: InputDecoration(
                  labelText: 'Huidige uurloon',
                ),
            
              ),
              Padding(padding: const EdgeInsets.all(0)),
              TextButton(
                  onPressed: () async => await saveSettings(),
                  child: Text('Opslaan')),
            ],
          ),
        ),
      ),
    );
  }
}
