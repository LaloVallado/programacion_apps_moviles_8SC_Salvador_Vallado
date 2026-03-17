import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: TelemetryList(),
  ));
}

class TelemetryList extends StatelessWidget {
  const TelemetryList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("PROYECTO_66_SISTEMAS"),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) => ListTile(
          leading: const Icon(Icons.developer_mode, color: Colors.blue),
          title: Text("Nodo Sensor #$index", style: const TextStyle(color: Colors.white)),
          subtitle: const Text("Estado: Transmitiendo...", style: TextStyle(color: Colors.white70)),
        ),
      ),
    );
  }
}