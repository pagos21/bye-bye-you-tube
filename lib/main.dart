import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:u_down2/db/db_service.dart';
import 'package:u_down2/navbar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //avvio isar
  await mydbService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        elevatedButtonTheme: ElevatedButtonThemeData(),
        // cardTheme: CardThemeData(color: const Color.fromARGB(255, 2, 31, 26)),
        colorScheme: ColorScheme.fromSeed(
          // surface: const Color(0xFF121212),
          // surfaceContainerHighest: Colors.blueGrey[100],
          brightness: Brightness.dark,
          seedColor: Colors.teal[900]!,
          // secondary: Colors.blueGrey[400],
          // onSecondary: Colors.white,
          // primary: Colors.blue,
        ),
        // scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.green,
          primary: Colors.green,
        ),
      ),
      home: const MyHomePage(title: 'U_Mp3_Mp4_Downloader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    log("Home Build!");
    return Navbar();
  }
}
