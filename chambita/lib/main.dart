// =============================================================================
// CHAMBITA — Practica entrevistas con un reclutador-IA
// =============================================================================
// Equipo 8 · 8SC · Programación de Aplicaciones Móviles
// Instituto Tecnológico de Mérida
//
// Integrantes:
//   - Salvador Eduardo Vallado Villamonte
//   - Juan Chan
//   - Erick Castilla
//   - Susan Chin
//
// -----------------------------------------------------------------------------
// FUENTES DE LA RÚBRICA DE EVALUACIÓN (referencias reales y públicas):
//   - Método STAR (Situation, Task, Action, Result): estándar usado por
//     reclutadores en Amazon, Google, Microsoft para entrevistas conductuales.
//   - SHRM (Society for Human Resource Management): competencias blandas
//     en entrevistas profesionales.
//   - WEF Future of Jobs Report 2023: habilidades blandas más demandadas.
//   - LinkedIn Talent Solutions México 2024: guías de qué buscan los
//     reclutadores en MX.
//   - OCC Mundial — Guías de preparación para entrevistas en México.
// =============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

// =============================================================================
// CONFIGURACIÓN — Cambia tu API key aquí
// =============================================================================
const String _geminiApiKey = 'AIzaSyBq2zrf9Z-c6sCYL3A45YZCSOyFPNXpIVc';

// Modelos que vamos a probar en cascada hasta encontrar uno que jale.
// Si el primero falla, prueba el siguiente, y así.
const List<String> _geminiModels = [
  'gemini-2.0-flash-lite',
  'gemini-2.0-flash',
  'gemini-2.5-flash-lite',
  'gemini-2.5-flash',
  'gemini-1.5-flash-latest',
];

// =============================================================================
// PALETA Y ESTILOS — Estilo Apple, oscuro, minimalista
// =============================================================================
class AppColors {
  static const bg = Color(0xFF000000);
  static const bgElev = Color(0xFF0A0A0F);
  static const card = Color(0xFF111118);
  static const cardElev = Color(0xFF1A1A22);
  static const border = Color(0xFF2A2A33);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textTertiary = Color(0xFF71717A);

  static const blue = Color(0xFF0A84FF);
  static const indigo = Color(0xFF5E5CE6);
  static const purple = Color(0xFFBF5AF2);
  static const pink = Color(0xFFFF375F);
  static const orange = Color(0xFFFF9F0A);
  static const yellow = Color(0xFFFFD60A);
  static const green = Color(0xFF30D158);
  static const teal = Color(0xFF40C8E0);
}

class AppText {
  static const String fontFamily = '.SF Pro Display';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );
  static const TextStyle title1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
    height: 1.15,
  );
  static const TextStyle title2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );
  static const TextStyle title3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );
  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.4,
  );
  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );
}

// =============================================================================
// MODELOS
// =============================================================================
enum ChatRole { user, ai }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'role': role.name,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: ChatRole.values.firstWhere((r) => r.name == json['role']),
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class JobRole {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const JobRole({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });
}

class SeniorityLevel {
  final String id;
  final String label;
  final String description;
  const SeniorityLevel({
    required this.id,
    required this.label,
    required this.description,
  });
}

const List<JobRole> kJobRoles = [
  JobRole(
    id: 'dev',
    title: 'Desarrollador',
    subtitle: 'Frontend / Backend / Full-stack',
    icon: CupertinoIcons.chevron_left_slash_chevron_right,
    accent: AppColors.blue,
  ),
  JobRole(
    id: 'ux',
    title: 'Diseñador UX/UI',
    subtitle: 'Producto y experiencia',
    icon: CupertinoIcons.paintbrush_fill,
    accent: AppColors.purple,
  ),
  JobRole(
    id: 'mkt',
    title: 'Marketing Digital',
    subtitle: 'Performance y contenido',
    icon: CupertinoIcons.chart_bar_alt_fill,
    accent: AppColors.orange,
  ),
  JobRole(
    id: 'sales',
    title: 'Ventas',
    subtitle: 'B2B / B2C',
    icon: CupertinoIcons.person_2_fill,
    accent: AppColors.green,
  ),
  JobRole(
    id: 'data',
    title: 'Analista de Datos',
    subtitle: 'BI, dashboards, SQL',
    icon: CupertinoIcons.graph_circle_fill,
    accent: AppColors.teal,
  ),
  JobRole(
    id: 'pm',
    title: 'Project Manager',
    subtitle: 'Gestión de proyectos',
    icon: CupertinoIcons.briefcase_fill,
    accent: AppColors.indigo,
  ),
];

