import 'package:intl/intl.dart';

String formatMoney(int value, String currency) {
  const symbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'SGD': 'S\$',
    'MYR': 'RM',
  };
  return '${symbols[currency] ?? currency} ${NumberFormat.decimalPattern('id_ID').format(value)}';
}

String greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 18) return 'Good afternoon';
  return 'Good evening';
}
