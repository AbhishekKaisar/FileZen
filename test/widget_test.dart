import 'package:flutter_test/flutter_test.dart';

import 'package:file_zen/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FileZenApp());

    // Let async timers (mock repository delays) complete.
    await tester.pumpAndSettle();

    // Verify that the app launches successfully.
    expect(find.byType(FileZenApp), findsOneWidget);
  });
}
