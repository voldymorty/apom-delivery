import 'package:flutter/material.dart';
import 'package:delivery/global/colortheme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delivery/Screens/splash_Screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Delivery App',
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.deliveryColor),
      ),
      home: const SplashScreen(),
    );
  }
}
