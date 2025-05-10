// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:skrybe/core/services/notification_service.dart';
import 'package:skrybe/core/theme/app_theme.dart';
import 'package:skrybe/firebase_options.dart';
import 'package:skrybe/routes/app_router.dart';

void main() async {
  // Initialize MediaKit before anything else
  MediaKit.ensureInitialized();

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🔥🔥🔥🔥 App started 🔥🔥🔥🔥");

  try {
    await initializeApp();
    debugPrint("✅ App initialized successfully");
  } catch (e) {
    debugPrint("❌ Initialization error: $e");
    // Attempt fallback initialization for critical components
    await initializeFallbacks();
  }

  runApp(const ProviderScope(child: SkrybeApp()));
}

Future<void> initializeApp() async {
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
    // Continue with other initializations even if Firebase fails
  }

  // Initialize Hive
  await initializeHive();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Environment variables loaded");
  } catch (e) {
    debugPrint("❌ Failed to load environment variables: $e");
  }

  // Initialize notification service
  try {
    await NotificationService.initialize();
    debugPrint("✅ Notification service initialized");
  } catch (e) {
    debugPrint("❌ Notification service initialization failed: $e");
  }

  // Set display mode for high refresh rate
  if (!kIsWeb) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
      debugPrint("✅ High refresh rate set");
    } catch (e) {
      debugPrint('❌ Could not set high refresh rate: $e');
    }
  }

  // Set preferred orientations
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    debugPrint("✅ Orientation lock set");
  } catch (e) {
    debugPrint("❌ Failed to set orientation lock: $e");
  }
}

Future<void> initializeHive() async {
  try {
    // Get application document directory for Hive storage
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    debugPrint("✅ Hive initialized with document directory");

    // Open required boxes
    await openBoxSafely('settings');
    await openBoxSafely('transcripts');
    await openBoxSafely('user');
  } catch (e) {
    // Fallback to default initialization if getting directory fails
    debugPrint("⚠️ Falling back to default Hive initialization: $e");
    await Hive.initFlutter();

    // Still try to open the boxes
    await openBoxSafely('settings');
    await openBoxSafely('transcripts');
    await openBoxSafely('user');
  }
}

Future<Box?> openBoxSafely(String boxName) async {
  try {
    if (!Hive.isBoxOpen(boxName)) {
      final box = await Hive.openBox(boxName);
      debugPrint("✅📦✅ Opened Hive box: $boxName");
      return box;
    } else {
      debugPrint("\n\nℹ️ℹ️ℹ️ℹ️ Hive box already open: $boxName");
      return Hive.box(boxName);
    }
  } catch (e) {
    debugPrint("\n\n❌📦❌ Failed to open Hive box $boxName: $e");
    return null;
  }
}

Future<void> initializeFallbacks() async {
  // Minimal fallback initialization for critical components
  try {
    // Try initializing Hive without checking if it's already initialized
    // Hive will safely handle repeated initialization attempts
    try {
      await Hive.initFlutter();
      debugPrint("\n\n🍯🐝🐝🐝 Fallback Hive initialization successful");
    } catch (e) {
      debugPrint("\n\n⚠️⚠️⚠️🐝 Fallback Hive initialization error: $e");
      // Continue anyway to try opening the box
    }

    // Try to open at least the settings box which is critical
    await openBoxSafely('settings');
  } catch (e) {
    debugPrint("\n\n❌❌❌❌ Even fallback initialization failed: $e");
  }
}

class SkrybeApp extends ConsumerWidget {
  const SkrybeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("\n\n🔁 Building SkrybeApp\n");

    final themeMode = ref.watch(themeModeProvider);
    final appRouter = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Skrybe',
      routerConfig: appRouter,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    );
  }
}
