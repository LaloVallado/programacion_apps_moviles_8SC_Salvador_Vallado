// ╔══════════════════════════════════════════════════════════════════════════╗
// ║   ITBOT · TecNM Mérida · Diseñado por Salvador Eduardo Vallado Villamonte ║
// ╚══════════════════════════════════════════════════════════════════════════╝

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PALETA — Blanco · Negro · Azul Rey · Minimalista iOS 26
// ═══════════════════════════════════════════════════════════════════════════

class C {
  // Fondos
  static const bg          = Color(0xFFFFFFFF);
  static const bgSoft      = Color(0xFFF7F7F8);
  static const bgInput     = Color(0xFFF0F0F2);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceCard = Color(0xFFF9F9FB);

  // Bordes
  static const border      = Color(0xFFE8E8EC);
  static const borderFocus = Color(0xFF1A56DB);

  // Azul rey
  static const blue        = Color(0xFF1A56DB);
  static const blueDark    = Color(0xFF1043B8);
  static const blueLight   = Color(0xFF3B76F0);
  static const bluePale    = Color(0xFFE8EFFE);
  static const blueGhost   = Color(0xFFF0F4FF);

  // Textos
  static const textP       = Color(0xFF0D0D0D);
  static const textS       = Color(0xFF6B7280);
  static const textM       = Color(0xFFADB5C0);
  static const textInv     = Color(0xFFFFFFFF);

  // Bubbles
  static const userBubble  = Color(0xFF1A56DB);
  static const aiBubble    = Color(0xFFF7F7F8);

  // Estado
  static const err         = Color(0xFFEF4444);
  static const ok          = Color(0xFF10B981);

  // Sombras
  static const shadowSoft  = Color(0x0A000000);
  static const shadowMed   = Color(0x14000000);
}

// ═══════════════════════════════════════════════════════════════════════════
// THEME
// ═══════════════════════════════════════════════════════════════════════════

ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: C.bg,
  fontFamily: 'SF Pro Display',
  colorScheme: const ColorScheme.light(
    primary: C.blue, secondary: C.blueLight,
    surface: C.surface, onSurface: C.textP),
  appBarTheme: const AppBarTheme(
    backgroundColor: C.bg, foregroundColor: C.textP,
    elevation: 0, scrolledUnderElevation: 0, centerTitle: true),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: C.blue, foregroundColor: C.textInv,
      elevation: 0, shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)))),
);

// ═══════════════════════════════════════════════════════════════════════════
// MODELS
// ═══════════════════════════════════════════════════════════════════════════

enum MsgRole   { user, assistant }
enum MsgStatus { streaming, done, error }

class ChatMsg {
  final String id, content;
  final MsgRole role;
  final MsgStatus status;
  final DateTime ts;

  const ChatMsg({required this.id, required this.content,
      required this.role, required this.ts, this.status = MsgStatus.done});

  factory ChatMsg.user(String content) => ChatMsg(
      id: const Uuid().v4(), content: content,
      role: MsgRole.user, ts: DateTime.now());

  factory ChatMsg.assistant({required String content, MsgStatus status = MsgStatus.done}) =>
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
      {'id': id, 'content': content, 'role': role.name, 'ts': ts.toIso8601String()};

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

  factory Conv.create() => Conv(
      id: const Uuid().v4(), title: 'Nueva conversación',
      messages: [], updatedAt: DateTime.now());

  Conv copyWith({String? title, List<ChatMsg>? messages, DateTime? updatedAt}) =>
      Conv(id: id, title: title ?? this.title,
          messages: messages ?? this.messages,
          updatedAt: updatedAt ?? this.updatedAt);

  String get autoTitle {
    if (messages.isEmpty) return 'Nueva conversación';
    final first = messages.firstWhere((m) => m.isUser,
        orElse: () => messages.first);
    final t = first.content;
    return t.length > 40 ? '${t.substring(0, 40)}…' : t;
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Conv.fromJson(Map<String, dynamic> j) => Conv(
      id: j['id'] as String, title: j['title'] as String,
      messages: (j['messages'] as List)
          .map((m) => ChatMsg.fromJson(m as Map<String, dynamic>))
          .toList(),
      updatedAt: DateTime.parse(j['updatedAt'] as String));
}

// ═══════════════════════════════════════════════════════════════════════════
// STORAGE
// ═══════════════════════════════════════════════════════════════════════════

class Store {
  static const _kKey = 'gemini_api_key';
  static const _kConvs = 'conversations';
  static const _kAct = 'active_conv_id';

  static Future<SharedPreferences> _p() => SharedPreferences.getInstance();

  static Future<void>    saveKey(String k)  async => (await _p()).setString(_kKey, k);
  static Future<String?> getKey()           async => (await _p()).getString(_kKey);
  static Future<void>    clearAll()         async => (await _p()).clear();

  static Future<List<Conv>> loadConvs() async {
    final raw = (await _p()).getString(_kConvs);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Conv.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveConvs(List<Conv> cs) async =>
      (await _p()).setString(_kConvs,
          jsonEncode(cs.map((c) => c.toJson()).toList()));

  static Future<void>    saveActiveId(String id) async =>
      (await _p()).setString(_kAct, id);
  static Future<String?> getActiveId()           async =>
      (await _p()).getString(_kAct);
}

// ═══════════════════════════════════════════════════════════════════════════
// GEMINI SERVICE
// ═══════════════════════════════════════════════════════════════════════════

class GeminiSvc {
  String? _apiKey, _workingModel;
  bool get ready => _apiKey != null;

