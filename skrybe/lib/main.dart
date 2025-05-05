// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:skrybe/core/services/notification_service.dart';
import 'package:skrybe/core/theme/app_theme.dart';
import 'package:skrybe/firebase_options.dart';
import 'package:skrybe/routes/app_router.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred display mode (high refresh rate)
  if (!kIsWeb) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Could not set high refresh rate: $e');
    }
  }

  // Initialize services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await dotenv.load();
  await NotificationService.initialize();

  // Open important Hive boxes
  await Hive.openBox('settings');
  await Hive.openBox('transcripts');
  await Hive.openBox('user');

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: SkrybeApp()));
}

class SkrybeApp extends ConsumerWidget {
  const SkrybeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Skrybe',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}

//...
