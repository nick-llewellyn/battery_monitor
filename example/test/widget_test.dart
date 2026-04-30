// Smoke test for the example app: confirms it boots without throwing
// and renders the main scaffold. The example builds a `BatteryProvider`
// in `initState`, which subscribes to platform EventChannels; in the
// test environment those channels return no data, so the screen stays
// in the initial loading state.

import 'package:battery_monitor_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots and shows the example scaffold', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const BatteryStatusExampleApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('battery_status example'), findsWidgets);
  });
}
