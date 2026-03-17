import 'package:flutter/material.dart'; // <--- ESTA LÍNEA CORRIGE EL "UNDEFINED NAME LISTVIEW"
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:proyecto66/main.dart'; // <--- ASEGÚRATE QUE SEA 66

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Prueba de carga de lista', (WidgetTester tester) async {
    // Usamos el nombre de la clase que definimos en el main.dart
    await tester.pumpWidget(const MaterialApp(home: TelemetryList()));

    // Ahora ListView ya no marcará error porque importamos material.dart
    final finder = find.byType(ListView);
    expect(finder, findsOneWidget);
  });
}