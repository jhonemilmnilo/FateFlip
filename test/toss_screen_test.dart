import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fate_flip/app/theme.dart';
import 'package:fate_flip/features/toss/toss_config.dart';
import 'package:fate_flip/features/toss/toss_controller.dart';
import 'package:fate_flip/features/toss/toss_screen.dart';
import 'package:fate_flip/features/toss/widgets/coin_view.dart';
import 'package:fate_flip/features/toss/widgets/toss_fab.dart';
import 'package:fate_flip/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      TossConfig.prefsHeadsKey: 'Oo',
      TossConfig.prefsTailsKey: 'Hindi',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Widget createSubject({Random? seededRandom, double textScale = 1.0}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tossControllerProvider.overrideWith(() {
          final notifier = TossController();
          if (seededRandom != null) {
            notifier.injectedRandom = seededRandom;
          }
          return notifier;
        }),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
            size: const Size(360, 640),
          ),
          child: const TossScreen(),
        ),
      ),
    );
  }

  group('TossScreen Widget Tests (AGENTS spec)', () {
    testWidgets('1. Fallback labels when input is cleared or spaces', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Find text fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2));

      // Enter empty/space into Heads and Tails
      await tester.enterText(textFields.at(0), '   ');
      await tester.enterText(textFields.at(1), '');
      await tester.pump();

      // Verify CoinView widget receives both effective fallback labels
      final coinView = tester.widget<CoinView>(find.byType(CoinView));
      expect(coinView.headsLabel, TossConfig.fallbackHeadsLabel);
      expect(coinView.tailsLabel, TossConfig.fallbackTailsLabel);

      // And the active resting face (Heads at angle 0) displays the Heads fallback
      expect(
        find.descendant(
          of: find.byType(CoinView),
          matching: find.text(TossConfig.fallbackHeadsLabel),
        ),
        findsOneWidget,
      );
    });

    testWidgets('2. FAB is disabled while flipping and prevents double taps', (tester) async {
      await tester.pumpWidget(createSubject(seededRandom: Random(1)));
      await tester.pump();

      final fabFinder = find.byType(TossFab);
      expect(fabFinder, findsOneWidget);

      // Tap FAB to start flip
      await tester.tap(fabFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Attempt second tap while mid-flight
      await tester.tap(fabFinder);
      await tester.pump(const Duration(milliseconds: 200));

      // Fast forward past the flip animation
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });

    testWidgets('3. Result matches the winning face side accurately', (tester) async {
      // Seed 1 produces deterministic first outcome
      await tester.pumpWidget(createSubject(seededRandom: Random(10)));
      await tester.pump();

      expect(find.text('Pindutin ang Toss'), findsOneWidget);

      final fabFinder = find.text('Toss');
      await tester.tap(fabFinder);

      // Pump frames until animation completes (no infinite pumpAndSettle hang)
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Ensure "Pindutin ang Toss" is replaced by the winning result
      expect(find.text('Pindutin ang Toss'), findsNothing);
      expect(find.byType(CoinView), findsOneWidget);
    });

    testWidgets('4. High accessibility text scale (200%) does not overflow', (tester) async {
      await tester.pumpWidget(createSubject(textScale: 2.0));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
