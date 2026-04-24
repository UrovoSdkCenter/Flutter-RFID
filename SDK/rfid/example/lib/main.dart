import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'connect_page.dart';
import 'l10n.dart';

void main() {
  runApp(const RfidExampleApp());
}

class RfidExampleApp extends StatelessWidget {
  const RfidExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RFID Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: const ConnectPage(),
    );
  }
}
