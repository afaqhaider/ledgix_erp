import 'package:intl/intl.dart';

class DateFormatter {
  static String format(DateTime date, {String pattern = 'dd-MMM-yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  static DateTime parse(String dateStr, {String pattern = 'dd-MMM-yyyy'}) {
    return DateFormat(pattern).parse(dateStr);
  }
}
