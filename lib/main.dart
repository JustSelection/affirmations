import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app/affirmations_app.dart';
import 'data/shared_preferences_progress_store.dart';
import 'state/app_controller.dart';

void main() {
  runZonedGuarded<void>(
    () {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        debugPrint('FlutterError: ${details.exceptionAsString()}');
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('Unhandled Flutter error: $error');
        debugPrint('Stack: $stack');
        return false;
      };
      ErrorWidget.builder = (_) => const _AppErrorWidget();
      runApp(
        AffirmationsApp(
          controller: AppController(SharedPreferencesProgressStore()),
        ),
      );
    },
    (error, stack) {
      debugPrint('Zone error: $error');
      debugPrint('Stack: $stack');
    },
  );
}

class _AppErrorWidget extends StatelessWidget {
  const _AppErrorWidget();

  @override
  Widget build(BuildContext context) => const Directionality(
    textDirection: TextDirection.ltr,
    child: ColoredBox(
      color: Color(0xFF121212),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Произошла внутренняя ошибка. Перезапустите приложение.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFEDEDED), fontSize: 16),
          ),
        ),
      ),
    ),
  );
}
