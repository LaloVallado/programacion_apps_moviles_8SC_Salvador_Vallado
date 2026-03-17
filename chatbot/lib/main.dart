// ╔══════════════════════════════════════════════════════════════════════╗
// ║  ITBOT · TecNM Mérida · Salvador Eduardo Vallado Villamonte · 2026  ║
// ╚══════════════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════
// PALETTE — Neumorphism + Glass, Azul Rey, Blanco Cálido
// ═══════════════════════════════════════════════════════════════════════
class C {
  // Base
  static const bg         = Color(0xFFECEFF4);
  static const bgWarm     = Color(0xFFF0F2F8);
  static const white      = Color(0xFFFFFFFF);

  // Neomorphism shadows
  static const shadowDark  = Color(0xFFD1D5E0);
  static const shadowLight = Color(0xFFFFFFFF);

  // Glass
  static const glass      = Color(0xCCFFFFFF);
  static const glassBorder = Color(0x40FFFFFF);

  // Blue system
  static const blue       = Color(0xFF1A56DB);
  static const blueDark   = Color(0xFF1043B8);
  static const blueLight  = Color(0xFF4B7BEC);
  static const bluePale   = Color(0xFFDEE9FF);
  static const blueGhost  = Color(0xFFF0F4FF);
  static const blueMint   = Color(0xFF00C6FF);

  // Gradient blues
  static const grad1      = Color(0xFF1A56DB);
  static const grad2      = Color(0xFF00C6FF);

  // Text
  static const textP      = Color(0xFF1A1D2E);
  static const textS      = Color(0xFF6B7A99);
  static const textM      = Color(0xFFADB8CC);
  static const textInv    = Color(0xFFFFFFFF);

  // Bubbles
  static const userBub    = Color(0xFF1A56DB);
  static const aiBub      = Color(0xFFFFFFFF);

  // Status
  static const err        = Color(0xFFFF4757);
  static const ok         = Color(0xFF2ED573);
  static const warn       = Color(0xFFFFB142);
}

// ═══════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════
ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: C.bg,
  colorScheme: const ColorScheme.light(
    primary: C.blue, secondary: C.blueLight,
    surface: C.white, onSurface: C.textP),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0, scrolledUnderElevation: 0),
);

// ═══════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════
enum MsgRole   { user, assistant }
enum MsgStatus { streaming, done, error }

class ChatMsg {
  final String id, content;
  final MsgRole role;
  final MsgStatus status;
  final DateTime ts;

  const ChatMsg({required this.id, required this.content,
      required this.role, required this.ts,
      this.status = MsgStatus.done});

  factory ChatMsg.user(String c) => ChatMsg(
      id: const Uuid().v4(), content: c,
      role: MsgRole.user, ts: DateTime.now());

  factory ChatMsg.assistant({required String content,
      MsgStatus status = MsgStatus.done}) =>
      ChatMsg(id: const Uuid().v4(), content: content,
          role: MsgRole.assistant, ts: DateTime.now(), status: status);

  ChatMsg copyWith({String? content, MsgStatus? status}) => ChatMsg(
      id: id, content: content ?? this.content, role: role, ts: ts,
      status: status ?? this.status);

  bool get isUser      => role == MsgRole.user;
  bool get isStreaming => status == MsgStatus.streaming;
  bool get isError     => status == MsgStatus.error;
  bool get isDone      => status == MsgStatus.done;

  Map<String, dynamic> toJson() =>
      {'id': id, 'content': content, 'role': role.name,
       'ts': ts.toIso8601String()};

  factory ChatMsg.fromJson(Map<String, dynamic> j) => ChatMsg(
      id: j['id'] as String, content: j['content'] as String,
      role: MsgRole.values.firstWhere((r) => r.name == j['role'],
          orElse: () => MsgRole.user),
      ts: DateTime.parse(j['ts'] as String));
}

class Conv {
  final String id, title;
  final List<ChatMsg> messages;
  final DateTime updatedAt;

  const Conv({required this.id, required this.title,
      required this.messages, required this.updatedAt});

  factory Conv.create() => Conv(id: const Uuid().v4(),
      title: 'Nueva consulta', messages: [], updatedAt: DateTime.now());

  Conv copyWith({String? title, List<ChatMsg>? messages,
      DateTime? updatedAt}) =>
      Conv(id: id, title: title ?? this.title,
          messages: messages ?? this.messages,
          updatedAt: updatedAt ?? this.updatedAt);

  String get autoTitle {
    if (messages.isEmpty) return 'Nueva consulta';
    final f = messages.firstWhere((m) => m.isUser,
        orElse: () => messages.first);
    return f.content.length > 38 ? '${f.content.substring(0, 38)}…' : f.content;
  }

  Map<String, dynamic> toJson() => {'id': id, 'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'updatedAt': updatedAt.toIso8601String()};

  factory Conv.fromJson(Map<String, dynamic> j) => Conv(
      id: j['id'] as String, title: j['title'] as String,
      messages: (j['messages'] as List)
          .map((m) => ChatMsg.fromJson(m as Map<String, dynamic>)).toList(),
      updatedAt: DateTime.parse(j['updatedAt'] as String));
}

// ═══════════════════════════════════════════════════════════════════════
// STORAGE
// ═══════════════════════════════════════════════════════════════════════
class Store {
  static const _kKey = 'gemini_api_key';
  static const _kConvs = 'conversations';
  static const _kAct = 'active_conv_id';
  static Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  static Future<void>    saveKey(String k)   async => (await _p()).setString(_kKey, k);
  static Future<String?> getKey()            async => (await _p()).getString(_kKey);
  static Future<void>    clearAll()          async => (await _p()).clear();
  static Future<void>    saveActiveId(String id) async => (await _p()).setString(_kAct, id);
  static Future<String?> getActiveId()       async => (await _p()).getString(_kAct);

  static Future<List<Conv>> loadConvs() async {
    final raw = (await _p()).getString(_kConvs);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Conv.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  static Future<void> saveConvs(List<Conv> cs) async =>
      (await _p()).setString(_kConvs,
          jsonEncode(cs.map((c) => c.toJson()).toList()));
}

// ═══════════════════════════════════════════════════════════════════════
// GEMINI SERVICE
// ═══════════════════════════════════════════════════════════════════════
class GeminiSvc {
  String? _apiKey, _workingModel;
  bool get ready => _apiKey != null;