  // NOTE: \$850 uses escaped dollar to avoid Dart string interpolation
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
      '- Haber concluido bachillerato o estar en el último curso con certeza de concluir en este ciclo\n'
      '- Haber aplicado y aprobado el examen de admisión\n'
      '- Clases inician en agosto de 2026\n\n'
      '## INFORMACIÓN IMPORTANTE\n'
      '- Personas con licenciatura ya concluida: enviar correo a dep_merida@tecnm.mx con título\n'
      '- Si ya fuiste estudiante y NO concluiste: contactar dep_merida@tecnm.mx antes de iniciar\n'
      '- Exámenes de otras instituciones de nivel superior NO tienen validez en el ITM\n'
      '- Dudas del proceso: admision.itmerida@merida.tecnm.mx\n\n'
      '## CARRERAS OFERTADAS\n'
      '1. Ingeniería Ambiental\n2. Ingeniería Biomédica\n3. Ingeniería Bioquímica\n'
      '4. Ingeniería Civil\n5. Ingeniería Eléctrica\n6. Ingeniería Electrónica\n'
      '7. Ingeniería en Ciberseguridad\n8. Ingeniería en Gestión Empresarial\n'
      '9. Ingeniería en Semiconductores\n10. Ingeniería en Sistemas Computacionales\n'
      '11. Ingeniería Industrial\n12. Ingeniería Mecánica\n13. Ingeniería Química\n'
      '14. Licenciatura en Administración\n15. Licenciatura en Administración (No escolarizada)\n\n'
      '## FECHAS IMPORTANTES 2026\n'
      '- Paso 1 - Registro en SIE y Datos Generales: del 5 de febrero al 21 de mayo de 2026\n'
      '- Paso 2 - Obtener preficha: del 5-19 feb / 2-19 mar / 13-23 abr / 4-21 may\n'
      '- Paso 3 - Pago por derecho a examen (850 pesos MXN): del 5-20 feb / 2-20 mar / 13-24 abr / 4-22 may\n'
      '- Paso 4 - Generación de ficha de aspirante: fecha límite 29 de mayo de 2026\n'
      '- Paso 5 - Publicación de horarios de examen: 8 de junio de 2026\n'
      '- Paso 6 - Aplicación del examen de admisión (en línea): 13 y 14 de junio de 2026\n'
      '- Paso 7 - Publicación de resultados: 19 de junio de 2026\n\n'
      '## PROCESO PASO A PASO\n'
      '### Paso 1 - Registro en SIE\n'
      '- Ingresar al Sistema de Integración Escolar (SIE): sie.tecnm.mx\n'
      '- Registrar tu CURP (sin contraseña)\n'
      '- Seleccionar "Datos Generales" y llenar tu información\n'
      '- Si no aparece tu municipio o escuela, enviar correo a admision.itmerida@merida.tecnm.mx\n'
      '### Paso 2 - Preficha\n'
      '- Seleccionar "Solicitar preficha" en el menú\n'
      '- Elegir el plan de estudios deseado\n'
      '### Paso 3 - Pago\n'
      '- Costo: 850 pesos mexicanos\n'
      '- Verificar vigencia de la ficha antes de pagar\n'
      '- Los pagos NO son reembolsables\n'
      '- No hay cambios de carrera después del pago\n'
      '- Para factura: tesoreria@merida.tecnm.mx el mismo día o al día siguiente del pago\n'
      '### Paso 4 - Ficha de aspirante\n'
      '- Subir fotografía (JPG o PNG) con rostro visible\n'
      '### Paso 5 - Horarios\n'
      '- Consultar en merida.tecnm.mx el 8 de junio\n'
      '### Paso 6 - Examen (en línea desde casa)\n'
      '- Plataforma: EVALUATEC\n'
      '- Requisitos técnicos: cámara web obligatoria, mínimo 15 Mbps de subida\n'
      '- Usar Google Chrome o Microsoft Edge\n'
      '- Duración: 2 horas 30 minutos\n'
      '- Prohibido: celulares, tabletas, audífonos, relojes inteligentes, libros, apuntes\n'
      '- Permitido: hojas blancas, lápiz, calculadora básica\n'
      '- Se envía enlace un día antes al correo registrado en SIE\n'
      '### Paso 7 - Resultados\n'
      '- Publicación de folios admitidos en merida.tecnm.mx el 19 de junio\n\n'
      '## PREGUNTAS FRECUENTES CONOCIDAS\n'
      '- ¿Cuánto cuesta el examen? 850 pesos, no reembolsables\n'
      '- ¿Puedo cambiar de carrera? No, una vez pagado no hay cambios\n'
      '- ¿El examen es presencial? No, es en línea desde casa vía EVALUATEC\n'
      '- ¿Necesito cámara? Sí, es obligatorio tener cámara web\n'
      '- ¿Qué velocidad de internet necesito? Mínimo 15 Mbps de subida\n'
      '- ¿Cuándo empiezan clases? Agosto de 2026\n'
      '- ¿Mi examen de CENEVAL/COMIPEMS vale? No, no tienen validez en el ITM\n'
      '- ¿Dónde veo mis resultados? En merida.tecnm.mx el 19 de junio de 2026\n'
      '- ¿Cómo registro mi escuela si no aparece? Envía correo a admision.itmerida@merida.tecnm.mx\n\n'
      'Si no sabes algo con certeza, indícalo y sugiere contactar: admision.itmerida@merida.tecnm.mx '
      'o visitar merida.tecnm.mx. También puedes sugerir revisar '
      'facebook.com/TecNMCampusMerida para actualizaciones recientes.';

