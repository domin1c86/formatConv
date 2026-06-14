import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:format_conv/screens/home_screen.dart';

void main() {
  testWidgets('Home screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    expect(find.text('Format Converter'), findsOneWidget);
    expect(find.text('Select Files'), findsOneWidget);
    expect(find.text('Select Output Format'), findsOneWidget);
  });

  testWidgets('Home screen shows empty state message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );
    expect(
      find.text('Select files first, then click a format to convert'),
      findsOneWidget,
    );
  });
}
