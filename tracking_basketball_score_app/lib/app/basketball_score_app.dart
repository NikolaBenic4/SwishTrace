import 'package:flutter/material.dart';

import 'app_shell.dart';

class BasketballScoreApp extends StatelessWidget {
  const BasketballScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    const courtOrange = Color(0xFFE87521);
    const ink = Color(0xFF161616);

    return MaterialApp(
      title: 'SwishTrace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: courtOrange,
          brightness: Brightness.light,
          primary: courtOrange,
          surface: const Color(0xFFF8F7F4),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F7F4),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
        ),
      ),
      home: const AppShell(),
    );
  }
}
