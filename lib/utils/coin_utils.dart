// lib/utils/coin_utils.dart

const int cpPerPP = 1000;
const int cpPerGP = 100;
const int cpPerEP = 50;
const int cpPerSP = 10;

int coinToCopper(int amount, String coin) {
  switch (coin) {
    case 'PP': return amount * cpPerPP;
    case 'GM': return amount * cpPerGP;
    case 'EM': return amount * cpPerEP;
    case 'SM': return amount * cpPerSP;
    default:   return amount;
  }
}

Map<String, int> breakdownCopper(int cp) {
  var rem = cp;
  final pp = rem ~/ cpPerPP; rem -= pp * cpPerPP;
  final gp = rem ~/ cpPerGP; rem -= gp * cpPerGP;
  final ep = rem ~/ cpPerEP; rem -= ep * cpPerEP;
  final sp = rem ~/ cpPerSP; rem -= sp * cpPerSP;
  return {'PP': pp, 'GM': gp, 'EM': ep, 'SM': sp, 'KM': rem};
}

String formatWallet(int totalCp) {
  if (totalCp <= 0) return '0 GM';
  final b = breakdownCopper(totalCp);
  final parts = <String>[];
  for (final coin in ['PP', 'GM', 'EM', 'SM', 'KM']) {
    if (b[coin]! > 0) parts.add('${b[coin]} $coin');
  }
  return parts.join(' ');
}

String formatGP(int totalCp) {
  final gp = totalCp / cpPerGP;
  if (gp == gp.truncateToDouble()) return '${gp.toInt()} GM';
  return '${gp.toStringAsFixed(2)} GM';
}
