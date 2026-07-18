import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/holdToRevealListener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget buildTestWidget() {
  return MaterialApp(
    home: Scaffold(
      body: HoldToRevealListener(
        builder: (context, isRevealed) => SizedBox(
          width: 200,
          height: 200,
          child: Text(isRevealed ? 'revealed' : 'hidden'),
        ),
      ),
    ),
  );
}

void main() {
  group('HoldToRevealListener', () {
    testWidgets('starts hidden', (tester) async {
      appStateSettings = {"obscureAmounts": true};
      await tester.pumpWidget(buildTestWidget());
      expect(find.text('hidden'), findsOneWidget);
    });

    testWidgets('press reveals, stays revealed while holding', (tester) async {
      appStateSettings = {"obscureAmounts": true};
      await tester.pumpWidget(buildTestWidget());

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
      await tester.pump();
      expect(find.text('revealed'), findsOneWidget);

      // Still revealed while held, even after the collapse duration.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('revealed'), findsOneWidget);

      await gesture.up();
      await tester.pump();
    });

    testWidgets('re-obscures 2 seconds after release', (tester) async {
      appStateSettings = {"obscureAmounts": true};
      await tester.pumpWidget(buildTestWidget());

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      // Still revealed right after release...
      expect(find.text('revealed'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.text('revealed'), findsOneWidget);

      // ...and hidden once the 2 second timer fires.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('hidden'), findsOneWidget);
    });

    testWidgets('does nothing when obscureAmounts is off', (tester) async {
      appStateSettings = {"obscureAmounts": false};
      await tester.pumpWidget(buildTestWidget());

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
      await tester.pump();
      expect(find.text('hidden'), findsOneWidget);

      await gesture.up();
      await tester.pump();
      expect(find.text('hidden'), findsOneWidget);
    });

    testWidgets('pressing again cancels pending collapse', (tester) async {
      appStateSettings = {"obscureAmounts": true};
      await tester.pumpWidget(buildTestWidget());

      // Press and release: collapse timer starts.
      final first =
          await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
      await tester.pump();
      await first.up();
      await tester.pump(const Duration(milliseconds: 1500));

      // Press again before the timer fires: reveal persists.
      final second =
          await tester.startGesture(tester.getCenter(find.byType(SizedBox)));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('revealed'), findsOneWidget);

      await second.up();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('hidden'), findsOneWidget);
    });
  });
}
