import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: OptimisticControlScreen()));

class OptimisticControlScreen extends StatefulWidget {
  const OptimisticControlScreen({super.key});

  @override
  State<OptimisticControlScreen> createState() => _OptimisticControlScreenState();
}

class _OptimisticControlScreenState extends State<OptimisticControlScreen> {
  // Estado real en el dispositivo
  bool isPumpOn = false;

  // Función que simula una petición al ESP32 (con latencia y posible error)
  Future<void> _togglePumpRemote(bool targetState) async {
    await Future.delayed(const Duration(seconds: 2)); // Simula latencia de red
    
    // Simulamos un error aleatorio (ej. el sensor no respondió)
    if (DateTime.now().second % 5 == 0) {
      throw Exception("Error de conexión con el nodo");
    }
    print("Servidor actualizado: Bomba ${targetState ? 'ON' : 'OFF'}");
  }

  void _handleToggle() async {
    // 1. GUARDAR ESTADO ANTERIOR (para el rollback)
    final previousState = isPumpOn;

    // 2. ACTUALIZACIÓN OPTIMISTA (La UI cambia al instante)
    setState(() {
      isPumpOn = !isPumpOn;
    });

    try {
      // 3. LLAMADA REAL A LA RED
      await _togglePumpRemote(isPumpOn);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comando ejecutado con éxito")),
      );
    } catch (e) {
      // 4. ROLLBACK (Si falla, regresamos al estado anterior)
      setState(() {
        isPumpOn = previousState;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text("CONTROL_OPTIMISTA_V1")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop,
              size: 100,
              color: isPumpOn ? Colors.blue : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              "ESTADO DE LA BOMBA: ${isPumpOn ? 'ACTIVA' : 'INACTIVA'}",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 40),
            Switch(
              value: isPumpOn,
              onChanged: (value) => _handleToggle(),
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }
}