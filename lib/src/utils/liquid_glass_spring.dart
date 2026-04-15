import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Spring presets
// ─────────────────────────────────────────────────────────────────────────────

/// Static spring-description factories that mirror Apple's Cupertino motion
/// presets.
///
/// Every preset uses [SpringDescription.withDurationAndBounce].
///
/// ```dart
/// SpringBuilder(
///   value: _expanded ? 1.0 : 0.0,
///   spring: LiquidGlassSpring.snappy(),
///   builder: (context, value, child) {
///     return Transform.scale(scale: value, child: child);
///   },
///   child: const Icon(Icons.star),
/// )
/// ```
abstract final class LiquidGlassSpring {
  /// Bouncy spring — 500 ms duration, 0.3 bounce.
  static SpringDescription bouncy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.3 + extraBounce,
      );

  /// Snappy spring — 500 ms duration, 0.15 bounce.
  static SpringDescription snappy({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.15 + extraBounce,
      );

  /// Smooth spring — 500 ms duration, critically-damped (0.0 bounce).
  static SpringDescription smooth({
    Duration duration = const Duration(milliseconds: 500),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.0 + extraBounce,
      );

  /// Interactive spring — 150 ms response, 0.14 bounce.
  /// Ideal for tracking a pointer during drag.
  static SpringDescription interactive({
    Duration duration = const Duration(milliseconds: 150),
    double extraBounce = 0.0,
  }) =>
      SpringDescription.withDurationAndBounce(
        duration: duration,
        bounce: 0.14 + extraBounce,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SingleSpringController
// ─────────────────────────────────────────────────────────────────────────────

/// A controller that drives a single [double] value using [SpringSimulation].
///
/// Features:
/// * [value] — current animated value.
/// * [velocity] — current spring velocity (units/second).
/// * [animateTo] — start/redirect a spring toward a new target, preserving
///   current velocity.
/// * [spring] can be changed at any time; a running simulation is redirected
///   immediately.
/// * Optional [lowerBound]/[upperBound] clamping.
/// * Implements [Listenable] so it works directly with [ListenableBuilder].
///
/// ```dart
/// late final SingleSpringController _ctrl;
///
/// @override
/// void initState() {
///   super.initState();
///   _ctrl = SingleSpringController(
///     vsync: this,
///     spring: LiquidGlassSpring.snappy(),
///     initialValue: 0.0,
///   );
/// }
///
/// void _onTap() => _ctrl.animateTo(1.0);
/// ```
class SingleSpringController extends ChangeNotifier {
  SingleSpringController({
    required TickerProvider vsync,
    required SpringDescription spring,
    double initialValue = 0.0,
    double? lowerBound,
    double? upperBound,
  })  : _spring = spring,
        _value = initialValue,
        _lowerBound = lowerBound,
        _upperBound = upperBound {
    _ticker = vsync.createTicker(_tick);
  }

  SpringDescription _spring;
  double _value;
  double _tickerElapsed = 0.0;
  double _simStartTime = 0.0;
  double _target = 0.0;
  SpringSimulation? _sim;
  late final Ticker _ticker;

  final double? _lowerBound;
  final double? _upperBound;

  /// The current animated value.
  double get value => _value;

  /// The current spring velocity in units/second.
  double get velocity {
    final sim = _sim;
    if (sim == null) return 0.0;
    final t = (_tickerElapsed - _simStartTime).clamp(0.0, double.infinity);
    return sim.dx(t);
  }

  /// The spring description. Changing it redirects any running simulation
  /// immediately, preserving current velocity.
  SpringDescription get spring => _spring;
  set spring(SpringDescription value) {
    if (_spring == value) return;
    _spring = value;
    if (_ticker.isActive) _startSim(target: _target, fromVelocity: velocity);
  }

  /// Animates toward [target], preserving current velocity.
  /// If [fromVelocity] is provided it overrides the current velocity.
  void animateTo(double target, {double? fromVelocity}) {
    _target = _clamp(target);
    _startSim(target: _target, fromVelocity: fromVelocity ?? velocity);
  }

  /// Immediately sets the value without animating.
  void setValue(double value) {
    _ticker.stop();
    _sim = null;
    _value = _clamp(value);
    _tickerElapsed = 0.0;
    _simStartTime = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  double _clamp(double v) {
    final lower = _lowerBound;
    final upper = _upperBound;
    if (lower != null && v < lower) return lower;
    if (upper != null && v > upper) return upper;
    return v;
  }

  void _startSim({required double target, required double fromVelocity}) {
    _sim = SpringSimulation(_spring, _value, target, fromVelocity);
    if (!_ticker.isActive) {
      _tickerElapsed = 0.0;
      _simStartTime = 0.0;
      _ticker.start();
    } else {
      _simStartTime = _tickerElapsed;
    }
  }

  void _tick(Duration elapsed) {
    _tickerElapsed = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final simElapsed =
        (_tickerElapsed - _simStartTime).clamp(0.0, double.infinity);
    final sim = _sim;
    if (sim == null) {
      _ticker.stop();
      return;
    }

    _value = _clamp(sim.x(simElapsed));

    if (sim.isDone(simElapsed)) {
      _value = _clamp(_target);
      _sim = null;
      _ticker.stop();
    }
    notifyListeners();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OffsetSpringController
// ─────────────────────────────────────────────────────────────────────────────

/// A controller that drives an [Offset] value using two independent
/// [SingleSpringController]s (one per axis).
///
/// Implements [Listenable]; listeners fire whenever either axis ticks.
class OffsetSpringController extends ChangeNotifier {
  OffsetSpringController({
    required TickerProvider vsync,
    required SpringDescription spring,
    Offset initialValue = Offset.zero,
  }) {
    _x = SingleSpringController(
      vsync: vsync,
      spring: spring,
      initialValue: initialValue.dx,
    )..addListener(notifyListeners);
    _y = SingleSpringController(
      vsync: vsync,
      spring: spring,
      initialValue: initialValue.dy,
    )..addListener(notifyListeners);
  }

  late final SingleSpringController _x;
  late final SingleSpringController _y;

  /// Current animated offset.
  Offset get value => Offset(_x.value, _y.value);

  /// Current spring velocity as an [Offset].
  Offset get velocity => Offset(_x.velocity, _y.velocity);

  /// Animate toward [target], preserving current velocity.
  void animateTo(Offset target) {
    _x.animateTo(target.dx);
    _y.animateTo(target.dy);
  }

  /// Immediately set both axes without animating.
  set value(Offset v) {
    _x.setValue(v.dx);
    _y.setValue(v.dy);
  }

  /// Change the spring for both axes, redirecting any running simulation.
  set spring(SpringDescription s) {
    _x.spring = s;
    _y.spring = s;
  }

  @override
  void dispose() {
    _x.removeListener(notifyListeners);
    _y.removeListener(notifyListeners);
    _x.dispose();
    _y.dispose();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpringBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Builder function signature for [SpringBuilder].
typedef SpringWidgetBuilder = Widget Function(
  BuildContext context,
  double value,
  Widget? child,
);

/// Animates a [double] [value] to new targets using a spring, calling
/// [builder] on every frame.
///
/// When [value] changes, the spring redirects to the new target while
/// preserving current velocity. Respects the platform's reduce-motion setting.
///
/// ```dart
/// SpringBuilder(
///   value: _isPressed ? 0.95 : 1.0,
///   spring: LiquidGlassSpring.interactive(),
///   builder: (context, value, child) {
///     return Transform.scale(scale: value, child: child);
///   },
///   child: myWidget,
/// )
/// ```
class SpringBuilder extends StatefulWidget {
  const SpringBuilder({
    required this.value,
    required this.spring,
    required this.builder,
    this.child,
    super.key,
  });

  final double value;
  final SpringDescription spring;
  final SpringWidgetBuilder builder;
  final Widget? child;

  @override
  State<SpringBuilder> createState() => _SpringBuilderState();
}

class _SpringBuilderState extends State<SpringBuilder>
    with SingleTickerProviderStateMixin {
  late final SingleSpringController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SingleSpringController(
      vsync: this,
      spring: widget.spring,
      initialValue: widget.value,
    );
  }

  @override
  void didUpdateWidget(SpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spring != oldWidget.spring) {
      _ctrl.spring = widget.spring;
    }
    if (widget.value != oldWidget.value) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _ctrl.setValue(widget.value);
      } else {
        _ctrl.animateTo(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, child) => widget.builder(context, _ctrl.value, child),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VelocitySpringBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Builder function signature for [VelocitySpringBuilder].
typedef VelocitySpringWidgetBuilder = Widget Function(
  BuildContext context,
  double value,
  double velocity,
  Widget? child,
);

/// Like [SpringBuilder] but also provides the current spring [velocity] to
/// the builder.
///
/// [springWhenActive] is used while the user is interacting (e.g. dragging).
/// [springWhenReleased] is used after the user lifts their finger.
/// Switching between them mid-animation redirects the simulation smoothly.
///
/// ```dart
/// VelocitySpringBuilder(
///   value: _dragOffset,
///   active: _isDragging,
///   springWhenActive: LiquidGlassSpring.interactive(),
///   springWhenReleased: LiquidGlassSpring.snappy(),
///   builder: (context, value, velocity, child) {
///     return Transform.translate(
///       offset: Offset(value, 0),
///       child: child,
///     );
///   },
///   child: myWidget,
/// )
/// ```
class VelocitySpringBuilder extends StatefulWidget {
  const VelocitySpringBuilder({
    required this.value,
    required this.springWhenActive,
    required this.springWhenReleased,
    required this.builder,
    this.active = true,
    this.child,
    super.key,
  });

  /// Current target value.
  final double value;

  /// Spring used while [active] is true (following a pointer).
  final SpringDescription springWhenActive;

  /// Spring used while [active] is false (settling to rest).
  final SpringDescription springWhenReleased;

  /// Whether the user is currently interacting.
  final bool active;

  final VelocitySpringWidgetBuilder builder;
  final Widget? child;

  @override
  State<VelocitySpringBuilder> createState() => _VelocitySpringBuilderState();
}

class _VelocitySpringBuilderState extends State<VelocitySpringBuilder>
    with SingleTickerProviderStateMixin {
  late final SingleSpringController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SingleSpringController(
      vsync: this,
      spring: _currentSpring,
      initialValue: widget.value,
    );
  }

  SpringDescription get _currentSpring =>
      widget.active ? widget.springWhenActive : widget.springWhenReleased;

  @override
  void didUpdateWidget(VelocitySpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    final springChanged = widget.active != oldWidget.active ||
        widget.springWhenActive != oldWidget.springWhenActive ||
        widget.springWhenReleased != oldWidget.springWhenReleased;
    if (springChanged) {
      _ctrl.spring = _currentSpring;
    }
    if (widget.value != oldWidget.value) {
      if (MediaQuery.disableAnimationsOf(context)) {
        _ctrl.setValue(widget.value);
      } else {
        _ctrl.animateTo(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, child) =>
          widget.builder(context, _ctrl.value, _ctrl.velocity, child),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OffsetSpringBuilder
// ─────────────────────────────────────────────────────────────────────────────

/// Builder function signature for [OffsetSpringBuilder].
typedef OffsetSpringWidgetBuilder = Widget Function(
  BuildContext context,
  Offset value,
  Widget? child,
);

/// Like [SpringBuilder] but for [Offset] values.
///
/// ```dart
/// OffsetSpringBuilder(
///   value: _targetPosition,
///   spring: LiquidGlassSpring.smooth(),
///   builder: (context, value, child) {
///     return Transform.translate(offset: value, child: child);
///   },
///   child: myWidget,
/// )
/// ```
class OffsetSpringBuilder extends StatefulWidget {
  const OffsetSpringBuilder({
    required this.value,
    required this.spring,
    required this.builder,
    this.child,
    super.key,
  });

  final Offset value;
  final SpringDescription spring;
  final OffsetSpringWidgetBuilder builder;
  final Widget? child;

  @override
  State<OffsetSpringBuilder> createState() => _OffsetSpringBuilderState();
}

class _OffsetSpringBuilderState extends State<OffsetSpringBuilder>
    with TickerProviderStateMixin {
  late final OffsetSpringController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = OffsetSpringController(
      vsync: this,
      spring: widget.spring,
      initialValue: widget.value,
    );
  }

  @override
  void didUpdateWidget(OffsetSpringBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spring != oldWidget.spring) {
      _ctrl.spring = widget.spring;
    }
    if (widget.value != oldWidget.value) {
      _ctrl.animateTo(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (context, child) => widget.builder(context, _ctrl.value, child),
      child: widget.child,
    );
  }
}
