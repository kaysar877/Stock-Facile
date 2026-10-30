// Point d'entrée de l'application StockFacile.
//
// Sur Windows et Linux, sqflite n'est pas disponible nativement : il passe
// par la couche FFI (Foreign Function Interface), c'est-à-dire un appel
// direct à la bibliothèque SQLite du système. On l'initialise une fois,
// avant de lancer l'interface.
// Sur Android et iOS, ces lignes sont inutiles : sqflite fonctionne
// nativement et le reste du fichier est identique.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Flutter a besoin de cette initialisation avant d'appeler la base de données.
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const StockFacileApp());
}

class StockFacileApp extends StatelessWidget {
  const StockFacileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StockFacile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: const PageAccueil(),
    );
  }
}

class PageAccueil extends StatelessWidget {
  const PageAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StockFacile'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Gestion du stock de l\'épicerie'),
      ),
    );
  }
}
