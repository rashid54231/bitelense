import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/strings/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';
import 'data/providers/app_providers.dart';

/// Root application widget with theme management, router, and offline banners.
class BiteLensApp extends ConsumerWidget {
  const BiteLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      builder: (context, child) {
        return OfflineBanner(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
