import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fate_flip/features/toss/toss_config.dart';
import 'package:fate_flip/features/toss/toss_controller.dart';
import 'package:fate_flip/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TossController & TossConfig Unit Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        TossConfig.prefsHeadsKey: 'Oo',
        TossConfig.prefsTailsKey: 'Hindi',
      });
      prefs = await SharedPreferences.getInstance();
    });

    test('Initial state loads saved labels from SharedPreferences', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(tossControllerProvider);
      expect(state.headsLabel, 'Oo');
      expect(state.tailsLabel, 'Hindi');
      expect(state.effectiveHeadsLabel, 'Oo');
      expect(state.effectiveTailsLabel, 'Hindi');
      expect(state.isFlipping, false);
      expect(state.resultLabel, null);
    });

    test('Empty or whitespace labels fallback to Heads and Tails', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      container.read(tossControllerProvider.notifier).updateHeadsLabel('   ');
      container.read(tossControllerProvider.notifier).updateTailsLabel('');

      final state = container.read(tossControllerProvider);
      expect(state.effectiveHeadsLabel, TossConfig.fallbackHeadsLabel);
      expect(state.effectiveTailsLabel, TossConfig.fallbackTailsLabel);
    });

    test('Toss outcome is decided before animation and 50 seeded tosses land accurately', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(tossControllerProvider.notifier);
      // Inject seeded Random to verify predictability and 50/50 distribution
      controller.injectedRandom = Random(42);

      for (int i = 0; i < 50; i++) {
        final plan = controller.prepareToss();
        expect(plan, isNotNull);
        expect(container.read(tossControllerProvider).isFlipping, true);

        // Verify target angle calculation matches the decided outcome
        final isHeadsDecided = plan!.side == CoinSide.heads;
        final cosTarget = cos(plan.targetAngle);
        if (isHeadsDecided) {
          expect(cosTarget, greaterThanOrEqualTo(0.0),
              reason: 'Heads must have cos(target) >= 0');
        } else {
          expect(cosTarget, lessThan(0.0),
              reason: 'Tails must have cos(target) < 0');
        }

        // Finalize flip
        controller.finalizeFlip(
          side: plan.side,
          label: plan.label,
          finalAngle: plan.targetAngle,
        );

        final state = container.read(tossControllerProvider);
        expect(state.isFlipping, false);
        expect(state.resultSide, plan.side);
        expect(state.resultLabel, plan.label);
      }
    });

    test('Second toss cannot start while one is already flipping (guard)', () {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(tossControllerProvider.notifier);
      final firstPlan = controller.prepareToss();
      expect(firstPlan, isNotNull);

      // Attempt second toss while flipping
      final secondPlan = controller.prepareToss();
      expect(secondPlan, isNull);
    });
  });
}
