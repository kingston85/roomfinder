// Kept so `flutter create .` in the build workflow does not add its default
// counter-app test (which would not compile against this app).
import 'package:flutter_test/flutter_test.dart';
import 'package:roomfinder/data/liberia.dart';

void main() {
  test('every listing type and amenity has a label', () {
    expect(listingTypes.values.every((v) => v.isNotEmpty), isTrue);
    expect(amenityLabels.values.every((v) => v.isNotEmpty), isTrue);
    expect(communities.contains('Other'), isTrue);
  });
}
