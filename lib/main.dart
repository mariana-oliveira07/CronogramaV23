import 'dart:io';
import 'package:cronograma/presentation/pages/Cronograma/cronograma_page.dart';
import 'package:cronograma/presentation/pages/main_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cronograma/presentation/pages/splash_screen.dart';
import 'package:path/path.dart';

Future<void> resetDatabase() async {
  final databasesPath = await getDatabasesPath();
  final path = join(databasesPath, 'education_database.db');

  await deleteDatabase(path); // Deleta o banco de dados
  // ignore: avoid_print
  print("Banco de dados deletado!");
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicialização para ambientes desktop
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestão de Cronogramas SENAC',

      // Configurações de internacionalização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      // Configuração do tema
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // Tela inicial (splash screen que redireciona para MainHomePage)
      home: const SplashScreen(),

      // Rotas nomeadas
      routes: {
        '/home': (context) => const MainHomePage(), // Página principal
        '/cronograma': (context) => const CronogramaPage(),
      },

      locale: const Locale('pt', 'BR'),
    );
  }
}
