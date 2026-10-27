# AGENTS.md: "Fate Flip" Flutter App Build Spec and Guardrails

> Read this whole file before writing any code. Re-read the **Hard Rules** and
> **Definition of Done** before you say anything is finished.

---

## 0. Who you are

You are a Principal Flutter engineer and motion designer (20 years of
experience). You ship polished, performant consumer apps. You make small,
verified steps. You do not guess APIs, you do not invent packages, and you
do not claim something works until you have run it.

## 1. What we are building

**Toss** is a single-screen decision helper.

- The person types a label for **Heads** and a label for **Tails**.
- A floating **Toss** button sits fixed at the **bottom-right**.
- Tapping it flips a realistic 3D coin: it flies up, spins, falls, bounces
  twice, and settles.
- The outcome is **random 50/50**. The label the person wrote for the winning
  side is shown as the result.

Nothing else. No accounts, no backend, no ads, no analytics.

### Out of scope (do NOT build unless I ask)

History strip, sound effects, multiple coins, settings page, onboarding,
sharing, login, cloud sync, localization framework, tablet-specific layout.
If you think one of these is a good idea, mention it in one line at the end
and do not implement it.

---

## 2. Stack (locked)

| Area | Decision |
|---|---|
| Framework | Flutter stable channel, Dart 3, null safety, Material 3 |
| State | `flutter_riverpod` 2.x using `Notifier` / `NotifierProvider`. **No code generation, no build_runner** |
| Persistence | `shared_preferences` only |
| Animation | Built in: `AnimationController`, `TweenSequence`, `Curves`, `Transform`, `Matrix4`, `CustomPainter`. **No animation packages, no Lottie, no Rive, no images/GIFs of a coin** |
| Fonts | System font or one bundled font. **No `google_fonts` runtime fetching** (breaks offline) |
| Targets | Android and iOS portrait. Web is for quick preview only |

Rules for dependencies:

1. Before adding any package, run `flutter pub add <pkg>` (do not hand-edit
   versions from memory) and tell me what you added and why.
2. Do not add a package that is not in the table above without asking.
3. Do not upgrade Flutter, Gradle, AGP, Kotlin, or Xcode settings unless a
   build error forces it. If forced, change one thing at a time and explain.

---

## 3. Hard Rules (the "never" list)

### Process
- **Never** claim "done" without running `flutter analyze` (0 issues) and
  `flutter test` (all pass), and running the app at least once.
- **Never** leave `TODO`, placeholder code, fake data, or commented-out
  blocks in delivered files.
- **Never** rewrite a whole file to change a few lines. Make targeted edits.
- **Never** refactor working code outside the current phase.
- **Never** add features from the out-of-scope list.
- **Never** hallucinate APIs. If unsure a method exists, check the SDK
  source or docs, or let the analyzer tell you.
- **Never** loop forever retrying the same failing fix. After 2 failed
  attempts on the same error, stop, summarize what you tried, and ask me.
- **Never** hide errors with empty `catch` blocks or `// ignore:` comments to
  silence the analyzer.
- **Never** commit generated build output, `.dart_tool`, `build/`, or IDE
  junk.

### Flutter / performance
- **Never** call `setState` on the whole screen every animation frame. Only
  an `AnimatedBuilder` subtree may rebuild per frame.
- **Never** use `Opacity`, `ClipRRect`, `BackdropFilter`, `ImageFiltered`,
  or `saveLayer`-triggering widgets around the animating coin. Use
  `Paint.color` alpha and `MaskFilter.blur` inside a `CustomPainter`.
- **Never** allocate new `Paint`, `Gradient`, `TextPainter`, or `Path`
  objects every frame if they can be cached. Cache shaders by size.
- **Never** run animation logic inside `build()` beyond reading
  `animation.value`.
- **Never** forget `RepaintBoundary` around the stage.
- **Never** forget to `dispose()` controllers, timers, and text controllers.
- **Never** use deprecated APIs. Known ones on current Flutter:
  `withOpacity` (use `withValues(alpha:)`), `MaterialStateProperty` (use
  `WidgetStateProperty`), `textScaleFactor` (use `textScaler`),
  `WillPopScope` (use `PopScope`), `Color.value`/`.red`/`.green`/`.blue`
  (use component accessors). If the analyzer shows a deprecation, follow
  its suggested replacement. This includes `Matrix4` helpers; if
  `translate`/`scale` are flagged, use the suggested newer methods.

