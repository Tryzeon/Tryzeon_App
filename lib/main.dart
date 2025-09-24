import 'package:flutter/material.dart';
import 'package:tryzeon/pages/LoginPage.dart';
import 'pages/customer/SelfPage.dart';
import 'pages/customer/SelfPage_info.dart';
import 'pages/customer/SelfPage_link.dart';


void main() => runApp(const Tryzeon());

class Tryzeon extends StatelessWidget {
  const Tryzeon({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TryZeon',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
        ).copyWith(
          onSurface: Colors.brown[900],
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF4EC),
        useMaterial3: true,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.brown[700],
          displayColor: Colors.brown[700],
        ),
      ),
      home: LoginPage(),
      routes: {
        '/self': (context) => const SelfPage(),
        '/self_info': (context) => const SelfPageInfo(),
        '/self_link': (context) => const SelfPageLink(),

      },
    );
  }
}