  static const _sys =
      'Eres ITBOT, un asistente de inteligencia artificial sofisticado, amable y preciso. '
      'Puedes responder cualquier pregunta general: código, matemáticas, ciencia, escritura, análisis, creatividad y más. '
      'Responde siempre en el mismo idioma que el usuario. '
      'Usa Markdown cuando sea útil: **negrita**, listas, bloques de código, tablas. '
      'Sé conciso pero completo. Si no sabes algo, dilo honestamente.\n\n'
      'ADEMÁS tienes conocimiento especializado sobre admisiones del TecNM Campus Mérida 2026. '
      'Cuando el usuario pregunte sobre inscripción, examen, carreras o el Tec de Mérida, usa esta información:\n\n'
      'INFORMACIÓN TecNM MÉRIDA — CONVOCATORIA 2026:\n'
      '## REQUISITOS DE INGRESO\n'
      '- Haber concluido bachillerato o estar en el último curso\n'
      '- Haber aplicado y aprobado el examen de admisión\n'
      '- Clases inician en agosto de 2026\n\n'
      '## INFORMACIÓN IMPORTANTE\n'
      '- Personas con licenciatura ya concluida: dep_merida@tecnm.mx\n'
      '- Si ya fuiste estudiante y NO concluiste: dep_merida@tecnm.mx\n'
      '- Exámenes de otras instituciones NO tienen validez en el ITM\n'
      '- Dudas: admision.itmerida@merida.tecnm.mx\n\n'
      '## CARRERAS OFERTADAS\n'
      '1. Ingeniería Ambiental  2. Ingeniería Biomédica  3. Ingeniería Bioquímica\n'
      '4. Ingeniería Civil  5. Ingeniería Eléctrica  6. Ingeniería Electrónica\n'
      '7. Ing. en Ciberseguridad  8. Ing. en Gestión Empresarial  9. Ing. en Semiconductores\n'
      '10. Ing. en Sistemas Computacionales  11. Ing. Industrial  12. Ing. Mecánica\n'
      '13. Ingeniería Química  14. Lic. en Administración  15. Lic. en Administración (No escolarizada)\n\n'
      '## FECHAS IMPORTANTES 2026\n'
      '- Paso 1 Registro SIE: del 5 feb al 21 may 2026\n'
      '- Paso 2 Preficha: 5-19 feb / 2-19 mar / 13-23 abr / 4-21 may\n'
      '- Paso 3 Pago examen (850 pesos MXN): 5-20 feb / 2-20 mar / 13-24 abr / 4-22 may\n'
      '- Paso 4 Ficha aspirante: límite 29 may 2026\n'
      '- Paso 5 Publicación horarios: 8 jun 2026\n'
      '- Paso 6 Examen en línea: 13 y 14 jun 2026\n'
      '- Paso 7 Resultados: 19 jun 2026\n\n'
      '## PROCESO DETALLADO\n'
      'Paso 1: Ingresa a sie.tecnm.mx, registra tu CURP, llena Datos Generales\n'
      'Paso 2: Selecciona "Solicitar preficha", elige tu carrera\n'
      'Paso 3: Paga 850 pesos en banco. Los pagos NO son reembolsables. No hay cambios de carrera.\n'
      'Paso 4: Sube foto JPG/PNG con rostro visible\n'
      'Paso 5: Consulta horario en merida.tecnm.mx el 8 de junio\n'
      'Paso 6: Examen en plataforma EVALUATEC, en línea desde casa.\n'
      '  - Requisitos: cámara web obligatoria, mínimo 15 Mbps subida\n'
      '  - Usar Chrome o Edge\n'
      '  - Duración: 2h 30min\n'
      '  - Prohibido: celular, audífonos, libros, apuntes\n'
      '  - Permitido: hojas, lápiz, calculadora básica\n'
      '  - Enlace llega al correo registrado en SIE un día antes\n'
      'Paso 7: Resultados en merida.tecnm.mx el 19 de junio\n\n'
      '## PREGUNTAS FRECUENTES\n'
      '- Costo: 850 pesos, no reembolsables\n'
      '- Cambio de carrera: No es posible una vez pagado\n'
      '- Examen presencial: No, es en línea vía EVALUATEC\n'
      '- ¿Necesito cámara? Sí, obligatorio\n'
      '- Internet mínimo: 15 Mbps de subida\n'
      '- Inicio de clases: agosto 2026\n'
      '- CENEVAL/COMIPEMS: No tienen validez en el ITM\n'
      '- Resultados: merida.tecnm.mx el 19 jun 2026\n'
      '- Escuela no aparece: admision.itmerida@merida.tecnm.mx\n'
      '- Facebook oficial: facebook.com/TecNMCampusMerida\n'
      '- Web oficial: merida.tecnm.mx';

  static const _models = [
    'gemini-2.0-flash-lite', 'gemini-2.0-flash',
    'gemini-2.5-flash-lite', 'gemini-2.5-flash',
  ];

  void init(String apiKey) { _apiKey = apiKey; }

