import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto26/main.dart'; // Asegúrate de que el nombre coincida con tu proyecto

void main() {
  testWidgets('MyWidget tiene un título y un mensaje', (WidgetTester tester) async {
    // 1. Construir el widget en el entorno de prueba
    await tester.pumpWidget(const MyWidget(title: 'T', message: 'M'));

    // 2. Crear los Finders (Buscadores)
    final titleFinder = find.text('T');
    final messageFinder = find.text('M');

    // 3. Verificar que aparezcan exactamente una vez
    expect(titleFinder, findsOneWidget);
    expect(messageFinder, findsOneWidget);
  });
}