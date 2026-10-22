import 'dart:async';

import 'package:flutter/widgets.dart';

enum RealtimeStatus { idle, active, reconnecting }

/// Generic polling loop shared by screens that must show fresh server state.
///
/// Polling is one-shot chained (never overlapping), pauses while the app or
/// browser tab is in the background, and backs off 5s -> 10s -> 30s on errors.
class RealtimeService<T> with WidgetsBindingObserver {
  RealtimeService({
    required this.fetch,
    required this.onData,
    this.onError,
    this.onStatusChanged,
    this.interval = const Duration(seconds: 5),
    this.backoff = const [
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 30),
    ],
  }) : assert(interval > Duration.zero),
       assert(backoff.isNotEmpty);

  final Future<T> Function() fetch;
  final void Function(T data) onData;
  final void Function(Object error)? onError;
  final void Function(RealtimeStatus status)? onStatusChanged;
  final Duration interval;
  final List<Duration> backoff;

  Timer? _timer;
  bool _started = false;
  bool _inFlight = false;
  bool _paused = false;
  bool _disposed = false;
  int _consecutiveFailures = 0;
  RealtimeStatus _status = RealtimeStatus.idle;

  RealtimeStatus get status => _status;

  void start() {
    if (_disposed || _started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _tick();
  }

  Future<void> refreshNow() async {
    if (_disposed || _paused) return;
    await _tick();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
    _setStatus(RealtimeStatus.idle);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    if (_started) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _resume();
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _pause();
    }
  }

  void _pause() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  void _resume() {
    if (!_paused) return;
    _paused = false;
    if (_started && !_disposed) {
      _tick();
    }
  }

  Future<void> _tick() async {
    if (_disposed || !_started || _paused || _inFlight) return;
    _timer?.cancel();
    _timer = null;
    _inFlight = true;
    try {
      final data = await fetch();
      if (_disposed) return;
      _consecutiveFailures = 0;
      _setStatus(RealtimeStatus.active);
      onData(data);
    } catch (error) {
      if (_disposed) return;
      _consecutiveFailures++;
      _setStatus(RealtimeStatus.reconnecting);
      onError?.call(error);
    } finally {
      _inFlight = false;
      if (!_disposed && _started && !_paused) {
        _timer = Timer(_nextDelay(), _tick);
      }
    }
  }

  Duration _nextDelay() {
    if (_consecutiveFailures == 0) return interval;
    final index = _consecutiveFailures - 1 < backoff.length
        ? _consecutiveFailures - 1
        : backoff.length - 1;
    return backoff[index];
  }

  void _setStatus(RealtimeStatus next) {
    if (_status == next) return;
    _status = next;
    onStatusChanged?.call(next);
  }
}
