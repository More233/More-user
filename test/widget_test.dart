import 'package:flutter_test/flutter_test.dart';
import 'package:moor/main.dart';
import 'package:moor/sections/splash/splash_screen.dart';

void main() {
  testWidgets('App launches with SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our SplashScreen is rendered.
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
