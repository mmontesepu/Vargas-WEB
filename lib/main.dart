import 'package:flutter/material.dart';

import 'app/theme/app_theme.dart';
import 'features/home/presentation/home_page.dart';

void main() => runApp(const VargasApp());

class VargasApp extends StatelessWidget {
  const VargasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vargas SPA Construcciones',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomePage(),
    );
  }
}
