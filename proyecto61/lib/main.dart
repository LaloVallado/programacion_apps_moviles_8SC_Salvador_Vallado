import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MicroclimaApp());
}

class MicroclimaApp extends StatelessWidget {
  const MicroclimaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ITM Microclima',
      // Configuramos el tema oscuro global
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const DashboardTerminal(),
    );
  }
}

class DashboardTerminal extends StatelessWidget {
  const DashboardTerminal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ENGINEERING_CONSOLE_V1.0",
          style: GoogleFonts.getFont('JetBrains Mono', fontSize: 14),
        ),
        backgroundColor: const Color(0xFF161B22),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icono de estado del sistema
            const Icon(
              Icons.sensors,
              color: Colors.greenAccent,
              size: 80,
            ),
            const SizedBox(height: 30),
            
            // Texto principal con la fuente JetBrains Mono
            Text(
              "SISTEMA_ACTIVO",
              style: GoogleFonts.getFont(
                'JetBrains Mono',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
                letterSpacing: 3,
              ),
            ),
            
            const SizedBox(height: 15),
            
            // Subtexto de telemetría
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: Text(
                "NODE_ESP32: CONNECTED_IP_192.168.1.100",
                style: GoogleFonts.getFont(
                  'JetBrains Mono',
                  fontSize: 10,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Botón de acción con estilo técnico
            OutlinedButton(
              onPressed: () {
                print("Iniciando escaneo de sensores...");
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                "EJECUTAR_DIAGNÓSTICO",
                style: GoogleFonts.getFont(
                  'JetBrains Mono',
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}