  static const _models = [
    'gemini-2.0-flash-lite', 'gemini-2.0-flash',
    'gemini-2.5-flash-lite', 'gemini-2.5-flash',
  ];

  void init(String apiKey) {
    _apiKey = apiKey;
  }

  Stream<String> stream(String msg, List<ChatMsg> history) async* {
    if (_apiKey == null) throw Exception('No inicializado');

    final recent = history.length > 20
        ? history.sublist(history.length - 20)
        : history;

    final contents = <Map<String, dynamic>>[];
    for (final m in recent) {
      contents.add({
        'role': m.role == MsgRole.user ? 'user' : 'model',
        'parts': [{'text': m.content}],
      });
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
    if (_workingModel == null) {
      fromApi = await listAvailableModels(_apiKey!);
    }

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

  Future<bool> validate(String apiKey) async => true;

  Future<List<String>> listAvailableModels(String apiKey) async {
    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final models = (data['models'] as List?) ?? [];
        return models
            .where((m) =>
                (m['supportedGenerationMethods'] as List?)
                    ?.contains('generateContent') ==
                true)
            .map((m) => (m['name'] as String).replaceFirst('models/', ''))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PROVIDER
// ═══════════════════════════════════════════════════════════════════════════

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
      final c = Conv.create();
      _convs.add(c);
      _active = c;
    } else {
      final id = await Store.getActiveId();
      _active = id != null
          ? _convs.firstWhere((c) => c.id == id, orElse: () => _convs.first)
          : _convs.first;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> newConv() async {
    final c = Conv.create();
    _convs.insert(0, c);
    _active = c;
    await _save();
    notifyListeners();
  }

  Future<void> selectConv(String id) async {
    _active = _convs.firstWhere((c) => c.id == id);
    await Store.saveActiveId(id);
    notifyListeners();
  }

  Future<void> deleteConv(String id) async {
    _convs.removeWhere((c) => c.id == id);
    if (_active?.id == id) {
      if (_convs.isEmpty) {
        final c = Conv.create();
        _convs.add(c);
        _active = c;
      } else {
        _active = _convs.first;
      }
    }
    await _save();
    notifyListeners();
  }

  Future<void> rename(String id, String title) async {
    final i = _convs.indexWhere((c) => c.id == id);
    if (i == -1) return;
    _convs[i] = _convs[i].copyWith(title: title);
    if (_active?.id == id) _active = _convs[i];
    await _save();
    notifyListeners();
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty || _active == null || busy) return;

    _addMsg(ChatMsg.user(text.trim()));
    _state = ChatState.streaming;
    notifyListeners();

    final pid = DateTime.now().microsecondsSinceEpoch.toString();
    _addMsg(ChatMsg(
      id: pid, content: '', role: MsgRole.assistant,
      ts: DateTime.now(), status: MsgStatus.streaming,
    ));
    notifyListeners();

    try {
      final histForReq = msgs.where((m) => m.id != pid).toList();
      final buf = StringBuffer();
      await for (final chunk in _gemini.stream(text.trim(), histForReq)) {
        buf.write(chunk);
        _updateMsg(pid, buf.toString(), MsgStatus.streaming);
        notifyListeners();
      }
      _updateMsg(pid, buf.toString(), MsgStatus.done);
      if (msgs.where((m) => m.isUser).length == 1) _autoRename();
      _state = ChatState.idle;
    } catch (e) {
      _updateMsg(pid,
          'Error: ${e.toString().replaceAll('Exception: ', '')}',
          MsgStatus.error);
      _state = ChatState.error;
    }
    await _save();
    notifyListeners();
  }

  Future<void> retry() async {
    if (_active == null || msgs.length < 2) return;
    String? lastUser;
    for (int i = msgs.length - 1; i >= 0; i--) {
      if (msgs[i].isUser) {
        lastUser = msgs[i].content;
        break;
      }
    }
    if (lastUser == null) return;
    _updateActive(_active!.copyWith(messages: msgs.sublist(0, msgs.length - 2)));
    _state = ChatState.idle;
    notifyListeners();
    await send(lastUser);
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
      messages: [..._active!.messages, m],
      updatedAt: DateTime.now(),
    ));
  }

  void _updateMsg(String id, String content, MsgStatus status) {
    if (_active == null) return;
    _updateActive(_active!.copyWith(
      messages: _active!.messages
          .map((m) => m.id == id ? m.copyWith(content: content, status: status) : m)
          .toList(),
      updatedAt: DateTime.now(),
    ));
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

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: C.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const ChatbotApp());
}

class ChatbotApp extends StatefulWidget {
  const ChatbotApp({super.key});
  @override
  State<ChatbotApp> createState() => _ChatbotAppState();
}

class _ChatbotAppState extends State<ChatbotApp> {
  bool _init = false, _hasKey = false;

