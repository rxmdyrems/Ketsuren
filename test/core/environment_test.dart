import 'package:flutter_test/flutter_test.dart';
import 'package:ketsuren/core/environment.dart';

void main() {
  test('cloud sync defaults to the production VPS', () {
    expect(Environment.vpsSyncUrl, 'https://sync.zangetsu.online');
  });
}
