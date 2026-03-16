import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// 1. El Modelo de Datos
class UserProfile {
  final String name;
  final String photoUrl;
  UserProfile({required this.name, required this.photoUrl});
}

// 2. Simulación de Servicios (Backend y Base de Datos)
class ApiClientService {
  Future<UserProfile> getUserProfile() async {
    // Simulamos un retraso de red
    await Future.delayed(const Duration(seconds: 2));
    // Simulamos que el servidor responde con éxito
    return UserProfile(name: "Salvador Vallado (Desde Internet)", photoUrl: "");
    // Si quisieras probar el error, podrías poner: throw Exception('No hay red');
  }
}

class DatabaseService {
  Future<UserProfile?> fetchUserProfile() async {
    // Simulamos que en la memoria local ya hay un nombre guardado
    return UserProfile(name: "Lalo (Cargado de Memoria Local)", photoUrl: "");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: OfflineFirstScreen(),
    );
  }
}

class OfflineFirstScreen extends StatefulWidget {
  @override
  _OfflineFirstScreenState createState() => _OfflineFirstScreenState();
}

class _OfflineFirstScreenState extends State<OfflineFirstScreen> {
  final ApiClientService _api = ApiClientService();
  final DatabaseService _db = DatabaseService();
  String _displayName = "Cargando...";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // 3. Lógica de Offline-First (Fallback)
  Future<void> loadData() async {
    try {
      // Intento 1: Traer de internet
      final user = await _api.getUserProfile();
      setState(() {
        _displayName = user.name;
      });
    } catch (e) {
      // Intento 2: Si falla internet, traer de la base de datos local
      final localUser = await _db.fetchUserProfile();
      setState(() {
        _displayName = localUser?.name ?? "Usuario no encontrado";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proyecto 28: Offline First')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 50, color: Colors.blue),
            const SizedBox(height: 20),
            Text(_displayName, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() => _displayName = "Reintentando...");
                loadData();
              },
              child: const Text('Actualizar Datos'),
            ),
          ],
        ),
      ),
    );
  }
}