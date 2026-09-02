import 'package:finova/core/models/models.dart';
import 'package:finova/core/theme/finova_theme.dart';
import 'package:finova/core/services/account_service.dart';
import 'package:finova/features/onboarding/onboarding_page.dart';
import 'package:finova/features/shell/main_shell.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FinovaApp extends ConsumerWidget {
  const FinovaApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(accountProvider);
    final data = ref.watch(finovaControllerProvider);
    final mode = data.value?.settings.themeMode ?? AppThemeMode.system;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Finova',
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: FinovaTheme.light(),
      darkTheme: FinovaTheme.dark(),
      themeMode: switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        AppThemeMode.system => ThemeMode.system,
      },
      home: data.when(
        data: (state) => state.settings.onboardingComplete
            ? const MainShell()
            : const OnboardingPage(),
        loading: () => const _Startup(),
        error: (error, _) => _Startup(error: error.toString()),
      ),
    );
  }
}

class _Startup extends StatelessWidget {
  const _Startup({this.error});
  final String? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: error == null
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Finova tidak dapat dibuka.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
    ),
  );
}
