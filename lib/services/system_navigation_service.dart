import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class SystemNavigationService with WidgetsBindingObserver {
  SystemNavigationService._();

  static final _instance = SystemNavigationService._();
  static const _channel = MethodChannel('soundsight/system_navigation');

  Timer? _hideTimer;
  bool _keyboardWasVisible = false;

  static Future<void> initialize() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    WidgetsBinding.instance.addObserver(_instance);
    _instance._keyboardWasVisible = _instance._keyboardIsVisible;
    if (_instance._keyboardWasVisible) {
      await _instance._showStatusBar();
    } else {
      await _instance._hideSystemBars();
    }
  }

  bool get _keyboardIsVisible => WidgetsBinding.instance.platformDispatcher.views
      .any((view) => view.viewInsets.bottom > 0);

  Future<void> _showStatusBar() async {
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    await _channel.invokeMethod<void>('showStatusBar');
  }

  Future<void> _hideSystemBars() async {
    if (_keyboardIsVisible ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    await _channel.invokeMethod<void>('hideSystemBars');
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    // Android temporarily prevents hiding system bars after keyboard dismissal.
    _hideTimer = Timer(const Duration(milliseconds: 1100), () {
      unawaited(_hideSystemBars());
    });
  }

  @override
  void didChangeMetrics() {
    final keyboardIsVisible = _keyboardIsVisible;
    if (keyboardIsVisible) {
      _hideTimer?.cancel();
      if (!_keyboardWasVisible) unawaited(_showStatusBar());
    } else if (_keyboardWasVisible) {
      _scheduleHide();
    }
    _keyboardWasVisible = keyboardIsVisible;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_keyboardIsVisible) {
        unawaited(_showStatusBar());
      } else {
        _scheduleHide();
      }
    } else {
      _hideTimer?.cancel();
    }
  }
}