  Stream<String> stream(String msg, List<ChatMsg> history) async* {
    if (_apiKey == null) throw Exception('No inicializado');
    final recent = history.length > 20
        ? history.sublist(history.length - 20) : history;
    final contents = <Map<String, dynamic>>[];
    for (final m in recent) {
      contents.add({'role': m.isUser ? 'user' : 'model',
          'parts': [{'text': m.content}]});
    }
    contents.add({'role': 'user', 'parts': [{'text': msg}]});
    final body = jsonEncode({
      'system_instruction': {'parts': [{'text': _sys}]},
      'contents': contents,
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 2048},
    });
    final modelsToTry = _workingModel != null
        ? [_workingModel!, ..._models.where((m) => m != _workingModel)]
        : _models;
    List<String> fromApi = [];
    if (_workingModel == null) fromApi = await listAvailableModels(_apiKey!);
    final finalList =
        fromApi.isNotEmpty ? [...fromApi, ...modelsToTry] : modelsToTry;
    String? lastError;
    for (final model in finalList.toSet().toList()) {
      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');
        final res = await http
            .post(url, headers: {'Content-Type': 'application/json'}, body: body)
            .timeout(const Duration(seconds: 30));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final text =
              data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null && text.isNotEmpty) {
            _workingModel = model;
            yield text;
            return;
          }
        } else {
          final errData = jsonDecode(res.body);
          lastError = errData['error']?['message'] ?? 'Error ${res.statusCode}';
          if (res.statusCode == 429 || res.statusCode == 404) continue;
          throw Exception(lastError);
        }
      } catch (e) {
        lastError = e.toString().replaceAll('Exception: ', '');
        continue;
      }
    }
    throw Exception(lastError ?? 'Sin modelos disponibles');
  }

  Future<bool> validate(String k) async => true;

  Future<List<String>> listAvailableModels(String apiKey) async {
    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ((data['models'] as List?) ?? [])
            .where((m) =>
                (m['supportedGenerationMethods'] as List?)
                    ?.contains('generateContent') == true)
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════
enum ChatState { idle, streaming, error }

class ChatProv extends ChangeNotifier {
  final _gemini = GeminiSvc();
  List<Conv> _convs = [];
  Conv? _active;
  ChatState _state = ChatState.idle;
  bool _ready = false;

  List<Conv>    get convs  => _convs;
  Conv?         get active => _active;
  ChatState     get state  => _state;
  bool          get ready  => _ready;
  bool          get busy   => _state == ChatState.streaming;
  List<ChatMsg> get msgs   => _active?.messages ?? [];

  Future<void> init() async {
    final key = await Store.getKey();
    if (key == null || key.isEmpty) return;
    _gemini.init(key);
    _convs = await Store.loadConvs();
    if (_convs.isEmpty) {
      final c = Conv.create(); _convs.add(c); _active = c;
    } else {
      final id = await Store.getActiveId();
      _active = id != null
          ? _convs.firstWhere((c) => c.id == id, orElse: () => _convs.first)
          : _convs.first;
    }
    _ready = true; notifyListeners();
  }

  Future<void> newConv() async {
    final c = Conv.create(); _convs.insert(0, c); _active = c;
    await _save(); notifyListeners();
  }

  Future<void> selectConv(String id) async {
    _active = _convs.firstWhere((c) => c.id == id);
    await Store.saveActiveId(id); notifyListeners();
  }

  Future<void> deleteConv(String id) async {
    _convs.removeWhere((c) => c.id == id);
    if (_active?.id == id) {
      if (_convs.isEmpty) {
        final c = Conv.create(); _convs.add(c); _active = c;
      } else { _active = _convs.first; }
    }
    await _save(); notifyListeners();
  }

  Future<void> rename(String id, String title) async {
    final i = _convs.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _convs[i] = _convs[i].copyWith(title: title);
    if (_active?.id == id) _active = _convs[i];
    await _save(); notifyListeners();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || _active == null || busy) return;
    _addMsg(ChatMsg.user(text.trim()));
    _state = ChatState.streaming; notifyListeners();
    final pid = DateTime.now().microsecondsSinceEpoch.toString();
    _addMsg(ChatMsg(id: pid, content: '', role: MsgRole.assistant,
        ts: DateTime.now(), status: MsgStatus.streaming));
    notifyListeners();
    try {
      final hist = msgs.where((m) => m.id != pid).toList();
      final buf = StringBuffer();
      await for (final chunk in _gemini.stream(text.trim(), hist)) {
        buf.write(chunk);
        _updateMsg(pid, buf.toString(), MsgStatus.streaming);
        notifyListeners();
      }
      _updateMsg(pid, buf.toString(), MsgStatus.done);
      if (msgs.where((m) => m.isUser).length == 1) _autoRename();
      _state = ChatState.idle;
    } catch (e) {
      _updateMsg(pid, 'Error: ${e.toString().replaceAll('Exception: ', '')}',
          MsgStatus.error);
      _state = ChatState.error;
    }
    await _save(); notifyListeners();
  }

  Future<void> retry() async {
    if (_active == null || msgs.length < 2) return;
    String? lu;
    for (int i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].isUser) { lu = msgs[i].content; break; }
    }
    if (lu == null) return;
    _updateActive(_active!.copyWith(messages: msgs.sublist(0, msgs.length - 2)));
    _state = ChatState.idle; notifyListeners();
    await send(lu);
  }

  void _autoRename() {
    if (_active == null) return;
    final i = _convs.indexWhere((c) => c.id == _active!.id);
    if (i == -1) return;
    _convs[i] = _convs[i].copyWith(title: _active!.autoTitle);
    _active = _convs[i];
  }

  void _addMsg(ChatMsg m) {
    if (_active == null) return;
    _updateActive(_active!.copyWith(
        messages: [..._active!.messages, m], updatedAt: DateTime.now()));
  }

  void _updateMsg(String id, String content, MsgStatus status) {
    if (_active == null) return;
    _updateActive(_active!.copyWith(
        messages: _active!.messages
            .map((m) => m.id == id ? m.copyWith(content: content, status: status) : m)
            .toList(),
        updatedAt: DateTime.now()));
  }

  void _updateActive(Conv c) {
    final i = _convs.indexWhere((x) => x.id == c.id);
    if (i != -1) _convs[i] = c;
    if (_active?.id == c.id) _active = c;
  }

  Future<void> _save() async {
    await Store.saveConvs(_convs);
    if (_active != null) await Store.saveActiveId(_active!.id);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: C.bg,
  ));
  runApp(const ITBotApp());
}

class ITBotApp extends StatefulWidget {
  const ITBotApp({super.key});
  @override State<ITBotApp> createState() => _ITBotAppState();
}

class _ITBotAppState extends State<ITBotApp> {
  bool _init = false, _hasKey = false;
  @override
  void initState() {
    super.initState();
    Store.getKey().then((k) => setState(() {
      _hasKey = k != null && k.isNotEmpty; _init = true;
    }));
  }
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ITBOT · TecNM Mérida',
    debugShowCheckedModeBanner: false,
    theme: appTheme,
    home: _init
        ? (_hasKey ? const HomePage() : const ApiKeyPage())
        : const Scaffold(backgroundColor: C.bg,
            body: Center(child: _NeoLogo(size: 72))),
    routes: {'/home': (_) => const HomePage(), '/apikey': (_) => const ApiKeyPage()},
  );
}

// ═══════════════════════════════════════════════════════════════════════
// DESIGN SYSTEM — Neumorphism + Glass Components
// ═══════════════════════════════════════════════════════════════════════

// Neumorphic container — pressed or raised
class NeoBox extends StatelessWidget {
  final Widget child;
  final double radius;
  final bool pressed;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const NeoBox({
    super.key,
    required this.child,
    this.radius = 20,
    this.pressed = false,
    this.color,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? C.bg;
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: pressed
            ? [
                BoxShadow(color: C.shadowDark.withOpacity(0.5),
                    blurRadius: 3, offset: const Offset(2, 2)),
                BoxShadow(color: C.shadowLight.withOpacity(0.9),
                    blurRadius: 3, offset: const Offset(-1, -1)),
              ]
            : [
                BoxShadow(color: C.shadowDark.withOpacity(0.55),
                    blurRadius: 12, offset: const Offset(6, 6)),
                BoxShadow(color: C.shadowLight.withOpacity(0.95),
                    blurRadius: 12, offset: const Offset(-6, -6)),
              ],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

// Glass card
class GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets? padding;
  final Color? color;

  const GlassCard({super.key, required this.child, this.radius = 24,
      this.padding, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (color ?? C.glass),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: C.glassBorder, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Logo with neo effect
class _NeoLogo extends StatefulWidget {
  final double size;
  const _NeoLogo({this.size = 52});
  @override State<_NeoLogo> createState() => _NeoLogoState();
}

class _NeoLogoState extends State<_NeoLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Transform.scale(
        scale: _pulse.value,
        child: Container(
          width: widget.size, height: widget.size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [C.grad1, C.grad2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(widget.size * 0.3),
            boxShadow: [
              BoxShadow(color: C.blue.withOpacity(0.4 * _pulse.value),
                  blurRadius: widget.size * 0.5, spreadRadius: 0),
              BoxShadow(color: C.blueMint.withOpacity(0.2 * _pulse.value),
                  blurRadius: widget.size * 0.3, spreadRadius: 0),
            ],
          ),
          child: Center(
            child: Text('IT', style: TextStyle(
              color: Colors.white, fontSize: widget.size * 0.3,
              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          ),
        ),
      ),
    );
  }
}

// Gradient button (liquid feel)
class _GradBtn extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final double height;

  const _GradBtn({required this.label, this.icon, this.onTap,
      this.loading = false, this.height = 54});

  @override State<_GradBtn> createState() => _GradBtnState();
}

class _GradBtnState extends State<_GradBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _sc;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _sc = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null && !widget.loading;
    return GestureDetector(
      onTapDown: active ? (_) => _ac.forward() : null,
      onTapUp: active ? (_) { _ac.reverse(); widget.onTap!(); } : null,
      onTapCancel: () => _ac.reverse(),
      child: AnimatedBuilder(
        animation: _sc,
        builder: (_, child) => Transform.scale(scale: _sc.value, child: child),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [C.grad1, C.grad2],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight)
                : LinearGradient(colors: [
                    C.shadowDark.withOpacity(0.3),
                    C.shadowDark.withOpacity(0.3)
                  ]),
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: active
                ? [BoxShadow(color: C.blue.withOpacity(0.4),
                    blurRadius: 20, offset: const Offset(0, 6))]
                : null,
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, size: 18,
                          color: active ? Colors.white : C.textM),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.label, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: active ? Colors.white : C.textM,
                      letterSpacing: 0.3)),
                  ]),
          ),
        ),
      ),
    );
  }
}

