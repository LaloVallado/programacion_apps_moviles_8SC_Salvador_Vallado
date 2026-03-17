import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// 1. Asegúrate de que el nombre del paquete coincida con tu pubspec.yaml
import 'package:proyecto64/main.dart'; 

void main() {
  testWidgets('Smoke test de carga', (WidgetTester tester) async {
    // 2. CAMBIA "MyApp()" por el nombre de la clase que tienes en tu main.dart
    // Si usaste mi código anterior, probablemente sea DataSenderScreen
    await tester.pumpWidget(const MaterialApp(home: DataSenderScreen()));

    // 3. Verifica que encuentre el botón o un texto inicial
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}