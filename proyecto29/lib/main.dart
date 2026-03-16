import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// 1. Clase Modelo de Datos
class Photo {
  final int albumId;
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  const Photo({
    required this.albumId,
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      albumId: json['albumId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
    );
  }
}

// 2. Funciones de Red e Isolate
// NOTA: 'compute' en la Web usa Web Workers de forma interna
Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client.get(
    Uri.parse('https://jsonplaceholder.typicode.com/photos'),
  );

  // Ejecuta la función pesada en un Isolate (segundo plano)
  return compute(parsePhotos, response.body);
}

// Esta es la función pesada que procesa el JSON
List<Photo> parsePhotos(String responseBody) {
  final parsed = (jsonDecode(responseBody) as List<Object?>).cast<Map<String, Object?>>();
  return parsed.map<Photo>(Photo.fromJson).toList();
}

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const appTitle = 'Proyecto 29 - Isolate Demo';
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(title: appTitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<Photo>> futurePhotos;

  @override
  void initState() {
    super.initState();
    // Iniciamos la petición al nacer el Widget
    futurePhotos = fetchPhotos(http.Client());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<List<Photo>>(
        future: futurePhotos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            return PhotosList(photos: snapshot.data!);
          }
          // Mientras carga, mostramos el círculo de progreso
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class PhotosList extends StatelessWidget {
  const PhotosList({super.key, required this.photos});
  final List<Photo> photos;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // Dos columnas
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        // SOLUCIÓN AL CORS: Usamos Picsum para que Safari no bloquee la imagen en localhost
        final imageUrl = 'https://picsum.photos/id/${photos[index].id % 1000}/200';
        
        return Card(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            // Widget de carga mientras baja la imagen
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            // Si la imagen falla, mostramos un icono de error
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
          ),
        );
      },
    );
  }
}