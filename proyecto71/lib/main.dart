import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AdvancedPhysicsSystem(),
    ));

class AdvancedPhysicsSystem extends StatefulWidget {
  const AdvancedPhysicsSystem({super.key});

  @override
  State<AdvancedPhysicsSystem> createState() => _AdvancedPhysicsSystemState();
}

class _AdvancedPhysicsSystemState extends State<AdvancedPhysicsSystem> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  List<Particle> particles = [];
  final int totalParticles = 20;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    // Inicialización del motor de partículas
    for (int i = 0; i < totalParticles; i++) {
      particles.add(Particle(
        position: const Offset(100, 100),
        velocity: Offset(random.nextDouble() * 6 - 3, random.nextDouble() * 6 - 3),
        radius: random.nextDouble() * 15 + 5,
      ));
    }

    _ticker = createTicker((elapsed) {
      setState(() {
        for (var p in particles) {
          p.update(MediaQuery.of(context).size);
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
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          // Capa 1: Motor de Física (Canvas)
          CustomPaint(
            painter: PhysicsPainter(particles: particles),
            child: Container(),
          ),
          
          // Capa 2: UI Técnica (Fuentes)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PHYSICS_CORE_ACTIVE",
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  Text(
                    "SYSTEM_STABILITY: 98.4%",
                    style: GoogleFonts.shareTechMono(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  // Botón interactivo
                  ElevatedButton(
                    onPressed: () {
                      for (var p in particles) {
                        p.velocity = Offset(random.nextDouble() * 10 - 5, random.nextDouble() * 10 - 5);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withOpacity(0.1)),
                    child: Text("INJECT_ENERGY", style: GoogleFonts.orbitron(color: Colors.cyanAccent)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Particle {
  Offset position;
  Offset velocity;
  double radius;

  Particle({required this.position, required this.velocity, required this.radius});

  void update(Size size) {
    position += velocity;
    if (position.dx < 0 || position.dx > size.width) velocity = Offset(-velocity.dx, velocity.dy);
    if (position.dy < 0 || position.dy > size.height) velocity = Offset(velocity.dx, -velocity.dy);
  }
}

class PhysicsPainter extends CustomPainter {
  final List<Particle> particles;
  PhysicsPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      canvas.drawCircle(p.position, p.radius, paint);
      // Dibujar líneas de conexión (Red Neuronal Simulada)
      for (var other in particles) {
        double dist = (p.position - other.position).distance;
        if (dist < 100) {
          canvas.drawLine(
            p.position,
            other.position,
            Paint()..color = Colors.white.withOpacity(1 - (dist / 100))..strokeWidth = 0.5,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}