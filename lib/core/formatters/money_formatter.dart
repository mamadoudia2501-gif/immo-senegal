import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

final NumberFormat _frInteger = NumberFormat.decimalPattern('fr');

String formatFcfa(int amount) =>
    '${_frInteger.format(amount)} ${AppConstants.currency}';