### Logic
- **Never** derive the result from the animation angle. Decide the outcome
  **first** with `Random.secure()`, then animate toward it.
- **Never** hardcode `Random()` inside the controller. Inject it
  (`Random` parameter with a default) so tests can pass a seeded one.
- **Never** let a second toss start while one is running.
- **Never** let the angle grow forever. Normalize it after landing.

---

## 4. Architecture (exact layout)

```
lib/
  main.dart                      // ensureInitialized, orientation lock, prefs, runApp
  app/
    theme.dart                   // light + dark ColorScheme, text scale
  features/toss/
    toss_config.dart             // ALL tunable numbers live here
    toss_controller.dart         // Riverpod Notifier: labels, isFlipping, result, angle, persistence
    toss_screen.dart             // layout only
    widgets/
      coin_view.dart             // AnimationController + 3D transform + face switching
      coin_face_painter.dart     // CustomPainter for brass/silver faces + rim
      ground_shadow.dart
      toss_fab.dart
test/
  toss_controller_test.dart
  toss_screen_test.dart
```

Rules:
- Business logic in the controller. Animation in `coin_view.dart`'s State
  (`SingleTickerProviderStateMixin`). Layout in the screen.
- Widgets are small and `const` where possible.
- **Every magic number** (height, spins, duration, perspective, bounce
  sizes) lives in `toss_config.dart` as a named constant, so I can tune
  the feel in one place.

---

## 5. Screen spec

Top to bottom:

1. **Two text fields side by side**: "Heads" and "Tails". Max 40 chars.
   Defaults: `Oo` and `Hindi`. Filled, rounded, clear focus state. Faces
   update live while typing. Font size 16 or larger so iOS does not zoom.
2. **Stage**: coin centered, about 55% of screen width (max 240px), with a
   ground shadow below.
3. **Result**: the winning label in large type (22) with a small caption
   ("Heads" or "Tails") underneath. Before the first toss show
   "Pindutin ang Toss". Clear the old result the moment a new toss starts.
4. **Toss FAB**: circular 76px, fixed bottom-right, 20px margin, inside
   `SafeArea`. Dimmed and non-tappable while flipping. Text "Toss".

Layout safety:
- Wrap content in `LayoutBuilder` + `SingleChildScrollView` so nothing
  overflows when the keyboard opens or when the font is scaled to 200%.
- The stage shrinks gracefully on short screens (small phones, landscape
  should not crash even though we lock portrait).
- The FAB must stay reachable and must not cover the result text. Reserve
  bottom padding of at least 100px in the scroll area.
- Empty label falls back to "Heads" / "Tails". Trim whitespace.

---

## 6. Coin visual spec

All drawn with `CustomPainter`. No image assets.

- **Heads face**: warm brass radial gradient. **Tails face**: cool silver.
- Ring bevel: two concentric strokes (one light, one dark) near the edge.
- Moving specular highlight: a gradient whose angle depends on the current
  rotation, so the metal looks shiny while it spins.
- **Thickness**: fake it with 6 to 10 thin discs stacked along Z between the
  faces (`Matrix4` Z translation), in a darker edge color. This is what
  makes the coin look solid at mid-flip. If it flickers or sorts wrong,
  fall back to drawing a single rim band whose visible height is
  `thickness * sin(angle).abs()`.
- **Label text**: centered inside the inner ring, `FittedBox` with
  `BoxFit.scaleDown`, weight 800, 1px light emboss shadow, max 3 lines.
  Long words must never overflow the coin.
- `shouldRepaint` must compare only the fields that actually change.

---

## 7. Animation spec (the heart of the app)

One `AnimationController`, duration **1700 ms** (use **500 ms**, no bounce,
when `MediaQuery.disableAnimations` is true). Three coordinated channels.

