
import 'package:flutter_test/flutter_test.dart';
import 'package:routesync/main.dart';

void main() {
  testWidgets('Flutter app displays the counter demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Flutter Demo Home Page'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });
}