const List<SeniorityLevel> kSeniority = [
  SeniorityLevel(id: 'junior', label: 'Junior', description: '0-2 años'),
  SeniorityLevel(id: 'mid', label: 'Mid', description: '2-5 años'),
  SeniorityLevel(id: 'senior', label: 'Senior', description: '5+ años'),
];

class InterviewSession {
  final String id;
  final String roleId;
  final String roleTitle;
  final String seniorityLabel;
  final String mode;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final FeedbackResult? feedback;

  InterviewSession({
    required this.id,
    required this.roleId,
    required this.roleTitle,
    required this.seniorityLabel,
    required this.mode,
    required this.messages,
    required this.createdAt,
    this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'roleId': roleId,
        'roleTitle': roleTitle,
        'seniorityLabel': seniorityLabel,
        'mode': mode,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'feedback': feedback?.toJson(),
      };

  factory InterviewSession.fromJson(Map<String, dynamic> json) =>
      InterviewSession(
        id: json['id'] as String,
        roleId: json['roleId'] as String,
        roleTitle: json['roleTitle'] as String,
        seniorityLabel: json['seniorityLabel'] as String,
        mode: json['mode'] as String,
        messages: (json['messages'] as List)
            .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        feedback: json['feedback'] == null
            ? null
            : FeedbackResult.fromJson(json['feedback'] as Map<String, dynamic>),
      );
}

class FeedbackResult {
  final double scoreOverall;
  final Map<String, double> dimensions;
  final List<String> strengths;
  final List<String> improvements;
  final String summary;

  FeedbackResult({
    required this.scoreOverall,
    required this.dimensions,
    required this.strengths,
    required this.improvements,
    required this.summary,
  });

  Map<String, dynamic> toJson() => {
        'scoreOverall': scoreOverall,
        'dimensions': dimensions,
        'strengths': strengths,
        'improvements': improvements,
        'summary': summary,
      };

