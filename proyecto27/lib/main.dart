import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto 27 - Ripples',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Efecto Ripple (InkWell)'),
      ),
      body: Center(
        child: MyCustomButton(),
      ),
    );
  }
}

class MyCustomButton extends StatelessWidget {
  const MyCustomButton({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. El InkWell es el que crea la magia del ripple
    return InkWell(
      // 2. Definimos qué pasa al tocar (onTap)
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Tap detectado!'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      // 3. El hijo puede ser cualquier widget, en este caso un botón plano
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8), // Para que el ripple sea redondeado
        ),
        child: const Text(
          'Botón Plano con Ripple',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}