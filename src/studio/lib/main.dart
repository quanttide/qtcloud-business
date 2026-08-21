import 'package:flutter/material.dart';

import 'screens/business_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/quotation_list_screen.dart';
import 'screens/contract_list_screen.dart';

void main() {
  runApp(const _App());
}

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '量潮商务云',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const DashboardScreen(),
        '/businesses': (_) => const BusinessListScreen(),
        '/quotations': (_) => const QuotationListScreen(),
        '/contracts': (_) => const ContractListScreen(),
      },
    );
  }
}
