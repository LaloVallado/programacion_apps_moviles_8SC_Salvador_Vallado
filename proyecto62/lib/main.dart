import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoControlScreen(),
    ));

class VideoControlScreen extends StatefulWidget {
  const VideoControlScreen({super.key});

  @override
  State<VideoControlScreen> createState() => _VideoControlScreenState();
}

class _VideoControlScreenState extends State<VideoControlScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    // URL de prueba de video de Flutter
    _controller = VideoPlayerController.networkUrl(
      Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
    );

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo oscuro sólido
      appBar: AppBar(
        title: const Text(
          "CONTROL_DE_VIDEO_ITM",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    );
                  } else {
                    return const CircularProgressIndicator(color: Colors.blue);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Botón de reproducción simple
          Padding(
            padding: const EdgeInsets.only(bottom: 50),
            child: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying 
                      ? _controller.pause() 
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}