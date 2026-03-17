import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReactiveInputScreen(),
    ));

class ReactiveInputScreen extends StatefulWidget {
  const ReactiveInputScreen({super.key});

  @override
  State<ReactiveInputScreen> createState() => _ReactiveInputScreenState();
}

class _ReactiveInputScreenState extends State<ReactiveInputScreen> {
  final TextEditingController _commandController = TextEditingController();
  bool _isCommandValid = false;
  String _livePreview = "ESPERANDO COMANDO...";

  @override
  void initState() {
    super.initState();
    // 1. Vinculamos el listener al controlador al iniciar el widget
    _commandController.addListener(_validateInput);
  }

  // 2. Lógica de validación reactiva
  void _validateInput() {
    final text = _commandController.text;
    setState(() {
      // Regla: El comando debe empezar con 'SET_' y tener más de 5 caracteres
      _isCommandValid = text.startsWith('SET_') && text.length > 5;
      _livePreview = text.isEmpty ? "ESPERANDO COMANDO..." : text.toUpperCase();
    });
  }

  @override
  void dispose() {
    // 3. Limpieza de memoria (Vital para tu MacBook Air)
    _commandController.removeListener(_validateInput);
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        title: const Text('REACTIVE_IO_V1', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: const Color(0xFF161B22),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            _buildLiveTerminal(),
            const SizedBox(height: 40),
            TextField(
              controller: _commandController,
              style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: 'INGRESAR COMANDO (SET_...)',
                labelStyle: TextStyle(color: _isCommandValid ? Colors.greenAccent : Colors.white38),
                prefixIcon: Icon(Icons.code, color: _isCommandValid ? Colors.greenAccent : Colors.white38),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: _isCommandValid ? Colors.greenAccent : Colors.cyanAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildActionStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTerminal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Text("> $_livePreview", 
        style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
    );
  }

  Widget _buildActionStatus() {
    return Row(
      children: [
        Icon(_isCommandValid ? Icons.check_circle : Icons.error_outline, 
             color: _isCommandValid ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 10),
        Text(
          _isCommandValid ? "COMANDO AUTORIZADO" : "SINTAXIS INVÁLIDA",
          style: TextStyle(color: _isCommandValid ? Colors.greenAccent : Colors.redAccent, fontSize: 12),
        ),
      ],
    );
  }
}