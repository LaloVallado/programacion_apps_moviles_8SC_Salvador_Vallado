import 'package:flutter/material.dart';

// --- 1. DEFINICIÓN DEL CONTRATO (ABSTRACCIÓN) ---
// Esto permite que el sistema use datos reales o datos de prueba (Mocks)
abstract class SensorDataService {
  Future<String> getStatus();
}

// --- 2. IMPLEMENTACIÓN REAL (PRODUCCIÓN) ---
class RealSensorService implements SensorDataService {
  @override
  Future<String> getStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Simula latencia de red
    return "SISTEMA_ACTIVO: 24°C";
  }
}

// --- 3. PUNTO DE ENTRADA ---
void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: TelemetryDashboard(
      // Aquí inyectamos el servicio real
      service: RealSensorService(),
    ),
  ));
}

// --- 4. INTERFAZ DE USUARIO (DASHBOARD) ---
class TelemetryDashboard extends StatelessWidget {
  final SensorDataService service;

  const TelemetryDashboard({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Color estilo GitHub Dark
      appBar: AppBar(
        title: const Text('ENGINEERING_CONSOLE_V1', 
          style: TextStyle(fontFamily: 'monospace', fontSize: 14, letterSpacing: 2)),
        backgroundColor: const Color(0xFF161B22),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatusIcon(),
              const SizedBox(height: 40),
              _buildDataMonitor(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2), width: 2),
      ),
      child: const Icon(Icons.settings_input_component, size: 50, color: Colors.cyanAccent),
    );
  }

  Widget _buildDataMonitor() {
    return FutureBuilder<String>(
      future: service.getStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(color: Colors.cyanAccent);
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              const Text("OUTPUT_LOG", style: TextStyle(color: Colors.white38, fontSize: 10)),
              const Divider(color: Colors.white10),
              const SizedBox(height: 10),
              Text(
                snapshot.data ?? "ERROR_DATA",
                style: const TextStyle(
                  color: Colors.cyanAccent, 
                  fontFamily: 'monospace', 
                  fontSize: 18,
                  fontWeight: FontWeight.bold
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}