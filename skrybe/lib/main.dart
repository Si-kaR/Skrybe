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

Future<void> openBoxIfNotOpened(String boxName) async {
  if (!Hive.isBoxOpen(boxName)) {
    await Hive.openBox(boxName);
  }
}

Future<void> initializeApp() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await dotenv.load(fileName: ".env");
  await NotificationService.initialize();

  if (!kIsWeb) {
    try {
      await FlutterDisplayMode.setHighRefreshRate();
    } catch (e) {
      debugPrint('Could not set high refresh rate: $e');
    }
  }

  await openBoxIfNotOpened('settings');
  await openBoxIfNotOpened('transcripts');
  await openBoxIfNotOpened('user');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print("🔥🔥🔥🔥 App started 🔥🔥🔥🔥");

  try {
    await initializeApp();
  } catch (e) {
    debugPrint("Initialization error: $e");
  }

  runApp(const ProviderScope(child: SkrybeApp()));
}

class SkrybeApp extends ConsumerWidget {
  const SkrybeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print("\n\n🔁 Building SkrybeApp\n");

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



// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

// // ✅ Initialize Firebase only if not already initialized
//   // Initialize services
//   if (Firebase.apps.isEmpty) {
//     await Firebase.initializeApp(
//         options: DefaultFirebaseOptions.currentPlatform);
//     await Hive.initFlutter();
//     await dotenv.load();
//     await NotificationService.initialize();
//   }

//   // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   // await Hive.initFlutter();
//   // await dotenv.load();
//   // await NotificationService.initialize();

//   // Set preferred display mode (high refresh rate)
//   if (!kIsWeb) {
//     try {
//       await FlutterDisplayMode.setHighRefreshRate();
//     } catch (e) {
//       debugPrint('Could not set high refresh rate: $e');
//     }
//   }

//   // Open important Hive boxes
//   await Hive.openBox('settings');
//   await Hive.openBox('transcripts');
//   await Hive.openBox('user');

//   // Set preferred orientations
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   runApp(const ProviderScope(child: SkrybeApp()));
// }




// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   print("\n\n🔥🔥🔥🔥🔥🔥🔥🔥 App started 🔥🔥🔥🔥🔥🔥🔥🔥\n");

//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     print("\n\n🔥🔥🔥🔥🔥🔥🔥🔥 Firebase initialized 🔥🔥🔥🔥🔥🔥🔥\n");
//   } catch (e) {
//     debugPrint(
//         "\n\n⚠️🔥⚠️ Firebase already initialized or failed: $e ⚠️🔥⚠️\n\n");
//   }

//   await Hive.initFlutter();
//   print("\n\n🍯🐝🐝🐝🐝🐝🐝🐝🐝 Hive Initialised 🐝🐝🐝🐝🐝🐝🐝🐝🍯\n");

//   // await dotenv.load();
//   await dotenv.load(fileName: ".env\n");
//   print("\n\n⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️ .env loaded ⚙️⚙️⚙️⚙️⚙️⚙️⚙️⚙️\n");

//   await NotificationService.initialize();

//   // Set preferred display mode (high refresh rate)
//   if (!kIsWeb) {
//     try {
//       await FlutterDisplayMode.setHighRefreshRate();
//     } catch (e) {
//       debugPrint('Could not set high refresh rate: $e');
//     }
//   }

//   await Hive.openBox('settings');
//   await Hive.openBox('transcripts');
//   await Hive.openBox('user');
//   print("\n\n🍯🐝🐝🐝🐝🐝🐝🐝🐝 Hive boxes opened 📦📦📦📦📦📦📦📦\n");

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   runApp(const ProviderScope(child: SkrybeApp()));
// }
