import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;

// ESTA LÍNEA ES LA CLAVE: 
// Debe llamarse igual que tu archivo actual pero con el sufijo .mocks.dart
import 'widget_test.mocks.dart'; 

// La clase original
class SensorESP32 {
  Future<int> leerHumedad() async => 40;
}

// La anotación que lee build_runner
@GenerateMocks([SensorESP32])
void main() {
  // Aquí es donde te da el error de "indefinida"
  late MockSensorESP32 mockSensor; 

  setUp(() {
    mockSensor = MockSensorESP32();
  });

  test('Prueba de rango de humedad', () async {
    mockito.when(mockSensor.leerHumedad()).thenAnswer((_) async => 65);
    expect(await mockSensor.leerHumedad(), 65);
  });
}