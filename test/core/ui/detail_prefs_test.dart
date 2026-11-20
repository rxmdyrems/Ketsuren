import 'package:flutter_test/flutter_test.dart';
import 'package:ketsuren/core/ui/detail_prefs.dart';

void main() {
  group('reverse episode list default', () {
    test('defaults to off', () {
      expect(DetailPrefs.reverseEpisodesDefault, isFalse);
    });
  });
}
