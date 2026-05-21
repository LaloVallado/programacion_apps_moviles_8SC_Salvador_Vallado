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
// FUENTES DE RÚBRICA Y ESTÁNDARES (referencias reales y públicas):
//   - Método STAR (Situation, Task, Action, Result): Amazon, Google, Microsoft
//   - SHRM (Society for Human Resource Management)
//   - WEF Future of Jobs Report 2023
//   - LinkedIn Talent Solutions México 2024
//   - OCC Mundial — Guías de preparación para entrevistas en México
//   - Amazon 16 Leadership Principles (publico en amazon.jobs)
//   - Google — How We Hire (re:Work Google)
//   - Meta Careers — Interview Tips
//   - Microsoft — Growth Mindset Interview Culture
//   - Glassdoor México — Top Interview Questions 2024
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
// CONFIGURACIÓN — API key y modelos (NO TOCAR)
// =============================================================================
const String _geminiApiKey = 'AIzaSyCKgjN0u2UyZIrO-EvFCAdg6cJ5hKucrUs';

const List<String> _geminiModels = [
  'gemini-2.0-flash-lite',
  'gemini-2.0-flash',
  'gemini-2.5-flash-lite',
  'gemini-2.5-flash',
  'gemini-1.5-flash-latest',
];

// =============================================================================
// PALETA — Azul / Blanco / Negro · iOS Dark Mode System
// =============================================================================
class AppColors {
  // ── Fondos en capas (iOS layered system) ──────────────────────────────────
  static const bg          = Color(0xFF000000);  // System background
  static const bgElev      = Color(0xFF0C0C0E);  // Elevated background
  static const card        = Color(0xFF1C1C1E);  // Card surface
  static const cardElev    = Color(0xFF2C2C2E);  // Elevated card
  static const border      = Color(0xFF38383A);  // Separator

  // ── Texto (iOS label system) ───────────────────────────────────────────────
  static const textPrimary   = Color(0xFFFFFFFF);  // Label
  static const textSecondary = Color(0xFF8E8E93);  // Secondary label
  static const textTertiary  = Color(0xFF48484A);  // Tertiary label
  static const textQuaternary= Color(0xFF3A3A3C);  // Quaternary label

  // ── Azul principal iOS dark mode ─────────────────────────────────────────
  static const blue      = Color(0xFF0A84FF);
  static const blueDeep  = Color(0xFF0055FF);
  static const indigo    = Color(0xFF5856D6);
  static const blueLight = Color(0xFF64B5FF);

  // ── Sistema de colores (iOS system colors dark) ───────────────────────────
  static const green    = Color(0xFF32D74B);
  static const yellow   = Color(0xFFFFD60A);
  static const orange   = Color(0xFFFF9F0A);
  static const red      = Color(0xFFFF453A);
  static const pink     = Color(0xFFFF375F);
  static const teal     = Color(0xFF40C8E0);
  static const purple   = Color(0xFFBF5AF2);
  static const cyan     = Color(0xFF32ADE6);

  // ── Colores semánticos ────────────────────────────────────────────────────
  static const success  = green;
  static const warning  = orange;
  static const danger   = red;
  static const info     = blue;

  // ── Gradientes frecuentes ─────────────────────────────────────────────────
  static const List<Color> primaryGrad   = [blue, indigo];
  static const List<Color> successGrad   = [green, teal];
  static const List<Color> dangerGrad    = [red, pink];
  static const List<Color> neutralGrad   = [card, cardElev];
}

// =============================================================================
// TIPOGRAFÍA — SF Pro Display
// =============================================================================
class AppText {
  static const String fontFamily = '.SF Pro Display';

  static const TextStyle largeTitle = TextStyle(fontFamily: fontFamily,
      fontSize: 34, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -0.5, height: 1.1);
  static const TextStyle title1 = TextStyle(fontFamily: fontFamily,
      fontSize: 28, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -0.3, height: 1.15);
  static const TextStyle title2 = TextStyle(fontFamily: fontFamily,
      fontSize: 22, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, letterSpacing: -0.2);
  static const TextStyle title3 = TextStyle(fontFamily: fontFamily,
      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle headline = TextStyle(fontFamily: fontFamily,
      fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(fontFamily: fontFamily,
      fontSize: 16, fontWeight: FontWeight.w400,
      color: AppColors.textPrimary, height: 1.45);
  static const TextStyle bodySecondary = TextStyle(fontFamily: fontFamily,
      fontSize: 16, fontWeight: FontWeight.w400,
      color: AppColors.textSecondary, height: 1.45);
  static const TextStyle callout = TextStyle(fontFamily: fontFamily,
      fontSize: 15, fontWeight: FontWeight.w400,
      color: AppColors.textPrimary, height: 1.4);
  static const TextStyle subhead = TextStyle(fontFamily: fontFamily,
      fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
  static const TextStyle footnote = TextStyle(fontFamily: fontFamily,
      fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle caption = TextStyle(fontFamily: fontFamily,
      fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle caption2 = TextStyle(fontFamily: fontFamily,
      fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle eyebrow = TextStyle(fontFamily: fontFamily,
      fontSize: 11, fontWeight: FontWeight.w600,
      color: AppColors.textTertiary, letterSpacing: 1.4);
  static const TextStyle button = TextStyle(fontFamily: fontFamily,
      fontSize: 17, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary, letterSpacing: -0.1);
  static const TextStyle numericLarge = TextStyle(fontFamily: fontFamily,
      fontSize: 48, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: -2);
}

// =============================================================================
// ÍCONOS SVG PERSONALIZADOS — CustomPainter
// =============================================================================

/// Ícono de estrella llena (para ratings y logros)
class _StarPainter extends CustomPainter {
  final Color color;
  const _StarPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.42;
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (i * math.pi / 5) - math.pi / 2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _StarPainter o) => o.color != color;
}

/// Ícono de rayo / energía
class _BoltPainter extends CustomPainter {
  final Color color;
  const _BoltPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.6, 0);
    path.lineTo(w * 0.15, h * 0.52);
    path.lineTo(w * 0.45, h * 0.52);
    path.lineTo(w * 0.4, h);
    path.lineTo(w * 0.85, h * 0.48);
    path.lineTo(w * 0.55, h * 0.48);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant _BoltPainter o) => o.color != color;
}

/// Ícono de cerebro simplificado
class _BrainPainter extends CustomPainter {
  final Color color;
  const _BrainPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Lóbulo izquierdo
    canvas.drawArc(Rect.fromCircle(center: Offset(cx * 0.55, cy * 0.8),
        radius: cx * 0.55), math.pi * 0.8, math.pi * 1.4, false, paint);
    // Lóbulo derecho
    canvas.drawArc(Rect.fromCircle(center: Offset(cx * 1.45, cy * 0.8),
        radius: cx * 0.55), math.pi * 1.8, math.pi * 1.4, false, paint);
    // División central
    canvas.drawLine(Offset(cx, cy * 0.2), Offset(cx, cy * 1.6), paint);
  }
  @override
  bool shouldRepaint(covariant _BrainPainter o) => o.color != color;
}

/// Ícono de gráfica de crecimiento / tendencia
class _TrendPainter extends CustomPainter {
  final Color color;
  const _TrendPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w * 0.05, h * 0.85);
    path.lineTo(w * 0.3, h * 0.55);
    path.lineTo(w * 0.55, h * 0.65);
    path.lineTo(w * 0.95, h * 0.12);
    canvas.drawPath(path, paint);
    // Flecha al final
    final arrowPaint = Paint()..color = color..style = PaintingStyle.fill;
    final arrow = Path();
    arrow.moveTo(w * 0.95, h * 0.12);
    arrow.lineTo(w * 0.78, h * 0.08);
    arrow.lineTo(w * 0.88, h * 0.28);
    arrow.close();
    canvas.drawPath(arrow, arrowPaint);
  }
  @override
  bool shouldRepaint(covariant _TrendPainter o) => o.color != color;
}

/// Ícono de medalla
class _MedalPainter extends CustomPainter {
  final Color color;
  const _MedalPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    // Cinta izquierda
    final ribbonL = Path();
    ribbonL.moveTo(size.width * 0.3, 0);
    ribbonL.lineTo(size.width * 0.5, size.height * 0.28);
    ribbonL.lineTo(size.width * 0.35, size.height * 0.38);
    ribbonL.lineTo(size.width * 0.15, size.height * 0.1);
    ribbonL.close();
    canvas.drawPath(ribbonL, Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill);
    // Cinta derecha
    final ribbonR = Path();
    ribbonR.moveTo(size.width * 0.7, 0);
    ribbonR.lineTo(size.width * 0.5, size.height * 0.28);
    ribbonR.lineTo(size.width * 0.65, size.height * 0.38);
    ribbonR.lineTo(size.width * 0.85, size.height * 0.1);
    ribbonR.close();
    canvas.drawPath(ribbonR, Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill);
    // Círculo medalla
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.7),
        size.width * 0.32, paint);
    // Número interior
    final inner = Paint()..color = AppColors.bg..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.7),
        size.width * 0.22, inner);
  }
  @override
  bool shouldRepaint(covariant _MedalPainter o) => o.color != color;
}

/// Ícono de mira / target
class _TargetPainter extends CustomPainter {
  final Color color;
  const _TargetPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rings = [size.width / 2, size.width * 0.35, size.width * 0.2];
    for (int i = 0; i < rings.length; i++) {
      canvas.drawCircle(
        Offset(cx, cy), rings[i],
        Paint()
          ..color = i.isEven ? color : color.withOpacity(0.2)
          ..style = i.isEven ? PaintingStyle.stroke : PaintingStyle.fill
          ..strokeWidth = size.width * 0.06,
      );
    }
    canvas.drawCircle(Offset(cx, cy), size.width * 0.08,
        Paint()..color = color..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant _TargetPainter o) => o.color != color;
}

/// Widget genérico para íconos SVG pintados
class SvgIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;
  const SvgIcon({super.key, required this.painter, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: painter,
      size: Size(size, size),
    );
  }
}

// =============================================================================
// MODELOS DE DATOS
// =============================================================================
enum ChatRole { user, ai }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  ChatMessage({required this.role, required this.text, required this.timestamp});
  Map<String, dynamic> toJson() =>
      {'role': role.name, 'text': text, 'timestamp': timestamp.toIso8601String()};
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        role: ChatRole.values.firstWhere((r) => r.name == j['role']),
        text: j['text'] as String,
        timestamp: DateTime.parse(j['timestamp'] as String),
      );
}

class JobRole {
  final String id, title, subtitle;
  final IconData icon;
  final Color accent;
  const JobRole({required this.id, required this.title, required this.subtitle,
      required this.icon, required this.accent});
}

class SeniorityLevel {
  final String id, label, description;
  const SeniorityLevel({required this.id, required this.label, required this.description});
}

/// Preset de empresa — personaliza el contexto de la entrevista
class CompanyPreset {
  final String id;
  final String name;
  final String subtitle;
  final String flagEmoji;
  final Color accent;
  final String interviewStyle;       // descripción breve del estilo
  final List<String> keyPrinciples;  // valores/principios clave
  final List<String> commonQuestions;
  final String tip;

  const CompanyPreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.flagEmoji,
    required this.accent,
    required this.interviewStyle,
    required this.keyPrinciples,
    required this.commonQuestions,
    required this.tip,
  });
}

/// Tipo de entrevista
class InterviewType {
  final String id, label, description;
  final IconData icon;
  final Color color;
  const InterviewType({required this.id, required this.label,
      required this.description, required this.icon, required this.color});
}

/// Estándar profesional de entrevistas
class StandardInfo {
  final String id, name, org, description;
  final List<String> dimensions;
  final List<String> tips;
  final String source;
  const StandardInfo({required this.id, required this.name, required this.org,
      required this.description, required this.dimensions,
      required this.tips, required this.source});
}

/// Tip rápido de entrevista
class QuickTip {
  final String id, category, title, body;
  final IconData icon;
  final Color color;
  const QuickTip({required this.id, required this.category,
      required this.title, required this.body,
      required this.icon, required this.color});
}

class InterviewSession {
  final String id, roleId, roleTitle, seniorityLabel, mode;
  final String? companyPresetId;
  final String? interviewTypeId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final FeedbackResult? feedback;

  InterviewSession({
    required this.id, required this.roleId, required this.roleTitle,
    required this.seniorityLabel, required this.mode,
    this.companyPresetId, this.interviewTypeId,
    required this.messages, required this.createdAt, this.feedback,
  });

  Map<String, dynamic> toJson() => {
        'id': id, 'roleId': roleId, 'roleTitle': roleTitle,
        'seniorityLabel': seniorityLabel, 'mode': mode,
        'companyPresetId': companyPresetId,
        'interviewTypeId': interviewTypeId,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'feedback': feedback?.toJson(),
      };

  factory InterviewSession.fromJson(Map<String, dynamic> j) => InterviewSession(
        id: j['id'] as String, roleId: j['roleId'] as String,
        roleTitle: j['roleTitle'] as String,
        seniorityLabel: j['seniorityLabel'] as String,
        mode: j['mode'] as String,
        companyPresetId: j['companyPresetId'] as String?,
        interviewTypeId: j['interviewTypeId'] as String?,
        messages: (j['messages'] as List).map((m) => ChatMessage.fromJson(m)).toList(),
        createdAt: DateTime.parse(j['createdAt'] as String),
        feedback: j['feedback'] == null
            ? null
            : FeedbackResult.fromJson(j['feedback'] as Map<String, dynamic>),
      );
}

class FeedbackResult {
  final double scoreOverall;
  final Map<String, double> dimensions;
  final List<String> strengths, improvements;
  final String summary;

  FeedbackResult({required this.scoreOverall, required this.dimensions,
      required this.strengths, required this.improvements, required this.summary});

  Map<String, dynamic> toJson() => {
        'scoreOverall': scoreOverall, 'dimensions': dimensions,
        'strengths': strengths, 'improvements': improvements, 'summary': summary,
      };

