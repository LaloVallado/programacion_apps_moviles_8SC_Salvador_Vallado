import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';

void main() => runApp(const MaterialApp(home: FadeImageScreen()));

class FadeImageScreen extends StatelessWidget {
  const FadeImageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("IMAGE_FADE_ENGINE_V1"),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // El widget clave para ingeniería de UI
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage, // Lo que se ve primero (transparente)
                image: 'https://picsum.photos/400/300', // Imagen real de red
                width: 350,
                height: 250,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 800), // Control del fade
                fadeInCurve: Curves.easeIn,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "PROCESANDO_TELEMETRÍA_VISUAL...",
              style: TextStyle(color: Colors.white54, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}