import 'package:flutter/material.dart';

void main() => runApp(const ITMTelemetryApp());

class ITMTelemetryApp extends StatelessWidget {
  const ITMTelemetryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // --- CONFIGURACIÓN GLOBAL DEL TEMA ---
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        
        // Paleta de colores principal
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyanAccent,
          brightness: Brightness.dark,
          primary: Colors.cyanAccent,
          secondary: const Color(0xFF1E293B),
        ),

        // Estilos de texto globales (Tipografía)
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold, 
            color: Colors.cyanAccent,
            fontFamily: 'monospace',
          ),
          bodyMedium: TextStyle(
            fontSize: 16, 
            color: Colors.white70,
          ),
        ),

        // Estilo global para todos los botones
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const ThemedDashboard(),
    );
  }
}

class ThemedDashboard extends StatelessWidget {
  const ThemedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // 3. RECUPERANDO DATOS DEL TEMA
    // Accedemos a los colores y fuentes definidos arriba
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("THEME_ENGINE_V1"),
        backgroundColor: theme.colorScheme.secondary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("TELEMETRY_DATA", style: theme.textTheme.displayLarge),
            const SizedBox(height: 10),
            Text(
              "Monitoreo activo de sensores ESP32 en el laboratorio.",
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text("INICIAR ESCANEO"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}