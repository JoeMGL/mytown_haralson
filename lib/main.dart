import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'app_router.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/auth/force_logout_listener.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyC0iUCwHViywjjWctCnAzoLsZHUbohOWXk",
      authDomain: "visit-haralson.firebaseapp.com",
      projectId: "visit-haralson",
      storageBucket: "visit-haralson.firebasestorage.app",
      messagingSenderId: "721812855685",
      appId: "1:721812855685:web:79d972c8965d0f312802ec",
      measurementId: "G-H4BDP61CY6",
    ),
  );
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

      // 👇 Wrap the entire routed app in the force logout listener
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ForceLogoutListener(child: child);
      },
    );
  }
}
