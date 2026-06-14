import 'package:flutter_test/flutter_test.dart';
import 'package:format_conv/screens/home_screen.dart';

void main() {
  testWidgets('Home screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeScreen());
    expect(find.text('Format Converter'), findsOneWidget);
  });
}
