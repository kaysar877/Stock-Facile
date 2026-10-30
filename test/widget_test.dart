// Test de démarrage : l'application doit s'afficher avec son AppBar
// « StockFacile ». Rien n'est demandé à la base de données ici, on vérifie
// seulement que l'interface se construit sans erreur.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stock_facile/main.dart';

void main() {
  testWidgets('StockFacile démarre et affiche son AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(const StockFacileApp());

    expect(find.text('StockFacile'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
