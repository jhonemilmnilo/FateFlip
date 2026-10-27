import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'toss_config.dart';
import 'toss_controller.dart';
import 'widgets/coin_view.dart';
import 'widgets/toss_fab.dart';

class TossScreen extends ConsumerStatefulWidget {
  const TossScreen({super.key});

  @override
  ConsumerState<TossScreen> createState() => _TossScreenState();
}

class _TossScreenState extends ConsumerState<TossScreen> {
  late final TextEditingController _headsController;
  late final TextEditingController _tailsController;
  final GlobalKey<CoinViewState> _coinViewKey = GlobalKey<CoinViewState>();

  @override
  void initState() {
    super.initState();
    final initial = ref.read(tossControllerProvider);
    _headsController = TextEditingController(text: initial.headsLabel);
    _tailsController = TextEditingController(text: initial.tailsLabel);
  }

  ({CoinSide side, String label, double targetAngle, int spins, Duration duration})? _currentTossPlan;

  @override
  void dispose() {
    _headsController.dispose();
    _tailsController.dispose();
    super.dispose();
  }

  void _onTossPressed() {
    final controller = ref.read(tossControllerProvider.notifier);
    final tossPlan = controller.prepareToss();
    if (tossPlan == null) return;

    _currentTossPlan = tossPlan;

    // Trigger physical coin flip with realistic variable duration
    _coinViewKey.currentState?.startFlip(
      targetAngle: tossPlan.targetAngle,
      spins: tossPlan.spins,
      duration: tossPlan.duration,
    );
  }

  void _onFlipComplete(double finalAngle) {
    final plan = _currentTossPlan;
    final tossState = ref.read(tossControllerProvider);

    // Finalize flip outcome
    final isHeads = math.cos(finalAngle) >= 0;
    final winningSide = plan?.side ?? (isHeads ? CoinSide.heads : CoinSide.tails);
    final winningLabel = plan?.label ??
        (winningSide == CoinSide.heads
            ? tossState.effectiveHeadsLabel
            : tossState.effectiveTailsLabel);

    ref.read(tossControllerProvider.notifier).finalizeFlip(
          side: winningSide,
          label: winningLabel,
          finalAngle: finalAngle,
        );
  }

  @override
  Widget build(BuildContext context) {
    final tossState = ref.watch(tossControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // Coin sizing according to spec
            final targetCoinSize = math.min(
              screenWidth * TossConfig.coinWidthFactor,
              TossConfig.maxCoinDiameter,
            );
            // Dynamic scale on shorter screens
            final coinDiameter = math.min(targetCoinSize, screenHeight * 0.36);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 36.0), // Elevated bottom space
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 52.0,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Spacer leaves the top area completely clear and serene
                      const Spacer(),

                      // STAGE: Coin & ground shadow sitting right on top of controls
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Center(
                          child: CoinView(
                            key: _coinViewKey,
                            diameter: coinDiameter,
                            headsLabel: tossState.effectiveHeadsLabel,
                            tailsLabel: tossState.effectiveTailsLabel,
                            isFlipping: tossState.isFlipping,
                            currentAngle: tossState.currentAngle,
                            onAnimationComplete: _onFlipComplete,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // BOTTOM: Inputs on the left, Toss FAB on the right
                      _buildBottomControlBar(theme, tossState),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// BOTTOM: Side-by-side inputs on the left + Toss FAB fixed on the bottom right
  Widget _buildBottomControlBar(ThemeData theme, TossState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Inputs stacked/aligned on the bottom left
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heads Input
              Text(
                'Heads',
                style: TextStyle(
                  fontSize: TossConfig.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _headsController,
                maxLength: TossConfig.maxLabelLength,
                style: const TextStyle(fontSize: TossConfig.inputFontSize),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: TossConfig.fallbackHeadsLabel,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) {
                  ref.read(tossControllerProvider.notifier).updateHeadsLabel(val);
                },
              ),
              const SizedBox(height: 8),

              // Tails Input
              Text(
                'Tails',
                style: TextStyle(
                  fontSize: TossConfig.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _tailsController,
                maxLength: TossConfig.maxLabelLength,
                style: const TextStyle(fontSize: TossConfig.inputFontSize),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: TossConfig.fallbackTailsLabel,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onChanged: (val) {
                  ref.read(tossControllerProvider.notifier).updateTailsLabel(val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Fixed Toss FAB on bottom right
        TossFab(
          isFlipping: state.isFlipping,
          onPressed: _onTossPressed,
        ),
      ],
    );
  }
}
