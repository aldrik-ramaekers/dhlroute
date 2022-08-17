import 'package:flutter/material.dart';
import 'package:training_planner/pages/agenda_page.dart';
import 'package:training_planner/pages/logbook_page.dart';
import 'package:training_planner/shift.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/style/style.dart';

class HomePage extends StatefulWidget {
  int agendaWeekNr;
  @override
  _HomePageState createState() => _HomePageState();

  HomePage({Key? key, required this.agendaWeekNr}) : super(key: key);
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  List<Widget> _widgetOptions = [];

  @override
  initState() {
    _widgetOptions = <Widget>[
      new AgendaPage(agendaWeekNr: widget.agendaWeekNr),
      new LogbookPage(),
    ];

    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      widget.agendaWeekNr = 0;
      _widgetOptions = <Widget>[
        new AgendaPage(agendaWeekNr: widget.agendaWeekNr),
        new LogbookPage(),
      ];
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
