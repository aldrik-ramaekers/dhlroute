import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:training_planner/main.dart';
import 'package:training_planner/services/iblacklist_provider_service.dart';
import 'package:training_planner/services/settings_service.dart';
import 'package:training_planner/style/style.dart';

class BlacklistPage extends StatefulWidget {
  @override
  _BlacklistPageState createState() => _BlacklistPageState();

  const BlacklistPage({Key? key}) : super(key: key);
}

class _BlacklistPageState extends State<BlacklistPage> {
  List<BlacklistEntry>? blacklist;

  final postalCodeNumericController = TextEditingController();
  final postalCodeAlphaController = TextEditingController();
  final houseNumberController = TextEditingController();
  final houseNumberExtraController = TextEditingController();

  @override
  initState() {
    super.initState();

    blacklistProvider.getBlacklist().then((value) async {
      if (mounted) {
        setState(
          () {
            blacklist = value;
          },
        );
      }
    });
  }

  Widget getLoadingScreen() {
    return LoadingAnimationWidget.flickr(
      leftDotColor: Style.titleColor,
      rightDotColor: Style.background,
      size: MediaQuery.of(context).size.width / 4,
    );
  }

  List<Widget> createBlacklistWidgets() {
    List<Widget> result = [];

    for (var entry in blacklist!) {
      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Style.logbookEntryBorder),
                color: Style.logbookEntryBackground,
                borderRadius: BorderRadius.all(Radius.circular(4))),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.postalcodeNumeric +
                            ' ' +
                            entry.postalcodeAplha +
                            ' ' +
                            entry.houseNumber.toString() +
                            entry.houseNumberExtra,
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return result;
  }

  Widget getDataList() {
    var monthDataWidgets = createBlacklistWidgets();
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

  Widget getLoadingScreenOrDataList() {
    if (blacklist != null) {
      return getDataList();
    } else {
      return getLoadingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blacklist'),
        backgroundColor: Style.background,
        foregroundColor: Style.titleColor,
      ),
      body: ShaderMask(
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showAddAddressDialog();
          //eventBus.fire(RefreshWeekEvent());
        },
        backgroundColor: Style.titleColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> addAddressFromDialog() async {
    await blacklistProvider.addToBlacklist(BlacklistEntry(
        postalCodeNumericController.text,
        postalCodeAlphaController.text,
        int.tryParse(houseNumberController.text) ?? 0,
        houseNumberExtraController.text));
  }

  Future<void> showAddAddressDialog() async {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: Text("Terug"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: Text("Ok"),
      onPressed: () async {
        await addAddressFromDialog();
        Navigator.pop(context);
      },
    );

    // show the dialog
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text("Vul adres in"),
            content: Column(children: [
              TextField(
                controller: postalCodeNumericController,
                decoration: const InputDecoration(
                  labelText: 'Postcode',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: postalCodeAlphaController,
                decoration: const InputDecoration(
                  labelText: 'Postcode Toevoeging',
                ),
                keyboardType: TextInputType.text,
              ),
              TextField(
                controller: houseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Huisnummer',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: houseNumberExtraController,
                decoration: const InputDecoration(
                  labelText: 'Huisnummer Toegoeging',
                ),
                keyboardType: TextInputType.text,
              ),
            ]),
            actions: [
              cancelButton,
              continueButton,
            ],
          );
        });
      },
    );
  }
}
