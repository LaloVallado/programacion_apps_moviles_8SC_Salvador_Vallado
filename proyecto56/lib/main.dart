import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InputCaptureScreen(),
    ));

class InputCaptureScreen extends StatefulWidget {
  const InputCaptureScreen({super.key});

  @override
  State<InputCaptureScreen> createState() => _InputCaptureScreenState();
}

class _InputCaptureScreenState extends State<InputCaptureScreen> {
  // 1. Instanciamos el controlador (Propiedad de la clase)
  final TextEditingController _nodeIpController = TextEditingController();
  String _capturedValue = "ESPERANDO NODO...";

  // 2. IMPORTANTE: Limpiar el controlador cuando el widget se destruye
  @override
  void dispose() {
    _nodeIpController.dispose();
    super.dispose();
  }

  void _processInput() {
    setState(() {
      // 3. RECUPERAR EL TEXTO: Simplemente accedemos a .text
      if (_nodeIpController.text.isEmpty) {
        _capturedValue = "ERROR: CAMPO VACÍO";
      } else {
        _capturedValue = "CONECTANDO A: ${_nodeIpController.text}";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('IO_SYSTEM_V3', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTerminalHeader(),
            const SizedBox(height: 30),
            
            // EL CAMPO DE TEXTO
            TextField(
              controller: _nodeIpController, // Asignamos el controlador
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'DIRECCIÓN IP DEL NODO',
                labelStyle: const TextStyle(color: Colors.cyanAccent),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white10),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.cyanAccent),
                ),
                prefixIcon: const Icon(Icons.lan, color: Colors.cyanAccent),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 20),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("SERIAL_MONITOR_OUT:", style: TextStyle(color: Colors.white38, fontSize: 10)),
          const Divider(color: Colors.white10),
          Text("> $_capturedValue", 
            style: const TextStyle(color: Colors.cyanAccent, fontFamily: 'monospace', fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: _processInput,
        child: const Text("ESTABLECER CONEXIÓN", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}