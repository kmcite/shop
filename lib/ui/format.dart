/// Formats [amount] as Pakistani rupees: `Rs 1,234` / `Rs 12.50`.
String formatMoney(double amount) {
  final rounded = (amount * 100).round() / 100;
  final isWhole = rounded == rounded.roundToDouble();
  final body = isWhole
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(2);
  return 'Rs ${_withSeparators(body)}';
}

/// Inserts thousands separators into an integer-part string.
String _withSeparators(String digits) {
  final parts = digits.split('.');
  final intPart = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length > 1 ? '$intPart.${parts[1]}' : intPart;
}

String formatStock(int quantity) {
  if (quantity == 0) return 'Out of stock';
  if (quantity == 1) return '1 left';
  return '$quantity in stock';
}

/// Clock time for a sale row, e.g. `3:05 PM`.
/// Short calendar date for bulk history, e.g. `Nov 17, 2026`.
String formatBulkDate(DateTime? dateTime) {
  if (dateTime == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = dateTime.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}

String formatSaleClock(DateTime soldAt) {
  final local = soldAt.toLocal();
  final hour = local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
  final period = hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $period';
}

/// Section heading for grouping sales (Today, Yesterday, weekday, or date).
String formatSaleDayHeading(DateTime soldAt, DateTime now) {
  final saleDay = DateTime(soldAt.year, soldAt.month, soldAt.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(saleDay).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  if (diff < 7) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return weekdays[soldAt.weekday - 1];
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[soldAt.month - 1]} ${soldAt.day}, ${soldAt.year}';
}