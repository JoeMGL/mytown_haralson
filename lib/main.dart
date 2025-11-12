import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: VisitHaralsonApp()));
}

class VisitHaralsonApp extends StatelessWidget {
  const VisitHaralsonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Visit Haralson',
      theme: AppTheme.light(),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