  @override
  void initState() {
    super.initState();
    Store.getKey().then((k) => setState(() {
      _hasKey = k != null && k.isNotEmpty;
      _init = true;
    }));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ITBOT · TecNM Mérida',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: _init
          ? (_hasKey ? const HomePage() : const ApiKeyPage())
          : const Scaffold(
              backgroundColor: C.bg,
              body: Center(child: _AppLogo(size: 56))),
      routes: {
        '/home': (_) => const HomePage(),
        '/apikey': (_) => const ApiKeyPage(),
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED DESIGN COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _AppLogo extends StatelessWidget {
  final double size;
  const _AppLogo({this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: C.blue,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: C.blue.withOpacity(0.25),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'IT',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(color: C.border, height: 1, thickness: 1);
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  const _Tag({required this.label, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? C.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
        ],
        Text(label, style: TextStyle(
          fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// API KEY PAGE — Centrada y responsive
// ═══════════════════════════════════════════════════════════════════════════

class ApiKeyPage extends StatefulWidget {
  const ApiKeyPage({super.key});
  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

class _ApiKeyPageState extends State<ApiKeyPage> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _obscure = true, _loading = false;
  String? _error;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _ac.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final k = _ctrl.text.trim();
    if (k.isEmpty) {
      setState(() => _error = 'Ingresa tu Gemini API Key');
      return;
    }
    if (!k.startsWith('AIza')) {
      setState(() => _error = 'La key debe iniciar con AIza…');
      return;
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
    final screenW = MediaQuery.of(context).size.width;
    final isWide = screenW > 600;

    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 0 : 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Logo ──────────────────────────────────────
                        const _AppLogo(size: 64),
                        const SizedBox(height: 20),

                        // ── Título ────────────────────────────────────
                        const Text(
                          'ITBOT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: C.textP,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Asistente de admisiones\nTecNM Campus Mérida 2026',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: C.textS,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Desarrollado por Salvador Eduardo Vallado Villamonte',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: C.textM,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Tags ──────────────────────────────────────
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: const [
                            _Tag(label: 'TecNM Mérida',
                                icon: Icons.school_rounded),
                            _Tag(label: 'Admisiones 2026',
                                icon: Icons.calendar_today_rounded),
                            _Tag(label: 'Gemini AI',
                                icon: Icons.auto_awesome_rounded),
                          ],
                        ),
                        const SizedBox(height: 36),

                        // ── Campo API Key ─────────────────────────────
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Gemini API Key',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: C.textP,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: C.bgSoft,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _error != null
                                  ? C.err
                                  : _focus.hasFocus
                                      ? C.blue
                                      : C.border,
                              width: _focus.hasFocus ? 1.5 : 1,
                            ),
                          ),
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            obscureText: _obscure,
                            enabled: !_loading,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: C.textP,
                              letterSpacing: 0.5,
                            ),
                            decoration: InputDecoration(
                              hintText: 'AIzaSy··············',
                              hintStyle: const TextStyle(
                                  color: C.textM, fontFamily: 'monospace'),
                              prefixIcon: Icon(
                                Icons.key_rounded,
                                color: _focus.hasFocus ? C.blue : C.textM,
                                size: 18,
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 18,
                                  color: C.textM,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16),
                            ),
                            onSubmitted: (_) => _go(),
                          ),
                        ),

                        // ── Error ─────────────────────────────────────
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: C.err.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: C.err.withOpacity(0.2)),
                            ),
                            child: Row(children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 15, color: C.err),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_error!,
                                    style: const TextStyle(
                                        fontSize: 12, color: C.err)),
                              ),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // ── Botón ─────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: _loading
                              ? Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: C.bgSoft,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(C.blue),
                                      ),
                                    ),
                                  ),
                                )
                              : GestureDetector(
                                  onTap: _go,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: _ctrl.text.trim().isNotEmpty
                                          ? C.blue
                                          : C.bgInput,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: _ctrl.text.trim().isNotEmpty
                                          ? [BoxShadow(
                                              color: C.blue.withOpacity(0.3),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            )]
                                          : null,
                                    ),
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Continuar',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: _ctrl.text.trim().isNotEmpty
                                                  ? Colors.white
                                                  : C.textM,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 16,
                                            color: _ctrl.text.trim().isNotEmpty
                                                ? Colors.white
                                                : C.textM,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 28),

                        // ── Info expandible ───────────────────────────
                        GestureDetector(
                          onTap: () => setState(() => _showInfo = !_showInfo),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: C.bgSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: C.border),
                            ),
                            child: Column(
                              children: [
                                Row(children: [
                                  Container(
                                    width: 30, height: 30,
                                    decoration: BoxDecoration(
                                      color: C.bluePale,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      size: 16, color: C.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text('¿Cómo obtener tu API Key?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: C.textP,
                                      )),
                                  ),
                                  AnimatedRotation(
                                    turns: _showInfo ? 0.5 : 0,
                                    duration: const Duration(milliseconds: 250),
                                    child: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: C.textS, size: 20,
                                    ),
                                  ),
                                ]),
                                AnimatedCrossFade(
                                  duration: const Duration(milliseconds: 250),
                                  firstChild: const SizedBox.shrink(),
                                  secondChild: Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(color: C.border, height: 1),
                                        const SizedBox(height: 12),
                                        ...[
                                          ('1', 'Ve a aistudio.google.com'),
                                          ('2', 'Inicia sesión con tu cuenta Google'),
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
                                                  color: C.bluePale,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Center(
                                                  child: Text(s.$1,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      color: C.blue,
                                                    )),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(s.$2,
                                                  style: const TextStyle(
                                                    fontSize: 13, color: C.textS,
                                                    height: 1.5,
                                                  )),
                                              ),
                                            ],
                                          ),
                                        )),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: C.ok.withOpacity(0.07),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                                color: C.ok.withOpacity(0.2)),
                                          ),
                                          child: const Row(children: [
                                            Icon(Icons.lock_rounded,
                                                size: 13, color: C.ok),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Tu API key se guarda solo en tu dispositivo.',
                                                style: TextStyle(
                                                    fontSize: 12, color: C.ok),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      ],
                                    ),
                                  ),
                                  crossFadeState: _showInfo
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Footer ────────────────────────────────────
                        Text(
                          'ITBOT · TecNM Mérida · 2026',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 11, color: C.textM, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════════════════════════════════════

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final ChatProv _prov;
  late final AnimationController _ac;
  late final Animation<double> _fade;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _prov = ChatProv();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _prov.init().then((_) {
      if (mounted) {
        _ac.forward();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _prov.dispose();
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _prov,
      builder: (ctx, _) => Scaffold(
        key: _scaffoldKey,
        backgroundColor: C.bg,
        drawer: _Sidebar(
          prov: _prov,
          onSelect: (id) {
            _prov.selectConv(id);
            Navigator.pop(context);
          },
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
              scaffoldKey: _scaffoldKey,
              prov: _prov,
              onNew: _prov.newConv,
              onRename: () => _rename(context),
            ),
            if (_prov.ready) _StatusStrip(busy: _prov.busy),
            if (_prov.ready && _prov.msgs.isEmpty)
              _QuickPanel(onQuestion: _prov.send),
            Expanded(
              child: _prov.msgs.isEmpty
                  ? _EmptyState(onTap: _prov.send)
                  : _MsgList(
                      msgs: _prov.msgs,
                      streaming: _prov.busy,
                      onRetry: _prov.retry,
                    ),
            ),
            _InputBar(enabled: !_prov.busy, onSend: _prov.send),
          ]),
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final conv = _prov.active;
    if (conv == null) return;
    final ctrl = TextEditingController(text: conv.title);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _RenameDialog(ctrl: ctrl),
    );
    if (result != null && result.isNotEmpty) {
      await _prov.rename(conv.id, result);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Cambiar API Key',
            style: TextStyle(
                color: C.textP, fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
          'Se eliminará la API key y todas las conversaciones guardadas.',
          style: TextStyle(color: C.textS, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar',
                style: TextStyle(color: C.textS)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: C.err,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await Store.clearAll();
      Navigator.pushReplacementNamed(context, '/apikey');
    }
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final ChatProv prov;
  final VoidCallback onNew, onRename;

  const _TopBar({
    required this.scaffoldKey,
    required this.prov,
    required this.onNew,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.bg,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            // Menu
            _TopBarBtn(
              icon: Icons.menu_rounded,
              onTap: () => scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 10),

            // Logo
            const _AppLogo(size: 32),
            const SizedBox(width: 10),

            // Title
            Expanded(
              child: GestureDetector(
                onTap: onRename,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      prov.active?.title ?? 'ITBOT · Admisiones ITM',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: C.textP,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Text(
                      'Salvador E. Vallado Villamonte',
                      style: TextStyle(fontSize: 10, color: C.textM),
                    ),
                  ],
                ),
              ),
            ),

            // New chat
            _TopBarBtn(
              icon: Icons.add_rounded,
              onTap: onNew,
              filled: true,
            ),
          ]),
        ),
      ),
    );
  }
}

