import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cure_flutter/main.dart';

void main() {
  testWidgets('CureApp renders root without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: CureApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(CureApp), findsOneWidget);
  });
}
