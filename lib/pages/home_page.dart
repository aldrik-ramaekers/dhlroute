import 'package:flutter/material.dart';
import 'package:training_planner/pages/agenda_page.dart';
import 'package:training_planner/pages/logbook_page.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/style/style.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();

  const HomePage({Key? key}) : super(key: key);
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    new AgendaPage(),
    new LogbookPage(),
  ];

  @override
  initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Werkschema'),
        backgroundColor: Style.background,
        foregroundColor: Style.titleColor,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_ind_sharp),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Logboek',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Style.titleColor,
        onTap: _onItemTapped,
      ),
    );
  }
}
