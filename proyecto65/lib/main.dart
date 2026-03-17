import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: AdSimulationScreen()
    ));

class AdSimulationScreen extends StatefulWidget {
  const AdSimulationScreen({super.key});

  @override
  State<AdSimulationScreen> createState() => _AdSimulationScreenState();
}

class _AdSimulationScreenState extends State<AdSimulationScreen> {
  bool _isBannerLoaded = false;
  bool _isInterstitialAdReady = false;

  // Simulación de carga de anuncio (Ingeniería de estados)
  void _loadAds() async {
    setState(() => _isBannerLoaded = false);
    await Future.delayed(const Duration(seconds: 2)); // Simula latencia de red
    setState(() => _isBannerLoaded = true);
    setState(() => _isInterstitialAdReady = true);
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady) {
      // Simulamos la interrupción del flujo de la app
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _InterstitialAdMock(onClose: () {
          setState(() => _isInterstitialAdReady = false);
          Navigator.pop(context);
        }),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("AD_MANAGER_SIMULATOR"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          const Expanded(
            child: Center(
              child: Text(
                "CONTENIDO DEL SISTEMA DE MICROCLIMA",
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          
          // Botón para disparar anuncio a pantalla completa
          ElevatedButton(
            onPressed: _isInterstitialAdReady ? _showInterstitialAd : null,
            child: const Text("MOSTRAR ANUNCIO INTERSTICIAL"),
          ),
          const SizedBox(height: 20),

          // Espacio para el Banner Simulado
          _buildBannerMock(),
        ],
      ),
    );
  }

  // Widget que simula un Banner de AdMob
  Widget _buildBannerMock() {
    return Container(
      width: double.infinity,
      height: 60,
      color: _isBannerLoaded ? Colors.grey[850] : Colors.black,
      child: Center(
        child: _isBannerLoaded
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.ad_units, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Text("ANUNCIO DE PRUEBA: 320x50", style: TextStyle(color: Colors.amber)),
                ],
              )
            : const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

// Clase para simular el anuncio a pantalla completa
class _InterstitialAdMock extends StatelessWidget {
  final VoidCallback onClose;
  const _InterstitialAdMock({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          const Center(
            child: Text(
              "ANUNCIO INTERSTICIAL\n(Simulación de Video)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black, fontSize: 24, decoration: TextDecoration.none),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.black, size: 30),
              onPressed: onClose,
            ),
          ),
        ],
      ),
    );
  }
}