class _TopBarBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _TopBarBtn({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: filled ? C.bluePale : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: filled ? Border.all(color: C.blue.withOpacity(0.15)) : null,
        ),
        child: Icon(icon,
          size: 20,
          color: filled ? C.blue : C.textS,
        ),
      ),
    );
  }
}

// ─── Status Strip ─────────────────────────────────────────────────────────

class _StatusStrip extends StatelessWidget {
  final bool busy;
  const _StatusStrip({required this.busy});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: busy ? C.bluePale : C.bgSoft,
      child: Row(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: busy ? C.blue : C.ok,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          busy ? 'Buscando información…' : 'ITBOT listo · TecNM Mérida 2026',
          style: TextStyle(
            fontSize: 11,
            color: busy ? C.blue : C.textS,
            fontWeight: busy ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        const Spacer(),
        if (!busy)
          const _Tag(
            label: 'Admisiones 2026',
            icon: Icons.school_rounded,
          ),
      ]),
    );
  }
}

// ─── Quick Panel ──────────────────────────────────────────────────────────

class _QuickPanel extends StatefulWidget {
  final void Function(String) onQuestion;
  const _QuickPanel({required this.onQuestion});
  @override
  State<_QuickPanel> createState() => _QuickPanelState();
}

class _QuickPanelState extends State<_QuickPanel> {
  bool _expanded = false;

