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

class _TossScreenState extends ConsumerState<TossScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _headsController;
  late final TextEditingController _tailsController;
  final GlobalKey<CoinViewState> _coinViewKey = GlobalKey<CoinViewState>();

  late final AnimationController _resultFadeController;
  late final Animation<double> _resultFadeAnimation;
  late final Animation<Offset> _resultSlideAnimation;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(tossControllerProvider);
    _headsController = TextEditingController(text: initial.headsLabel);
    _tailsController = TextEditingController(text: initial.tailsLabel);

    _resultFadeController = AnimationController(
      vsync: this,
      duration: TossConfig.resultFadeDuration,
    );

    _resultFadeAnimation = CurvedAnimation(
      parent: _resultFadeController,
      curve: Curves.easeOut,
    );

    _resultSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, -TossConfig.resultSlideOffset / 22.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _resultFadeController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _headsController.dispose();
    _tailsController.dispose();
    _resultFadeController.dispose();
    super.dispose();
  }

  void _onTossPressed() {
    final controller = ref.read(tossControllerProvider.notifier);
    final tossPlan = controller.prepareToss();
    if (tossPlan == null) return;

    _resultFadeController.reset();

    // Trigger physical coin flip
    _coinViewKey.currentState?.startFlip(
      targetAngle: tossPlan.targetAngle,
      spins: tossPlan.spins,
    );
  }

  void _onFlipComplete({
    required CoinSide side,
    required String label,
    required double finalAngle,
  }) {
    ref.read(tossControllerProvider.notifier).finalizeFlip(
          side: side,
          label: label,
          finalAngle: finalAngle,
        );

    _resultFadeController.forward();
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
            final coinDiameter = math.min(targetCoinSize, screenHeight * 0.38);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TOP: Result announcement area
                    _buildResultArea(theme, tossState),

                    const SizedBox(height: 72),

                    // CENTER STAGE: Coin & ground shadow (shifted lower for maximum flip clearance)
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                      child: Center(
                        child: CoinView(
                          key: _coinViewKey,
                          diameter: coinDiameter,
                          headsLabel: tossState.effectiveHeadsLabel,
                          tailsLabel: tossState.effectiveTailsLabel,
                          isFlipping: tossState.isFlipping,
                          currentAngle: tossState.currentAngle,
                          onAnimationComplete: () {
                            final isHeads = math.cos(tossState.currentAngle) >= 0;
                            final winningSide = isHeads ? CoinSide.heads : CoinSide.tails;
                            final winningLabel = isHeads
                                ? tossState.effectiveHeadsLabel
                                : tossState.effectiveTailsLabel;

                            _onFlipComplete(
                              side: winningSide,
                              label: winningLabel,
                              finalAngle: tossState.currentAngle,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BOTTOM: Inputs on the left, Toss FAB on the right
                    _buildBottomControlBar(theme, tossState),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// TOP: Clean result banner (Empty until flip settles and produces a winner)
  Widget _buildResultArea(ThemeData theme, TossState state) {
    final hasResult = state.resultLabel != null && !state.isFlipping;

    return Semantics(
      liveRegion: true,
      label: hasResult
          ? 'Winner is ${state.resultLabel}, ${state.resultSide == CoinSide.heads ? 'Heads' : 'Tails'}'
          : '',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 76),
        child: AnimatedBuilder(
          animation: _resultFadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: hasResult ? _resultFadeAnimation.value : 0.0,
              child: Transform.translate(
                offset: hasResult ? _resultSlideAnimation.value : Offset.zero,
                child: child,
              ),
            );
          },
          child: hasResult
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.resultLabel!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: TossConfig.resultFontSize + 4,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.resultSide == CoinSide.heads ? 'Heads' : 'Tails',
                        style: TextStyle(
                          fontSize: TossConfig.labelFontSize,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
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