// ITM quick question pill button
class _IQBtn extends StatefulWidget {
  final String label;
  final String query;
  final IconData icon;
  final void Function(String) onTap;

  const _IQBtn({required this.label, required this.query,
      required this.icon, required this.onTap});
  @override State<_IQBtn> createState() => _IQBtnState();
}

class _IQBtnState extends State<_IQBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _sc;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _sc = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { _ac.forward(); setState(() => _pressed = true); },
      onTapUp: (_) {
        _ac.reverse(); setState(() => _pressed = false);
        widget.onTap(widget.query);
      },
      onTapCancel: () { _ac.reverse(); setState(() => _pressed = false); },
      child: AnimatedBuilder(
        animation: _sc,
        builder: (_, child) => Transform.scale(scale: _sc.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: _pressed
                ? const LinearGradient(
                    colors: [C.grad1, C.grad2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: _pressed ? null : C.bg,
            borderRadius: BorderRadius.circular(50),
            boxShadow: _pressed
                ? [BoxShadow(color: C.blue.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 4))]
                : [
                    BoxShadow(color: C.shadowDark.withOpacity(0.45),
                        blurRadius: 8, offset: const Offset(4, 4)),
                    BoxShadow(color: C.shadowLight.withOpacity(0.9),
                        blurRadius: 8, offset: const Offset(-4, -4)),
                  ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 14,
                color: _pressed ? Colors.white : C.blue),
            const SizedBox(width: 6),
            Text(widget.label, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600,
              color: _pressed ? Colors.white : C.textP)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// API KEY PAGE
// ═══════════════════════════════════════════════════════════════════════
class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key});
  @override State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage>
    with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _fadeAc, _floatAc;
  late final Animation<double> _fade, _float;
  bool _obscure = true, _loading = false, _showInfo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fadeAc = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 700));
    _floatAc = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _fadeAc, curve: Curves.easeOut);
    _float = Tween<double>(begin: -8.0, end: 8.0)
        .animate(CurvedAnimation(parent: _floatAc, curve: Curves.easeInOut));
    _fadeAc.forward();
    _ctrl.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose(); _focus.dispose();
    _fadeAc.dispose(); _floatAc.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final k = _ctrl.text.trim();
    if (k.isEmpty) { setState(() => _error = 'Ingresa tu API Key'); return; }
    if (!k.startsWith('AIza')) {
      setState(() => _error = 'Debe iniciar con AIza…'); return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await Store.saveKey(k);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (_) {
      setState(() { _error = 'Error al guardar'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: sw > 500 ? 0 : 28, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Floating logo
                      AnimatedBuilder(
                        animation: _float,
                        builder: (_, child) => Transform.translate(
                          offset: Offset(0, _float.value), child: child),
                        child: const _NeoLogo(size: 80),
                      ),
                      const SizedBox(height: 28),

                      // Title
                      const Text('ITBOT', textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 36,
                            fontWeight: FontWeight.w900, color: C.textP,
                            letterSpacing: -1.5)),
                      const SizedBox(height: 8),
                      const Text('Asistente de Admisiones\nTecNM Campus Mérida 2026',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: C.textS,
                            height: 1.5)),
                      const SizedBox(height: 6),
                      const Text('Desarrollado por Salvador Eduardo Vallado Villamonte',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: C.textM)),
                      const SizedBox(height: 28),

                      // Info tags row
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8, runSpacing: 8,
                        children: [
                          _infoTag(Icons.school_rounded, 'TecNM Mérida'),
                          _infoTag(Icons.auto_awesome_rounded, 'Gemini AI'),
                          _infoTag(Icons.lock_rounded, 'Local & Seguro'),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // API Key field
                      NeoBox(
                        radius: 20,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 4),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [C.grad1, C.grad2],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.key_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _ctrl, focusNode: _focus,
                              obscureText: _obscure, enabled: !_loading,
                              style: const TextStyle(
                                  fontFamily: 'monospace', fontSize: 14,
                                  color: C.textP, letterSpacing: 0.5),
                              decoration: InputDecoration(
                                hintText: 'AIzaSy··············',
                                hintStyle: const TextStyle(
                                    color: C.textM, fontFamily: 'monospace'),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 14)),
                              onSubmitted: (_) => _go(),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18, color: C.textM)),
                        ]),
                      ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        GlassCard(
                          radius: 14, padding: const EdgeInsets.all(12),
                          color: C.err.withOpacity(0.08),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                                size: 16, color: C.err),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(
                                    fontSize: 12, color: C.err))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Gradient button
                      SizedBox(
                        width: double.infinity,
                        child: _GradBtn(
                          label: 'Comenzar',
                          icon: Icons.rocket_launch_rounded,
                          onTap: _ctrl.text.trim().isNotEmpty && !_loading
                              ? _go : null,
                          loading: _loading,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Info card expandable
                      NeoBox(
                        radius: 20,
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Column(children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _showInfo = !_showInfo),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(
                                      color: C.bluePale,
                                      borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.help_outline_rounded,
                                        size: 16, color: C.blue)),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text('¿Cómo obtener tu API Key?',
                                      style: TextStyle(fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: C.textP))),
                                  AnimatedRotation(
                                    turns: _showInfo ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 300),
                                    child: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: C.textS, size: 22)),
                                ]),
                              ),
                            ),
                            if (_showInfo) ...[
                              Container(height: 1, color: C.shadowDark.withOpacity(0.15),
                                  margin: const EdgeInsets.symmetric(horizontal: 16)),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...[
                                      ('1', 'Ve a aistudio.google.com'),
                                      ('2', 'Inicia sesión con Google'),
                                      ('3', 'Haz clic en "Get API key"'),
                                      ('4', 'Crea una key en proyecto nuevo'),
                                      ('5', 'Copia y pégala aquí'),
                                    ].map((s) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 22, height: 22,
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                  colors: [C.grad1, C.grad2]),
                                              borderRadius: BorderRadius.circular(7)),
                                            child: Center(child: Text(s.$1,
                                              style: const TextStyle(
                                                  fontSize: 10, color: Colors.white,
                                                  fontWeight: FontWeight.w800)))),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(s.$2,
                                            style: const TextStyle(
                                                fontSize: 13, color: C.textS,
                                                height: 1.5))),
                                        ],
                                      ),
                                    )),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: C.ok.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: C.ok.withOpacity(0.2))),
                                      child: const Row(children: [
                                        Icon(Icons.shield_rounded,
                                            size: 13, color: C.ok),
                                        SizedBox(width: 8),
                                        Expanded(child: Text(
                                          'Tu API key se guarda solo en tu dispositivo.',
                                          style: TextStyle(
                                              fontSize: 12, color: C.ok))),
                                      ]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('ITBOT · TecNM Mérida · 2026',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: C.textM,
                            letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoTag(IconData icon, String label) {
    return NeoBox(
      radius: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: C.blue),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(
            fontSize: 11, color: C.textS, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════════════════════════════════
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final ChatProv _prov;
  late final AnimationController _fadeAc;
  late final Animation<double> _fade;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _prov = ChatProv();
    _fadeAc = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeAc, curve: Curves.easeOut);
    _prov.init().then((_) {
      if (mounted) { _fadeAc.forward(); setState(() {}); }
    });
  }

  @override
  void dispose() { _prov.dispose(); _fadeAc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _prov,
      builder: (ctx, _) => Scaffold(
        key: _scaffoldKey,
        backgroundColor: C.bg,
        drawer: _Sidebar(
          prov: _prov,
          onSelect: (id) { _prov.selectConv(id); Navigator.pop(context); },
          onNew: () async {
            await _prov.newConv();
            if (mounted) Navigator.pop(context);
          },
          onDelete: _prov.deleteConv,
          onLogout: () => _logout(context),
        ),
        body: FadeTransition(
          opacity: _fade,
          child: Column(children: [
            _TopBar(
              scaffoldKey: _scaffoldKey, prov: _prov,
              onNew: _prov.newConv, onRename: () => _rename(context)),
            Expanded(
              child: _prov.msgs.isEmpty
                  ? _EmptyState(onTap: _prov.send)
                  : _MsgList(msgs: _prov.msgs, streaming: _prov.busy,
                      onRetry: _prov.retry),
            ),
            _InputBar(enabled: !_prov.busy, onSend: _prov.send),
          ]),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext ctx) async {
    final conv = _prov.active; if (conv == null) return;
    final ctrl = TextEditingController(text: conv.title);
    final r = await showDialog<String>(context: ctx,
        builder: (_) => _RenameDialog(ctrl: ctrl));
    if (r != null && r.isNotEmpty) await _prov.rename(conv.id, r);
  }

  Future<void> _logout(BuildContext ctx) async {
    final ok = await showDialog<bool>(context: ctx, builder: (c) => Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        radius: 24, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: C.err.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.logout_rounded, color: C.err, size: 18)),
            const SizedBox(width: 12),
            const Text('Cambiar API Key', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: C.textP)),
          ]),
          const SizedBox(height: 12),
          const Text('Se eliminará la API key y las conversaciones guardadas.',
              style: TextStyle(color: C.textS, height: 1.5)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: NeoBox(
              radius: 50, onTap: () => Navigator.pop(c, false),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(child: Text('Cancelar',
                  style: TextStyle(color: C.textS,
                      fontWeight: FontWeight.w600))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(c, true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: C.err, borderRadius: BorderRadius.circular(50)),
                child: const Center(child: Text('Eliminar',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)))))),
          ]),
        ]),
      ),
    ));
    if (ok == true && ctx.mounted) {
      await Store.clearAll();
      Navigator.pushReplacementNamed(ctx, '/apikey');
    }
  }
}

