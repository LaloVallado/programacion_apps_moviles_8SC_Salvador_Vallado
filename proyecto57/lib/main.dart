import 'dart:async';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DeepLinkRouterScreen(),
    ));

class DeepLinkRouterScreen extends StatefulWidget {
  const DeepLinkRouterScreen({super.key});

  @override
  State<DeepLinkRouterScreen> createState() => _DeepLinkRouterScreenState();
}

class _DeepLinkRouterScreenState extends State<DeepLinkRouterScreen> {
  // Estado para simular la captura del link
  String _currentRoute = "ESPERANDO SEÑAL...";
  String? _sensorId;
  bool _isNavigating = false;

  // --- MOTOR DE PROCESAMIENTO (SIMULACIÓN DE UNIVERSAL LINK) ---
  Future<void> _handleIncomingLink(String url) async {
    setState(() {
      _isNavigating = true;
      _currentRoute = "PROCESANDO: $url";
    });

    // Simulamos un delay de procesamiento de red/parsing
    await Future.delayed(const Duration(seconds: 2));

    final uri = Uri.parse(url);
    
    // Lógica de ruteo: verificamos si el path es de sensores
    if (uri.path.contains('/sensor')) {
      final id = uri.queryParameters['id'];
      setState(() {
        _sensorId = id ?? "DESCONOCIDO";
        _currentRoute = "NODO DETECTADO: $_sensorId";
        _isNavigating = false;
      });
      _navigateToSensorDetail();
    } else {
      setState(() {
        _currentRoute = "RUTA NO RECONOCIDA";
        _isNavigating = false;
      });
    }
  }

  void _navigateToSensorDetail() {
    // Aquí iría el Navigator.push real
    print("Navegando a los detalles del sensor: $_sensorId");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('LINK_ROUTER_ENGINE_V1', 
          style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusDisplay(),
            const SizedBox(height: 50),
            _buildManualTriggerSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isNavigating ? Colors.cyanAccent : Colors.white10),
      ),
      child: Column(
        children: [
          Icon(
            _isNavigating ? Icons.sync : Icons.settings_input_antenna,
            color: _isNavigating ? Colors.cyanAccent : Colors.white30,
            size: 40,
          ),
          const SizedBox(height: 20),
          Text(_currentRoute, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildManualTriggerSection() {
    return Column(
      children: [
        const Text("SIMULADOR DE EVENTO EXTERNO", 
          style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildLinkButton(
                "LINK_SENSOR_01", 
                "https://tu-sitio.com/sensor?id=ESP32_MÉRIDA",
                Colors.cyanAccent
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildLinkButton(
                "LINK_INVALID", 
                "https://tu-sitio.com/root",
                Colors.redAccent
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkButton(String label, String url, Color color) {
    return OutlinedButton(
      onPressed: _isNavigating ? null : () => _handleIncomingLink(url),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}