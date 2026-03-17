import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() => runApp(const MaterialApp(home: PhysicsEngineScreen()));

class PhysicsEngineScreen extends StatefulWidget {
  const PhysicsEngineScreen({super.key});

  @override
  State<PhysicsEngineScreen> createState() => _PhysicsEngineScreenState();
}

class _PhysicsEngineScreenState extends State<PhysicsEngineScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  List<Particle> particles = [];
  final int totalParticles = 15;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    // Creamos partículas con vectores de velocidad aleatorios
    for (int i = 0; i < totalParticles; i++) {
      particles.add(Particle(
        position: Offset(random.nextDouble() * 300, random.nextDouble() * 500),
        velocity: Offset(random.nextDouble() * 4 - 2, random.nextDouble() * 4 - 2),
        radius: random.nextDouble() * 20 + 10,
        color: Colors.blueAccent.withOpacity(0.7),
      ));
    }

    // El Ticker es el "corazón" del motor físico (60 FPS)
    _ticker = createTicker((elapsed) {
      setState(() {
        for (var particle in particles) {
          particle.update(MediaQuery.of(context).size);
        }
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text("ROBUST_PHYSICS_CORE"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _resetParticles(),
          )
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) => _applyForce(details.localPosition),
        child: CustomPaint(
          painter: PhysicsPainter(particles: particles),
          child: Container(),
        ),
      ),
    );
  }

  void _applyForce(Offset touchPosition) {
    for (var p in particles) {
      double dx = p.position.dx - touchPosition.dx;
      double dy = p.position.dy - touchPosition.dy;
      double distance = sqrt(dx * dx + dy * dy);
      
      if (distance < 150) {
        // Efecto de repulsión (Fuerza de Lorentz simulada)
        p.velocity += Offset(dx / 50, dy / 50);
      }
    }
  }

  void _resetParticles() {
    for (var p in particles) {
      p.velocity = Offset(random.nextDouble() * 4 - 2, random.nextDouble() * 4 - 2);
    }
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  Color color;

  Particle({required this.position, required this.velocity, required this.radius, required this.color});

  void update(Size size) {
    position += velocity;

    // Rebote en bordes (Ingeniería de colisiones simple)
    if (position.dx - radius < 0 || position.dx + radius > size.width) {
      velocity = Offset(-velocity.dx * 0.8, velocity.dy); // Perder 20% energía
    }
    if (position.dy - radius < 0 || position.dy + radius > size.height) {
      velocity = Offset(velocity.dx, -velocity.dy * 0.8);
    }
  }
}

class PhysicsPainter extends CustomPainter {
  final List<Particle> particles;
  PhysicsPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      // Dibujar estela/brillo
      paint.color = p.color;
      canvas.drawCircle(p.position, p.radius, paint);
      
      // Dibujar núcleo técnico
      paint.color = Colors.white.withOpacity(0.5);
      paint.style = PaintingStyle.stroke;
      canvas.drawCircle(p.position, p.radius + 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}