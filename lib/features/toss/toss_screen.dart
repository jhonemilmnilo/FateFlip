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
      begin: const Offset(0.0, TossConfig.resultSlideOffset / 22.0),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          right: TossConfig.fabMargin,
          bottom: TossConfig.fabMargin,
        ),
        child: TossFab(
          isFlipping: tossState.isFlipping,
          onPressed: _onTossPressed,
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;

            // Coin sizing according to spec 5.2
            final targetCoinSize = math.min(
              screenWidth * TossConfig.coinWidthFactor,
              TossConfig.maxCoinDiameter,
            );
            // Dynamic scale on short screens (e.g. landscape/small devices)
            final coinDiameter = math.min(targetCoinSize, screenHeight * 0.35);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20.0,
                16.0,
                20.0,
                TossConfig.scrollBottomPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - TossConfig.scrollBottomPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Two text fields side-by-side
                    _buildInputSection(theme, tossState),

                    const SizedBox(height: 24),

                    // Center Stage: Coin & ground shadow
                    Center(
                      child: CoinView(
                        key: _coinViewKey,
                        diameter: coinDiameter,
                        headsLabel: tossState.effectiveHeadsLabel,
                        tailsLabel: tossState.effectiveTailsLabel,
                        isFlipping: tossState.isFlipping,
                        currentAngle: tossState.currentAngle,
                        onAnimationComplete: () {
                          // The outcome was decided in prepareToss and passed into finalizeFlip
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

                    const SizedBox(height: 24),

                    // Bottom: Result announcement area
                    _buildResultArea(theme, tossState),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputSection(ThemeData theme, TossState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heads Input
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Heads (Tigre)',
                style: TextStyle(
                  fontSize: TossConfig.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _headsController,
                maxLength: TossConfig.maxLabelLength,
                style: const TextStyle(fontSize: TossConfig.inputFontSize),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: TossConfig.fallbackHeadsLabel,
                ),
                onChanged: (val) {
                  ref.read(tossControllerProvider.notifier).updateHeadsLabel(val);
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        // Tails Input
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tails (Tao)',
                style: TextStyle(
                  fontSize: TossConfig.labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _tailsController,
                maxLength: TossConfig.maxLabelLength,
                style: const TextStyle(fontSize: TossConfig.inputFontSize),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: TossConfig.fallbackTailsLabel,
                ),
                onChanged: (val) {
                  ref.read(tossControllerProvider.notifier).updateTailsLabel(val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultArea(ThemeData theme, TossState state) {
    final hasResult = state.resultLabel != null && !state.isFlipping;

    return Semantics(
      liveRegion: true,
      label: hasResult
          ? 'Winner is ${state.resultLabel}, ${state.resultSide == CoinSide.heads ? 'Heads' : 'Tails'}'
          : 'Pindutin ang Toss',
      child: AnimatedBuilder(
        animation: _resultFadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: hasResult ? _resultFadeAnimation.value : 1.0,
            child: Transform.translate(
              offset: hasResult
                  ? _resultSlideAnimation.value
                  : Offset.zero,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasResult) ...[
                Text(
                  state.resultLabel!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: TossConfig.resultFontSize,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.resultSide == CoinSide.heads ? 'Heads' : 'Tails',
                  style: TextStyle(
                    fontSize: TossConfig.labelFontSize,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ] else ...[
                Text(
                  'Pindutin ang Toss',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: TossConfig.resultFontSize - 2,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
