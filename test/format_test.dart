import 'package:flutter_test/flutter_test.dart';
import 'package:roomfinder/utils/format.dart';

void main() {
  test('withCommas', () {
    expect(withCommas(60), '60');
    expect(withCommas(1234), '1,234');
    expect(withCommas(12000), '12,000');
    expect(withCommas(1234567), '1,234,567');
  });

  test('formatPrice', () {
    expect(formatPrice(60, 'USD'), 'US\$60');
    expect(formatPrice(12000, 'LRD'), 'L\$12,000');
  });

  test('daysAgo', () {
    final now = DateTime(2026, 10, 17, 15);
    expect(daysAgo(DateTime(2026, 10, 17, 8), now: now), 'today');
    expect(daysAgo(DateTime(2026, 10, 16, 23), now: now), 'yesterday');
    expect(daysAgo(DateTime(2026, 10, 12), now: now), '5 days ago');
    expect(daysAgo(null, now: now), 'not yet');
  });

  test('toInternationalDigits', () {
    expect(toInternationalDigits('0777 123 456'), '231777123456');
    expect(toInternationalDigits('+231 88 765 4321'), '231887654321');
    expect(toInternationalDigits('777123456'), '231777123456');
    expect(toInternationalDigits('00231777123456'), '231777123456');
  });

  test('thumbUrl inserts a Cloudinary transform', () {
    expect(
      thumbUrl('https://res.cloudinary.com/demo/image/upload/v1/listings/a.jpg', width: 300),
      'https://res.cloudinary.com/demo/image/upload/w_300,c_fill,q_auto,f_auto/v1/listings/a.jpg',
    );
    expect(thumbUrl('https://example.com/a.jpg'), 'https://example.com/a.jpg');
  });
}
