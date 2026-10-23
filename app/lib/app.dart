import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'core/widgets/glass_surface.dart';
import 'features/home/application/startup.dart';

class ShaktiApp extends ConsumerWidget {
  const ShaktiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Decides the first gate, restores a live incident, arms triggers.
    final startup = ref.watch(startupProvider);
    return MaterialApp.router(
      title: 'Shakti',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // Dark-first: used at night and under stress.
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(appRouterProvider),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', 'IN'),
        Locale('hi', 'IN'),
        Locale('kn', 'IN'),
      ],
      builder: (context, child) {
        // Cap text scaling at 2x so layouts stay usable without clipping.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 2.0),
          ),
          child: ShaktiBackdrop(
            child: startup.isLoading ? const _Splash() : child!,
          ),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ShaktiColors.bg,
    child: Center(
      child: Semantics(
        label: 'Shakti is starting',
        child: const SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: ShaktiColors.sosGlow,
          ),
        ),
      ),
    ),
  );
}