// ─── TopBar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ChatProv prov;
  final VoidCallback onNew, onRename;

  const _TopBar({required this.scaffoldKey, required this.prov,
      required this.onNew, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.bg,
        boxShadow: [
          BoxShadow(color: C.shadowDark.withOpacity(0.3),
              blurRadius: 8, offset: const Offset(0, 4)),
          BoxShadow(color: C.shadowLight.withOpacity(0.8),
              blurRadius: 4, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            _NeoIconBtn(
                icon: Icons.menu_rounded,
                onTap: () => scaffoldKey.currentState?.openDrawer()),
            const SizedBox(width: 12),
            const _NeoLogo(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onRename,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, children: [
                  Text(prov.active?.title ?? 'ITBOT · Admisiones ITM',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.w700, color: C.textP),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(prov.busy ? 'Buscando información…' : 'Listo · TecNM Mérida 2026',
                    style: TextStyle(fontSize: 10,
                        color: prov.busy ? C.blue : C.textM)),
                ]),
              ),
            ),
            if (prov.busy)
              Container(
                width: 8, height: 8, margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                    color: C.blue, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: C.blue.withOpacity(0.5),
                        blurRadius: 6, spreadRadius: 1)]),
              ),
            _NeoIconBtn(icon: Icons.add_rounded, onTap: onNew,
                gradient: true),
          ]),
        ),
      ),
    );
  }
}

class _NeoIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool gradient;
  const _NeoIconBtn({required this.icon, required this.onTap,
      this.gradient = false});
  @override State<_NeoIconBtn> createState() => _NeoIconBtnState();
}

