import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EngineeringTabsScreen(),
    ));

class EngineeringTabsScreen extends StatelessWidget {
  const EngineeringTabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. El controlador envuelve todo el Scaffold
    return DefaultTabController(
      length: 3, // Número de pestañas
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          title: const Text(
            'NODE_CONTROL_V2',
            style: TextStyle(fontFamily: 'monospace', letterSpacing: 2),
          ),
          centerTitle: true,
          // 2. Definición de la Barra de Pestañas
          bottom: const TabBar(
            indicatorColor: Colors.cyanAccent,
            indicatorWeight: 3,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(icon: Icon(Icons.sensors), text: "REAL-TIME"),
              Tab(icon: Icon(Icons.storage), text: "SQL_LOGS"),
              Tab(icon: Icon(Icons.settings_remote), text: "CONFIG"),
            ],
          ),
        ),
        // 3. El contenido de cada pestaña
        body: const TabBarView(
          children: [
            ModuloTelemetria(),
            ModuloHistorial(),
            ModuloConfiguracion(),
          ],
        ),
      ),
    );
  }
}

// --- VISTAS INDEPENDIENTES (Módulos) ---

class ModuloTelemetria extends StatelessWidget {
  const ModuloTelemetria({super.key});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.radar, size: 80, color: Colors.cyanAccent),
          const SizedBox(height: 20),
          Text("ESCANEANDO NODOS...", 
            style: TextStyle(color: Colors.cyanAccent.withOpacity(0.7), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ModuloHistorial extends StatelessWidget {
  const ModuloHistorial({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Text("CONSULTANDO BASE DE DATOS SQL", style: TextStyle(color: Colors.white70)),
      );
}

class ModuloConfiguracion extends StatelessWidget {
  const ModuloConfiguracion({super.key});
  @override
  Widget build(BuildContext context) => const Center(
        child: Text("PARÁMETROS DEL SISTEMA EMBEBIDO", style: TextStyle(color: Colors.white70)),
      );
}