  static const _qs = [
    ('📅 Fechas', '¿Cuáles son todas las fechas importantes del proceso de admisión 2026 del TecNM Mérida?'),
    ('💰 Costo', '¿Cuánto cuesta el examen de admisión del TecNM Mérida y cómo puedo pagarlo?'),
    ('📚 Carreras', '¿Qué carreras ofrece el Instituto Tecnológico de Mérida en 2026?'),
    ('💻 Examen', '¿Cómo es el examen de admisión del TecNM Mérida? ¿Es en línea? ¿Qué necesito?'),
    ('📋 Pasos', 'Explícame paso a paso todo el proceso de admisión del TecNM Mérida 2026'),
    ('📧 Contacto', '¿Cuáles son los correos de contacto del TecNM Mérida para el proceso de admisión?'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: C.bgSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.border),
      ),
      child: Column(children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: C.bluePale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.help_outline_rounded,
                    size: 15, color: C.blue),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Preguntas frecuentes · TecNM Mérida',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: C.textP)),
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: C.textS),
              ),
            ]),
          ),
        ),
        if (_expanded) ...[
          const _Divider(),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _qs.map((q) => GestureDetector(
                onTap: () => widget.onQuestion(q.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: C.bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: C.border),
                  ),
                  child: Text(q.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: C.textP,
                      fontWeight: FontWeight.w500,
                    )),
                ),
              )).toList(),
            ),
          ),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  final ChatProv prov;
  final void Function(String) onSelect, onDelete;
  final VoidCallback onNew, onLogout;

  const _Sidebar({
    required this.prov,
    required this.onSelect,
    required this.onNew,
    required this.onDelete,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: C.bg,
      width: 300,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              child: Row(children: [
                const _AppLogo(size: 38),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ITBOT · ITM',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800,
                          color: C.textP)),
                      Text('Asistente de Admisiones',
                        style: TextStyle(fontSize: 11, color: C.textM)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onNew,
                  child: Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: C.bluePale,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: C.blue.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.add_rounded,
                        size: 18, color: C.blue),
                  ),
                ),
              ]),
            ),
          ),
        ),

        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: C.bgSoft,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(children: [
            Text('${prov.convs.length} conversaciones',
                style: const TextStyle(fontSize: 11, color: C.textS)),
            const Spacer(),
            Text('${prov.msgs.length} mensajes',
                style: const TextStyle(fontSize: 11, color: C.textS)),
          ]),
        ),

        // Conversations
        Expanded(
          child: prov.convs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: C.bgSoft,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: C.border),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 22, color: C.textM),
                      ),
                      const SizedBox(height: 10),
                      const Text('Sin conversaciones',
                          style: TextStyle(color: C.textM, fontSize: 13)),
                      const SizedBox(height: 4),
                      const Text('Toca + para comenzar',
                          style: TextStyle(color: C.textM, fontSize: 11)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: prov.convs.length,
                  itemBuilder: (ctx, i) {
                    final c = prov.convs[i];
                    return _SideConvTile(
                      conv: c,
                      isActive: c.id == prov.active?.id,
                      onTap: () => onSelect(c.id),
                      onDelete: () => onDelete(c.id),
                    );
                  },
                ),
        ),

        // Footer
        const _Divider(),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            GestureDetector(
              onTap: onLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: C.err.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: C.err.withOpacity(0.15)),
                ),
                child: const Row(children: [
                  Icon(Icons.logout_rounded, size: 16, color: C.err),
                  SizedBox(width: 10),
                  Text('Cambiar API Key',
                    style: TextStyle(
                      fontSize: 13, color: C.err, fontWeight: FontWeight.w500)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            const Text('Salvador Eduardo Vallado Villamonte',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: C.textM)),
            const SizedBox(height: 2),
            const Text('ITBOT · TecNM Mérida · 2026',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: C.textM)),
          ]),
        ),
      ]),
    );
  }
}

class _SideConvTile extends StatefulWidget {
  final Conv conv;
  final bool isActive;
  final VoidCallback onTap, onDelete;

