import 'package:flutter/material.dart';

// --- LA LÓGICA DE INGENIERÍA ---
class ClimateLogic {
  // Función pura: Fácil de probar
  String checkStatus(double humidity) {
    if (humidity < 0 || humidity > 100) return "ERROR_SENSOR";
    if (humidity > 60) return "OPTIMO";
    return "BAJO";
  }

  double celsiusToFahrenheit(double c) => (c * 9 / 5) + 32;
}

void main() => runApp(const MaterialApp(home: UnitTestVisualizer()));

class UnitTestVisualizer extends StatefulWidget {
  const UnitTestVisualizer({super.key});

  @override
  State<UnitTestVisualizer> createState() => _UnitTestVisualizerState();
}

class _UnitTestVisualizerState extends State<UnitTestVisualizer> {
  final ClimateLogic _logic = ClimateLogic();
  final List<Map<String, dynamic>> _testResults = [];

  void _runUnitTests() {
    _testResults.clear();
    
    // Simulación de "expect(actual, expected)"
    _verify("Prueba Humedad Alta", _logic.checkStatus(85), "OPTIMO");
    _verify("Prueba Humedad Negativa", _logic.checkStatus(-10), "ERROR_SENSOR");
    _verify("Conversión Temp 0°C", _logic.celsiusToFahrenheit(0), 32.0);
    _verify("Conversión Temp 100°C", _logic.celsiusToFahrenheit(100), 212.0);

    setState(() {});
  }

  void _verify(String name, dynamic actual, dynamic expected) {
    bool passed = actual == expected;
    _testResults.add({
      "name": name,
      "passed": passed,
      "details": "Esperado: $expected, Recibido: $actual"
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(title: const Text("UNIT_TEST_RUNNER_V1"), backgroundColor: Colors.black),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: _runUnitTests,
              child: const Text("EJECUTAR SUITE DE PRUEBAS"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                final test = _testResults[index];
                return ListTile(
                  leading: Icon(
                    test['passed'] ? Icons.check_circle : Icons.error,
                    color: test['passed'] ? Colors.green : Colors.red,
                  ),
                  title: Text(test['name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text(test['details'], style: const TextStyle(color: Colors.white54)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}