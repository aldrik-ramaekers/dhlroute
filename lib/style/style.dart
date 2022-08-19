import 'package:flutter/material.dart';

class Style {
  static const Color background = Color.fromARGB(255, 255, 204, 0);
  static const Color titleColor = Color.fromARGB(255, 212, 5, 17);

  static const TextStyle listItemTitletextBold =
      TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold);
  static const Color listEntryBackground = background;
  static const Color listEntryStandardColor = Colors.black;
  static const Color listEntryTransparentColor = Color.fromARGB(80, 0, 0, 0);

  static const Color logbookEntryBorder = Color.fromARGB(255, 140, 140, 180);
  static const Color logbookEntryBackground =
      Color.fromARGB(255, 180, 180, 200);
}
