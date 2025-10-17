import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BetterMeApp());
}

class BetterMeApp extends StatelessWidget {
  const BetterMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Better Me',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
