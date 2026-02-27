// Basic smoke test for the RG AModule app.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:divinepooja/main.dart';

void main() {
  testWidgets('App smoke test – splash renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: DivinePoojaApp()),
    );
    // Allow the first frame to render.
    await tester.pump();
    // The app should render without throwing.
    expect(find.byType(DivinePoojaApp), findsOneWidget);
  });
}
