import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

final NumberFormat _frInteger = NumberFormat.decimalPattern('fr');

String formatFcfa(int amount) =>
    '${_frInteger.format(amount)} ${AppConstants.currency}';

String formatCompactFcfa(int amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    final text = millions >= 10 || millions == millions.roundToDouble()
        ? millions.round().toString()
        : millions.toStringAsFixed(1).replaceFirst('.', ',');
    return '$text M ${AppConstants.currency}';
  }
  return formatFcfa(amount);
}
