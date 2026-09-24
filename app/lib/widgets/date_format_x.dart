extension DateFormatX on DateTime {
  String get deDate =>
      '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}.$year';
}