  factory FeedbackResult.fromJson(Map<String, dynamic> json) => FeedbackResult(
        scoreOverall: (json['scoreOverall'] as num).toDouble(),
        dimensions: (json['dimensions'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
        strengths: List<String>.from(json['strengths'] as List),
        improvements: List<String>.from(json['improvements'] as List),
        summary: json['summary'] as String,
      );
}

// =============================================================================
// SERVICIO DE GEMINI (HTTP DIRECTO — funciona en web, móvil, todo)
// =============================================================================
class GeminiService {
  String? _workingModel;
  // Histórico de conversación para mantener contexto
  final List<Map<String, dynamic>> _history = [];
  String? _systemPrompt;

  /// Inicia una entrevista. Guarda el system prompt y limpia el historial.
  void startInterview({
    required String roleTitle,
    required String seniority,
    required String mode,
  }) {
    _history.clear();

    final modeContext = mode == 'voz'
        ? 'La entrevista es por LLAMADA DE VOZ, así que tus mensajes deben '
            'sonar naturales al hablarlos en voz alta. Sé conversacional, '
            'usa frases cortas y deja claro cuándo terminas tu pregunta.'
        : 'La entrevista es por CHAT escrito.';

    _systemPrompt = '''
Eres ReclutA, una reclutadora profesional mexicana experimentada que está
entrevistando a un candidato para un puesto de $roleTitle nivel $seniority.

$modeContext

Tu estilo:
- Amable pero profesional. Usas un español neutro mexicano.
- Haces UNA pregunta a la vez, no varias en el mismo mensaje.
- Tus mensajes son CORTOS (máximo 2-3 oraciones, salvo el saludo inicial).
- Después de cada respuesta del candidato, das un breve reconocimiento
  ("Entiendo", "Interesante", "Gracias por compartirlo") y haces la siguiente
  pregunta. NO des consejos ni evalúes durante la entrevista.
- Variás entre preguntas conductuales (método STAR), técnicas básicas del rol,
  y preguntas sobre motivación y fit cultural.
- Después de unas 6-8 preguntas, despídete cordialmente y avisa que el
  feedback se generará al cerrar la sesión.

Empieza ahora con un saludo natural y la primera pregunta.
''';
  }

  /// Llamada HTTP directa a Gemini probando varios modelos en cascada.
  Future<String> _callGemini({
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
    double temperature = 0.8,
    int maxTokens = 400,
    bool jsonMode = false,
  }) async {
    if (_geminiApiKey == 'PEGA_TU_KEY_AQUI' || _geminiApiKey.isEmpty) {
      throw Exception(
          'No has configurado tu API key. Pégala en main.dart en la línea '
          'const String _geminiApiKey = ...');
    }

    final body = <String, dynamic>{
      'contents': contents,
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxTokens,
        if (jsonMode) 'responseMimeType': 'application/json',
      },
    };
    if (systemInstruction != null) {
      body['system_instruction'] = {
        'parts': [
          {'text': systemInstruction}
        ]
      };
    }

    final encodedBody = jsonEncode(body);

    // Si ya sabemos qué modelo jala, lo probamos primero.
    final modelsToTry = _workingModel != null
        ? [_workingModel!, ..._geminiModels.where((m) => m != _workingModel)]
        : _geminiModels;

    String? lastError;
    for (final model in modelsToTry) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_geminiApiKey',
        );
        final response = await http
            .post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: encodedBody,
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) {
            lastError = 'Respuesta vacía de Gemini';
            continue;
          }
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          final text = parts?[0]?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            _workingModel = model; // Recordamos cuál jaló
            return text;
          }
          lastError = 'Respuesta vacía';
          continue;
        }

        // Error: leemos el detalle
        try {
          final errData = jsonDecode(response.body);
          lastError = errData['error']?['message']?.toString() ??
              'Error ${response.statusCode}';
        } catch (_) {
          lastError = 'Error HTTP ${response.statusCode}';
        }

        // 404 = modelo no existe, probamos el siguiente
        // 429 = rate limit, probamos el siguiente
        if (response.statusCode == 404 || response.statusCode == 429) continue;

        // Otros errores (403, 400, etc.) los lanzamos
        throw Exception(lastError);
      } on Exception catch (e) {
        lastError = e.toString().replaceAll('Exception: ', '');
        // si es error de red, probar siguiente modelo
        continue;
      }
    }
    throw Exception(lastError ?? 'No se pudo conectar a Gemini');
  }

  /// Genera el saludo inicial de la entrevista.
  Future<String> openingMessage() async {
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': 'Comienza la entrevista ahora con un saludo y la primera pregunta.'}
        ]
      },
    ];
    final response = await _callGemini(
      contents: contents,
      systemInstruction: _systemPrompt,
    );
    // Guardamos la respuesta en el historial
    _history.add({
      'role': 'user',
      'parts': [
        {'text': 'Comienza la entrevista ahora.'}
      ]
    });
    _history.add({
      'role': 'model',
      'parts': [
        {'text': response}
      ]
    });
    return response;
  }

  /// Envía un mensaje del usuario y obtiene respuesta de la IA.
  Future<String> sendMessage(String userMessage) async {
    final contents = [
      ..._history,
      {
        'role': 'user',
        'parts': [
          {'text': userMessage}
        ]
      },
    ];
    final response = await _callGemini(
      contents: contents,
      systemInstruction: _systemPrompt,
    );
    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ]
    });
    _history.add({
      'role': 'model',
      'parts': [
        {'text': response}
      ]
    });
    return response;
  }

  /// Evalúa la entrevista completa y devuelve un FeedbackResult.
  Future<FeedbackResult> evaluate({
    required String roleTitle,
    required String seniority,
    required List<ChatMessage> messages,
  }) async {
    final transcript = messages
        .map((m) =>
            '${m.role == ChatRole.ai ? "RECLUTADORA" : "CANDIDATO"}: ${m.text}')
        .join('\n');

    final prompt = '''
Eres una experta en reclutamiento de talento en México. Vas a evaluar la
siguiente transcripción de una entrevista simulada para un puesto de
$roleTitle nivel $seniority.

EVALUA SOLO LAS RESPUESTAS DEL CANDIDATO usando la siguiente rúbrica basada en
estándares profesionales:

1. CLARIDAD (0-10): ¿Sus respuestas son entendibles, ordenadas, sin muletillas?
2. ESTRUCTURA STAR (0-10): ¿Usa el método STAR (Situación, Tarea, Acción,
   Resultado) en preguntas conductuales? Estándar usado por Amazon, Google,
   Microsoft.
3. EJEMPLOS CONCRETOS (0-10): ¿Da ejemplos específicos en lugar de
   generalidades?
4. CONOCIMIENTO DEL ROL (0-10): ¿Demuestra conocer el puesto y la industria?
5. ACTITUD Y FIT (0-10): ¿Muestra entusiasmo, motivación, autoconocimiento?
   (Habilidades blandas según WEF Future of Jobs Report y SHRM).
6. COMUNICACIÓN (0-10): ¿Sus respuestas son del largo correcto? ¿Vocabulario
   apropiado?

DEVUELVE EXCLUSIVAMENTE UN JSON con esta estructura exacta (sin markdown, sin
texto antes o después, SOLO el JSON):
{
  "scoreOverall": <número 0-10 con un decimal>,
  "dimensions": {
    "Claridad": <0-10>,
    "Estructura STAR": <0-10>,
    "Ejemplos concretos": <0-10>,
    "Conocimiento del rol": <0-10>,
    "Actitud y fit": <0-10>,
    "Comunicación": <0-10>
  },
  "strengths": [<string>, <string>, <string>],
  "improvements": [<string>, <string>, <string>],
  "summary": "<2-3 oraciones de resumen general en español>"
}

Sé honesto y específico. No uses lenguaje genérico tipo "buena comunicación".
Sé concreto, cita ejemplos textuales del candidato cuando puedas.

TRANSCRIPCIÓN:
$transcript
''';

    final raw = await _callGemini(
      contents: [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      temperature: 0.4,
      maxTokens: 1500,
      jsonMode: true,
    );

    // Limpiar posible markdown alrededor del JSON
    var cleaned = raw.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```\s*$'), '');
    }

    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return FeedbackResult.fromJson(json);
    } catch (e) {
      throw Exception('Gemini devolvió un JSON inválido: $e\n\nRaw: $cleaned');
    }
  }

  void reset() {
    _history.clear();
    _systemPrompt = null;
  }
}

// =============================================================================
// REPOSITORIO DE HISTORIAL
// =============================================================================
class HistoryRepo {
  static const _key = 'chambita_sessions_v1';

  Future<List<InterviewSession>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => InterviewSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(InterviewSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.insert(0, session);
    final raw = jsonEncode(all.map((s) => s.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// =============================================================================
// MAIN
// =============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.bg,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ChambitaApp());
}

class ChambitaApp extends StatelessWidget {
  const ChambitaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chambita',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: AppText.fontFamily,
        colorScheme: const ColorScheme.dark(
          surface: AppColors.bg,
          primary: AppColors.blue,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// =============================================================================
// PANTALLA: HOME
// =============================================================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HistoryRepo _repo = HistoryRepo();
  List<InterviewSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.loadAll();
    if (!mounted) return;
    setState(() {
      _sessions = s;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                _GradientText(
                  'Chambita',
                  style: const TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1,
                  ),
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.indigo,
                      AppColors.purple,
                      AppColors.pink,
                      AppColors.orange,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(CupertinoIcons.sparkles,
                    color: AppColors.yellow, size: 24),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Practica entrevistas con un\nreclutador-IA en tu celu.',
              style: AppText.bodySecondary,
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: 'Nueva entrevista',
              icon: CupertinoIcons.add,
              onPressed: () async {
                final r = await Navigator.of(context).push(
                  CupertinoPageRoute(builder: (_) => const SetupScreen()),
                );
                if (r == true) _load();
              },
            ),
            const SizedBox(height: 32),
            const _StatsRow(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tu historial', style: AppText.title2),
                if (_sessions.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final ok = await _confirmClear(context);
                      if (ok == true) {
                        await _repo.clearAll();
                        _load();
                      }
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 14,
                        color: AppColors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: CupertinoActivityIndicator(color: Colors.white),
                ),
              )
            else if (_sessions.isEmpty)
              _EmptyHistory()
            else
              ..._sessions.map((s) => _SessionCard(
                    session: s,
                    onTap: () {
                      if (s.feedback != null) {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => FeedbackScreen(
                              session: s,
                              feedback: s.feedback!,
                              isFromHistory: true,
                            ),
                          ),
                        );
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmClear(BuildContext context) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¿Borrar todo?'),
        content: const Text('Se eliminarán todas las entrevistas guardadas.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Borrar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONTEXTO MX', style: AppText.eyebrow),
          const SizedBox(height: 12),
          const Text(
            'Buscar trabajo en México es trancazo.',
            style: AppText.title3,
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _StatCell(
                  number: '46%',
                  label: 'lo vive como difícil',
                  color: AppColors.indigo,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCell(
                  number: '21%',
                  label: 'tarda más de un año',
                  color: AppColors.pink,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatCell(
                  number: '38%',
                  label: 'falta experiencia',
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'ENE 2023 (UVM / Laureate México)',
            style: TextStyle(
              fontFamily: AppText.fontFamily,
              fontSize: 11,
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  const _StatCell({
    required this.number,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardElev,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: TextStyle(
              fontFamily: AppText.fontFamily,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppText.fontFamily,
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(CupertinoIcons.tray, color: AppColors.textTertiary, size: 36),
          SizedBox(height: 12),
          Text(
            'Aquí verás tus entrevistas pasadas',
            style: AppText.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final InterviewSession session;
  final VoidCallback onTap;
  const _SessionCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final score = session.feedback?.scoreOverall ?? 0;
    final scoreColor = _scoreColor(score);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scoreColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    score.toStringAsFixed(1),
                    style: TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session.roleTitle} · ${session.seniorityLabel}',
                      style: AppText.title3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.mode == "voz" ? "Modo voz" : "Modo chat"} · '
                      '${_formatDate(session.createdAt)}',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
              const Icon(CupertinoIcons.chevron_right,
                  color: AppColors.textTertiary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 8) return AppColors.green;
    if (s >= 6) return AppColors.yellow;
    if (s >= 4) return AppColors.orange;
    return AppColors.pink;
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Hace un momento';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// =============================================================================
// PANTALLA: SETUP
// =============================================================================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _roleId;
  String _seniorityId = 'junior';
  String? _mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar('Nueva entrevista',
          onLeading: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          const Text('1.  Puesto', style: AppText.eyebrow),
          const SizedBox(height: 12),
          ...kJobRoles.map((r) => _RoleCard(
                role: r,
                selected: _roleId == r.id,
                onTap: () => setState(() => _roleId = r.id),
              )),
          const SizedBox(height: 32),
          const Text('2.  Nivel', style: AppText.eyebrow),
          const SizedBox(height: 12),
          Row(
            children: kSeniority
                .map((s) => Expanded(
                      child: _SeniorityChip(
                        level: s,
                        selected: _seniorityId == s.id,
                        onTap: () => setState(() => _seniorityId = s.id),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 32),
          const Text('3.  Modo', style: AppText.eyebrow),
          const SizedBox(height: 12),
          _ModeCard(
            icon: CupertinoIcons.chat_bubble_fill,
            title: 'Chat por texto',
            subtitle: 'Escribe tus respuestas. Más fácil para empezar.',
            selected: _mode == 'chat',
            color: AppColors.blue,
            onTap: () => setState(() => _mode = 'chat'),
          ),
          const SizedBox(height: 12),
          _ModeCard(
            icon: CupertinoIcons.phone_fill,
            title: 'Llamada por voz',
            subtitle: 'Habla en voz alta. Simula la presión real.',
            selected: _mode == 'voz',
            color: AppColors.purple,
            badge: 'NUEVO',
            onTap: () => setState(() => _mode = 'voz'),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: _PrimaryButton(
            label: 'Empezar entrevista',
            icon: CupertinoIcons.play_fill,
            enabled: _roleId != null && _mode != null,
            onPressed: () {
              final role = kJobRoles.firstWhere((r) => r.id == _roleId);
              final sen = kSeniority.firstWhere((s) => s.id == _seniorityId);
              Navigator.of(context).pushReplacement(
                CupertinoPageRoute(
                  builder: (_) => InterviewScreen(
                    role: role,
                    seniority: sen,
                    mode: _mode!,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final JobRole role;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? role.accent : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: role.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(role.icon, color: role.accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(role.title, style: AppText.title3),
                    const SizedBox(height: 2),
                    Text(role.subtitle, style: AppText.caption),
                  ],
                ),
              ),
              Icon(
                selected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                color: selected ? role.accent : AppColors.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeniorityChip extends StatelessWidget {
  final SeniorityLevel level;
  final bool selected;
  final VoidCallback onTap;
  const _SeniorityChip({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Text(
                level.label,
                style: const TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                level.description,
                style: TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 11,
                  color: selected
                      ? Colors.white.withOpacity(0.8)
                      : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final String? badge;
  final VoidCallback onTap;
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppText.title3),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.pink.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontFamily: AppText.fontFamily,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.pink,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PANTALLA: ENTREVISTA
// =============================================================================
class InterviewScreen extends StatefulWidget {
  final JobRole role;
  final SeniorityLevel seniority;
  final String mode;
  const InterviewScreen({
    super.key,
    required this.role,
    required this.seniority,
    required this.mode,
  });

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  late final GeminiService _gemini;
  final HistoryRepo _repo = HistoryRepo();
  final List<ChatMessage> _messages = [];
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  stt.SpeechToText? _speech;
  FlutterTts? _tts;
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _partialTranscript = '';
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;

  bool _aiThinking = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _gemini = GeminiService();
    _gemini.startInterview(
      roleTitle: widget.role.title,
      seniority: widget.seniority.label,
      mode: widget.mode,
    );
    if (widget.mode == 'voz') {
      _initVoice();
    }
    _start();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    _speech?.stop();
    _tts?.stop();
    super.dispose();
  }

  Future<void> _initVoice() async {
    try {
      await Permission.microphone.request();

      _speech = stt.SpeechToText();
      _speechAvailable = await _speech!.initialize(
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
              if (_partialTranscript.trim().isNotEmpty) {
                _sendUserMessage(_partialTranscript.trim());
                _partialTranscript = '';
              }
            }
          }
        },
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
        },
      );

      _tts = FlutterTts();
      await _tts!.setLanguage('es-MX');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setPitch(1.0);
      _tts!.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });
      _tts!.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      _tts!.setCancelHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _started) {
          setState(() {
            _callDuration = _callDuration + const Duration(seconds: 1);
          });
        }
      });
    } catch (e) {
      // En web, voice puede fallar; lo dejamos pasar
      print('Error inicializando voz: $e');
    }
  }

  Future<void> _start() async {
    setState(() => _aiThinking = true);
    try {
      final greeting = await _gemini.openingMessage();
      _addAi(greeting);
      if (widget.mode == 'voz') await _speak(greeting);
    } catch (e) {
      _addAi('Error al conectar con Gemini.\n\nDetalle: ${e.toString().replaceAll("Exception: ", "")}\n\nRevisa que pegaste tu API key correctamente en main.dart.');
    } finally {
      if (mounted) {
        setState(() {
          _aiThinking = false;
          _started = true;
        });
      }
    }
  }

  void _addAi(String text) {
    setState(() {
      _messages.add(ChatMessage(
        role: ChatRole.ai,
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _addUser(String text) {
    setState(() {
      _messages.add(ChatMessage(
        role: ChatRole.user,
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendUserMessage(String text) async {
    if (text.trim().isEmpty || _aiThinking) return;
    _addUser(text.trim());
    _input.clear();
    setState(() => _aiThinking = true);
    try {
      final response = await _gemini.sendMessage(text.trim());
      _addAi(response);
      if (widget.mode == 'voz') await _speak(response);
    } catch (e) {
      _addAi('Tuve un problema técnico: ${e.toString().replaceAll("Exception: ", "")}\n\n¿Puedes repetirme tu última respuesta?');
    } finally {
      if (mounted) setState(() => _aiThinking = false);
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable || _speech == null) {
      _showError('Micrófono no disponible');
      return;
    }
    if (_isSpeaking && _tts != null) {
      await _tts!.stop();
    }
    if (_isListening) {
      await _speech!.stop();
      setState(() => _isListening = false);
      if (_partialTranscript.trim().isNotEmpty) {
        _sendUserMessage(_partialTranscript.trim());
        _partialTranscript = '';
      }
    } else {
      _partialTranscript = '';
      await _speech!.listen(
        localeId: 'es_MX',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 3),
        onResult: (r) {
          setState(() => _partialTranscript = r.recognizedWords);
        },
      );
      setState(() => _isListening = true);
    }
  }

  Future<void> _speak(String text) async {
    if (_tts == null) return;
    await _tts!.stop();
    await _tts!.speak(text);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.cardElev,
      ),
    );
  }

  Future<void> _finishInterview() async {
    if (_messages.where((m) => m.role == ChatRole.user).length < 2) {
      final ok = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('¿Salir?'),
          content: const Text(
              'Necesitas responder al menos 2 preguntas para generar feedback.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Seguir'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Salir igual'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );
      if (ok == true && mounted) Navigator.of(context).pop();
      return;
    }

    if (widget.mode == 'voz') {
      await _speech?.stop();
      await _tts?.stop();
      _callTimer?.cancel();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingFeedback(),
    );

    try {
      final feedback = await _gemini.evaluate(
        roleTitle: widget.role.title,
        seniority: widget.seniority.label,
        messages: _messages,
      );
      final session = InterviewSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roleId: widget.role.id,
        roleTitle: widget.role.title,
        seniorityLabel: widget.seniority.label,
        mode: widget.mode,
        messages: _messages,
        createdAt: DateTime.now(),
        feedback: feedback,
      );
      await _repo.save(session);

      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(
          builder: (_) => FeedbackScreen(session: session, feedback: feedback),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('Error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.mode == 'voz' ? _buildVoiceCallUI() : _buildChatUI();
  }

  Widget _buildChatUI() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(
        '${widget.role.title} · ${widget.seniority.label}',
        onLeading: () => _confirmExit(),
        trailing: GestureDetector(
          onTap: _finishInterview,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardElev,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Terminar',
              style: TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.blue,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              itemCount: _messages.length + (_aiThinking ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length && _aiThinking) {
                  return const _TypingBubble();
                }
                final m = _messages[i];
                return _ChatBubble(message: m);
              },
            ),
          ),
          _ChatInputBar(
            controller: _input,
            enabled: !_aiThinking,
            onSend: () => _sendUserMessage(_input.text),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceCallUI() {
    final mins = _callDuration.inMinutes.toString().padLeft(2, '0');
    final secs = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');

    String statusLabel;
    if (_aiThinking) {
      statusLabel = 'Pensando...';
    } else if (_isSpeaking) {
      statusLabel = 'Hablando...';
    } else if (_isListening) {
      statusLabel = 'Escuchándote...';
    } else {
      statusLabel = 'En llamada';
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _confirmExit,
                    child: const Icon(CupertinoIcons.chevron_down,
                        color: AppColors.textSecondary, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    statusLabel,
                    style: const TextStyle(
                      fontFamily: AppText.fontFamily,
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _finishInterview,
                    child: const Text(
                      'Terminar',
                      style: TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.indigo, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: const Icon(CupertinoIcons.sparkles,
                  color: Colors.white, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('ReclutA', style: AppText.title1),
            const SizedBox(height: 6),
            Text(
              '${widget.role.title} · ${widget.seniority.label}',
              style: AppText.bodySecondary,
            ),
            const SizedBox(height: 16),
            Text(
              '$mins:$secs',
              style: const TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 32),
            _VoiceWave(
              active: _isSpeaking || _isListening,
              listening: _isListening,
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(minHeight: 80, maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SingleChildScrollView(
                reverse: true,
                child: _buildLiveTranscript(),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 16, 40, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallButton(
                    icon: _isListening
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.mic_fill,
                    color: _isListening ? AppColors.pink : AppColors.cardElev,
                    iconColor:
                        _isListening ? Colors.white : AppColors.textPrimary,
                    onPressed: _aiThinking ? null : _toggleListening,
                    size: 64,
                    label: _isListening ? 'Para de hablar' : 'Habla',
                  ),
                  _CallButton(
                    icon: CupertinoIcons.phone_down_fill,
                    color: AppColors.pink,
                    iconColor: Colors.white,
                    onPressed: _finishInterview,
                    size: 64,
                    label: 'Colgar',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveTranscript() {
    if (_partialTranscript.isNotEmpty) {
      return Text(
        '"$_partialTranscript"',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppText.fontFamily,
          fontSize: 16,
          color: AppColors.textPrimary,
          fontStyle: FontStyle.italic,
          height: 1.4,
        ),
      );
    }
    if (_messages.isNotEmpty && _messages.last.role == ChatRole.ai) {
      return Text(
        _messages.last.text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppText.fontFamily,
          fontSize: 15,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _confirmExit() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¿Salir de la entrevista?'),
        content:
            const Text('Se perderá la conversación y no se generará feedback.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Seguir'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Salir'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }
}

// =============================================================================
// PANTALLA: FEEDBACK
// =============================================================================
class FeedbackScreen extends StatelessWidget {
  final InterviewSession session;
  final FeedbackResult feedback;
  final bool isFromHistory;
  const FeedbackScreen({
    super.key,
    required this.session,
    required this.feedback,
    this.isFromHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(
        'Feedback',
        onLeading: () {
          if (isFromHistory) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              CupertinoPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
          }
        },
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          _ScoreHero(score: feedback.scoreOverall),
          const SizedBox(height: 8),
          Center(
            child: Text(
              '${session.roleTitle} · ${session.seniorityLabel}',
              style: AppText.bodySecondary,
            ),
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Resumen',
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(feedback.summary, style: AppText.body),
            ),
          ),
          _Section(
            title: 'Dimensiones evaluadas',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: feedback.dimensions.entries
                    .map((e) => _DimensionBar(label: e.key, value: e.value))
                    .toList(),
              ),
            ),
          ),
          _Section(
            title: 'Lo hiciste bien',
            icon: CupertinoIcons.checkmark_seal_fill,
            iconColor: AppColors.green,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: feedback.strengths
                    .map((s) => _BulletItem(text: s, color: AppColors.green))
                    .toList(),
              ),
            ),
          ),
          _Section(
            title: 'Para mejorar',
            icon: CupertinoIcons.arrow_up_circle_fill,
            iconColor: AppColors.orange,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: feedback.improvements
                    .map((s) => _BulletItem(text: s, color: AppColors.orange))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardElev,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CRITERIOS BASADOS EN', style: AppText.eyebrow),
                SizedBox(height: 8),
                Text(
                  '· Método STAR (Amazon, Google, Microsoft)\n'
                  '· SHRM — Society for Human Resource Management\n'
                  '· WEF Future of Jobs Report 2023\n'
                  '· LinkedIn Talent Solutions México',
                  style: TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          if (!isFromHistory) ...[
            const SizedBox(height: 24),
            _PrimaryButton(
              label: 'Volver al inicio',
              icon: CupertinoIcons.house_fill,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                CupertinoPageRoute(builder: (_) => const HomeScreen()),
                (_) => false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreHero extends StatelessWidget {
  final double score;
  const _ScoreHero({required this.score});

  Color get _color {
    if (score >= 8) return AppColors.green;
    if (score >= 6) return AppColors.yellow;
    if (score >= 4) return AppColors.orange;
    return AppColors.pink;
  }

  String get _label {
    if (score >= 8) return 'Muy bien';
    if (score >= 6) return 'Bien';
    if (score >= 4) return 'Aceptable';
    return 'A practicar';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (score / 10).clamp(0.0, 1.0);
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _CircularProgress(
                    value: pct,
                    color: _color,
                    bg: AppColors.cardElev,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontFamily: AppText.fontFamily,
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: _color,
                        letterSpacing: -2,
                      ),
                    ),
                    const Text('de 10', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _color.withOpacity(0.4)),
            ),
            child: Text(
              _label,
              style: TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _color,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularProgress extends CustomPainter {
  final double value;
  final Color color;
  final Color bg;
  _CircularProgress(
      {required this.value, required this.color, required this.bg});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;

    final bgPaint = Paint()
      ..color = bg
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularProgress old) =>
      old.value != value || old.color != color;
}

class _DimensionBar extends StatelessWidget {
  final String label;
  final double value;
  const _DimensionBar({required this.label, required this.value});

  Color get _color {
    if (value >= 8) return AppColors.green;
    if (value >= 6) return AppColors.yellow;
    if (value >= 4) return AppColors.orange;
    return AppColors.pink;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (value / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppText.fontFamily,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(1),
                style: TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AppColors.bgElev,
              valueColor: AlwaysStoppedAnimation(_color),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final Color? iconColor;
  const _Section({
    required this.title,
    required this.child,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(title, style: AppText.title3),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppText.body)),
        ],
      ),
    );
  }
}

// =============================================================================
// WIDGETS COMPARTIDOS
// =============================================================================
PreferredSizeWidget _buildAppBar(
  String title, {
  VoidCallback? onLeading,
  Widget? trailing,
}) {
  return AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: onLeading != null
        ? IconButton(
            icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
            onPressed: onLeading,
          )
        : null,
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: AppText.fontFamily,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    centerTitle: true,
    actions: trailing != null ? [trailing] : null,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool enabled;
  const _PrimaryButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [AppColors.indigo, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : AppColors.cardElev,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 20,
                color: isEnabled ? Colors.white : AppColors.textTertiary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppText.fontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : AppColors.textTertiary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;
  const _GradientText(this.text,
      {required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(
                        colors: [AppColors.indigo, AppColors.purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isUser ? null : AppColors.card,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: AppText.fontFamily,
                  fontSize: 15,
                  color: isUser ? Colors.white : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
                    final opacity = (math.sin(phase * math.pi) * 0.7) + 0.3;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary
                              .withOpacity(opacity.clamp(0.3, 1.0)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: AppColors.bg,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: AppText.body,
                  cursorColor: AppColors.blue,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu respuesta...',
                    hintStyle: TextStyle(color: AppColors.textTertiary),
                    border: InputBorder.none,
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: (_) => enabled ? onSend() : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: enabled
                      ? const LinearGradient(
                          colors: [AppColors.indigo, AppColors.purple],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: enabled ? null : AppColors.cardElev,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  CupertinoIcons.arrow_up,
                  color: enabled ? Colors.white : AppColors.textTertiary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback? onPressed;
  final double size;
  final String? label;
  const _CallButton({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onPressed,
    required this.size,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: onPressed == null ? AppColors.cardElev : color,
              borderRadius: BorderRadius.circular(size / 3),
            ),
            child: Icon(
              icon,
              color: onPressed == null ? AppColors.textTertiary : iconColor,
              size: size * 0.4,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: const TextStyle(
              fontFamily: AppText.fontFamily,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _VoiceWave extends StatefulWidget {
  final bool active;
  final bool listening;
  const _VoiceWave({required this.active, required this.listening});

  @override
  State<_VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<_VoiceWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 60,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (i) {
              double h;
              if (widget.active) {
                final phase = (_ctrl.value * 2 * math.pi) + i * 0.4;
                h = 8 + (math.sin(phase).abs() * 38);
              } else {
                h = 6;
              }
              final color = widget.listening
                  ? AppColors.green
                  : (widget.active ? AppColors.purple : AppColors.textTertiary);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Container(
                  width: 4,
                  height: h,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _LoadingFeedback extends StatelessWidget {
  const _LoadingFeedback();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.indigo, AppColors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(CupertinoIcons.sparkles,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 20),
            const Text('Analizando tu entrevista', style: AppText.title3),
            const SizedBox(height: 6),
            const Text(
              'La IA está leyendo tus respuestas y calificándote.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
            const SizedBox(height: 20),
            const CupertinoActivityIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}