import 'package:flutter_test/flutter_test.dart';

import 'package:ironlock/main.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const IronLockApp(initialRemainingTime: 0, allPermissionsGranted: false),
    );
    expect(find.text('IRONLOCK'), findsOneWidget);
  });
}