class _NeoIconBtnState extends State<_NeoIconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _sc;
  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 100));
    _sc = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ac.forward(),
      onTapUp: (_) { _ac.reverse(); widget.onTap(); },
      onTapCancel: () => _ac.reverse(),
      child: AnimatedBuilder(
        animation: _sc,
        builder: (_, child) => Transform.scale(scale: _sc.value, child: child),
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            gradient: widget.gradient
                ? const LinearGradient(
                    colors: [C.grad1, C.grad2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: widget.gradient ? null : C.bg,
            borderRadius: BorderRadius.circular(13),
            boxShadow: widget.gradient
                ? [BoxShadow(color: C.blue.withOpacity(0.35),
                    blurRadius: 10, offset: const Offset(0, 4))]
                : [
                    BoxShadow(color: C.shadowDark.withOpacity(0.45),
                        blurRadius: 7, offset: const Offset(3, 3)),
                    BoxShadow(color: C.shadowLight.withOpacity(0.9),
                        blurRadius: 7, offset: const Offset(-3, -3)),
                  ],
          ),
          child: Icon(widget.icon, size: 20,
              color: widget.gradient ? Colors.white : C.textS),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════════════
class _Sidebar extends StatelessWidget {
  final ChatProv prov;
  final void Function(String) onSelect, onDelete;
  final VoidCallback onNew, onLogout;

  const _Sidebar({required this.prov, required this.onSelect,
      required this.onNew, required this.onDelete, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: C.bg,
      width: 300,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28))),
      child: Column(children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
          decoration: BoxDecoration(
            color: C.bg,
            boxShadow: [
              BoxShadow(color: C.shadowDark.withOpacity(0.2),
                  blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              const _NeoLogo(size: 42),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ITBOT · ITM', style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800,
                        color: C.textP)),
                    Text('Asistente de Admisiones', style: TextStyle(
                        fontSize: 11, color: C.textM)),
                  ]),
              ),
              _NeoIconBtn(icon: Icons.add_rounded, onTap: onNew,
                  gradient: true),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // Stats strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(children: [
            _statBadge(Icons.chat_rounded, '${prov.convs.length}', 'chats'),
            const SizedBox(width: 8),
            _statBadge(Icons.message_rounded, '${prov.msgs.length}', 'msgs'),
          ]),
        ),

        // Conversations
        Expanded(
          child: prov.convs.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    NeoBox(
                      radius: 20,
                      padding: const EdgeInsets.all(16),
                      child: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 28, color: C.textM)),
                    const SizedBox(height: 12),
                    const Text('Sin conversaciones',
                        style: TextStyle(color: C.textM, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text('Toca + para comenzar',
                        style: TextStyle(color: C.textM, fontSize: 11)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: prov.convs.length,
                  itemBuilder: (ctx, i) {
                    final c = prov.convs[i];
                    return _SideConvTile(
                      conv: c, isActive: c.id == prov.active?.id,
                      onTap: () => onSelect(c.id),
                      onDelete: () => onDelete(c.id));
                  }),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            GestureDetector(
              onTap: onLogout,
              child: NeoBox(
                radius: 50,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(children: [
                  Container(width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: C.err.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.logout_rounded,
                        size: 14, color: C.err)),
                  const SizedBox(width: 10),
                  const Text('Cambiar API Key',
                    style: TextStyle(fontSize: 13,
                        color: C.err, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Salvador Eduardo Vallado Villamonte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: C.textM)),
            const Text('ITBOT · TecNM Mérida · 2026',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: C.textM)),
          ]),
        ),
      ]),
    );
  }

  Widget _statBadge(IconData icon, String value, String label) {
    return Expanded(
      child: NeoBox(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: C.blue),
          const SizedBox(width: 6),
          Text('$value $label', style: const TextStyle(
              fontSize: 11, color: C.textS, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _SideConvTile extends StatefulWidget {
  final Conv conv;
  final bool isActive;
  final VoidCallback onTap, onDelete;
  const _SideConvTile({required this.conv, required this.isActive,
      required this.onTap, required this.onDelete});
  @override State<_SideConvTile> createState() => _SideConvTileState();
}

class _SideConvTileState extends State<_SideConvTile> {
  bool _hov = false;
  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('d MMM', 'es').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hov = true),
      onExit: (_) => setState(() => _hov = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.isActive
                ? const LinearGradient(colors: [
                    Color(0xFFE8F0FF), Color(0xFFDEEBFF)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
            color: widget.isActive ? null
                : _hov ? C.bluePale.withOpacity(0.3) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: widget.isActive
                ? Border.all(color: C.blue.withOpacity(0.2)) : null,
            boxShadow: widget.isActive
                ? [BoxShadow(color: C.blue.withOpacity(0.08),
                    blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(children: [
            Container(width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: widget.isActive
                    ? const LinearGradient(colors: [C.grad1, C.grad2])
                    : null,
                color: widget.isActive ? null : C.bg,
                borderRadius: BorderRadius.circular(10),
                boxShadow: widget.isActive ? null : [
                  BoxShadow(color: C.shadowDark.withOpacity(0.4),
                      blurRadius: 4, offset: const Offset(2, 2)),
                  BoxShadow(color: C.shadowLight.withOpacity(0.9),
                      blurRadius: 4, offset: const Offset(-2, -2)),
                ],
              ),
              child: Icon(Icons.chat_bubble_outline_rounded, size: 14,
                  color: widget.isActive ? Colors.white : C.textM)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.conv.title, style: TextStyle(
                fontSize: 13,
                fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                color: widget.isActive ? C.blue : C.textP),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(_fmt(widget.conv.updatedAt),
                  style: const TextStyle(fontSize: 10, color: C.textM)),
            ])),
            if (_hov || widget.isActive)
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(width: 26, height: 26,
                  decoration: BoxDecoration(
                      color: C.err.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.close_rounded,
                      size: 13, color: C.err))),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// EMPTY STATE — Full ITM quick questions panel
// ═══════════════════════════════════════════════════════════════════════
class _EmptyState extends StatefulWidget {
  final void Function(String) onTap;
  const _EmptyState({required this.onTap});
  @override State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with TickerProviderStateMixin {
  late final AnimationController _fadeAc, _floatAc;
  late final Animation<double> _fade, _float;

  // All ITM quick questions organized by category
  static const _categories = [
    (
      'Inscripción',
      Icons.how_to_reg_rounded,
      Color(0xFF1A56DB),
      [
        ('📋 Pasos del proceso', 'Explícame paso a paso todo el proceso de admisión del TecNM Mérida 2026'),
        ('📅 Fechas importantes', '¿Cuáles son todas las fechas importantes del proceso de admisión 2026 del TecNM Mérida?'),
        ('🌐 ¿Cómo me registro?', '¿Cómo me registro en el Sistema SIE del TecNM Mérida? ¿Qué necesito?'),
        ('📸 Ficha aspirante', '¿Cómo genero mi ficha de aspirante en el TecNM Mérida?'),
      ]
    ),
    (
      'Pago y Costo',
      Icons.payments_rounded,
      Color(0xFF0096C7),
      [
        ('💰 ¿Cuánto cuesta?', '¿Cuánto cuesta el examen de admisión del TecNM Mérida?'),
        ('🏦 ¿Cómo pago?', '¿Cómo realizo el pago del examen de admisión del TecNM Mérida?'),
        ('🧾 Facturación', '¿Cómo puedo obtener factura del pago del examen en el TecNM Mérida?'),
        ('🔄 ¿Puedo cambiar carrera?', '¿Puedo cambiar de carrera después de pagar en el TecNM Mérida?'),
      ]
    ),
    (
      'Examen',
      Icons.quiz_rounded,
      Color(0xFF7B2FBE),
      [
        ('💻 ¿Es en línea?', '¿Cómo es el examen de admisión del TecNM Mérida? ¿Es en línea?'),
        ('📡 Requisitos técnicos', '¿Qué requisitos técnicos necesito para el examen en línea del TecNM Mérida?'),
        ('⏱ Duración y reglas', '¿Cuánto dura el examen del TecNM Mérida y qué está permitido o prohibido?'),
        ('📖 Guías de estudio', '¿Dónde puedo encontrar las guías de estudio para el examen del TecNM Mérida?'),
      ]
    ),
    (
      'Carreras',
      Icons.school_rounded,
      Color(0xFF0077B6),
      [
        ('🎓 Todas las carreras', '¿Qué carreras ofrece el Instituto Tecnológico de Mérida en 2026?'),
        ('💻 Sistemas Computacionales', '¿Cómo es la carrera de Ingeniería en Sistemas Computacionales en el TecNM Mérida?'),
        ('🔒 Ciberseguridad', '¿Cómo es la carrera de Ingeniería en Ciberseguridad en el TecNM Mérida?'),
        ('🏥 Biomédica', '¿Cómo es la carrera de Ingeniería Biomédica en el TecNM Mérida?'),
      ]
    ),
    (
      'Resultados',
      Icons.leaderboard_rounded,
      Color(0xFF10B981),
      [
        ('📊 ¿Cuándo salen?', '¿Cuándo se publican los resultados del examen de admisión del TecNM Mérida 2026?'),
        ('🔍 ¿Dónde los veo?', '¿Dónde puedo ver los resultados del examen de admisión del TecNM Mérida?'),
        ('📨 ¿Y si repruebo?', '¿Qué pasa si no apruebo el examen de admisión del TecNM Mérida?'),
      ]
    ),
    (
      'Contacto',
      Icons.contact_support_rounded,
      Color(0xFFFF6B35),
      [
        ('📧 Correos oficiales', '¿Cuáles son los correos de contacto del TecNM Mérida para admisiones?'),
        ('🌐 Página web', '¿Cuál es la página web oficial del Instituto Tecnológico de Mérida?'),
        ('📘 Facebook', '¿Cuál es el Facebook oficial del TecNM Mérida?'),
        ('❓ Tengo dudas', '¿A quién contacto si tengo dudas sobre el proceso de admisión del TecNM Mérida?'),
      ]
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeAc = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600));
    _floatAc = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _fadeAc, curve: Curves.easeOut);
    _float = Tween<double>(begin: -5.0, end: 5.0)
        .animate(CurvedAnimation(parent: _floatAc, curve: Curves.easeInOut));
    _fadeAc.forward();
  }

  @override
  void dispose() { _fadeAc.dispose(); _floatAc.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              // Hero
              AnimatedBuilder(
                animation: _float,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _float.value), child: child),
                child: const _NeoLogo(size: 72),
              ),
              const SizedBox(height: 18),
              const Text('¿En qué puedo ayudarte?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                    color: C.textP, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text(
                'Soy ITBOT, tu asistente de admisiones del TecNM Mérida.\nPuedo responder cualquier pregunta también.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: C.textS, height: 1.5)),
              const SizedBox(height: 6),
              const Text('Desarrollado por Salvador Eduardo Vallado Villamonte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: C.textM)),
              const SizedBox(height: 24),

              // Category quick access
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('DUDAS · ADMISIONES ITM 2026',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                      color: C.textM, letterSpacing: 1.5)),
              ),
              const SizedBox(height: 14),

              // Categories grid
              ..._categories.map((cat) => _CategorySection(
                title: cat.$1, icon: cat.$2, color: cat.$3,
                questions: cat.$4, onTap: widget.onTap)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<(String, String)> questions;
  final void Function(String) onTap;

  const _CategorySection({required this.title, required this.icon,
      required this.color, required this.questions, required this.onTap});

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late final AnimationController _ac;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300));
    _ac.forward();
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NeoBox(
        radius: 20,
        child: Column(children: [
          // Category header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color,
                          widget.color.withOpacity(0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(
                        color: widget.color.withOpacity(0.3),
                        blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: Icon(widget.icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(widget.title, style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: C.textP)),
                const Spacer(),
                NeoBox(
                  radius: 8, pressed: true,
                  padding: const EdgeInsets.all(4),
                  child: AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 18, color: C.textS)),
                ),
              ]),
            ),
          ),

          // Question pills
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 8, runSpacing: 8,
                children: widget.questions.map((q) => _IQBtn(
                  label: q.$1, query: q.$2,
                  icon: Icons.arrow_forward_ios_rounded,
                  onTap: widget.onTap,
                )).toList(),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// MESSAGE LIST
// ═══════════════════════════════════════════════════════════════════════
class _MsgList extends StatefulWidget {
  final List<ChatMsg> msgs;
  final bool streaming;
  final VoidCallback onRetry;

  const _MsgList({required this.msgs, required this.streaming,
      required this.onRetry});
  @override State<_MsgList> createState() => _MsgListState();
}

class _MsgListState extends State<_MsgList> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_MsgList old) {
    super.didUpdateWidget(old);
    if (widget.msgs.length != old.msgs.length || widget.streaming) _toBottom();
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 16, left: 14, right: 14, bottom: 120),
      itemCount: widget.msgs.length,
      itemBuilder: (ctx, i) {
        final m = widget.msgs[i];
        return _AniMsg(
          key: ValueKey(m.id),
          child: _Bubble(msg: m, isLast: i == widget.msgs.length - 1,
              onRetry: m.isError ? widget.onRetry : null));
      },
    );
  }
}

