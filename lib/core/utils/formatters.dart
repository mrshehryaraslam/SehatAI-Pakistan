import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  static String formatCurrencyPKR(num amount) {
    final format = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  static String formatPhone(String phone) {
    if (phone.length == 11 && phone.startsWith('03')) {
      return '+92 ${phone.substring(1, 4)} ${phone.substring(4)}';
    }
    return phone;
  }
}