  const _SideConvTile({
    required this.conv,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_SideConvTile> createState() => _SideConvTileState();
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
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? C.bluePale
                : _hov
                    ? C.bgSoft
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: widget.isActive
                ? Border.all(color: C.blue.withOpacity(0.2))
                : null,
          ),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: widget.isActive ? C.blue.withOpacity(0.12) : C.bgSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isActive ? C.blue.withOpacity(0.3) : C.border),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 13,
                color: widget.isActive ? C.blue : C.textM,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conv.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.isActive ? C.blue : C.textP,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(_fmt(widget.conv.updatedAt),
                    style: const TextStyle(fontSize: 10, color: C.textM)),
                ],
              ),
            ),
            if (_hov || widget.isActive)
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 26, height: 26,
                  decoration: BoxDecoration(
                    color: C.err.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.close_rounded, size: 13, color: C.err),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyState extends StatefulWidget {
  final void Function(String) onTap;
  const _EmptyState({required this.onTap});
  @override
  State<_EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<_EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;

  static const _suggs = [
    ('¿Cuáles son los pasos para inscribirme?',
        Icons.list_alt_rounded, C.blue),
    ('¿Cuánto cuesta el examen y cómo pago?',
        Icons.payments_rounded, C.blue),
    ('¿Qué carreras ofrece el TecNM Mérida?',
        Icons.school_rounded, C.blue),
    ('¿El examen de admisión es en línea?',
        Icons.computer_rounded, C.blue),
    ('¿Cuáles son las fechas importantes 2026?',
        Icons.calendar_month_rounded, C.blue),
    ('¿Qué necesito para registrarme en el SIE?',
        Icons.app_registration_rounded, C.blue),
  ];

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(children: [
              // Hero
              const _AppLogo(size: 60),
              const SizedBox(height: 16),
              const Text(
                '¿En qué puedo ayudarte?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: C.textP,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Soy ITBOT, tu asistente oficial de admisiones\ndel Instituto Tecnológico de Mérida.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: C.textS, height: 1.5),
              ),
              const SizedBox(height: 6),
              const Text(
                'Desarrollado por Salvador Eduardo Vallado Villamonte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: C.textM),
              ),
              const SizedBox(height: 24),

              // Tags
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Tag(label: 'Admisiones ITM',
                      icon: Icons.school_rounded),
                  _Tag(label: 'Convocatoria 2026',
                      icon: Icons.calendar_today_rounded),
                  _Tag(label: '24/7 Disponible',
                      icon: Icons.help_outline_rounded),
                ],
              ),
              const SizedBox(height: 32),

              // Divider with label
              Row(children: [
                Expanded(child: Container(height: 1, color: C.border)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('SUGERENCIAS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: C.textM,
                      letterSpacing: 1.5,
                    )),
                ),
                Expanded(child: Container(height: 1, color: C.border)),
              ]),
              const SizedBox(height: 16),

              // Suggestions grid — responsive
              LayoutBuilder(builder: (ctx, constraints) {
                final cols = constraints.maxWidth > 400 ? 2 : 1;
                if (cols == 1) {
                  return Column(
                    children: List.generate(_suggs.length, (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SuggCard(
                        text: _suggs[i].$1,
                        icon: _suggs[i].$2,
                        index: i,
                        onTap: () => widget.onTap(_suggs[i].$1),
                      ),
                    )),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_suggs.length, (i) => SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: _SuggCard(
                      text: _suggs[i].$1,
                      icon: _suggs[i].$2,
                      index: i,
                      onTap: () => widget.onTap(_suggs[i].$1),
                    ),
                  )),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SuggCard extends StatefulWidget {
  final String text;
  final IconData icon;
  final int index;
  final VoidCallback onTap;

  const _SuggCard({
    required this.text,
    required this.icon,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SuggCard> createState() => _SuggCardState();
}

class _SuggCardState extends State<_SuggCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _ac.forward();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _pressed ? C.bluePale : C.bgSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _pressed ? C.blue.withOpacity(0.3) : C.border,
              ),
            ),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: _pressed ? C.blue : C.bg,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: C.border),
                ),
                child: Icon(widget.icon,
                  size: 16,
                  color: _pressed ? Colors.white : C.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: _pressed ? C.blue : C.textS,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                  )),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: C.textM),
            ]),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MESSAGE LIST
// ═══════════════════════════════════════════════════════════════════════════

class _MsgList extends StatefulWidget {
  final List<ChatMsg> msgs;
  final bool streaming;
  final VoidCallback onRetry;

  const _MsgList({
    required this.msgs,
    required this.streaming,
    required this.onRetry,
  });

  @override
  State<_MsgList> createState() => _MsgListState();
}

class _MsgListState extends State<_MsgList> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_MsgList old) {
    super.didUpdateWidget(old);
    if (widget.msgs.length != old.msgs.length || widget.streaming) {
      _toBottom();
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(
          top: 16, left: 14, right: 14, bottom: 120),
      itemCount: widget.msgs.length,
      itemBuilder: (ctx, i) {
        final m = widget.msgs[i];
        return _AniMsg(
          key: ValueKey(m.id),
          child: _Bubble(
            msg: m,
            isLast: i == widget.msgs.length - 1,
            onRetry: m.isError ? widget.onRetry : null,
          ),
        );
      },
    );
  }
}

class _AniMsg extends StatefulWidget {
  final Widget child;
  const _AniMsg({super.key, required this.child});
  @override
  State<_AniMsg> createState() => _AniMsgState();
}

