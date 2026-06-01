import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';
import 'theme/gym_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gym System Cloud Practice',
      debugShowCheckedModeBanner: false,
      theme: GymTheme.themeData,
      home: const MainNavigationScreen(),
    );
  }
}