### A. Flip (rotateX)
```dart
Matrix4.identity()
  ..setEntry(3, 2, 0.0012)   // perspective FIRST
  ..rotateX(angle);          // then rotation
// Transform(alignment: Alignment.center, transform: m, child: ...)
```
- `isHeads = rng.nextBool()` is decided **before** `controller.forward()`.
- `target = floorToMultipleOf2Pi(current) + spins * 2π + (isHeads ? 0 : π)`
  with `spins` a random int 5..8. If `target <= current`, add `2π`.
- Easing: fast launch, long slow tail (`Curves.easeOutCubic` or a custom
  cubic like `Cubic(.25, .55, .35, 1)`).
- Face selection per frame: `cos(angle) >= 0` shows front, otherwise back.
  The **back face is pre-rotated by π around X** so its text is never
  mirrored or upside down.

### B. Toss arc (translateY + scale), `TweenSequence`
| Phase | Motion | Weight | Curve |
|---|---|---|---|
| Launch | 0 → -240 px | 45 | easeOutQuad |
| Fall | -240 → 0 | 37 | easeInQuad |
| Bounce 1 | 0 → -22 → 0 | 8 | easeOut / easeIn |
| Bounce 2 | 0 → -6 → 0 | 5 | easeOut / easeIn |
| Settle | hold | 5 | linear |

Weights must sum to 100. Scale goes 1.0 → 1.3 at the apex and back to 1.0
on landing.

### C. Ground shadow
Ellipse, `MaskFilter.blur` inside a painter. At the apex: scale 0.45,
opacity 0.4. On landing: back to 1.0. Tiny squash at each bounce.

### D. Polish
- Random wobble: ±6 px horizontal, ±0.08 rad rotateZ during flight. Seed
  it per toss so it does not jitter randomly every frame.
- Result text appears **after** settle: fade + 8 px slide up, 220 ms.
- Haptics: `mediumImpact` on launch, `lightImpact` on each bounce,
  `selectionClick` when the result shows. (They are no-ops on web; that is
  fine.)
- FAB press: scale to 0.92 and release in 120 ms.

---

## 8. Known pitfalls and how to avoid them (read carefully)

| # | Symptom | Likely cause | Fix |
|---|---|---|---|
| 1 | Text on the back face is mirrored or upside down | Back face not pre-rotated | Rotate back face by π around **X** (not Y) |
| 2 | Coin looks flat, no depth | `setEntry(3,2,…)` missing, applied after rotate, or value too small | Perspective entry before rotation, about 0.001 to 0.0015 |
| 3 | Coin looks paper-thin mid-flip | No thickness layers | Stack 6 to 10 discs along Z or draw the rim band |
| 4 | Face flickers at exactly 90° | Both faces visible / z-fighting | Switch face by `cos(angle)`; hide the face with `cos == 0` side by using `>=` on one only |
| 5 | Wrong side shown after landing | Angle not an exact multiple of π, or outcome derived from angle | Compute target from the pre-decided outcome; normalize after landing |
| 6 | Second tap breaks the animation | Controller restarted mid-flight | Guard with `isFlipping`; disable FAB |
| 7 | Coin does not flip on the 2nd toss | Controller not reset, angle not advanced | Keep `currentAngle` in state; each toss animates from `current` to a larger `target` |
| 8 | Weird snap at the end | Angle normalized while still animating | Normalize only in the completed-status callback, in one frame, no visible jump (2π multiple) |
| 9 | Jank on mid-range Android | Per-frame allocations, blur, opacity layers | Cache paints/shaders, `RepaintBoundary`, no `Opacity` / `saveLayer` |
| 10 | "RenderFlex overflowed" when keyboard opens | Fixed-height column | `LayoutBuilder` + `SingleChildScrollView`, flexible stage height |
| 11 | FAB hides behind keyboard or covers text | Wrong placement | Use `Scaffold.floatingActionButton` with `endFloat`; reserve scroll padding |
| 12 | Long labels overflow the coin | No fitting | `FittedBox(scaleDown)` + `maxLines` + `TextOverflow.ellipsis` |
| 13 | Reduced-motion users still get a wild flip | `MediaQuery` read in `initState` | Read in `didChangeDependencies`, set duration there |
| 14 | `LateInitializationError` on hot reload | Controllers created in `late` fields incorrectly | Create in `initState`, dispose in `dispose` |
| 15 | Tests hang forever | `pumpAndSettle()` with a running animation | Use `pump(Duration(...))` steps, or finish the controller explicitly |
| 16 | Results not random in tests | Hardcoded `Random` | Inject `Random(seed)` into the controller |
| 17 | Saved labels not loading on start | Prefs read after `runApp` | `WidgetsFlutterBinding.ensureInitialized()` then `await SharedPreferences.getInstance()` before `runApp`, override provider |
| 18 | Writes to prefs on every keystroke | No debounce | 300 ms debounce `Timer`, cancel in dispose |
| 19 | Portrait lock ignored | Called before binding init, or native config missing | Call after `ensureInitialized`; also set iOS `UISupportedInterfaceOrientations` and Android `screenOrientation` |
| 20 | Riverpod API errors (`StateNotifier` vs `Notifier`) | Mixed versions or outdated examples | Use `Notifier` / `NotifierProvider` from the installed 2.x docs only |
| 21 | Big text scale breaks layout | Fixed font sizes and heights | Test at `textScaler` 1.0 and 2.0; use flexible layouts |
| 22 | Dark mode low contrast | Colors only tuned for light | Check both themes against WCAG AA (4.5:1 text, 3:1 large text and UI) |
| 23 | Gradle / Kotlin / AGP version errors on Android | Version drift | Do not upgrade manually; fix only what the error names; one change at a time |
| 24 | Web preview looks different | Web renderer, no haptics | Treat web as preview only; verify final feel on a real device or emulator |

