import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:pilulasdoconhecimento/car_selection_screen.dart';
import 'package:pilulasdoconhecimento/home.dart';
import 'package:pilulasdoconhecimento/l10n/app_localizations.dart'; // Import relativo ao seu projeto
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    final appDocDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(appDocDir.path);
  }

  // Verifica se um carro já foi selecionado anteriormente
  final prefs = await SharedPreferences.getInstance();
  final selectedCar = prefs.getString('selectedCar');

  runApp(MyApp(selectedCar: selectedCar)); // <-- CORREÇÃO AQUI
}
class MyApp extends StatelessWidget {
  final String? selectedCar;
  const MyApp({super.key, required this.selectedCar});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Guide',
      theme: ThemeData(
        fontFamily: 'NouvelR',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:  selectedCar == null ? CarSelectionScreen() : Home(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }
}