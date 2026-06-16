import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format_conv/screens/home_screen.dart';

void main() {
  Future<void> pumpHomeScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('Home screen renders workbench sections',
      (WidgetTester tester) async {
    await pumpHomeScreen(tester);

    expect(find.text('Add Files', skipOffstage: false), findsOneWidget);
    expect(find.text('Added Files', skipOffstage: false), findsOneWidget);
    expect(find.text('Format Selection', skipOffstage: false), findsOneWidget);
    expect(find.text('Results', skipOffstage: false), findsOneWidget);
    expect(find.text('Settings', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Home screen shows empty format guidance',
      (WidgetTester tester) async {
    await pumpHomeScreen(tester);

    expect(
      find.text(
        'Add files, then choose a target format or drag files onto a compatible format.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
  });
}