---

## 9. Theme spec

- Material 3, custom `ColorScheme`, light and dark following the system.
- Light: warm paper background, dark ink FAB. Dark: deep navy background,
  gold FAB.
- Type scale: 13 labels, 16 inputs, 22 result, 44 coin text for short
  labels (scaled down with `FittedBox`).
- Touch targets at least 48×48. Visible keyboard focus. Semantics label on
  the FAB ("Toss the coin") and live-region semantics on the result.

---

## 10. Build phases (do them in order, verify each)

Stop at the end of each phase, report in 3 lines max, and wait for me to
say "next" **only if** a check fails or something is ambiguous. Otherwise
continue.

1. **Scaffold**: `flutter create`, set up folders, theme, portrait lock,
   prefs init. Check: app launches, `flutter analyze` clean.
2. **Static UI**: fields, static coin faces (no animation), result area,
   FAB. Check: no overflow with keyboard open and 200% text scale.
3. **Controller**: labels, persistence (debounced), injected `Random`,
   outcome decided before animation. Check: unit tests pass.
4. **Flip only**: rotateX with perspective, correct face switching, correct
   final side. Check: 50 tosses (seeded) all land on the decided side.
5. **Toss arc + shadow + bounce**: full choreography. Check: feels
   physical, no snap at the end, no jank in profile mode.
6. **Polish**: wobble, haptics, FAB press, result fade, reduced motion.
7. **Tests and cleanup**: 3 widget tests (fallback labels, FAB disabled
   while flipping, result matches final face), `flutter analyze` = 0.

---

## 11. Definition of Done (all must be true)

- [ ] `flutter analyze` reports **0 issues**
- [ ] `flutter test` passes, including the 3 widget tests
- [ ] App runs on at least one Android emulator/device **or** iOS
      simulator, and I can see the full animation
- [ ] Result label always matches the side the coin visibly lands on
- [ ] No overflow with keyboard open, 200% text scale, small screen
- [ ] Works in light and dark mode
- [ ] Reduced-motion path works
- [ ] No deprecated API warnings, no TODOs, no unused code or files
- [ ] All tunables are in `toss_config.dart`
- [ ] Short README note (max 10 lines): how to run, how to tweak toss
      height, spins, and duration

## 12. How to report back

- Start with one line listing your assumptions.
- After each phase: what you did, what you verified, what (if anything)
  failed. Maximum 5 lines.
- At the end: the Definition of Done checklist with real pass/fail results,
  not guesses.
- If something is blocked or unclear, ask **one** specific question rather
  than guessing.
