import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Proyecto 30 - Uso de Listas';

    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        // Aquí empieza el ListView
        body: ListView(
          children: const <Widget>[
            // ListTile es el widget perfecto para filas de listas
            ListTile(
              leading: Icon(Icons.map, color: Colors.indigo),
              title: Text('Mapa de Mérida'),
              subtitle: Text('Consulta ubicaciones locales'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: Icon(Icons.photo_album, color: Colors.indigo),
              title: Text('Álbum de Fotos'),
              subtitle: Text('Imágenes del Proyecto 29'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            ListTile(
              leading: Icon(Icons.phone, color: Colors.indigo),
              title: Text('Contactos'),
              subtitle: Text('Llamadas de emergencia'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
            ),
            Divider(), // Una línea divisoria para separar secciones
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey),
              title: Text('Configuración'),
            ),
          ],
        ),
      ),
    );
  }
}