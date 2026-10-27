# Fate Flip 🪙

A hyper-polished, zero-bloat 3D coin toss decision helper built with Flutter and Riverpod.

## How to Run

```bash
flutter run
```

## How to Tweak Physics & Tunables

All tunable parameters live in `lib/features/toss/toss_config.dart`:
- **Apex Height**: edit `tossApexHeight` (default `-240.0` px).
- **Spins Range**: edit `minSpins` (default `5`) and `maxSpins` (default `8`).
- **Flip Duration**: edit `flipDuration` (default `1700` ms) or `reducedMotionDuration` (`500` ms).