class _AniMsg extends StatefulWidget {
  final Widget child;
  const _AniMsg({super.key, required this.child});
  @override State<_AniMsg> createState() => _AniMsgState();
}

class _AniMsgState extends State<_AniMsg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _op;
  late final Animation<Offset> _sl;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 300));
    _op = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _sl = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() { _ac.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _op,
        child: SlideTransition(position: _sl, child: widget.child));
  }
}

// ═══════════════════════════════════════════════════════════════════════
// BUBBLES
// ═══════════════════════════════════════════════════════════════════════
class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final bool isLast;
  final VoidCallback? onRetry;

  const _Bubble({required this.msg, required this.isLast, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: msg.isUser
          ? _UserBub(msg: msg)
          : _AiBub(msg: msg, isLast: isLast, onRetry: onRetry),
    );
  }
}

class _UserBub extends StatelessWidget {
  final ChatMsg msg;
  const _UserBub({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: msg.content));
              ScaffoldMessenger.of(context).showSnackBar(_snack('Copiado'));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [C.grad1, C.grad2],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(6),
                ),
                boxShadow: [
                  BoxShadow(color: C.blue.withOpacity(0.3),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Text(msg.content, style: const TextStyle(
                  fontSize: 14, color: Colors.white, height: 1.55)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [C.grad1, C.grad2],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: C.blue.withOpacity(0.3),
                blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: const Center(
              child: Icon(Icons.person_rounded, size: 15, color: Colors.white)),
        ),
      ],
    );
  }
}

class _AiBub extends StatelessWidget {
  final ChatMsg msg;
  final bool isLast;
  final VoidCallback? onRetry;

