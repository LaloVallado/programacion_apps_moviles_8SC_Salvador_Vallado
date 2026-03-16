import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// 1. Definir la clase de los argumentos
class ScreenArguments {
  final String title;
  final String message;

  ScreenArguments(this.title, this.message);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Proyecto 25 - Navigation',
      // 3. Registrar las rutas en la tabla
      routes: {
        '/': (context) => const HomeScreen(),
        ExtractArgumentsScreen.routeName: (context) => const ExtractArgumentsScreen(),
      },
    );
  }
}

// Pantalla de Inicio (Donde enviamos los datos)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pantalla de Inicio')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 4. Navegar y pasar los argumentos
            Navigator.pushNamed(
              context,
              ExtractArgumentsScreen.routeName,
              arguments: ScreenArguments(
                'Datos del Proyecto 25',
                'Este mensaje fue pasado desde el Home con éxito.',
              ),
            );
          },
          child: const Text('Ir a pantalla de detalles'),
        ),
      ),
    );
  }
}

// 2. Widget que extrae los argumentos (El Receptor)
class ExtractArgumentsScreen extends StatelessWidget {
  const ExtractArgumentsScreen({super.key});

  static const routeName = '/extractArguments';

  @override
  Widget build(BuildContext context) {
    // Extraemos los argumentos y les damos el tipo ScreenArguments
    final args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Center(
        child: Text(
          args.message,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}