import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('PocketTxApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PocketTxApp()),
    );
    // App renders without throwing
    expect(find.byType(ProviderScope), findsWidgets);
  });
}
