import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_router.dart';

void main() {
  runApp(const ProviderScope(child: HelperApp()));
}

class HelperApp extends StatelessWidget {
  const HelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Helperr4u',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00D09C)),
        useMaterial3: true,
      ),
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes(),
    );
  }
}
