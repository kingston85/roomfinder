// Small helpers with no Firebase dependency (unit-tested in test/).

String withCommas(num value) {
  final whole = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final fromEnd = whole.length - i;
    buf.write(whole[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1 && whole[i] != '-') buf.write(',');
  }
  return buf.toString();
}

String formatPrice(num amount, String currency) =>
    currency == 'LRD' ? 'L\$${withCommas(amount)}' : 'US\$${withCommas(amount)}';

/// "today", "yesterday", "5 days ago".
String daysAgo(DateTime? when, {DateTime? now}) {
  if (when == null) return 'not yet';
  final today = now ?? DateTime.now();
  final days = DateTime(today.year, today.month, today.day)
      .difference(DateTime(when.year, when.month, when.day))
      .inDays;
  if (days <= 0) return 'today';
  if (days == 1) return 'yesterday';
  return '$days days ago';
}

/// Turns a Liberian number into international digits for WhatsApp links:
/// "0777 123 456" -> "231777123456", "+231 88 765 4321" -> "231887654321".
String toInternationalDigits(String phone) {
  var digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.startsWith('231')) return digits;
  if (digits.startsWith('0')) return '231${digits.substring(1)}';
  if (digits.length == 9) return '231$digits';
  return digits;
}

/// Cloudinary: insert a resize transform for list thumbnails.
String thumbUrl(String url, {int width = 480}) {
  const marker = '/upload/';
  final i = url.indexOf(marker);
  if (i < 0) return url;
  return '${url.substring(0, i + marker.length)}w_$width,c_fill,q_auto,f_auto/${url.substring(i + marker.length)}';
}
