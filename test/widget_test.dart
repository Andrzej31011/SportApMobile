import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sport_ap_mobile/app.dart';

void main() {
  testWidgets('app starts and shows auth bootstrap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SportApApp()),
    );

    expect(find.text('Ladowanie sesji...'), findsOneWidget);
  });
}
