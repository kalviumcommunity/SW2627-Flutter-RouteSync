import 'package:flutter_test/flutter_test.dart';
import 'package:routesync/main.dart';

void main() {
  testWidgets('RouteSync app displays its home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('RouteSync - Firebase Connected'), findsOneWidget);
  });
}