class _AniMsgState extends State<_AniMsg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _op;
  late final Animation<Offset> _sl;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _op = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _sl = Tween<Offset>(
      begin: const Offset(0, 0.06), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _ac.forward();
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _op,
      child: SlideTransition(position: _sl, child: widget.child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BUBBLES
// ═══════════════════════════════════════════════════════════════════════════

class _Bubble extends StatelessWidget {
  final ChatMsg msg;
  final bool isLast;
  final VoidCallback? onRetry;

  const _Bubble({
    required this.msg,
    required this.isLast,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: msg.isUser
          ? _UserBubble(msg: msg)
          : _AiBubble(
              msg: msg, isLast: isLast, onRetry: onRetry),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final ChatMsg msg;
  const _UserBubble({required this.msg});

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
              ScaffoldMessenger.of(context)
                  .showSnackBar(_buildSnack('Copiado'));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: C.userBubble,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(5),
                ),
              ),
              child: Text(msg.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.55,
                )),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: C.userBubble,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(Icons.person_rounded,
                size: 15, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatMsg msg;
  final bool isLast;
  final VoidCallback? onRetry;

  const _AiBubble({
    required this.msg,
    required this.isLast,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: C.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('IT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              )),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: msg.isError
                      ? C.err.withOpacity(0.06)
                      : C.aiBubble,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: msg.isError
                        ? C.err.withOpacity(0.2)
                        : msg.isStreaming
                            ? C.blue.withOpacity(0.15)
                            : C.border,
                  ),
                ),
                child: _buildContent(),
              ),
              if (msg.isDone && isLast && msg.content.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 2),
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: msg.content));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(_buildSnack('Copiado'));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: C.bgSoft,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: C.border),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 11, color: C.textS),
                          SizedBox(width: 4),
                          Text('Copiar',
                            style: TextStyle(
                                fontSize: 11, color: C.textS)),
                        ]),
                    ),
                  ),
                ),
              if (msg.isError && onRetry != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: C.err.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: C.err.withOpacity(0.2)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded,
                              size: 11, color: C.err),
                          SizedBox(width: 4),
                          Text('Reintentar',
                            style: TextStyle(
                                fontSize: 11, color: C.err)),
                        ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (msg.isStreaming && msg.content.isEmpty) return const _Typing();

    if (msg.isError) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 15, color: C.err),
        const SizedBox(width: 8),
        Flexible(
          child: Text(msg.content,
            style: const TextStyle(
                fontSize: 13, color: C.err, height: 1.5)),
        ),
      ]);
    }

    return MarkdownBody(
      data: msg.content,
      selectable: true,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
            fontSize: 14, color: C.textP, height: 1.65),
        h1: const TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: C.textP),
        h2: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: C.textP),
        h3: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: C.blue),
        strong: const TextStyle(
            fontWeight: FontWeight.w700, color: C.textP),
        em: const TextStyle(
            fontStyle: FontStyle.italic, color: C.textS),
        code: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          color: C.blue,
          backgroundColor: Color(0xFFEEF2FF),
        ),
        codeblockDecoration: BoxDecoration(
          color: C.bgSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.border),
        ),
        codeblockPadding: const EdgeInsets.all(14),
        blockquoteDecoration: BoxDecoration(
          border: Border(
              left: BorderSide(color: C.blue, width: 3)),
        ),
        blockquotePadding: const EdgeInsets.only(
            left: 12, top: 4, bottom: 4),
        blockquote: const TextStyle(
            color: C.textS, fontStyle: FontStyle.italic),
        listBullet: const TextStyle(color: C.blue),
        tableHead: const TextStyle(
            fontWeight: FontWeight.w700, color: C.textP),
        tableBody: const TextStyle(color: C.textS),
        tableBorder: TableBorder.all(color: C.border),
      ),
    );
  }
}

// ─── Typing ───────────────────────────────────────────────────────────────

class _Typing extends StatefulWidget {
  const _Typing();
  @override
  State<_Typing> createState() => _TypingState();
}

class _TypingState extends State<_Typing> with TickerProviderStateMixin {
  late final List<AnimationController> _cs;
  late final List<Animation<double>> _as;

  @override
  void initState() {
    super.initState();
    _cs = List.generate(3, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600)));
    _as = _cs.map((c) => Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    _start();
  }

  void _start() async {
    for (int i = 0; i < _cs.length; i++) {
      await Future.delayed(Duration(milliseconds: i * 160));
      if (mounted) _cs[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _cs) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('Pensando',
        style: TextStyle(fontSize: 12, color: C.textM)),
      const SizedBox(width: 8),
      ...List.generate(3, (i) => Padding(
        padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
        child: AnimatedBuilder(
          animation: _as[i],
          builder: (_, __) => Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.blue.withOpacity(_as[i].value),
            ),
          ),
        ),
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INPUT BAR
// ═══════════════════════════════════════════════════════════════════════════

class _InputBar extends StatefulWidget {
  final bool enabled;
  final void Function(String) onSend;

  const _InputBar({required this.enabled, required this.onSend});
  @override
  State<_InputBar> createState() => _InputBarState();
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
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

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
        border: Border(top: BorderSide(color: C.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        14, 10, 14,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 130),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: C.bgSoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _focus.hasFocus ? C.blue : C.border,
                  width: _focus.hasFocus ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                enabled: widget.enabled,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    fontSize: 15, color: C.textP, height: 1.5),
                decoration: InputDecoration(
                  hintText: widget.enabled
                      ? 'Escribe tu pregunta…'
                      : 'Buscando respuesta…',
                  hintStyle: const TextStyle(
                      color: C.textM, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                ),
                onSubmitted: widget.enabled ? (_) => _send() : null,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (widget.enabled && _has) ? C.blue : C.bgInput,
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: (widget.enabled && _has) ? _send : null,
              customBorder: const CircleBorder(),
              child: Center(
                child: !widget.enabled
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(C.blue),
                        ),
                      )
                    : Icon(
                        Icons.arrow_upward_rounded,
                        size: 20,
                        color: (widget.enabled && _has)
                            ? Colors.white
                            : C.textM,
                      ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  bool get busy => !widget.enabled;
}

// ═══════════════════════════════════════════════════════════════════════════
// RENAME DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _RenameDialog extends StatelessWidget {
  final TextEditingController ctrl;
  const _RenameDialog({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: C.bg,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      title: const Text('Renombrar',
        style: TextStyle(
          color: C.textP, fontSize: 17, fontWeight: FontWeight.w700)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(color: C.textP),
        decoration: InputDecoration(
          hintText: 'Ej: Dudas sobre el examen…',
          hintStyle: const TextStyle(color: C.textM),
          filled: true,
          fillColor: C.bgSoft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: C.blue, width: 1.5),
          ),
        ),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar',
              style: TextStyle(color: C.textS)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, ctrl.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════════════════

SnackBar _buildSnack(String t) => SnackBar(
  content: Row(children: [
    const Icon(Icons.check_circle_rounded, size: 15, color: C.ok),
    const SizedBox(width: 8),
    Text(t, style: const TextStyle(fontSize: 13, color: C.textP)),
  ]),
  backgroundColor: C.bg,
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12)),
  margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
  duration: const Duration(seconds: 2),
);