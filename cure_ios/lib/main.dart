import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'config/theme.dart';
import 'config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization info: $e");
  }
  runApp(
    const ProviderScope(
      child: CureApp(),
    ),
  );
}

class CureApp extends ConsumerWidget {
  const CureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Cure',
      debugShowCheckedModeBanner: false,
      theme: getAppTheme(),
      routerConfig: router,
    );
  }
}
