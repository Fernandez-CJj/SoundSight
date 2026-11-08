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
    await _instance._hideNavigationBar();
  }

  bool get _keyboardIsVisible => WidgetsBinding.instance.platformDispatcher.views
      .any((view) => view.viewInsets.bottom > 0);

  Future<void> _hideNavigationBar() async {
    if (_keyboardIsVisible ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    await _channel.invokeMethod<void>('hideNavigationBar');
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    // Android temporarily prevents hiding system bars after keyboard dismissal.
    _hideTimer = Timer(const Duration(milliseconds: 1100), () {
      unawaited(_hideNavigationBar());
    });
  }

  @override
  void didChangeMetrics() {
    final keyboardIsVisible = _keyboardIsVisible;
    if (keyboardIsVisible) {
      _hideTimer?.cancel();
    } else if (_keyboardWasVisible) {
      _scheduleHide();
    }
    _keyboardWasVisible = keyboardIsVisible;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleHide();
    } else {
      _hideTimer?.cancel();
    }
  }
}
