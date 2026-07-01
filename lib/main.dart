import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/config/app_config.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (local database)
  await Hive.initFlutter();

  // Initialize Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAQrV3ZZ8-GCUWp4Tpokbn7SmgLNGUKQvw",
        authDomain: "evnein.firebaseapp.com",
        projectId: "evnein",
        storageBucket: "evnein.firebasestorage.app",
        messagingSenderId: "1043646912719",
        appId: "1:1043646912719:web:04fa921a1a4d2bf7b4ffba",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    const ProviderScope(
      child: EvneinApp(),
    ),
  );
}

class EvneinApp extends ConsumerWidget {
  const EvneinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