  const _AiBub({required this.msg, required this.isLast, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [C.grad1, C.grad2],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: C.blue.withOpacity(0.3),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: const Center(child: Text('IT', style: TextStyle(
            color: Colors.white, fontSize: 9,
            fontWeight: FontWeight.w900))),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NeoBox(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildContent(),
          ),
          if (msg.isDone && isLast && msg.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: msg.content));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(_snack('Respuesta copiada'));
                },
                child: NeoBox(
                  radius: 50, pressed: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.copy_rounded, size: 11, color: C.textS),
                    SizedBox(width: 4),
                    Text('Copiar', style: TextStyle(
                        fontSize: 11, color: C.textS)),
                  ]),
                ),
              ),
            ),
          if (msg.isError && onRetry != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: GestureDetector(
                onTap: onRetry,
                child: NeoBox(
                  radius: 50, pressed: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded, size: 11, color: C.err),
                    SizedBox(width: 4),
                    Text('Reintentar', style: TextStyle(
                        fontSize: 11, color: C.err)),
                  ]),
                ),
              ),
            ),
        ]),
      ),
    ]);
  }

  Widget _buildContent() {
    if (msg.isStreaming && msg.content.isEmpty) return const _Typing();
    if (msg.isError) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 15, color: C.err),
        const SizedBox(width: 8),
        Flexible(child: Text(msg.content, style: const TextStyle(
            fontSize: 13, color: C.err, height: 1.5))),
      ]);
    }
    return MarkdownBody(
      data: msg.content, selectable: true, shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: C.textP, height: 1.65),
        h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
            color: C.textP),
        h2: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
            color: C.textP),
        h3: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
            color: C.blue),
        strong: const TextStyle(fontWeight: FontWeight.w700, color: C.textP),
        em: const TextStyle(fontStyle: FontStyle.italic, color: C.textS),
        code: const TextStyle(fontFamily: 'monospace', fontSize: 13,
            color: C.blue, backgroundColor: Color(0xFFEEF2FF)),
        codeblockDecoration: BoxDecoration(
            color: C.blueGhost,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.bluePale)),
        codeblockPadding: const EdgeInsets.all(14),
        blockquoteDecoration: BoxDecoration(
            border: Border(left: BorderSide(color: C.blue, width: 3))),
        blockquotePadding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
        blockquote: const TextStyle(color: C.textS, fontStyle: FontStyle.italic),
        listBullet: const TextStyle(color: C.blue),
        tableHead: const TextStyle(fontWeight: FontWeight.w700, color: C.textP),
        tableBody: const TextStyle(color: C.textS),
        tableBorder: TableBorder.all(color: C.shadowDark),
      ),
    );
  }
}

// ─── Typing ───────────────────────────────────────────────────────────
class _Typing extends StatefulWidget {
  const _Typing();
  @override State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with TickerProviderStateMixin {
  late final List<AnimationController> _cs;
  late final List<Animation<double>> _as;

  @override
  void initState() {
    super.initState();
    _cs = List.generate(3, (_) => AnimationController(vsync: this,
        duration: const Duration(milliseconds: 600)));
    _as = _cs.map((c) => Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    _start();
  }

  void _start() async {
    for (int i = 0; i < _cs.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 160));
      if (mounted) _cs[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() { for (final c in _cs) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Pensando', style: TextStyle(fontSize: 12, color: C.textM)),
      const SizedBox(width: 8),
      ...List.generate(3, (i) => Padding(
        padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
        child: AnimatedBuilder(animation: _as[i],
          builder: (_, __) => Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [C.grad1.withOpacity(_as[i].value),
                    C.grad2.withOpacity(_as[i].value)]),
            ),
          )),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════
// INPUT BAR
// ═══════════════════════════════════════════════════════════════════════
class _InputBar extends StatefulWidget {
  final bool enabled;
  final void Function(String) onSend;
  const _InputBar({required this.enabled, required this.onSend});
  @override State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _has = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final h = _ctrl.text.trim().isNotEmpty;
      if (h != _has) setState(() => _has = h);
    });
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_InputBar old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) _focus.requestFocus();
  }

  @override
  void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _send() {
    if (!widget.enabled || _ctrl.text.trim().isEmpty) return;
    final t = _ctrl.text.trim();
    _ctrl.clear();
    widget.onSend(t);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.bg,
        boxShadow: [
          BoxShadow(color: C.shadowDark.withOpacity(0.25),
              blurRadius: 12, offset: const Offset(0, -4)),
          BoxShadow(color: C.shadowLight.withOpacity(0.9),
              blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          14, 12, 14, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 130),
            child: NeoBox(
              radius: 26,
              pressed: _focus.hasFocus,
              child: TextField(
                controller: _ctrl, focusNode: _focus,
                enabled: widget.enabled, maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15, color: C.textP, height: 1.5),
                decoration: InputDecoration(
                  hintText: widget.enabled
                      ? 'Escribe tu pregunta…'
                      : 'Buscando respuesta…',
                  hintStyle: const TextStyle(color: C.textM, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 13),
                ),
                onSubmitted: widget.enabled ? (_) => _send() : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: (widget.enabled && _has) ? _send : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50, height: 50,
            decoration: BoxDecoration(
              gradient: (widget.enabled && _has)
                  ? const LinearGradient(
                      colors: [C.grad1, C.grad2],
                      begin: Alignment.topLeft, end: Alignment.bottomRight)
                  : null,
              color: (widget.enabled && _has) ? null : C.bg,
              shape: BoxShape.circle,
              boxShadow: (widget.enabled && _has)
                  ? [BoxShadow(color: C.blue.withOpacity(0.4),
                      blurRadius: 14, offset: const Offset(0, 4))]
                  : [
                      BoxShadow(color: C.shadowDark.withOpacity(0.4),
                          blurRadius: 8, offset: const Offset(3, 3)),
                      BoxShadow(color: C.shadowLight.withOpacity(0.9),
                          blurRadius: 8, offset: const Offset(-3, -3)),
                    ],
            ),
            child: Center(
              child: !widget.enabled
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(C.blue)))
                  : Icon(Icons.arrow_upward_rounded, size: 22,
                      color: _has ? Colors.white : C.textM),
            ),
          ),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RENAME DIALOG
// ═══════════════════════════════════════════════════════════════════════
class _RenameDialog extends StatelessWidget {
  final TextEditingController ctrl;
  const _RenameDialog({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        radius: 24, padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Renombrar', style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: C.textP)),
          const SizedBox(height: 14),
          NeoBox(
            radius: 16,
            child: TextField(
              controller: ctrl, autofocus: true,
              style: const TextStyle(color: C.textP),
              decoration: const InputDecoration(
                hintText: 'Ej: Dudas sobre el examen…',
                hintStyle: TextStyle(color: C.textM),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14)),
              onSubmitted: (v) => Navigator.pop(context, v)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: NeoBox(
              radius: 50, onTap: () => Navigator.pop(context),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Center(child: Text('Cancelar',
                  style: TextStyle(color: C.textS,
                      fontWeight: FontWeight.w600))))),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, ctrl.text),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [C.grad1, C.grad2]),
                    borderRadius: BorderRadius.circular(50)),
                child: const Center(child: Text('Guardar',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w700)))))),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════
SnackBar _snack(String t) => SnackBar(
  content: Row(children: [
    const Icon(Icons.check_circle_rounded, size: 15, color: C.ok),
    const SizedBox(width: 8),
    Text(t, style: const TextStyle(fontSize: 13, color: C.textP)),
  ]),
  backgroundColor: C.bg,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
  duration: const Duration(seconds: 2),
);