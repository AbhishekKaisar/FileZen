import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:file_zen/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Load empty env so Env helper works in test without .env file.
    dotenv.load(mergeWith: {});

    await tester.pumpWidget(const FileZenApp());
    await tester.pumpAndSettle();

    expect(find.byType(FileZenApp), findsOneWidget);
  });
}
