import 'package:exam_duel/services/deep_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a room link builds the code in upper case', () {
    expect(joinLink('abcde'), 'https://wogbe.github.io/exam-duel/?code=ABCDE');
  });

  test('no code is waiting until a link brings one', () {
    expect(takeLinkCode(), isNull);
    expect(hasLinkCode, isFalse);
  });

  testWidgets('reading a link never throws, whatever the app was opened with', (t) async {
    readLinkCode();
    final code = takeLinkCode();
    // The test host opens no link, so there is nothing to take. It must not throw.
    expect(code, anyOf(isNull, isA<String>()));
    expect(hasLinkCode, isFalse);
  });
}
