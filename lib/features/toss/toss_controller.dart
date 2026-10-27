import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import 'toss_config.dart';

enum CoinSide { heads, tails }

class TossState {
  final String headsLabel;
  final String tailsLabel;
  final bool isFlipping;
  final CoinSide? resultSide;
  final String? resultLabel;
  final double currentAngle;

  const TossState({
    required this.headsLabel,
    required this.tailsLabel,
    required this.isFlipping,
    required this.resultSide,
    required this.resultLabel,
    required this.currentAngle,
  });

  TossState copyWith({
    String? headsLabel,
    String? tailsLabel,
    bool? isFlipping,
    CoinSide? Function()? resultSide,
    String? Function()? resultLabel,
    double? currentAngle,
  }) {
    return TossState(
      headsLabel: headsLabel ?? this.headsLabel,
      tailsLabel: tailsLabel ?? this.tailsLabel,
      isFlipping: isFlipping ?? this.isFlipping,
      resultSide: resultSide != null ? resultSide() : this.resultSide,
      resultLabel: resultLabel != null ? resultLabel() : this.resultLabel,
      currentAngle: currentAngle ?? this.currentAngle,
    );
  }

  String get effectiveHeadsLabel {
    final trimmed = headsLabel.trim();
    return trimmed.isEmpty ? TossConfig.fallbackHeadsLabel : trimmed;
  }

  String get effectiveTailsLabel {
    final trimmed = tailsLabel.trim();
    return trimmed.isEmpty ? TossConfig.fallbackTailsLabel : trimmed;
  }
}

class TossController extends Notifier<TossState> {
  late final SharedPreferences _prefs;
  late final Random _random;
  Timer? _debounceTimer;

  // Injection of random (defaults to Random.secure() in production)
  Random? injectedRandom;

  @override
  TossState build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    _random = injectedRandom ?? Random.secure();

    final savedHeads = _prefs.getString(TossConfig.prefsHeadsKey) ?? TossConfig.defaultHeadsLabel;
    final savedTails = _prefs.getString(TossConfig.prefsTailsKey) ?? TossConfig.defaultTailsLabel;

    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    return TossState(
      headsLabel: savedHeads,
      tailsLabel: savedTails,
      isFlipping: false,
      resultSide: null,
      resultLabel: null,
      currentAngle: 0.0,
    );
  }

  void updateHeadsLabel(String text) {
    state = state.copyWith(headsLabel: text);
    _schedulePersist(TossConfig.prefsHeadsKey, text);
  }

  void updateTailsLabel(String text) {
    state = state.copyWith(tailsLabel: text);
    _schedulePersist(TossConfig.prefsTailsKey, text);
  }

  void _schedulePersist(String key, String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(TossConfig.prefsDebounce, () {
      _prefs.setString(key, value);
    });
  }

  /// Decides outcome FIRST before starting animation (spec rule 3 & 4)
  ({CoinSide side, String label, double targetAngle, int spins})? prepareToss() {
    if (state.isFlipping) return null;

    final isHeads = _random.nextBool();
    final chosenSide = isHeads ? CoinSide.heads : CoinSide.tails;
    final winningLabel = isHeads ? state.effectiveHeadsLabel : state.effectiveTailsLabel;

    final spins = TossConfig.minSpins + _random.nextInt(TossConfig.maxSpins - TossConfig.minSpins + 1);
    final targetAngle = TossConfig.calculateTargetAngle(
      currentAngle: state.currentAngle,
      isHeads: isHeads,
      spins: spins,
    );

    // Clear old result the moment a new toss starts (spec 5.3)
    state = state.copyWith(
      isFlipping: true,
      resultSide: () => null,
      resultLabel: () => null,
    );

    return (
      side: chosenSide,
      label: winningLabel,
      targetAngle: targetAngle,
      spins: spins,
    );
  }

  /// Finalizes flip outcome after settle
  void finalizeFlip({
    required CoinSide side,
    required String label,
    required double finalAngle,
  }) {
    // Normalize angle to prevent overflow (spec rule 3 & 8)
    final normalized = finalAngle % (2 * pi);

    state = state.copyWith(
      isFlipping: false,
      resultSide: () => side,
      resultLabel: () => label,
      currentAngle: normalized,
    );
  }
}

final tossControllerProvider = NotifierProvider<TossController, TossState>(() {
  return TossController();
});