  factory FeedbackResult.fromJson(Map<String, dynamic> j) => FeedbackResult(
        scoreOverall: (j['scoreOverall'] as num).toDouble(),
        dimensions: (j['dimensions'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        strengths: List<String>.from(j['strengths'] as List),
        improvements: List<String>.from(j['improvements'] as List),
        summary: j['summary'] as String,
      );
}

// =============================================================================
// CONSTANTES — PUESTOS (12 roles)
// =============================================================================
const List<JobRole> kJobRoles = [
  JobRole(id: 'dev',   title: 'Desarrollador',    subtitle: 'Frontend / Backend / Full-stack',
      icon: CupertinoIcons.chevron_left_slash_chevron_right, accent: AppColors.blue),
  JobRole(id: 'ux',    title: 'Diseñador UX/UI',  subtitle: 'Producto y experiencia',
      icon: CupertinoIcons.paintbrush_fill,                  accent: AppColors.indigo),
  JobRole(id: 'mkt',   title: 'Marketing Digital', subtitle: 'Performance y contenido',
      icon: CupertinoIcons.chart_bar_alt_fill,               accent: AppColors.blue),
  JobRole(id: 'sales', title: 'Ventas',            subtitle: 'B2B / B2C',
      icon: CupertinoIcons.person_2_fill,                    accent: AppColors.indigo),
  JobRole(id: 'data',  title: 'Analista de Datos', subtitle: 'BI, dashboards, SQL',
      icon: CupertinoIcons.graph_circle_fill,                accent: AppColors.blue),
  JobRole(id: 'pm',    title: 'Project Manager',   subtitle: 'Gestión de proyectos',
      icon: CupertinoIcons.briefcase_fill,                   accent: AppColors.indigo),
  JobRole(id: 'qa',    title: 'QA / Testing',      subtitle: 'Calidad de software',
      icon: CupertinoIcons.checkmark_shield_fill,            accent: AppColors.blue),
  JobRole(id: 'devops',title: 'DevOps / SRE',      subtitle: 'Infraestructura y CI/CD',
      icon: CupertinoIcons.cloud_fill,                       accent: AppColors.indigo),
  JobRole(id: 'cs',    title: 'Customer Success',  subtitle: 'Retención y onboarding',
      icon: CupertinoIcons.star_fill,                        accent: AppColors.blue),
  JobRole(id: 'fin',   title: 'Finanzas',          subtitle: 'Análisis y planeación',
      icon: CupertinoIcons.money_dollar_circle_fill,         accent: AppColors.indigo),
  JobRole(id: 'hr',    title: 'Recursos Humanos',  subtitle: 'Talento y cultura',
      icon: CupertinoIcons.person_crop_circle_fill_badge_checkmark, accent: AppColors.blue),
  JobRole(id: 'op',    title: 'Operaciones',       subtitle: 'Logística y procesos',
      icon: CupertinoIcons.gear_alt_fill,                    accent: AppColors.indigo),
];

const List<SeniorityLevel> kSeniority = [
  SeniorityLevel(id: 'junior', label: 'Junior',   description: '0–2 años'),
  SeniorityLevel(id: 'mid',    label: 'Mid',       description: '2–5 años'),
  SeniorityLevel(id: 'senior', label: 'Senior',    description: '5+ años'),
];

// =============================================================================
// CONSTANTES — PRESETS DE EMPRESA
// =============================================================================
const List<CompanyPreset> kCompanyPresets = [
  CompanyPreset(
    id: 'generic',
    name: 'General',
    subtitle: 'Entrevista estándar',
    flagEmoji: '🌐',
    accent: AppColors.blue,
    interviewStyle:
        'Entrevista balanceada con preguntas conductuales, técnicas y de motivación.',
    keyPrinciples: [
      'Comunicación clara', 'Trabajo en equipo', 'Resolución de problemas',
      'Adaptabilidad', 'Orientación a resultados',
    ],
    commonQuestions: [
      '¿Por qué quieres este puesto?',
      'Cuéntame sobre ti.',
      'Describe tu mayor logro.',
      '¿Dónde te ves en 5 años?',
      '¿Cuál es tu mayor debilidad?',
    ],
    tip: 'Usa el método STAR para tus respuestas conductuales.',
  ),
  CompanyPreset(
    id: 'amazon',
    name: 'Amazon',
    subtitle: 'FAANG · Bar Raiser',
    flagEmoji: '🇺🇸',
    accent: AppColors.orange,
    interviewStyle:
        'Entrevista basada en los 16 Principios de Liderazgo. El entrevistador evalúa '
        '"bar-raising" — si elevas el nivel del equipo. Cada respuesta DEBE mapear '
        'a un principio específico.',
    keyPrinciples: [
      'Customer Obsession — El cliente primero, siempre',
      'Ownership — Actúa como dueño, no como empleado',
      'Invent and Simplify — Innova y busca soluciones simples',
      'Dive Deep — Conoce los detalles de tu trabajo',
      'Deliver Results — Los resultados importan, sin excusas',
      'Bias for Action — Velocidad importa, los errores se pueden corregir',
      'Earn Trust — Sé honesto aunque duela',
    ],
    commonQuestions: [
      'Tell me about a time you took ownership of a problem (Ownership).',
      'Describe a situation where you had to disagree with your manager (Earn Trust).',
      'Give an example of a time you simplified a complex process (Invent & Simplify).',
      'Tell me about the most challenging customer experience (Customer Obsession).',
      'Describe a time you failed and what you learned (Learn and Be Curious).',
    ],
    tip:
        'Amazon usa el método STAR estrictamente. Cada historia debe tener Situación, '
        'Tarea, Acción (detallada) y Resultado cuantificado. Prepara 2+ historias por principio.',
  ),
  CompanyPreset(
    id: 'google',
    name: 'Google',
    subtitle: 'FAANG · re:Work',
    flagEmoji: '🇺🇸',
    accent: AppColors.blue,
    interviewStyle:
        'Google evalúa 4 dimensiones: Habilidad General Cognitiva, Liderazgo, '
        'Conocimiento del Rol y "Googleyness" (comodidad con ambigüedad, '
        'humildad, empuje). El método re:Work define preguntas conductuales '
        'estructuradas y no puzzles de lógica.',
    keyPrinciples: [
      'Cognitive Ability — Aprende rápido, resuelve problemas nuevos',
      'Leadership — Lidera sin autoridad formal',
      'Role-related Knowledge — Expertise técnico relevante',
      'Googleyness — Disfruta la ambigüedad, colabora, tiene valores',
    ],
    commonQuestions: [
      '¿Cuéntame sobre un proyecto en el que tuviste que aprender algo rápido?',
      '¿Cómo manejaste un conflicto en equipo sin tener autoridad formal?',
      '¿Describe una situación donde la solución obvia resultó equivocada?',
      '¿Cómo priorizas cuando todo es urgente?',
      '¿Qué harías en tus primeros 90 días en este rol?',
    ],
    tip:
        'Google valora mucho el aprendizaje sobre el fracaso. Habla abiertamente '
        'de errores y lo que aprendiste. Usa datos y métricas en tus respuestas '
        'siempre que puedas.',
  ),
  CompanyPreset(
    id: 'meta',
    name: 'Meta',
    subtitle: 'FAANG · Move Fast',
    flagEmoji: '🇺🇸',
    accent: AppColors.indigo,
    interviewStyle:
        'Meta evalúa impacto a escala, velocidad de ejecución y colaboración '
        'radical. Usa "Craftsmanship" para roles técnicos. Valora el fracaso '
        'rápido y aprendizaje ágil sobre la perfección.',
    keyPrinciples: [
      'Move Fast — Actúa con velocidad, itera',
      'Be Bold — Toma riesgos calculados',
      'Focus on Impact — Mide todo en escala e impacto real',
      'Be Open — Transparencia radical',
      'Build Social Value — El producto conecta personas',
    ],
    commonQuestions: [
      '¿Cuéntame sobre un proyecto que tuvo impacto a gran escala?',
      '¿Cómo decides qué no hacer cuando tienes muchas prioridades?',
      '¿Describe una decisión que tomaste rápido con información incompleta?',
      '¿Cómo mides el éxito de tu trabajo?',
      '¿Qué construirías si no pudieras fallar?',
    ],
    tip:
        'Meta ama los números. Por cada logro: ¿cuántos usuarios impactó? '
        '¿Cuánto % mejoró la métrica? Habla de datos, no solo de acciones.',
  ),
  CompanyPreset(
    id: 'microsoft',
    name: 'Microsoft',
    subtitle: 'FAANG · Growth Mindset',
    flagEmoji: '🇺🇸',
    accent: AppColors.teal,
    interviewStyle:
        'Satya Nadella transformó Microsoft con el concepto de Growth Mindset '
        '(Carol Dweck). Buscan personas que aprenden de errores, no las que '
        'siempre tienen razón. Cultura Model-Coach-Care para líderes.',
    keyPrinciples: [
      'Growth Mindset — El talento se desarrolla, no es fijo',
      'Model — Predica con el ejemplo',
      'Coach — Desarrolla a tu equipo',
      'Care — Muestra interés genuino en las personas',
      'Clarity — Crea claridad en la ambigüedad',
      'Energy — Energiza a otros',
    ],
    commonQuestions: [
      '¿Cuéntame sobre una vez que cambiaste de opinión sobre algo importante?',
      '¿Cómo has desarrollado a alguien de tu equipo?',
      '¿Describe una situación donde fallaste y cómo lo convertiste en aprendizaje?',
      '¿Cómo creas claridad cuando los requerimientos son ambiguos?',
      '¿Qué harías diferente si pudieras repetir tu rol anterior?',
    ],
    tip:
        'Microsoft valora la vulnerabilidad intelectual. No tengas miedo de '
        'decir "me equivoqué" o "no sé, pero así lo aprendería". '
        'Eso es exactamente lo que buscan.',
  ),
  CompanyPreset(
    id: 'startup_mx',
    name: 'Startup MX',
    subtitle: 'Kavak · Clip · Bitso · Konfío',
    flagEmoji: '🇲🇽',
    accent: AppColors.green,
    interviewStyle:
        'Las startups mexicanas unicornio buscan "founders mentality": '
        'ownership extremo, tolerancia alta a la ambigüedad y velocidad sobre '
        'perfección. Cultura muy similar a Silicon Valley pero con contexto MX.',
    keyPrinciples: [
      'Ownership — Nadie te dice qué hacer, tú lo defines',
      'Velocidad — Done > Perfect',
      'Datos — Cada decisión basada en métricas',
      'Usuario MX — Entiende al usuario mexicano profundamente',
      'Escalabilidad — Piensa en millones, no en miles',
    ],
    commonQuestions: [
      '¿Qué proyecto construiste desde cero sin que nadie te lo pidiera?',
      '¿Cómo decides si lanzar algo imperfecto o esperar?',
      '¿Cuál es el mayor problema no resuelto en tu industria en México?',
      '¿Cómo priorizas sin un roadmap claro?',
      '¿Describe un momento en que moviste una métrica clave de negocio?',
    ],
    tip:
        'En startups MX importa mucho que conozcas el contexto local: '
        'bancarización, OXXO como canal, CFDI, SAT, etc. '
        'Muestra que entiendes el México real.',
  ),
  CompanyPreset(
    id: 'femsa',
    name: 'FEMSA / OXXO',
    subtitle: 'Corporativo MX · Top Employer',
    flagEmoji: '🇲🇽',
    accent: AppColors.red,
    interviewStyle:
        'FEMSA (OXXO, Coca-Cola FEMSA, Heineken MX) usa entrevistas por '
        'competencias basadas en su modelo "Liderazgo FEMSA". Valoran '
        'liderazgo ejecutivo, visión de negocio y desarrollo de talento.',
    keyPrinciples: [
      'Liderazgo Ejecutivo — Inspira y moviliza equipos grandes',
      'Visión de Negocio — Piensa en P&L y creación de valor',
      'Orientación al Cliente — El shopper en el centro',
      'Desarrollo de Talento — Eres responsable de crecer a tu equipo',
      'Ejecución con Excelencia — Disciplina operacional',
    ],
    commonQuestions: [
      '¿Cómo has desarrollado y retenido talento en equipos anteriores?',
      '¿Describe una decisión que impactó el P&L directamente?',
      '¿Cómo manejas la presión de resultados en entornos de alta demanda?',
      '¿Cuál ha sido tu mayor reto de liderazgo?',
      '¿Cómo desarrollas la cultura de un equipo disperso geográficamente?',
    ],
    tip:
        'FEMSA valora mucho la estabilidad y el largo plazo. '
        'Habla de permanencia en roles, proyectos de multi-año y '
        'desarrollo de personas como logros concretos.',
  ),
  CompanyPreset(
    id: 'banorte',
    name: 'Banorte',
    subtitle: 'Banca MX · Fintech',
    flagEmoji: '🇲🇽',
    accent: AppColors.blue,
    interviewStyle:
        'Banorte combina cultura bancaria tradicional con transformación '
        'digital. Valoran la gestión de riesgos, compliance y al mismo '
        'tiempo innovación en productos financieros digitales.',
    keyPrinciples: [
      'Gestión de Riesgo — Decisiones con control y compliance',
      'Transformación Digital — Fintech dentro del banco',
      'Inclusión Financiera — Bancarizar México',
      'Orientación al Cliente — NPS y satisfacción como KPI',
      'Integridad — Ética sin compromisos',
    ],
    commonQuestions: [
      '¿Cómo equilibras innovación con cumplimiento regulatorio?',
      '¿Describe un momento donde identificaste y mitigaste un riesgo operacional?',
      '¿Cómo has mejorado la experiencia digital de un cliente?',
      '¿Cuál es tu experiencia trabajando con regulaciones (CNBV, CONDUSEF)?',
      '¿Cómo presentas datos financieros complejos a audiencias no técnicas?',
    ],
    tip:
        'En banca MX el compliance es clave. Conoce CNBV, CONDUSEF y las '
        'principales regulaciones AML. Demuestra que entiendes el balance '
        'entre innovar y operar dentro del marco regulatorio.',
  ),
];

// =============================================================================
// CONSTANTES — TIPOS DE ENTREVISTA
// =============================================================================
const List<InterviewType> kInterviewTypes = [
  InterviewType(
    id: 'mixed',
    label: 'Mixta',
    description: 'Conductual + técnica + motivación. La más realista.',
    icon: CupertinoIcons.square_grid_2x2_fill,
    color: AppColors.blue,
  ),
  InterviewType(
    id: 'behavioral',
    label: 'Conductual',
    description: 'Solo preguntas STAR sobre experiencias pasadas.',
    icon: CupertinoIcons.person_fill,
    color: AppColors.indigo,
  ),
  InterviewType(
    id: 'technical',
    label: 'Técnica',
    description: 'Conocimiento del rol, herramientas y cases.',
    icon: CupertinoIcons.wrench_fill,
    color: AppColors.blue,
  ),
  InterviewType(
    id: 'hr',
    label: 'RRHH / Fit',
    description: 'Motivación, valores, cultura y expectativas.',
    icon: CupertinoIcons.heart_fill,
    color: AppColors.indigo,
  ),
];

// =============================================================================
// CONSTANTES — ESTÁNDARES PROFESIONALES DETALLADOS
// =============================================================================
const List<StandardInfo> kStandards = [
  StandardInfo(
    id: 'star',
    name: 'Método STAR',
    org: 'Amazon · Google · Microsoft',
    description:
        'El estándar global para respuestas conductuales. Cada respuesta debe '
        'describir una Situación específica, la Tarea asignada, las Acciones '
        'tomadas y los Resultados obtenidos (idealmente cuantificados).',
    dimensions: [
      'S — Situación: Contexto breve, 10–20% de la respuesta',
      'T — Tarea: Tu responsabilidad específica en esa situación',
      'A — Acción: Qué hiciste TÚ (usa "yo", no "nosotros")',
      'R — Resultado: Qué pasó, con números si es posible',
    ],
    tips: [
      'Usa "yo" en las Acciones, no "el equipo" o "nosotros"',
      'Los resultados deben ser cuantificables: %, tiempo, dinero, usuarios',
      'La Acción debe ser el 60–70% de tu respuesta',
      'Prepara 5–8 historias STAR versátiles para reutilizar',
      'Evita historias de más de 2 años sin actualizar',
    ],
    source: 'amazon.jobs, re.work (Google), Microsoft Careers',
  ),
  StandardInfo(
    id: 'shrm',
    name: 'Competencias SHRM',
    org: 'Society for Human Resource Management',
    description:
        'La SHRM define 9 competencias profesionales aplicables a cualquier '
        'industria. Son el marco más reconocido de habilidades blandas a nivel '
        'global y forman la base de miles de sistemas de evaluación.',
    dimensions: [
      'Comunicación — Transmite ideas con claridad oral y escrita',
      'Pensamiento Crítico — Analiza información para tomar decisiones',
      'Conciencia Global y Cultural — Opera en contextos diversos',
      'Liderazgo e Influencia — Inspira y moviliza personas',
      'Consulta — Provee orientación experta',
      'Ética e Integridad — Actúa con valores sólidos',
      'Agilidad de Negocio — Entiende el modelo de negocio',
      'Gestión de Relaciones — Construye y mantiene redes',
      'Gestión del Conocimiento — Aprende y comparte saber',
    ],
    tips: [
      'Mapea tus experiencias pasadas a estas competencias antes de la entrevista',
      'Los entrevistadores en RRHH conocen este modelo — úsalo como framework',
      'Demuestra consciencia cultural en entornos internacionales',
      'La comunicación escrita importa tanto como la oral en roles remotos',
    ],
    source: 'SHRM Competency Model — shrm.org/competencies',
  ),
  StandardInfo(
    id: 'wef',
    name: 'Habilidades del Futuro',
    org: 'World Economic Forum — Future of Jobs 2023',
    description:
        'El WEF publica bienalmente las habilidades más demandadas por '
        'empleadores globales. El reporte 2023 identifica las top 10 '
        'habilidades que serán críticas hasta 2027.',
    dimensions: [
      '1. Pensamiento analítico — La habilidad #1 más demandada',
      '2. Pensamiento creativo — Soluciones nuevas para problemas nuevos',
      '3. Resiliencia, flexibilidad y agilidad',
      '4. Motivación y autoconciencia',
      '5. Curiosidad y aprendizaje continuo',
      '6. Orientación tecnológica y digital',
      '7. Confiabilidad y atención al detalle',
      '8. Empatía y escucha activa',
      '9. Liderazgo e influencia social',
      '10. Gestión de la calidad y del tiempo',
    ],
    tips: [
      'Prepara ejemplos de adaptación al cambio tecnológico',
      'Muestra curiosidad genuina por aprender en la entrevista',
      'La resiliencia se demuestra con historias de fracasos superados',
      'Menciona cursos, certificaciones o proyectos personales recientes',
    ],
    source: 'World Economic Forum — Future of Jobs Report 2023',
  ),
  StandardInfo(
    id: 'linkedin_mx',
    name: 'LinkedIn Talent MX',
    org: 'LinkedIn Talent Solutions México 2024',
    description:
        'LinkedIn publica datos de los empleadores mexicanos sobre qué '
        'buscan realmente en candidatos. El reporte 2024 revela las '
        'habilidades más solicitadas en México por industria.',
    dimensions: [
      'Comunicación efectiva — #1 en todas las industrias MX',
      'Trabajo en equipo — Crítico en modelos matriciales',
      'Orientación a resultados — Medir impacto propio',
      'Adaptabilidad — Post-pandemia sigue siendo top 3',
      'Inglés profesional — Requerido en 62% de roles senior',
      'Manejo de datos — Excel/SQL básico exigido en más roles',
      'Liderazgo sin autoridad — Habilidad diferenciadora',
    ],
    tips: [
      'El 78% de reclutadores MX revisa LinkedIn antes de la entrevista',
      'Tener recomendaciones en LinkedIn aumenta 40% tu probabilidad de pasar',
      'Los skills verificados en LinkedIn son valorizados por reclutadores',
      'Personalizar tu mensaje de aplicación según la oferta incrementa 3x la respuesta',
    ],
    source: 'LinkedIn Talent Solutions — Informe MX 2024',
  ),
  StandardInfo(
    id: 'occ',
    name: 'Guía OCC Mundial',
    org: 'OCC Mundial — Portal de empleo México',
    description:
        'OCC Mundial, el portal de empleo líder en México, publica guías '
        'basadas en datos reales de miles de entrevistas realizadas en el país. '
        'Sus insights reflejan la realidad del mercado laboral mexicano.',
    dimensions: [
      'Puntualidad — En México, llegar tarde es descalificatorio',
      'Presentación personal — Apropiada al sector e industria',
      'Conocimiento de la empresa — Investigar antes es obligatorio',
      'Preguntas inteligentes — Muestra interés genuino',
      'Seguimiento post-entrevista — Thank you email en 24h',
      'Expectativa salarial — Investigar el rango del mercado',
    ],
    tips: [
      'El 91% de reclutadores MX descalifica por llegar tarde sin avisar',
      'Investiga la empresa en LinkedIn, Glassdoor y su página oficial',
      'Prepara 3 preguntas para el entrevistador (no sobre salario aún)',
      'Envía un email de seguimiento en 24h tras la entrevista',
      'El rango salarial en MX se negocia: pide 15–20% arriba de tu mínimo',
    ],
    source: 'OCC Mundial — Guías de Empleabilidad 2024',
  ),
  StandardInfo(
    id: 'glassdoor_mx',
    name: 'Glassdoor MX',
    org: 'Glassdoor — Top Questions México 2024',
    description:
        'Glassdoor recopila preguntas reales de entrevistas reportadas por '
        'candidatos. Las más frecuentes en empresas mexicanas top revelan '
        'patrones claros de evaluación.',
    dimensions: [
      'Háblame de ti — Siempre es la primera pregunta',
      '¿Por qué esta empresa? — Investiga ANTES',
      '¿Cuáles son tus fortalezas? — Cita 3 con ejemplos',
      '¿Cuáles son tus debilidades? — Di una real que estés mejorando',
      '¿Dónde te ves en 5 años? — Alinea con la empresa',
      '¿Por qué dejas tu trabajo actual? — Nunca hables mal del ex-jefe',
      '¿Cuál fue tu mayor logro? — Usa STAR con números',
      '¿Tienes preguntas para nosotros? — SIEMPRE sí',
    ],
    tips: [
      'Busca la empresa en Glassdoor para ver reviews de entrevistas reales',
      'La pregunta "háblame de ti" tiene 90 segundos ideales — practica',
      'Nunca hables mal de empleadores o compañeros anteriores',
      'Si no sabes algo técnico, di "no lo sé pero así lo investigaría"',
      'Pide retroalimentación al final si no quedaste seleccionado',
    ],
    source: 'Glassdoor.com.mx — Interview Questions Report 2024',
  ),
];

// =============================================================================
// CONSTANTES — TIPS RÁPIDOS (30 tips)
// =============================================================================
const List<QuickTip> kQuickTips = [
  QuickTip(id: 't01', category: 'Antes', icon: CupertinoIcons.search, color: AppColors.blue,
      title: 'Investiga la empresa',
      body: 'Antes de entrar revisa: misión, valores, productos, noticias recientes y '
          'reviews en Glassdoor. El 91% de los reclutadores nota si no investigaste.'),
  QuickTip(id: 't02', category: 'Antes', icon: CupertinoIcons.clock_fill, color: AppColors.indigo,
      title: 'Llega 10 minutos antes',
      body: 'Para entrevistas presenciales llega 10 min antes. Para virtuales, prueba '
          'audio/video 30 min antes. La puntualidad es señal de respeto y profesionalismo.'),
  QuickTip(id: 't03', category: 'Antes', icon: CupertinoIcons.list_bullet_below_rectangle, color: AppColors.blue,
      title: 'Prepara 5 historias STAR',
      body: 'Prepara 5 historias versátiles que cubran: liderazgo, conflicto, fracaso, '
          'logro y aprendizaje. La mayoría de preguntas conductuales caen en estas categorías.'),
  QuickTip(id: 't04', category: 'Antes', icon: CupertinoIcons.money_dollar_circle, color: AppColors.indigo,
      title: 'Investiga el rango salarial',
      body: 'Usa OCC, LinkedIn Salary, Indeed y Glassdoor para conocer el rango. '
          'Pide 15-20% arriba de tu mínimo aceptable para tener margen de negociación.'),
  QuickTip(id: 't05', category: 'Antes', icon: CupertinoIcons.person_2_fill, color: AppColors.blue,
      title: 'Revisa el perfil del entrevistador',
      body: 'Busca al entrevistador en LinkedIn. Conocer su trayectoria te da contexto '
          'y puntos de conexión que pueden romper el hielo naturalmente.'),
  QuickTip(id: 't06', category: 'Durante', icon: CupertinoIcons.mic_fill, color: AppColors.indigo,
      title: 'Habla despacio y claro',
      body: 'La nerviosidad nos hace hablar rápido. Respira antes de responder. '
          'Un segundo de pausa antes de contestar muestra que piensas.'),
  QuickTip(id: 't07', category: 'Durante', icon: CupertinoIcons.eye_fill, color: AppColors.blue,
      title: 'Mantén contacto visual',
      body: 'En presencial, mantén contacto visual natural (no fijo). '
          'En virtual, mira a la cámara, no a la pantalla, al hablar.'),
  QuickTip(id: 't08', category: 'Durante', icon: CupertinoIcons.checkmark_circle_fill, color: AppColors.indigo,
      title: 'Usa el método STAR siempre',
      body: 'Para preguntas "cuéntame de una vez que..." usa STAR. '
          'Situación (10%), Tarea (10%), Acción (60%), Resultado (20%).'),
  QuickTip(id: 't09', category: 'Durante', icon: CupertinoIcons.chart_bar_fill, color: AppColors.blue,
      title: 'Cuantifica tus logros',
      body: 'Convierte logros en números: "mejoré el proceso" → "reduje el tiempo '
          'de proceso en 30%, ahorrando 2 horas diarias al equipo de 8 personas".'),
  QuickTip(id: 't10', category: 'Durante', icon: CupertinoIcons.exclamationmark_bubble_fill, color: AppColors.indigo,
      title: 'Si no sabes, dilo bien',
      body: '"No tengo experiencia con eso, pero lo he investigado y lo aprendería '
          'haciendo X" es mejor respuesta que inventar o quedarte callado.'),
  QuickTip(id: 't11', category: 'Durante', icon: CupertinoIcons.person_fill, color: AppColors.blue,
      title: 'Háblame de ti: 90 segundos',
      body: 'Estructura: Presente (qué haces ahora), Pasado (logro relevante), '
          'Futuro (por qué este rol). Practica hasta que fluya natural.'),
  QuickTip(id: 't12', category: 'Durante', icon: CupertinoIcons.heart_fill, color: AppColors.indigo,
      title: 'Demuestra entusiasmo genuino',
      body: 'Los reclutadores detectan el entusiasmo fabricado. Investiga algo '
          'específico que te emocione de la empresa y menciónalo con sinceridad.'),
  QuickTip(id: 't13', category: 'Errores', icon: CupertinoIcons.xmark_circle_fill, color: AppColors.red,
      title: 'No hables mal del ex-jefe',
      body: 'Nunca, bajo ninguna circunstancia, hables mal de empleadores anteriores. '
          'Da razones positivas para cambiar: crecimiento, nuevos retos, alineación.'),
  QuickTip(id: 't14', category: 'Errores', icon: CupertinoIcons.xmark_circle_fill, color: AppColors.red,
      title: 'No interrumpas al entrevistador',
      body: 'Escucha la pregunta completa antes de responder. Interrumpir es señal '
          'de que no escuchas activamente — una de las competencias más valoradas.'),
  QuickTip(id: 't15', category: 'Errores', icon: CupertinoIcons.xmark_circle_fill, color: AppColors.red,
      title: 'No seas demasiado genérico',
      body: '"Soy muy trabajador y detallista" no dice nada. Cada afirmación '
          'necesita una historia o ejemplo concreto que la respalde.'),
  QuickTip(id: 't16', category: 'Errores', icon: CupertinoIcons.xmark_circle_fill, color: AppColors.red,
      title: 'No preguntes por salario primero',
      body: 'En la primera entrevista no preguntes por salario, beneficios ni '
          'vacaciones. Espera que ellos lo mencionen o hazlo en la segunda ronda.'),
  QuickTip(id: 't17', category: 'Preguntas que tú haces', icon: CupertinoIcons.question_circle_fill, color: AppColors.blue,
      title: '¿Cómo es el éxito en 90 días?',
      body: 'Pregunta: "¿Qué esperas que logre en mis primeros 90 días?" '
          'Muestra iniciativa y que quieres saber cómo evaluarán tu desempeño.'),
  QuickTip(id: 't18', category: 'Preguntas que tú haces', icon: CupertinoIcons.question_circle_fill, color: AppColors.indigo,
      title: '¿Qué retos enfrenta el equipo?',
      body: 'Pregunta sobre los principales desafíos que enfrenta el equipo ahora. '
          'Muestra pensamiento estratégico y que no tienes miedo de los retos.'),
  QuickTip(id: 't19', category: 'Preguntas que tú haces', icon: CupertinoIcons.question_circle_fill, color: AppColors.blue,
      title: '¿Cómo es la cultura del equipo?',
      body: 'Pregunta: "¿Cómo describirías la cultura del equipo?" '
          'Evalúa si el ambiente se alinea con lo que buscas y muestra interés en el fit.'),
  QuickTip(id: 't20', category: 'Preguntas que tú haces', icon: CupertinoIcons.question_circle_fill, color: AppColors.indigo,
      title: '¿Qué oportunidades de crecimiento hay?',
      body: 'Pregunta sobre planes de desarrollo, mentoring y crecimiento. '
          'Muestra ambición positiva y que piensas en el largo plazo.'),
  QuickTip(id: 't21', category: 'Voz', icon: CupertinoIcons.waveform, color: AppColors.blue,
      title: 'Tono de voz importa 38%',
      body: 'Según Mehrabian (UCLA), el 38% del impacto en comunicación viene '
          'del tono de voz. Habla con convicción, varía el ritmo y enfatiza logros.'),
  QuickTip(id: 't22', category: 'Voz', icon: CupertinoIcons.waveform, color: AppColors.indigo,
      title: 'Pausa estratégica',
      body: 'Antes de responder una pregunta difícil di: "Buena pregunta, déjame '
          'pensar un momento". Pausa 3 segundos. Se ve como reflexivo, no como '
          'confundido.'),
  QuickTip(id: 't23', category: 'Voz', icon: CupertinoIcons.waveform, color: AppColors.blue,
      title: 'Elimina las muletillas',
      body: 'Grábate respondiendo y cuenta "este", "eh", "como que", "osea". '
          'Cada muletilla reduce tu percepción de seguridad y preparación.'),
  QuickTip(id: 't24', category: 'Voz', icon: CupertinoIcons.waveform, color: AppColors.indigo,
      title: 'Cierra con fuerza',
      body: 'Al final di: "Estoy muy entusiasmado con esta oportunidad. ¿Cuáles '
          'son los próximos pasos?" Muestra interés y controla el cierre.'),
  QuickTip(id: 't25', category: 'Después', icon: CupertinoIcons.mail, color: AppColors.blue,
      title: 'Email de seguimiento en 24h',
      body: 'Envía un email en las próximas 24 horas agradeciendo el tiempo, '
          'reiterando tu interés y mencionando algo específico de la conversación.'),
  QuickTip(id: 't26', category: 'Después', icon: CupertinoIcons.star_fill, color: AppColors.indigo,
      title: 'Reflexiona y mejora',
      body: 'Anota qué preguntas te tomaron por sorpresa y prepara mejores respuestas '
          'para la próxima. Cada entrevista es práctica, no solo evaluación.'),
  QuickTip(id: 't27', category: 'Después', icon: CupertinoIcons.arrow_2_circlepath, color: AppColors.blue,
      title: 'Pide feedback si te rechazan',
      body: 'Si no quedas, escribe educadamente pidiendo retroalimentación. '
          'El 40% responde y la información es invaluable para mejorar.'),
  QuickTip(id: 't28', category: 'Negociación', icon: CupertinoIcons.money_dollar, color: AppColors.indigo,
      title: 'Negocia el paquete completo',
      body: 'El salario es solo parte: pregunta por bono, home office, capacitación, '
          'vales de despensa, seguro médico y plan de carrera. Todo suma.'),
  QuickTip(id: 't29', category: 'Negociación', icon: CupertinoIcons.money_dollar, color: AppColors.blue,
      title: 'No aceptes en el momento',
      body: 'Ante una oferta di: "Muchas gracias, me emociona mucho. '
          '¿Puedo tener hasta mañana para revisar los detalles?" Es profesional '
          'y te da tiempo de evaluar y negociar.'),
  QuickTip(id: 't30', category: 'Negociación', icon: CupertinoIcons.money_dollar, color: AppColors.indigo,
      title: 'Sé específico al negociar',
      body: '"Basado en mi investigación del mercado y mi experiencia, '
          'estaba pensando en X pesos" es más efectivo que "quiero más". '
          'Los datos te dan poder de negociación.'),
];

// =============================================================================
// SERVICIO DE GEMINI
// =============================================================================
class GeminiService {
  String? _workingModel;
  final List<Map<String, dynamic>> _history = [];
  String? _systemPrompt;

  void startInterview({
    required String roleTitle,
    required String seniority,
    required String mode,
    CompanyPreset? company,
    InterviewType? interviewType,
  }) {
    _history.clear();

    final modeContext = mode == 'voz'
        ? 'La entrevista es por LLAMADA DE VOZ. Mensajes cortos y naturales al hablar.'
        : 'La entrevista es por CHAT escrito.';

    final companyContext = company != null && company.id != 'generic'
        ? '''
Contexto de empresa: La empresa tiene el estilo de ${company.name}.
Estilo de entrevista: ${company.interviewStyle}
Principios clave que evalúan: ${company.keyPrinciples.join(', ')}.
Incorpora preguntas similares a las que usa esta empresa realmente.
'''
        : '';

    final typeContext = interviewType != null
        ? 'Tipo de entrevista: ${interviewType.label} — ${interviewType.description}'
        : '';

    _systemPrompt = '''
Eres ReclutA, una reclutadora profesional mexicana experimentada que está
entrevistando a un candidato para un puesto de $roleTitle nivel $seniority.

$modeContext
$companyContext
$typeContext

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

  Future<String> _callGemini({
    required List<Map<String, dynamic>> contents,
    String? systemInstruction,
    double temperature = 0.8,
    int maxTokens = 400,
    bool jsonMode = false,
  }) async {
    if (_geminiApiKey == 'PEGA_TU_KEY_AQUI' || _geminiApiKey.isEmpty) {
      throw Exception('No has configurado tu API key.');
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
      body['system_instruction'] = {'parts': [{'text': systemInstruction}]};
    }
    final encodedBody = jsonEncode(body);
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
            .post(url, headers: {'Content-Type': 'application/json'}, body: encodedBody)
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates == null || candidates.isEmpty) { lastError = 'Respuesta vacía'; continue; }
          final content = candidates[0]['content'] as Map<String, dynamic>?;
          final parts = content?['parts'] as List?;
          final text = parts?[0]?['text'] as String?;
          if (text != null && text.isNotEmpty) { _workingModel = model; return text; }
          lastError = 'Respuesta vacía';
          continue;
        }
        try {
          lastError = (jsonDecode(response.body))['error']?['message']?.toString()
              ?? 'Error ${response.statusCode}';
        } catch (_) { lastError = 'HTTP ${response.statusCode}'; }
        if (response.statusCode == 404 || response.statusCode == 429) continue;
        throw Exception(lastError);
      } on Exception catch (e) {
        lastError = e.toString().replaceAll('Exception: ', '');
        continue;
      }
    }
    throw Exception(lastError ?? 'No se pudo conectar a Gemini');
  }

  Future<String> openingMessage() async {
    final contents = [{'role': 'user', 'parts': [{'text': 'Comienza la entrevista.'}]}];
    final response = await _callGemini(contents: contents, systemInstruction: _systemPrompt);
    _history.add({'role': 'user', 'parts': [{'text': 'Comienza la entrevista.'}]});
    _history.add({'role': 'model', 'parts': [{'text': response}]});
    return response;
  }

  Future<String> sendMessage(String userMessage) async {
    final contents = [..._history, {'role': 'user', 'parts': [{'text': userMessage}]}];
    final response = await _callGemini(contents: contents, systemInstruction: _systemPrompt);
    _history.add({'role': 'user', 'parts': [{'text': userMessage}]});
    _history.add({'role': 'model', 'parts': [{'text': response}]});
    return response;
  }

  Future<FeedbackResult> evaluate({
    required String roleTitle,
    required String seniority,
    required List<ChatMessage> messages,
  }) async {
    final transcript = messages
        .map((m) => '${m.role == ChatRole.ai ? "RECLUTADORA" : "CANDIDATO"}: ${m.text}')
        .join('\n');
    final prompt = '''
Eres experta en reclutamiento en México. Evalúa esta entrevista simulada para
$roleTitle nivel $seniority. Evalúa SOLO al CANDIDATO:
1. CLARIDAD (0-10)
2. ESTRUCTURA STAR (0-10) — método Amazon/Google/Microsoft
3. EJEMPLOS CONCRETOS (0-10)
4. CONOCIMIENTO DEL ROL (0-10)
5. ACTITUD Y FIT (0-10) — WEF/SHRM
6. COMUNICACIÓN (0-10)
JSON exacto sin markdown:
{"scoreOverall":<0-10>,"dimensions":{"Claridad":<0-10>,"Estructura STAR":<0-10>,"Ejemplos concretos":<0-10>,"Conocimiento del rol":<0-10>,"Actitud y fit":<0-10>,"Comunicación":<0-10>},"strengths":["...","...","..."],"improvements":["...","...","..."],"summary":"2-3 oraciones"}
Sé específico. Cita ejemplos del candidato.
TRANSCRIPCIÓN:\n$transcript
''';
    var raw = await _callGemini(
      contents: [{'role': 'user', 'parts': [{'text': prompt}]}],
      temperature: 0.4, maxTokens: 1500, jsonMode: true,
    );
    raw = raw.trim();
    if (raw.startsWith('```')) {
      raw = raw.replaceFirst(RegExp(r'^```(?:json)?\s*'), '').replaceFirst(RegExp(r'\s*```\s*$'), '');
    }
    try {
  // Extraer únicamente el JSON válido
  final match = RegExp(r'[\{\｛][\s\S]*[\}\｝]').firstMatch(raw);
  if (match != null) {
    raw = match.group(0)!;
  }

  // Corregir propiedades sin comillas
  raw = raw.replaceAllMapped(
    RegExp(r'(?<=\{|,)\s*([A-Za-z0-9_]+)\s*:'),
    (m) => '"${m[1]}":',
  );

  // Corregir llaves unicode/japonesas
  raw = raw
      .replaceAll('｛', '{')
      .replaceAll('｝', '}');

  return FeedbackResult.fromJson(
    jsonDecode(raw) as Map<String, dynamic>,
  );
} catch (e) {
  throw Exception('JSON inválido: $e\nRAW:\n$raw');
}
  }

  void reset() { _history.clear(); _systemPrompt = null; }
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
      return list.map((e) => InterviewSession.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) { return []; }
  }

  Future<void> save(InterviewSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await loadAll();
    all.insert(0, session);
    await prefs.setString(_key, jsonEncode(all.map((s) => s.toJson()).toList()));
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
        colorScheme: const ColorScheme.dark(surface: AppColors.bg, primary: AppColors.blue),
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
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HistoryRepo _repo = HistoryRepo();
  List<InterviewSession> _sessions = [];
  bool _loading = true;
  late QuickTip _dailyTip;

  @override
  void initState() {
    super.initState();
    final idx = DateTime.now().day % kQuickTips.length;
    _dailyTip = kQuickTips[idx];
    _load();
  }

  Future<void> _load() async {
    final s = await _repo.loadAll();
    if (!mounted) return;
    setState(() { _sessions = s; _loading = false; });
  }

  // ── Estadísticas agregadas ─────────────────────────────────────────────────
  double get _avgScore {
    final withFeedback = _sessions.where((s) => s.feedback != null).toList();
    if (withFeedback.isEmpty) return 0;
    return withFeedback.map((s) => s.feedback!.scoreOverall).reduce((a, b) => a + b)
        / withFeedback.length;
  }

  int get _totalSessions => _sessions.length;
  int get _bestScore => _sessions
      .where((s) => s.feedback != null)
      .map((s) => s.feedback!.scoreOverall)
      .fold<double>(0, math.max)
      .round();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _GradientText(
                    'Chambita',
                    style: const TextStyle(fontFamily: AppText.fontFamily,
                        fontSize: 46, fontWeight: FontWeight.w800,
                        letterSpacing: -1.5, height: 1),
                    gradient: const LinearGradient(
                        colors: AppColors.primaryGrad,
                        begin: Alignment.centerLeft, end: Alignment.centerRight),
                  ),
                  const SizedBox(height: 4),
                  const Text('Practica entrevistas con IA', style: AppText.bodySecondary),
                ]),
              ),
              const SizedBox(width: 12),
              // Botón de tips/estándares
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const TipsScreen())),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.blue.withOpacity(0.28)),
                  ),
                  child: const Icon(CupertinoIcons.book_fill, color: AppColors.blue, size: 20),
                ),
              ),
            ]),
            const SizedBox(height: 22),

            // ── Progress banner (si hay sesiones) ───────────────────────────
            if (_sessions.isNotEmpty) ...[
              _ProgressBanner(
                sessions: _totalSessions,
                avg: _avgScore,
                best: _bestScore.toDouble(),
              ),
              const SizedBox(height: 18),
            ],

            // ── CTA principal ────────────────────────────────────────────────
            _PrimaryButton(
              label: 'Nueva entrevista',
              icon: CupertinoIcons.play_fill,
              onPressed: () async {
                final r = await Navigator.of(context).push(
                    CupertinoPageRoute(builder: (_) => const SetupScreen()));
                if (r == true) _load();
              },
            ),
            const SizedBox(height: 12),

            // ── Botones secundarios ──────────────────────────────────────────
            Row(children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Guía STAR',
                  icon: CupertinoIcons.star_fill,
                  onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const TipsScreen())),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SecondaryButton(
                  label: 'Empresas',
                  icon: CupertinoIcons.building_2_fill,
                  onPressed: () => Navigator.of(context).push(
                      CupertinoPageRoute(builder: (_) => const CompaniesScreen())),
                ),
              ),
            ]),
            const SizedBox(height: 24),

            // ── Tip del día ──────────────────────────────────────────────────
            _DailyTipCard(tip: _dailyTip),
            const SizedBox(height: 24),

            // ── Stats ────────────────────────────────────────────────────────
            const _StatsRow(),
            const SizedBox(height: 24),

            // ── Historial ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tu historial', style: AppText.title2),
                if (_sessions.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final ok = await _confirmClear(context);
                      if (ok == true) { await _repo.clearAll(); _load(); }
                    },
                    child: const Text('Limpiar', style: TextStyle(
                        fontFamily: AppText.fontFamily, fontSize: 14,
                        color: AppColors.blue, fontWeight: FontWeight.w500)),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CupertinoActivityIndicator(color: Colors.white)))
            else if (_sessions.isEmpty)
              _EmptyHistory()
            else
              ..._sessions.map((s) => _SessionCard(
                    session: s,
                    onTap: () {
                      if (s.feedback != null) {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (_) => FeedbackScreen(
                              session: s, feedback: s.feedback!, isFromHistory: true),
                        ));
                      } else {
                        Navigator.of(context).push(CupertinoPageRoute(
                          builder: (_) => TranscriptScreen(session: s),
                        ));
                      }
                    },
                  )),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmClear(BuildContext ctx) => showCupertinoDialog<bool>(
        context: ctx,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('¿Borrar todo?'),
          content: const Text('Se eliminarán todas las entrevistas guardadas.'),
          actions: [
            CupertinoDialogAction(child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(ctx, false)),
            CupertinoDialogAction(isDestructiveAction: true, child: const Text('Borrar'),
                onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
}

// ── Progress Banner ───────────────────────────────────────────────────────────
class _ProgressBanner extends StatelessWidget {
  final int sessions;
  final double avg, best;
  const _ProgressBanner({required this.sessions, required this.avg, required this.best});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF0A1628), Color(0xFF0D1F3C)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withOpacity(0.25)),
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(CupertinoIcons.chart_bar_alt_fill, color: AppColors.blue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Tu progreso', style: AppText.eyebrow),
            const SizedBox(height: 4),
            Row(children: [
              _MiniStat(val: '$sessions', label: 'sesiones'),
              const SizedBox(width: 16),
              _MiniStat(val: avg.toStringAsFixed(1), label: 'promedio'),
              const SizedBox(width: 16),
              _MiniStat(val: best.toStringAsFixed(1), label: 'mejor score'),
            ]),
          ]),
        ),
        GestureDetector(
          onTap: () {
            // Abrir stats screen
          },
          child: const Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 14),
        ),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String val, label;
  const _MiniStat({required this.val, required this.label});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(val, style: const TextStyle(fontFamily: AppText.fontFamily,
              fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.blue)),
          Text(label, style: const TextStyle(fontFamily: AppText.fontFamily,
              fontSize: 10, color: AppColors.textSecondary)),
        ],
      );
}

// ── Daily Tip Card ────────────────────────────────────────────────────────────
class _DailyTipCard extends StatelessWidget {
  final QuickTip tip;
  const _DailyTipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElev,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tip.color.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
                color: tip.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(tip.icon, color: tip.color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('TIP DEL DÍA · ${tip.category.toUpperCase()}',
                style: AppText.eyebrow.copyWith(color: tip.color)),
            Text(tip.title, style: AppText.subhead),
          ])),
        ]),
        const SizedBox(height: 10),
        Text(tip.body, style: AppText.footnote.copyWith(height: 1.5)),
      ]),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgElev,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(CupertinoIcons.chart_bar_fill, color: AppColors.blue, size: 13),
          const SizedBox(width: 6),
          Text('MERCADO LABORAL · MÉXICO',
              style: AppText.eyebrow.copyWith(color: AppColors.blue)),
        ]),
        const SizedBox(height: 12),
        const Text('Buscar chamba en México\nes un reto real.', style: AppText.title3),
        const SizedBox(height: 16),
        Row(children: const [
          Expanded(child: _StatCell(number: '46%', label: 'lo vive difícil', color: AppColors.blue)),
          SizedBox(width: 10),
          Expanded(child: _StatCell(number: '21%', label: 'tarda > 1 año', color: AppColors.indigo)),
          SizedBox(width: 10),
          Expanded(child: _StatCell(number: '38%', label: 'falta experiencia', color: AppColors.blue)),
        ]),
        const SizedBox(height: 12),
        const Text('Fuente: UVM / Laureate México 2023',
            style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 10,
                color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String number, label;
  final Color color;
  const _StatCell({required this.number, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(number, style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 22,
            fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontFamily: AppText.fontFamily,
            fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
      ]),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.bgElev, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.blue.withOpacity(0.2))),
          child: const Icon(CupertinoIcons.tray, color: AppColors.textTertiary, size: 28),
        ),
        const SizedBox(height: 14),
        const Text('Aún no tienes entrevistas', style: AppText.title3),
        const SizedBox(height: 6),
        const Text(
          'Presiona "Nueva entrevista" para\nempezar a practicar.',
          style: AppText.bodySecondary, textAlign: TextAlign.center,
        ),
      ]),
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
    final company = session.companyPresetId != null
        ? kCompanyPresets.where((c) => c.id == session.companyPresetId).firstOrNull
        : null;
    final type = session.interviewTypeId != null
        ? kInterviewTypes.where((t) => t.id == session.interviewTypeId).firstOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bgElev, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            // Score badge
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: scoreColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scoreColor.withOpacity(0.45), width: 1.5),
              ),
              child: Center(
                child: session.feedback != null
                    ? Text(score.toStringAsFixed(1), style: TextStyle(fontFamily: AppText.fontFamily,
                        fontSize: 17, fontWeight: FontWeight.w700, color: scoreColor))
                    : const Icon(CupertinoIcons.clock, color: AppColors.textTertiary, size: 20),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${session.roleTitle} · ${session.seniorityLabel}', style: AppText.title3),
                const SizedBox(height: 3),
                Row(children: [
                  Text('${session.mode == "voz" ? "Voz" : "Chat"} · ${_fmtDate(session.createdAt)}',
                      style: AppText.caption),
                  if (company != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: company.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5)),
                      child: Text('${company.flagEmoji} ${company.name}',
                          style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 10,
                              color: company.accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  if (type != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: type.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5)),
                      child: Text(type.label,
                          style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 10,
                              color: type.color, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ]),
              ]),
            ),
            const Icon(CupertinoIcons.chevron_right, color: AppColors.textTertiary, size: 14),
          ]),
        ),
      ),
    );
  }

  Color _scoreColor(double s) {
    if (s >= 8) return AppColors.green;
    if (s >= 6) return AppColors.blue;
    if (s >= 4) return AppColors.orange;
    return AppColors.red;
  }

  String _fmtDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
    return '${d.day}/${d.month}/${d.year}';
  }
}

// =============================================================================
// PANTALLA: SETUP EXTENDIDO (5 pasos)
// =============================================================================
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _roleId;
  String _seniorityId = 'junior';
  String? _mode;
  String _companyId = 'generic';
  String _typeId = 'mixed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar('Nueva entrevista', onLeading: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 120),
        children: [
          // ── Paso 1: Puesto ───────────────────────────────────────────────
          const _SetupLabel('1  Puesto'),
          ...kJobRoles.map((r) => _RoleCard(role: r, selected: _roleId == r.id,
              onTap: () => setState(() => _roleId = r.id))),

          // ── Paso 2: Nivel ────────────────────────────────────────────────
          const _SetupLabel('2  Nivel de experiencia'),
          Row(
            children: kSeniority.map((s) => Expanded(
              child: _SeniorityChip(level: s, selected: _seniorityId == s.id,
                  onTap: () => setState(() => _seniorityId = s.id)),
            )).toList(),
          ),

          // ── Paso 3: Modo ─────────────────────────────────────────────────
          const _SetupLabel('3  Modo de entrevista'),
          _ModeCard(icon: CupertinoIcons.chat_bubble_fill, title: 'Chat de texto',
              subtitle: 'Escribe tus respuestas. Más fácil para empezar.',
              selected: _mode == 'chat', onTap: () => setState(() => _mode = 'chat')),
          const SizedBox(height: 10),
          _ModeCard(icon: CupertinoIcons.phone_fill, title: 'Llamada por voz',
              subtitle: 'Habla en voz alta. Simula la presión real.',
              selected: _mode == 'voz', badge: 'NUEVO',
              onTap: () => setState(() => _mode = 'voz')),

          // ── Paso 4: Empresa ──────────────────────────────────────────────
          const _SetupLabel('4  Estilo de empresa (opcional)'),
          Text('El reclutador ajustará sus preguntas al estilo de la empresa.',
              style: AppText.caption.copyWith(height: 1.4)),
          const SizedBox(height: 10),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kCompanyPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final c = kCompanyPresets[i];
                final sel = _companyId == c.id;
                return GestureDetector(
                  onTap: () => setState(() => _companyId = c.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 110,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? c.accent.withOpacity(0.12) : AppColors.bgElev,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? c.accent : AppColors.border,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(c.flagEmoji, style: const TextStyle(fontSize: 20)),
                        const Spacer(),
                        if (sel) Icon(CupertinoIcons.checkmark_circle_fill,
                            color: c.accent, size: 14),
                      ]),
                      const SizedBox(height: 8),
                      Text(c.name, style: const TextStyle(fontFamily: AppText.fontFamily,
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(c.subtitle, style: const TextStyle(fontFamily: AppText.fontFamily,
                          fontSize: 9, color: AppColors.textSecondary), maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                );
              },
            ),
          ),

          // ── Paso 5: Tipo de entrevista ────────────────────────────────────
          const _SetupLabel('5  Tipo de preguntas'),
          ...kInterviewTypes.map((t) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _typeId = t.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _typeId == t.id ? t.color.withOpacity(0.08) : AppColors.bgElev,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                      color: _typeId == t.id ? t.color : AppColors.border,
                      width: _typeId == t.id ? 1.5 : 1),
                ),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                        color: t.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9)),
                    child: Icon(t.icon, color: t.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.label, style: AppText.subhead),
                    Text(t.description, style: AppText.caption),
                  ])),
                  Icon(
                    _typeId == t.id ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                    color: _typeId == t.id ? t.color : AppColors.textTertiary, size: 20,
                  ),
                ]),
              ),
            ),
          )),
        ],
      ),
      bottomSheet: Container(
        color: AppColors.bg,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: _PrimaryButton(
              label: 'Empezar entrevista',
              icon: CupertinoIcons.play_fill,
              enabled: _roleId != null && _mode != null,
              onPressed: () {
                final role = kJobRoles.firstWhere((r) => r.id == _roleId);
                final sen = kSeniority.firstWhere((s) => s.id == _seniorityId);
                final company = kCompanyPresets.firstWhere((c) => c.id == _companyId);
                final type = kInterviewTypes.firstWhere((t) => t.id == _typeId);
                Navigator.of(context).pushReplacement(CupertinoPageRoute(
                  builder: (_) => InterviewScreen(
                    role: role, seniority: sen, mode: _mode!,
                    companyPreset: company, interviewType: type,
                  ),
                ));
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupLabel extends StatelessWidget {
  final String text;
  const _SetupLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 10),
        child: Text(text.toUpperCase(), style: AppText.eyebrow),
      );
}

class _RoleCard extends StatelessWidget {
  final JobRole role; final bool selected; final VoidCallback onTap;
  const _RoleCard({required this.role, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue.withOpacity(0.08) : AppColors.bgElev,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? AppColors.blue : AppColors.border,
                width: selected ? 1.5 : 1),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: (selected ? AppColors.blue : role.accent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(role.icon, color: selected ? AppColors.blue : role.accent, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(role.title, style: AppText.subhead),
              Text(role.subtitle, style: AppText.caption),
            ])),
            Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                color: selected ? AppColors.blue : AppColors.textTertiary, size: 20),
          ]),
        ),
      ),
    );
  }
}

class _SeniorityChip extends StatelessWidget {
  final SeniorityLevel level; final bool selected; final VoidCallback onTap;
  const _SeniorityChip({required this.level, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.blue : AppColors.bgElev,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.blue : AppColors.border),
          ),
          child: Column(children: [
            Text(level.label, style: TextStyle(fontFamily: AppText.fontFamily,
                fontSize: 15, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(level.description, style: TextStyle(fontFamily: AppText.fontFamily,
                fontSize: 11, color: selected ? Colors.white70 : AppColors.textTertiary)),
          ]),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon; final String title, subtitle; final bool selected;
  final String? badge; final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle,
      required this.selected, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withOpacity(0.08) : AppColors.bgElev,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.blue : AppColors.border,
              width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(selected ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.blue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(title, style: AppText.title3),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.blue.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(badge!, style: const TextStyle(fontFamily: AppText.fontFamily,
                      fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.blue,
                      letterSpacing: 0.5)),
                ),
              ],
            ]),
            const SizedBox(height: 3),
            Text(subtitle, style: AppText.caption),
          ])),
          Icon(selected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
              color: selected ? AppColors.blue : AppColors.textTertiary, size: 20),
        ]),
      ),
    );
  }
}

// =============================================================================
// PANTALLA: TIPS / ESTÁNDARES
// =============================================================================
class TipsScreen extends StatefulWidget {
  const TipsScreen({super.key});
  @override State<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends State<TipsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar('Guía de Entrevistas',
          onLeading: () => Navigator.of(context).pop()),
      body: Column(children: [
        // ── Tab bar ──────────────────────────────────────────────────────
        Container(
          color: AppColors.bg,
          child: TabBar(
            controller: _tab,
            labelColor: AppColors.blue,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.blue,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontFamily: AppText.fontFamily,
                fontSize: 14, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Método STAR'),
              Tab(text: 'Tips Rápidos'),
              Tab(text: 'Estándares'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _StarMethodTab(),
              _TipsListTab(),
              _StandardsTab(),
            ],
          ),
        ),
      ]),
    );
  }
}

class _StarMethodTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF061428), Color(0xFF0A1E3D)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.blue.withOpacity(0.3)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(CupertinoIcons.star_fill, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Método STAR', style: AppText.title3),
                Text('El estándar global de entrevistas conductuales', style: AppText.caption),
              ])),
            ]),
            const SizedBox(height: 14),
            const Text(
              'Amazon, Google y Microsoft usan el método STAR para evaluar '
              'cómo manejas situaciones reales. Es la base de toda entrevista '
              'conductual profesional.',
              style: AppText.footnote,
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _StarCard(letter: 'S', word: 'Situación', color: AppColors.blue,
            description: 'Describe el contexto brevemente. ¿Dónde trabajabas? '
                '¿Cuál era la situación? Ocupa el 10–15% de tu respuesta.',
            example: '"En mi anterior trabajo como desarrollador en una fintech, '
                'teníamos un deployment crítico en 48 horas y el lead del equipo '
                'se puso enfermo."',
            icon: CupertinoIcons.doc_text_fill),
        _StarCard(letter: 'T', word: 'Tarea', color: AppColors.indigo,
            description: 'Define claramente tu responsabilidad específica. '
                '¿Cuál era TU tarea, no la del equipo? 10–15% de tu respuesta.',
            example: '"Mi responsabilidad era coordinar a los 3 desarrolladores '
                'restantes y asegurar que el release saliera a tiempo y sin bugs críticos."',
            icon: CupertinoIcons.checkmark_rectangle_fill),
        _StarCard(letter: 'A', word: 'Acción', color: AppColors.blue,
            description: 'Describe detalladamente LO QUE HICISTE TÚ. '
                'Usa "yo" no "nosotros". Esta es la parte más importante: 60–65% de la respuesta.',
            example: '"Organicé una reunión de 30 min para repartir módulos. '
                'Implementé feature flags para lanzar en fases. Hice pair programming '
                'con el miembro más junior. Armé un checklist de smoke tests."',
            icon: CupertinoIcons.bolt_fill),
        _StarCard(letter: 'R', word: 'Resultado', color: AppColors.indigo,
            description: 'Qué pasó gracias a tus acciones. Con números si es posible. '
                'Menciona también qué aprendiste. 15–20% de la respuesta.',
            example: '"Lanzamos a tiempo, con 0 bugs críticos. La retención de '
                'usuarios en la primera semana fue 23% mayor a releases anteriores. '
                'Aprendí a liderar bajo presión sin micromanagear."',
            icon: CupertinoIcons.chart_bar_fill),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.bgElev,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ERRORES COMUNES EN STAR', style: AppText.eyebrow),
            const SizedBox(height: 12),
            ...[
              'Usar "nosotros" en vez de "yo" en las Acciones',
              'Dar contexto demasiado largo sin llegar al punto',
              'No cuantificar los resultados ("lo mejoré" vs "mejoré 40%")',
              'Inventar situaciones — los reclutadores hacen preguntas de seguimiento',
              'Contar historias de hace más de 5 años sin actualizar',
              'Dar una historia negativa sin mencionar aprendizaje',
            ].map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.red, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(e, style: AppText.footnote)),
              ]),
            )),
          ]),
        ),
      ],
    );
  }
}

class _StarCard extends StatelessWidget {
  final String letter, word, description, example;
  final Color color;
  final IconData icon;
  const _StarCard({required this.letter, required this.word, required this.description,
      required this.example, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgElev,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
              child: Center(child: Text(letter, style: TextStyle(
                  fontFamily: AppText.fontFamily, fontSize: 20,
                  fontWeight: FontWeight.w800, color: color))),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(word, style: AppText.title3),
              Text(_pct(), style: AppText.caption),
            ]),
            const Spacer(),
            Icon(icon, color: color, size: 18),
          ]),
          const SizedBox(height: 12),
          Text(description, style: AppText.footnote.copyWith(height: 1.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EJEMPLO', style: AppText.eyebrow.copyWith(color: color)),
              const SizedBox(height: 6),
              Text(example, style: AppText.caption.copyWith(
                  color: AppColors.textPrimary, height: 1.5, fontStyle: FontStyle.italic)),
            ]),
          ),
        ]),
      ),
    );
  }

  String _pct() {
    switch (letter) {
      case 'S': return '10–15% de tu respuesta';
      case 'T': return '10–15% de tu respuesta';
      case 'A': return '60–65% de tu respuesta';
      case 'R': return '15–20% de tu respuesta';
      default: return '';
    }
  }
}

class _TipsListTab extends StatefulWidget {
  @override State<_TipsListTab> createState() => _TipsListTabState();
}

class _TipsListTabState extends State<_TipsListTab> {
  String _selectedCategory = 'Todos';

  List<String> get _categories {
    final cats = ['Todos', ...kQuickTips.map((t) => t.category).toSet().toList()];
    return cats;
  }

  List<QuickTip> get _filtered => _selectedCategory == 'Todos'
      ? kQuickTips
      : kQuickTips.where((t) => t.category == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Category chips ─────────────────────────────────────────────────
      Container(
        height: 44,
        color: AppColors.bg,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final cat = _categories[i];
            final sel = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.blue : AppColors.bgElev,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: sel ? AppColors.blue : AppColors.border),
                  ),
                  child: Text(cat, style: TextStyle(
                      fontFamily: AppText.fontFamily, fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: sel ? Colors.white : AppColors.textSecondary)),
                ),
              ),
            );
          },
        ),
      ),
      // ── Tips list ───────────────────────────────────────────────────────
      Expanded(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: _filtered.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _TipCard(tip: _filtered[i]),
        ),
      ),
    ]);
  }
}

class _TipCard extends StatefulWidget {
  final QuickTip tip;
  const _TipCard({required this.tip});
  @override State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _expanded ? widget.tip.color.withOpacity(0.08) : AppColors.bgElev,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _expanded ? widget.tip.color.withOpacity(0.35) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                  color: widget.tip.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9)),
              child: Icon(widget.tip.icon, color: widget.tip.color, size: 15),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.tip.title, style: AppText.subhead)),
            Icon(_expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                color: AppColors.textTertiary, size: 14),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Text(widget.tip.body, style: AppText.footnote.copyWith(
                height: 1.55, color: AppColors.textSecondary)),
          ],
        ]),
      ),
    );
  }
}

class _StandardsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      itemCount: kStandards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _StandardCard(standard: kStandards[i]),
    );
  }
}

class _StandardCard extends StatefulWidget {
  final StandardInfo standard;
  const _StandardCard({required this.standard});
  @override State<_StandardCard> createState() => _StandardCardState();
}

class _StandardCardState extends State<_StandardCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.standard;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgElev,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _expanded ? AppColors.blue.withOpacity(0.4) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(CupertinoIcons.bookmark_fill, color: AppColors.blue, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: AppText.subhead),
              Text(s.org, style: AppText.caption),
            ])),
            Icon(_expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                color: AppColors.textTertiary, size: 14),
          ]),
          if (!_expanded) ...[
            const SizedBox(height: 8),
            Text(s.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: AppText.footnote.copyWith(height: 1.4)),
          ],
          if (_expanded) ...[
            const SizedBox(height: 12),
            Text(s.description, style: AppText.footnote.copyWith(height: 1.55)),
            const SizedBox(height: 14),
            Text('DIMENSIONES', style: AppText.eyebrow),
            const SizedBox(height: 8),
            ...s.dimensions.map((d) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(margin: const EdgeInsets.only(top: 7),
                    width: 5, height: 5,
                    decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle)),
                const SizedBox(width: 9),
                Expanded(child: Text(d, style: AppText.caption.copyWith(
                    color: AppColors.textPrimary, height: 1.4))),
              ]),
            )),
            const SizedBox(height: 12),
            Text('CONSEJOS', style: AppText.eyebrow),
            const SizedBox(height: 8),
            ...s.tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(CupertinoIcons.checkmark_circle_fill,
                    color: AppColors.green, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(t, style: AppText.footnote.copyWith(height: 1.45))),
              ]),
            )),
            const SizedBox(height: 10),
            Text(s.source, style: AppText.caption.copyWith(
                color: AppColors.textTertiary, fontStyle: FontStyle.italic)),
          ],
        ]),
      ),
    );
  }
}

// =============================================================================
// PANTALLA: COMPANIES / PRESETS DETALLE
// =============================================================================
class CompaniesScreen extends StatelessWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar('Estilos de Empresa', onLeading: () => Navigator.of(context).pop()),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: AppColors.bgElev,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
            child: const Text(
              'Cada empresa tiene un estilo único de entrevista. Conocer sus principios '
              'y preguntas frecuentes te da una ventaja significativa.',
              style: AppText.footnote,
            ),
          ),
          const SizedBox(height: 16),
          ...kCompanyPresets.where((c) => c.id != 'generic').map((c) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CompanyDetailCard(company: c),
            )),
        ],
      ),
    );
  }
}

class _CompanyDetailCard extends StatefulWidget {
  final CompanyPreset company;
  const _CompanyDetailCard({required this.company});
  @override State<_CompanyDetailCard> createState() => _CompanyDetailCardState();
}

class _CompanyDetailCardState extends State<_CompanyDetailCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.company;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgElev,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _expanded ? c.accent.withOpacity(0.4) : AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: c.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(c.flagEmoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: AppText.title3),
              Text(c.subtitle, style: AppText.caption),
            ])),
            Icon(_expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                color: AppColors.textTertiary, size: 14),
          ]),
          if (_expanded) ...[
            const SizedBox(height: 14),
            Text('ESTILO DE ENTREVISTA', style: AppText.eyebrow),
            const SizedBox(height: 6),
            Text(c.interviewStyle, style: AppText.footnote.copyWith(height: 1.55)),
            const SizedBox(height: 14),
            Text('PRINCIPIOS CLAVE', style: AppText.eyebrow),
            const SizedBox(height: 8),
            ...c.keyPrinciples.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(margin: const EdgeInsets.only(top: 7), width: 5, height: 5,
                    decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle)),
                const SizedBox(width: 9),
                Expanded(child: Text(p, style: AppText.caption.copyWith(
                    color: AppColors.textPrimary, height: 1.4))),
              ]),
            )),
            const SizedBox(height: 14),
            Text('PREGUNTAS FRECUENTES', style: AppText.eyebrow),
            const SizedBox(height: 8),
            ...c.commonQuestions.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.accent.withOpacity(0.2))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${e.key + 1}', style: TextStyle(fontFamily: AppText.fontFamily,
                      fontSize: 12, fontWeight: FontWeight.w700, color: c.accent)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value, style: AppText.caption.copyWith(
                      color: AppColors.textPrimary, height: 1.4))),
                ]),
              ),
            )),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.green.withOpacity(0.25))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(CupertinoIcons.lightbulb_fill, color: AppColors.green, size: 14),
                const SizedBox(width: 8),
                Expanded(child: Text(c.tip, style: AppText.footnote.copyWith(
                    color: AppColors.textPrimary, height: 1.5))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}

// =============================================================================
// PANTALLA: TRANSCRIPT (replay de sesión)
// =============================================================================
class TranscriptScreen extends StatelessWidget {
  final InterviewSession session;
  const TranscriptScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(
        '${session.roleTitle} · ${session.seniorityLabel}',
        onLeading: () => Navigator.of(context).pop(),
      ),
      body: Column(children: [
        // ── Info banner ────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.bgElev, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const Icon(CupertinoIcons.doc_text, color: AppColors.textTertiary, size: 14),
            const SizedBox(width: 8),
            Text(
              '${session.messages.length} mensajes · ${session.mode == "voz" ? "Modo voz" : "Modo chat"} · '
              '${_fmtFull(session.createdAt)}',
              style: AppText.caption,
            ),
          ]),
        ),
        const SizedBox(height: 4),
        // ── Chat list ──────────────────────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: session.messages.length,
            itemBuilder: (_, i) => _ChatBubble(message: session.messages[i]),
          ),
        ),
      ]),
    );
  }

  String _fmtFull(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';
}

// =============================================================================
// PANTALLA: ENTREVISTA
// CORRECCIÓN VOZ: _userWantsListen + _sttRunning + _resumeListening()
// No se corta sola — el usuario controla cuándo parar.
// =============================================================================
class InterviewScreen extends StatefulWidget {
  final JobRole role;
  final SeniorityLevel seniority;
  final String mode;
  final CompanyPreset? companyPreset;
  final InterviewType? interviewType;

  const InterviewScreen({
    super.key,
    required this.role,
    required this.seniority,
    required this.mode,
    this.companyPreset,
    this.interviewType,
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

  // ── STT / TTS ──────────────────────────────────────────────────────────────
  stt.SpeechToText? _speech;
  FlutterTts? _tts;
  bool _speechAvailable = false;

  // _userWantsListen: INTENCIÓN del usuario — no se resetea por silencio
  // _sttRunning     : STT activo en este momento
  bool _userWantsListen = false;
  bool _sttRunning = false;
  bool _isSpeaking = false;

  // Texto parcial del ciclo actual + acumulado de ciclos anteriores
  String _partialTranscript = '';
  String _accumulatedText = '';

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
      company: widget.companyPreset,
      interviewType: widget.interviewType,
    );
    if (widget.mode == 'voz') _initVoice();
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

  // ── Inicializar voz ─────────────────────────────────────────────────────────
  Future<void> _initVoice() async {
    try {
      await Permission.microphone.request();
      _speech = stt.SpeechToText();
      _speechAvailable = await _speech!.initialize(
        onStatus: (status) async {
          if (!mounted) return;
          if (status == 'listening') {
            setState(() => _sttRunning = true);
            return;
          }
          if (status == 'done' || status == 'notListening') {
            if (mounted) setState(() => _sttRunning = false);
            // Si el usuario quiere seguir hablando → acumular y reiniciar
            if (_userWantsListen && mounted) {
              if (_partialTranscript.isNotEmpty) _accumulatedText = _partialTranscript;
              await Future.delayed(const Duration(milliseconds: 350));
              if (_userWantsListen && mounted) await _resumeListening();
            }
          }
        },
        onError: (error) async {
          debugPrint('STT error: ${error.errorMsg}');
          if (!mounted) return;
          setState(() => _sttRunning = false);
          if (_userWantsListen && mounted) {
            await Future.delayed(const Duration(milliseconds: 800));
            if (_userWantsListen && mounted) await _resumeListening();
          }
        },
      );

      _tts = FlutterTts();
      await _tts!.setLanguage('es-MX');
      await _tts!.setSpeechRate(0.5);
      await _tts!.setPitch(1.0);
      _tts!.setStartHandler(() { if (mounted) setState(() => _isSpeaking = true); });
      _tts!.setCompletionHandler(() { if (mounted) setState(() => _isSpeaking = false); });
      _tts!.setCancelHandler(() { if (mounted) setState(() => _isSpeaking = false); });

      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _started) setState(() => _callDuration += const Duration(seconds: 1));
      });
    } catch (e) {
      debugPrint('Error voz: $e');
    }
  }

  /// Inicia/reanuda STT. Se llama al presionar "Hablar" y en reinicios automáticos.
  Future<void> _resumeListening() async {
    if (!_speechAvailable || _speech == null || !_userWantsListen) return;
    try {
      await _speech!.listen(
        localeId: 'es_MX',
        listenFor: const Duration(minutes: 10),
        pauseFor: const Duration(seconds: 8), // pausa amplia + reinicio automático
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          setState(() {
            _partialTranscript = _accumulatedText.isEmpty ? words : '$_accumulatedText $words'.trim();
          });
        },
      );
      if (mounted) setState(() => _sttRunning = true);
    } catch (e) {
      debugPrint('resumeListening error: $e');
    }
  }

  /// Toggle: "Hablar" / "Pausar"
  Future<void> _toggleListening() async {
    if (!_speechAvailable || _speech == null) {
      _showError('Micrófono no disponible');
      return;
    }
    if (_isSpeaking) await _tts?.stop();

    if (_userWantsListen) {
      // ── PARAR ─────────────────────────────────────────────────────────
      _userWantsListen = false;
      await _speech!.stop();
      setState(() => _sttRunning = false);
      final finalText = _partialTranscript.trim();
      _accumulatedText = '';
      setState(() => _partialTranscript = '');
      if (finalText.isNotEmpty && !_aiThinking) _sendUserMessage(finalText);
    } else {
      // ── HABLAR ────────────────────────────────────────────────────────
      _userWantsListen = true;
      _accumulatedText = '';
      setState(() => _partialTranscript = '');
      await _resumeListening();
    }
  }

  // ── Chat logic ──────────────────────────────────────────────────────────────
  Future<void> _start() async {
    setState(() => _aiThinking = true);
    try {
      final greeting = await _gemini.openingMessage();
      _addAi(greeting);
      if (widget.mode == 'voz') await _speak(greeting);
    } catch (e) {
      _addAi('Error al conectar con Gemini.\n\n${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) setState(() { _aiThinking = false; _started = true; });
    }
  }

  void _addAi(String text) {
    setState(() => _messages.add(ChatMessage(role: ChatRole.ai, text: text, timestamp: DateTime.now())));
    _scrollToBottom();
  }

  void _addUser(String text) {
    setState(() => _messages.add(ChatMessage(role: ChatRole.user, text: text, timestamp: DateTime.now())));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
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
      _addAi('Problema técnico: ${e.toString().replaceAll("Exception: ", "")}. ¿Puedes repetirlo?');
    } finally {
      if (mounted) setState(() => _aiThinking = false);
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
        SnackBar(content: Text(msg), backgroundColor: AppColors.cardElev));
  }

  Future<void> _finishInterview() async {
    final userReplies = _messages.where((m) => m.role == ChatRole.user).length;
    if (userReplies < 2) {
      final ok = await showCupertinoDialog<bool>(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('¿Salir?'),
          content: const Text('Necesitas responder al menos 2 preguntas para generar feedback.'),
          actions: [
            CupertinoDialogAction(child: const Text('Seguir'), onPressed: () => Navigator.pop(context, false)),
            CupertinoDialogAction(isDestructiveAction: true, child: const Text('Salir igual'), onPressed: () => Navigator.pop(context, true)),
          ],
        ),
      );
      if (ok == true && mounted) Navigator.of(context).pop();
      return;
    }

    _userWantsListen = false;
    await _speech?.stop();
    await _tts?.stop();
    _callTimer?.cancel();

    showDialog(context: context, barrierDismissible: false, builder: (_) => const _LoadingFeedback());

    try {
      final feedback = await _gemini.evaluate(
          roleTitle: widget.role.title, seniority: widget.seniority.label, messages: _messages);
      final session = InterviewSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roleId: widget.role.id, roleTitle: widget.role.title,
        seniorityLabel: widget.seniority.label, mode: widget.mode,
        companyPresetId: widget.companyPreset?.id,
        interviewTypeId: widget.interviewType?.id,
        messages: _messages, createdAt: DateTime.now(), feedback: feedback,
      );
      await _repo.save(session);
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacement(CupertinoPageRoute(
        builder: (_) => FeedbackScreen(session: session, feedback: feedback),
      ));
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError('Error: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  Future<void> _confirmExit() async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('¿Salir de la entrevista?'),
        content: const Text('Se perderá la conversación y no se generará feedback.'),
        actions: [
          CupertinoDialogAction(child: const Text('Seguir'), onPressed: () => Navigator.pop(context, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: const Text('Salir'), onPressed: () => Navigator.pop(context, true)),
        ],
      ),
    );
    if (ok == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) =>
      widget.mode == 'voz' ? _buildVoiceCallUI() : _buildChatUI();

  // ── CHAT UI ─────────────────────────────────────────────────────────────────
  Widget _buildChatUI() {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar(
        '${widget.role.title} · ${widget.seniority.label}',
        onLeading: () => _confirmExit(),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          // Botón de tips dentro de la entrevista
          GestureDetector(
            onTap: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const TipsScreen())),
            child: Container(
              width: 32, height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                  color: AppColors.card, borderRadius: BorderRadius.circular(16)),
              child: const Icon(CupertinoIcons.book, color: AppColors.textSecondary, size: 16),
            ),
          ),
          GestureDetector(
            onTap: _finishInterview,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.blue.withOpacity(0.35)),
              ),
              child: const Text('Terminar', style: TextStyle(
                  fontFamily: AppText.fontFamily, fontSize: 14,
                  fontWeight: FontWeight.w600, color: AppColors.blue)),
            ),
          ),
        ]),
      ),
      body: Column(children: [
        // ── Company context banner ───────────────────────────────────────────
        if (widget.companyPreset != null && widget.companyPreset!.id != 'generic')
          _CompanyBanner(company: widget.companyPreset!),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            itemCount: _messages.length + (_aiThinking ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == _messages.length && _aiThinking) return const _TypingBubble();
              return _ChatBubble(message: _messages[i]);
            },
          ),
        ),
        _ChatInputBar(controller: _input, enabled: !_aiThinking,
            onSend: () => _sendUserMessage(_input.text)),
      ]),
    );
  }

  // ── VOICE CALL UI ────────────────────────────────────────────────────────────
  Widget _buildVoiceCallUI() {
    final mins = _callDuration.inMinutes.toString().padLeft(2, '0');
    final secs = (_callDuration.inSeconds % 60).toString().padLeft(2, '0');

    String statusLabel; Color statusColor; IconData statusIcon;
    if (_aiThinking) {
      statusLabel = 'PENSANDO'; statusColor = AppColors.blue; statusIcon = CupertinoIcons.ellipsis_circle_fill;
    } else if (_isSpeaking) {
      statusLabel = 'HABLANDO'; statusColor = AppColors.blue; statusIcon = CupertinoIcons.waveform;
    } else if (_userWantsListen) {
      statusLabel = _sttRunning ? 'ESCUCHÁNDOTE' : 'PREPARANDO...';
      statusColor = AppColors.green; statusIcon = CupertinoIcons.mic_fill;
    } else {
      statusLabel = 'EN LLAMADA'; statusColor = AppColors.textTertiary; statusIcon = CupertinoIcons.phone_fill;
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(children: [
              GestureDetector(
                onTap: _confirmExit,
                child: Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(CupertinoIcons.chevron_down, color: AppColors.textSecondary, size: 18)),
              ),
              const Spacer(),
              Column(children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 5),
                  Text(statusLabel, style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 11,
                      fontWeight: FontWeight.w600, color: statusColor, letterSpacing: 1.3)),
                ]),
                const SizedBox(height: 2),
                Text('$mins:$secs', style: const TextStyle(fontFamily: AppText.fontFamily,
                    fontSize: 13, color: AppColors.textSecondary, letterSpacing: 0.5)),
              ]),
              const Spacer(),
              GestureDetector(
                onTap: _finishInterview,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18)),
                  child: const Text('Terminar', style: TextStyle(fontFamily: AppText.fontFamily,
                      fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.blue)),
                ),
              ),
            ]),
          ),

          const Spacer(),

          // ── Company tag (si aplica) ──────────────────────────────────────
          if (widget.companyPreset != null && widget.companyPreset!.id != 'generic') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                  color: widget.companyPreset!.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.companyPreset!.accent.withOpacity(0.3))),
              child: Text(
                '${widget.companyPreset!.flagEmoji}  Estilo ${widget.companyPreset!.name}',
                style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 12,
                    fontWeight: FontWeight.w600, color: widget.companyPreset!.accent),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // ── Avatar ───────────────────────────────────────────────────────
          _AvatarPulse(active: _isSpeaking || _userWantsListen),
          const SizedBox(height: 18),
          const Text('ReclutA', style: AppText.title1),
          const SizedBox(height: 4),
          Text('${widget.role.title} · ${widget.seniority.label}', style: AppText.bodySecondary),

          const SizedBox(height: 28),

          // ── Wave ─────────────────────────────────────────────────────────
          _VoiceWave(active: _isSpeaking || _sttRunning, listening: _userWantsListen),

          const SizedBox(height: 18),

          // ── Live transcript ───────────────────────────────────────────────
          Container(
            constraints: const BoxConstraints(minHeight: 72, maxHeight: 110),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: SingleChildScrollView(reverse: true, child: _buildLiveTranscript()),
          ),

          const Spacer(),

          // ── Controles ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 36),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _CallButton(
                icon: _userWantsListen ? CupertinoIcons.mic_fill : CupertinoIcons.mic,
                label: _userWantsListen ? 'Pausar' : 'Hablar',
                color: _userWantsListen ? AppColors.green : AppColors.card,
                iconColor: _userWantsListen ? Colors.white : AppColors.textPrimary,
                glowColor: _userWantsListen ? AppColors.green : null,
                onPressed: _aiThinking ? null : _toggleListening,
                size: 66,
              ),
              _CallButton(
                icon: CupertinoIcons.doc_text,
                label: 'Transcript',
                color: AppColors.card,
                iconColor: AppColors.textSecondary,
                onPressed: () => Navigator.of(context).push(CupertinoPageRoute(
                  builder: (_) => TranscriptScreen(session: InterviewSession(
                    id: 'preview', roleId: widget.role.id, roleTitle: widget.role.title,
                    seniorityLabel: widget.seniority.label, mode: widget.mode,
                    messages: _messages, createdAt: DateTime.now(),
                  )),
                )),
                size: 56,
              ),
              _CallButton(
                icon: CupertinoIcons.phone_down_fill,
                label: 'Colgar',
                color: AppColors.red, iconColor: Colors.white,
                glowColor: AppColors.red, onPressed: _finishInterview, size: 66,
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildLiveTranscript() {
    if (_partialTranscript.isNotEmpty) {
      return Text('"$_partialTranscript"', textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: AppText.fontFamily, fontSize: 15,
              color: AppColors.textPrimary, fontStyle: FontStyle.italic, height: 1.4));
    }
    if (_messages.isNotEmpty && _messages.last.role == ChatRole.ai) {
      return Text(_messages.last.text, textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: AppText.fontFamily, fontSize: 14,
              color: AppColors.textSecondary, height: 1.4));
    }
    return const SizedBox.shrink();
  }
}

// ── Company Banner (en chat) ──────────────────────────────────────────────────
class _CompanyBanner extends StatelessWidget {
  final CompanyPreset company;
  const _CompanyBanner({required this.company});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: company.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: company.accent.withOpacity(0.25))),
      child: Row(children: [
        Text(company.flagEmoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(child: Text(
          'Estilo ${company.name} · ${company.interviewStyle.split('.').first}.',
          style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 12,
              color: company.accent, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}

// =============================================================================
// PANTALLA: FEEDBACK EXTENDIDO
// =============================================================================
class FeedbackScreen extends StatelessWidget {
  final InterviewSession session;
  final FeedbackResult feedback;
  final bool isFromHistory;
  const FeedbackScreen({super.key, required this.session, required this.feedback,
      this.isFromHistory = false});

  @override
  Widget build(BuildContext context) {
    final company = session.companyPresetId != null
        ? kCompanyPresets.where((c) => c.id == session.companyPresetId).firstOrNull
        : null;
    final type = session.interviewTypeId != null
        ? kInterviewTypes.where((t) => t.id == session.interviewTypeId).firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: _buildAppBar('Feedback', onLeading: () {
        if (isFromHistory) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushAndRemoveUntil(
              CupertinoPageRoute(builder: (_) => const HomeScreen()), (_) => false);
        }
      }),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
        children: [
          // ── Score hero ────────────────────────────────────────────────────
          _ScoreHero(score: feedback.scoreOverall),
          const SizedBox(height: 8),
          Center(child: Text('${session.roleTitle} · ${session.seniorityLabel}',
              style: AppText.bodySecondary)),
          // ── Tags empresa/tipo ─────────────────────────────────────────────
          if (company != null || type != null) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (company != null && company.id != 'generic') Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: company.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: company.accent.withOpacity(0.3))),
                child: Text('${company.flagEmoji} ${company.name}',
                    style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 12,
                        fontWeight: FontWeight.w600, color: company.accent)),
              ),
              if (company != null && company.id != 'generic' && type != null)
                const SizedBox(width: 8),
              if (type != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: type.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: type.color.withOpacity(0.3))),
                child: Text(type.label, style: TextStyle(fontFamily: AppText.fontFamily,
                    fontSize: 12, fontWeight: FontWeight.w600, color: type.color)),
              ),
            ]),
          ],

          const SizedBox(height: 24),

          // ── Resumen ───────────────────────────────────────────────────────
          _Section(title: 'Resumen', icon: CupertinoIcons.doc_text_fill,
              child: Container(padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.bgElev,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: Text(feedback.summary, style: AppText.body))),

          // ── Radar chart ───────────────────────────────────────────────────
          _Section(title: 'Perfil de habilidades', icon: CupertinoIcons.scope,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.bgElev,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border)),
                child: Column(children: [
                  SizedBox(
                    width: 220, height: 220,
                    child: CustomPaint(
                      painter: _RadarChart(
                        values: feedback.dimensions.values.map((v) => v / 10).toList(),
                        labels: feedback.dimensions.keys.toList(),
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ]),
              )),

          // ── Dimensiones ───────────────────────────────────────────────────
          _Section(title: 'Dimensiones evaluadas', icon: CupertinoIcons.chart_bar_fill,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.bgElev,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: Column(children: feedback.dimensions.entries
                      .map((e) => _DimensionBar(label: e.key, value: e.value)).toList()))),

          // ── Fortalezas ────────────────────────────────────────────────────
          _Section(title: 'Lo hiciste bien', icon: CupertinoIcons.checkmark_seal_fill,
              iconColor: AppColors.green,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.bgElev,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: feedback.strengths
                          .map((s) => _BulletItem(text: s, color: AppColors.green)).toList()))),

          // ── Mejoras ───────────────────────────────────────────────────────
          _Section(title: 'Para mejorar', icon: CupertinoIcons.arrow_up_circle_fill,
              iconColor: AppColors.blue,
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.bgElev,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: feedback.improvements
                          .map((s) => _BulletItem(text: s, color: AppColors.blue)).toList()))),

          // ── Tips aplicados ────────────────────────────────────────────────
          _Section(title: 'Tips para tu próxima entrevista', icon: CupertinoIcons.lightbulb_fill,
              iconColor: AppColors.yellow,
              child: _NextTips(score: feedback.scoreOverall, dimensions: feedback.dimensions)),

          // ── Transcript button ─────────────────────────────────────────────
          const SizedBox(height: 16),
          _SecondaryButton(
            label: 'Ver transcripción completa',
            icon: CupertinoIcons.doc_text,
            onPressed: () => Navigator.of(context).push(CupertinoPageRoute(
                builder: (_) => TranscriptScreen(session: session))),
          ),
          const SizedBox(height: 10),

          // ── Fuentes ───────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.bgElev,
                borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(CupertinoIcons.info_circle, color: AppColors.textTertiary, size: 13),
                const SizedBox(width: 6),
                Text('CRITERIOS BASADOS EN', style: AppText.eyebrow),
              ]),
              const SizedBox(height: 8),
              const Text(
                '· Método STAR (Amazon, Google, Microsoft)\n'
                '· SHRM — Society for Human Resource Management\n'
                '· WEF Future of Jobs Report 2023\n'
                '· LinkedIn Talent Solutions México 2024\n'
                '· OCC Mundial — Guías de Empleabilidad MX',
                style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 12,
                    color: AppColors.textSecondary, height: 1.65),
              ),
            ]),
          ),

          if (!isFromHistory) ...[
            const SizedBox(height: 22),
            _PrimaryButton(
              label: 'Volver al inicio',
              icon: CupertinoIcons.house_fill,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  CupertinoPageRoute(builder: (_) => const HomeScreen()), (_) => false),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tips dinámicos basados en las dimensiones más bajas
class _NextTips extends StatelessWidget {
  final double score;
  final Map<String, double> dimensions;
  const _NextTips({required this.score, required this.dimensions});

  @override
  Widget build(BuildContext context) {
    // Tomar las 2 dimensiones más bajas y mostrar tips relevantes
    final sorted = dimensions.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final weak = sorted.take(2).map((e) => e.key).toList();

    final tips = _getTips(weak, score);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bgElev,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
      child: Column(children: tips.map((t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 28, height: 28,
              decoration: BoxDecoration(
                  color: AppColors.yellow.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: const Icon(CupertinoIcons.lightbulb, color: AppColors.yellow, size: 14)),
          const SizedBox(width: 10),
          Expanded(child: Text(t, style: AppText.footnote.copyWith(height: 1.5))),
        ]),
      )).toList()),
    );
  }

  List<String> _getTips(List<String> weakDims, double score) {
    final tips = <String>[];
    if (weakDims.contains('Estructura STAR')) {
      tips.add('Practica el método STAR: Situación→Tarea→Acción→Resultado. '
          'Para cada historia que cuentes, asegúrate de que el Resultado tenga números.');
    }
    if (weakDims.contains('Ejemplos concretos')) {
      tips.add('Antes de tu próxima entrevista prepara 5 historias específicas '
          'con datos reales. Cada logro debe tener al menos un número.');
    }
    if (weakDims.contains('Conocimiento del rol')) {
      tips.add('Investiga las herramientas, metodologías y tendencias del rol. '
          'Lee las últimas 3 ofertas de trabajo similares y aprende el vocabulario.');
    }
    if (weakDims.contains('Claridad')) {
      tips.add('Grábate respondiendo preguntas y escúchate. Elimina muletillas. '
          'Practica hablar más despacio y pausar entre ideas.');
    }
    if (weakDims.contains('Actitud y fit')) {
      tips.add('Investiga la cultura de la empresa en Glassdoor. Prepara por qué '
          'genuinamente te interesa el puesto y qué valores compartes.');
    }
    if (weakDims.contains('Comunicación')) {
      tips.add('Las respuestas ideales duran 90–120 segundos. Si son más cortas, '
          'añade más Acción. Si son más largas, recorta la Situación.');
    }
    if (score >= 8) {
      tips.add('¡Excelente desempeño! Para llegar a 10, enfócate en cuantificar '
          'cada resultado y practicar con preguntas de empresas FAANG.');
    }
    if (tips.isEmpty) {
      tips.add('Sigue practicando. La consistencia es clave. '
          'Trata de hacer al menos una sesión por día los próximos 7 días.');
    }
    return tips.take(3).toList();
  }
}

// =============================================================================
// WIDGETS DE FEEDBACK
// =============================================================================
class _ScoreHero extends StatelessWidget {
  final double score;
  const _ScoreHero({required this.score});

  Color get _color {
    if (score >= 8) return AppColors.green;
    if (score >= 6) return AppColors.blue;
    if (score >= 4) return AppColors.orange;
    return AppColors.red;
  }

  String get _label {
    if (score >= 8) return 'Excelente';
    if (score >= 6) return 'Bien';
    if (score >= 4) return 'Aceptable';
    return 'A practicar';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (score / 10).clamp(0.0, 1.0);
    return Center(
      child: Column(children: [
        SizedBox(
          width: 178, height: 178,
          child: Stack(alignment: Alignment.center, children: [
            CustomPaint(
              size: const Size(178, 178),
              painter: _CircularProgress(value: pct, color: _color, bg: AppColors.card),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(score.toStringAsFixed(1), style: TextStyle(fontFamily: AppText.fontFamily,
                  fontSize: 52, fontWeight: FontWeight.w700, color: _color, letterSpacing: -2)),
              const Text('de 10', style: AppText.caption),
            ]),
          ]),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _color.withOpacity(0.35))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SvgIcon(painter: _StarPainter(color: _color), size: 13),
            const SizedBox(width: 5),
            Text(_label, style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 13,
                fontWeight: FontWeight.w600, color: _color, letterSpacing: 0.2)),
          ]),
        ),
      ]),
    );
  }
}

class _CircularProgress extends CustomPainter {
  final double value; final Color color, bg;
  const _CircularProgress({required this.value, required this.color, required this.bg});
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - stroke) / 2;
    canvas.drawCircle(center, radius, Paint()
        ..color = bg..strokeWidth = stroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, 2 * math.pi * value, false, Paint()
        ..color = color..strokeWidth = stroke..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
  }
  @override bool shouldRepaint(covariant _CircularProgress o) => o.value != value || o.color != color;
}

/// Radar chart para las 6 dimensiones
class _RadarChart extends CustomPainter {
  final List<double> values; // 0.0 – 1.0
  final List<String> labels;
  final Color color;
  const _RadarChart({required this.values, required this.labels, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = (math.min(size.width, size.height) / 2) * 0.68;
    final n = values.length;

    // ── Background rings ──
    for (int ring = 1; ring <= 4; ring++) {
      final rr = r * ring / 4;
      final ringPath = Path();
      for (int i = 0; i < n; i++) {
        final angle = (2 * math.pi * i / n) - math.pi / 2;
        final x = cx + rr * math.cos(angle);
        final y = cy + rr * math.sin(angle);
        i == 0 ? ringPath.moveTo(x, y) : ringPath.lineTo(x, y);
      }
      ringPath.close();
      canvas.drawPath(ringPath, Paint()
          ..color = AppColors.border..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }

    // ── Axis lines ──
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(cx + r * math.cos(angle), cy + r * math.sin(angle)),
        Paint()..color = AppColors.border..strokeWidth = 0.8,
      );
    }

    // ── Values polygon ──
    final valuePath = Path();
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final rv = r * values[i];
      final x = cx + rv * math.cos(angle);
      final y = cy + rv * math.sin(angle);
      i == 0 ? valuePath.moveTo(x, y) : valuePath.lineTo(x, y);
    }
    valuePath.close();
    canvas.drawPath(valuePath, Paint()
        ..color = color.withOpacity(0.18)..style = PaintingStyle.fill);
    canvas.drawPath(valuePath, Paint()
        ..color = color..style = PaintingStyle.stroke
        ..strokeWidth = 2..strokeJoin = StrokeJoin.round);

    // ── Dots at values ──
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final rv = r * values[i];
      canvas.drawCircle(Offset(cx + rv * math.cos(angle), cy + rv * math.sin(angle)),
          4, Paint()..color = color..style = PaintingStyle.fill);
    }

    // ── Labels ──
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < n; i++) {
      final angle = (2 * math.pi * i / n) - math.pi / 2;
      final lx = cx + (r + 22) * math.cos(angle);
      final ly = cy + (r + 22) * math.sin(angle);
      final short = labels[i].split(' ').first; // primera palabra
      tp.text = TextSpan(text: short, style: const TextStyle(
          fontFamily: AppText.fontFamily, fontSize: 9.5,
          color: AppColors.textSecondary, fontWeight: FontWeight.w500));
      tp.layout();
      tp.paint(canvas, Offset(lx - tp.width / 2, ly - tp.height / 2));
    }
  }

  @override bool shouldRepaint(covariant _RadarChart o) => false;
}

class _DimensionBar extends StatelessWidget {
  final String label; final double value;
  const _DimensionBar({required this.label, required this.value});

  Color get _color {
    if (value >= 8) return AppColors.green;
    if (value >= 6) return AppColors.blue;
    if (value >= 4) return AppColors.orange;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (value / 10).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(
              fontFamily: AppText.fontFamily, fontSize: 14, color: AppColors.textPrimary))),
          Text(value.toStringAsFixed(1), style: TextStyle(fontFamily: AppText.fontFamily,
              fontSize: 14, fontWeight: FontWeight.w600, color: _color)),
        ]),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: pct, minHeight: 5,
              backgroundColor: AppColors.cardElev,
              valueColor: AlwaysStoppedAnimation(_color)),
        ),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  final String title; final Widget child;
  final IconData? icon; final Color? iconColor;
  const _Section({required this.title, required this.child, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[
            Icon(icon, color: iconColor ?? AppColors.blue, size: 18),
            const SizedBox(width: 7),
          ],
          Text(title, style: AppText.title3),
        ]),
        const SizedBox(height: 10),
        child,
      ]),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text; final Color color;
  const _BulletItem({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(margin: const EdgeInsets.only(top: 8), width: 5, height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppText.body)),
      ]),
    );
  }
}

// =============================================================================
// WIDGETS COMPARTIDOS
// =============================================================================
PreferredSizeWidget _buildAppBar(String title,
    {VoidCallback? onLeading, Widget? trailing}) {
  return AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0, scrolledUnderElevation: 0,
    leading: onLeading != null
        ? IconButton(icon: const Icon(CupertinoIcons.back, color: AppColors.textPrimary),
            onPressed: onLeading)
        : null,
    title: Text(title, style: const TextStyle(fontFamily: AppText.fontFamily, fontSize: 17,
        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
    centerTitle: true,
    actions: trailing != null ? [trailing] : null,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );
}

// ── Primary Button ────────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label; final IconData icon;
  final VoidCallback? onPressed; final bool enabled;
  const _PrimaryButton({required this.label, required this.icon,
      this.onPressed, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    final on = enabled && onPressed != null;
    return GestureDetector(
      onTap: on ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: on ? const LinearGradient(
              colors: AppColors.primaryGrad, begin: Alignment.topLeft,
              end: Alignment.bottomRight) : null,
          color: on ? null : AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 18, color: on ? Colors.white : AppColors.textTertiary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontFamily: AppText.fontFamily, fontSize: 17,
              fontWeight: FontWeight.w600,
              color: on ? Colors.white : AppColors.textTertiary, letterSpacing: -0.1)),
        ]),
      ),
    );
  }
}

// ── Secondary Button ──────────────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  final String label; final IconData icon; final VoidCallback? onPressed;
  const _SecondaryButton({required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
            color: AppColors.bgElev,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: AppColors.blue),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(fontFamily: AppText.fontFamily, fontSize: 14,
              fontWeight: FontWeight.w600, color: AppColors.blue)),
        ]),
      ),
    );
  }
}

// ── Gradient Text ─────────────────────────────────────────────────────────────
class _GradientText extends StatelessWidget {
  final String text; final TextStyle style; final Gradient gradient;
  const _GradientText(this.text, {required this.style, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

// ── Chat Bubble ───────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser ? const LinearGradient(colors: AppColors.primaryGrad,
                    begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
                color: isUser ? null : AppColors.bgElev,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
              ),
              child: Text(message.text, style: TextStyle(fontFamily: AppText.fontFamily,
                  fontSize: 15, color: isUser ? Colors.white : AppColors.textPrimary, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Typing Bubble ─────────────────────────────────────────────────────────────
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();
  @override State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.bgElev,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Row(mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final phase = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
                final op = (math.sin(phase * math.pi) * 0.65 + 0.35).clamp(0.35, 1.0);
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Container(width: 7, height: 7,
                      decoration: BoxDecoration(
                          color: AppColors.blue.withOpacity(op),
                          borderRadius: BorderRadius.circular(4))));
              }),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Chat Input Bar ────────────────────────────────────────────────────────────
class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend; final bool enabled;
  const _ChatInputBar({required this.controller, required this.onSend, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(color: AppColors.bg,
            border: Border(top: BorderSide(color: AppColors.border, width: 0.5))),
        child: Row(children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: AppColors.bgElev,
                  borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.border)),
              child: TextField(
                controller: controller, enabled: enabled, style: AppText.body,
                cursorColor: AppColors.blue, minLines: 1, maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  hintStyle: TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none, isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
                onSubmitted: (_) => enabled ? onSend() : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: enabled ? onSend : null,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                gradient: enabled ? const LinearGradient(
                    colors: AppColors.primaryGrad, begin: Alignment.topLeft,
                    end: Alignment.bottomRight) : null,
                color: enabled ? null : AppColors.card,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(CupertinoIcons.arrow_up,
                  color: enabled ? Colors.white : AppColors.textTertiary, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Call Button ───────────────────────────────────────────────────────────────
class _CallButton extends StatelessWidget {
  final IconData icon; final Color color, iconColor;
  final Color? glowColor; final VoidCallback? onPressed;
  final double size; final String? label;
  const _CallButton({required this.icon, required this.color, required this.iconColor,
      this.glowColor, required this.onPressed, required this.size, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GestureDetector(
        onTap: onPressed,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: onPressed == null ? AppColors.cardElev : color,
            borderRadius: BorderRadius.circular(size / 3),
            boxShadow: (onPressed != null && glowColor != null)
                ? [BoxShadow(color: glowColor!.withOpacity(0.35), blurRadius: 22, spreadRadius: -4)]
                : null,
          ),
          child: Icon(icon,
              color: onPressed == null ? AppColors.textTertiary : iconColor, size: size * 0.4),
        ),
      ),
      if (label != null) ...[
        const SizedBox(height: 8),
        Text(label!, style: const TextStyle(fontFamily: AppText.fontFamily,
            fontSize: 12, color: AppColors.textSecondary)),
      ],
    ]);
  }
}

// ── Voice Waveform ────────────────────────────────────────────────────────────
class _VoiceWave extends StatefulWidget {
  final bool active, listening;
  const _VoiceWave({required this.active, required this.listening});
  @override State<_VoiceWave> createState() => _VoiceWaveState();
}

class _VoiceWaveState extends State<_VoiceWave> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220, height: 58,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(18, (i) {
            final double h;
            if (widget.active) {
              final phase = (_ctrl.value * 2 * math.pi) + i * 0.45;
              h = 6 + (math.sin(phase).abs() * 38);
            } else {
              h = 5;
            }
            final color = widget.listening ? AppColors.green : AppColors.blue;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(width: 4, height: h.clamp(5.0, 44.0),
                  decoration: BoxDecoration(
                      color: widget.active ? color : AppColors.textTertiary,
                      borderRadius: BorderRadius.circular(3))),
            );
          }),
        ),
      ),
    );
  }
}

// ── Avatar con pulso ──────────────────────────────────────────────────────────
class _AvatarPulse extends StatefulWidget {
  final bool active;
  const _AvatarPulse({required this.active});
  @override State<_AvatarPulse> createState() => _AvatarPulseState();
}

class _AvatarPulseState extends State<_AvatarPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final glow = widget.active ? (_anim.value * 0.38 + 0.18) : 0.12;
        return Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: [BoxShadow(color: AppColors.blue.withOpacity(glow),
                  blurRadius: 52, spreadRadius: -4)]),
          child: child,
        );
      },
      child: Container(
        width: 126, height: 126,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGrad,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(34),
        ),
        child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 50),
      ),
    );
  }
}

// ── Loading Feedback Dialog ───────────────────────────────────────────────────
class _LoadingFeedback extends StatelessWidget {
  const _LoadingFeedback();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bgElev,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGrad,
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(CupertinoIcons.sparkles, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 18),
          const Text('Analizando tu entrevista', style: AppText.title3),
          const SizedBox(height: 6),
          const Text('La IA está leyendo tus respuestas y calificándote con '
              'criterios de entrevistas profesionales.',
              textAlign: TextAlign.center, style: AppText.caption),
          const SizedBox(height: 20),
          const CupertinoActivityIndicator(color: Colors.white),
        ]),
      ),
    );
  }
}