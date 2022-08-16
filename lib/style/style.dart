import 'package:flutter/material.dart';

class Style {
  static const Color background = Color.fromARGB(255, 255, 204, 0);
  static const Color titleColor = Color.fromARGB(255, 212, 5, 17);

  static const TextStyle bodyNormal =
      TextStyle(color: Colors.white, fontSize: 14);

  static const TextStyle listItemTitletextBold =
      TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.bold);
  static const TextStyle listItemTitletext =
      TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.w300);

  static const Color listEntryBackground = background;
}
