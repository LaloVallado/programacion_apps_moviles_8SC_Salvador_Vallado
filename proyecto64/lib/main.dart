import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Necesario para jsonEncode

void main() => runApp(const MaterialApp(home: DataSenderScreen()));

class DataSenderScreen extends StatefulWidget {
  const DataSenderScreen({super.key});

  @override
  State<DataSenderScreen> createState() => _DataSenderScreenState();
}

class _DataSenderScreenState extends State<DataSenderScreen> {
  String _status = "LISTO PARA ENVIAR";

  // Función para enviar datos al servidor
  Future<void> _sendTelemetryData() async {
    setState(() => _status = "ENVIANDO...");

    try {
      // 1. Endpoint (URL del servidor o IP del ESP32)
      final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');

      // 2. Definición del cuerpo de los datos
      final Map<String, dynamic> telemetry = {
        'sensor_id': 'ESP32_LAB_ITM',
        'temp': 28.5,
        'hum': 65,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 3. Petición POST
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(telemetry), // Convertimos el Mapa a String JSON
      );

      // 4. Verificación de respuesta (Status Code 201 es "Creado")
      if (response.statusCode == 201) {
        setState(() => _status = "ÉXITO: DATOS RECIBIDOS");
        print("Respuesta del servidor: ${response.body}");
      } else {
        setState(() => _status = "ERROR DE SERVIDOR: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _status = "ERROR DE CONEXIÓN");
      print("Excepción: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text("TELEMETRY_UPLOADER_V1")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_upload, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            Text(
              "ESTADO: $_status",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _sendTelemetryData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text("ENVIAR REPORTE AHORA"),
            ),
          ],
        ),
      ),
    );
  }
}