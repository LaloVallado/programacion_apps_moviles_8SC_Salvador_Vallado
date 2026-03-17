import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameServicesScreen(),
    ));

class GameServicesScreen extends StatefulWidget {
  const GameServicesScreen({super.key});

  @override
  State<GameServicesScreen> createState() => _GameServicesScreenState();
}

class _GameServicesScreenState extends State<GameServicesScreen> {
  // Simulación de datos en "la nube"
  int _score = 1250;
  bool _isAchievementUnlocked = false;
  bool _isLoading = false;

  // Mock de la Tabla de Clasificación
  final List<Map<String, dynamic>> _leaderboard = [
    {"name": "Eduardo_ITM", "score": 2500, "rank": 1},
    {"name": "Sistemas_User", "score": 1800, "rank": 2},
    {"name": "Flutter_Dev", "score": 1250, "rank": 3},
  ];

  // Función para simular el envío de puntuación
  Future<void> _submitScore() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // Simula latencia de red
    
    setState(() {
      _score += 100;
      if (_score >= 1500) _isAchievementUnlocked = true;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Puntuación sincronizada con Game Services")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Dark mode tipo GitHub
      appBar: AppBar(
        title: const Text("GAME_SERVICES_SIMULATOR"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard, color: Colors.amber),
            onPressed: () => _showLeaderboard(),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("TU PUNTUACIÓN ACTUAL", style: TextStyle(color: Colors.white70)),
            Text("$_score", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            // Simulación de Logro
            _buildAchievementBadge(),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _submitScore,
              icon: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: const Text("ENVIAR PUNTUACIÓN"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _isAchievementUnlocked ? 1.0 : 0.2,
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 80),
          Text(
            _isAchievementUnlocked ? "¡LOGRO DESBLOQUEADO!" : "LOGRO BLOQUEADO (1500 pts)",
            style: TextStyle(color: _isAchievementUnlocked ? Colors.amber : Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("TABLA DE CLASIFICACIÓN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            ..._leaderboard.map((user) => ListTile(
              leading: CircleAvatar(child: Text("${user['rank']}")),
              title: Text(user['name'], style: const TextStyle(color: Colors.white)),
              trailing: Text("${user['score']} pts", style: const TextStyle(color: Colors.blueAccent)),
            )),
          ],
        ),
      ),
    );
  }
}