import 'dart:async';

import 'package:finova/app/finova_app.dart';
import 'package:finova/core/database/finova_database.dart';
import 'package:finova/core/services/ad_service.dart';
import 'package:finova/core/services/notification_service.dart';
import 'package:finova/features/state/finova_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final database = FinovaDatabase();
  await database.open();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        preferencesProvider.overrideWithValue(preferences),
      ],
      child: const FinovaApp(),
    ),
  );
  unawaited(NotificationService.initialize().catchError((_) {}));
  unawaited(AdService.initializeInBackground().catchError((_) {}));
}
