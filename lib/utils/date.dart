class DateHelper {
  static String getWeekdayName(int nr) {
    switch (nr) {
      case DateTime.monday:
        return 'Ma';
      case DateTime.tuesday:
        return 'Di';
      case DateTime.wednesday:
        return 'Wo';
      case DateTime.thursday:
        return 'Do';
      case DateTime.friday:
        return 'Vr';
      case DateTime.saturday:
        return 'Za';
      case DateTime.sunday:
        return 'Zo';
    }
    return '';
  }

  static String getMonthName(int nr) {
    switch (nr) {
      case 1:
        return 'Jan';
      case 2:
        return 'Feb';
      case 3:
        return 'Maa';
      case 4:
        return 'Apr';
      case 5:
        return 'Mei';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Aug';
      case 9:
        return 'Sep';
      case 10:
        return 'Okt';
      case 11:
        return 'Nov';
      case 12:
        return 'Dec';
    }
    return '';
  }
}
