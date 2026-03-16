import 'package:flutter/material.dart';

void main() => runApp(const HorarioApp());

// ─── DATA ────────────────────────────────────────────────────────────────────

class Materia {
  final String clave;
  final String nombre;
  final String docente;
  final Color color;
  final List<ClaseSlot> slots;

  const Materia({
    required this.clave,
    required this.nombre,
    required this.docente,
    required this.color,
    required this.slots,
  });
}

class ClaseSlot {
  final int dia; // 0=Lun,1=Mar,2=Mie,3=Jue,4=Vie
  final int horaInicio; // minutos desde las 07:00
  final int duracion;  // minutos
  final String aula;

  const ClaseSlot({
    required this.dia,
    required this.horaInicio,
    required this.duracion,
    required this.aula,
  });
}

int _t(int h, int m) => (h - 7) * 60 + m;

final List<Materia> materias = [
  Materia(
    clave: 'ACA0909',
    nombre: 'Taller de Inv. I',
    docente: '',
    color: const Color(0xFF6C63FF),
    slots: [
      ClaseSlot(dia: 1, horaInicio: _t(10, 0), duracion: 120, aula: 'H12'),
      ClaseSlot(dia: 3, horaInicio: _t(11, 0), duracion: 120, aula: 'LCOM4'),
    ],
  ),
  Materia(
    clave: 'DWB2402',
    nombre: 'Progr. Aplic. Mov.',
    docente: 'Sara Nelly Moreno Cimé',
    color: const Color(0xFFFF6584),
    slots: [
      ClaseSlot(dia: 1, horaInicio: _t(14, 0), duracion: 180, aula: 'H2'),
      ClaseSlot(dia: 3, horaInicio: _t(14, 0), duracion: 120, aula: 'H8'),
    ],
  ),
  Materia(
    clave: 'DWB2403',
    nombre: 'Ges. Agil Proy. Sofw.',
    docente: 'Mario Renán Moreno Sabido',
    color: const Color(0xFF43C6AC),
    slots: [
      ClaseSlot(dia: 2, horaInicio: _t(13, 0), duracion: 180, aula: ' H11'),
      ClaseSlot(dia: 4, horaInicio: _t(13, 0), duracion: 120, aula: 'H11'),
    ],
  ),
  Materia(
    clave: 'SCA1002',
    nombre: 'Admin. de Redes',
    docente: 'José Antonio Espinosa Atoche',
    color: const Color(0xFFFFB347),
    slots: [
      ClaseSlot(dia: 0, horaInicio: _t(8, 0), duracion: 120, aula: 'H2'),
      ClaseSlot(dia: 4, horaInicio: _t(7, 0), duracion: 120, aula: 'H12'),
    ],
  ),
  Materia(
    clave: 'SCC1012',
    nombre: 'Inteligencia Artif.',
    docente: 'Larissa Jeanette Peniche Ruiz',
    color: const Color(0xFF56CCF2),
    slots: [
      ClaseSlot(dia: 0, horaInicio: _t(14, 0), duracion: 120, aula: 'H1'),
      ClaseSlot(dia: 2, horaInicio: _t(11, 0), duracion: 120, aula: 'H12'),
    ],
  ),
  Materia(
    clave: 'SCC1023',
    nombre: 'Sis. Programables',
    docente: 'Wilbert Francisco Mézquita',
    color: const Color(0xFFF97316),
    slots: [
      ClaseSlot(dia: 0, horaInicio: _t(19, 0), duracion: 120, aula: 'H1'),
      ClaseSlot(dia: 4, horaInicio: _t(19, 0), duracion: 120, aula: 'H1'),
    ],
  ),
  Materia(
    clave: 'SCG1009',
    nombre: 'Gestión de Proy. Soft',
    docente: 'Grelty del Socorro Canul',
    color: const Color(0xFFA78BFA),
    slots: [
      ClaseSlot(dia: 0, horaInicio: _t(11, 0), duracion: 180, aula: 'H5'),
      ClaseSlot(dia: 2, horaInicio: _t(8, 0), duracion: 180, aula: 'H5'),
    ],
  ),
];

// ─── APP ─────────────────────────────────────────────────────────────────────

class HorarioApp extends StatelessWidget {
  const HorarioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Horario ITM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HorarioHome(),
    );
  }
}

// ─── HOME ─────────────────────────────────────────────────────────────────────

class HorarioHome extends StatefulWidget {
  const HorarioHome({super.key});

  @override
  State<HorarioHome> createState() => _HorarioHomeState();
}

class _HorarioHomeState extends State<HorarioHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  static const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie'];
  static const diasFull = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now().weekday - 1; // 0=Lun
    _tabCtrl = TabController(
      length: 5,
      vsync: this,
      initialIndex: hoy.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: List.generate(5, (d) => _DayView(dia: d)),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMateriasSheet(context),
        backgroundColor: const Color(0xFF6C63FF),
        icon: const Icon(Icons.list_alt_rounded),
        label: const Text('Materias'),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF6C63FF), width: 1),
                ),
                child: const Text(
                  'ENE – JUN 2026',
                  style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF43C6AC).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '32 créditos · 8vo',
                  style: TextStyle(color: Color(0xFF43C6AC), fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Salvador Eduardo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const Text(
            'Vallado Villamonte',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Ing. en Sistemas Computacionales  ·  07A',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TabBar(
        controller: _tabCtrl,
        isScrollable: false,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        indicator: BoxDecoration(
          color: const Color(0xFF6C63FF),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: List.generate(
          5,
          (i) => Tab(
            child: Text(
              dias[i],
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }

  void _showMateriasSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, ctrl) => ListView(
          controller: ctrl,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Todas las Materias',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            ...materias.map((m) => _MateriaCard(materia: m)),
          ],
        ),
      ),
    );
  }
}

// ─── DAY VIEW ─────────────────────────────────────────────────────────────────

class _DayView extends StatelessWidget {
  final int dia;
  const _DayView({required this.dia});

  static const startHour = 7;
  static const endHour = 21;
  static const totalMinutes = (endHour - startHour) * 60;
  static const pixelsPerMin = 1.4;

  @override
  Widget build(BuildContext context) {
    final slots = <(Materia, ClaseSlot)>[];
    for (final m in materias) {
      for (final s in m.slots) {
        if (s.dia == dia) slots.add((m, s));
      }
    }
    slots.sort((a, b) => a.$2.horaInicio.compareTo(b.$2.horaInicio));

    if (slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.weekend_rounded, color: Colors.white24, size: 64),
            const SizedBox(height: 12),
            const Text(
              '¡Día libre! 🎉',
              style: TextStyle(color: Colors.white38, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
      child: SizedBox(
        height: totalMinutes * pixelsPerMin,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time axis
            SizedBox(
              width: 44,
              child: Stack(
                children: List.generate(endHour - startHour + 1, (i) {
                  final h = startHour + i;
                  final top = i * 60 * pixelsPerMin;
                  return Positioned(
                    top: top - 8,
                    child: Text(
                      '${h.toString().padLeft(2, '0')}:00',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Grid lines + events
            Expanded(
              child: Stack(
                children: [
                  // Hour lines
                  ...List.generate(endHour - startHour + 1, (i) {
                    final top = i * 60 * pixelsPerMin;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: Container(height: 1, color: Colors.white.withOpacity(0.05)),
                    );
                  }),
                  // Events
                  ...slots.map((t) {
                    final m = t.$1;
                    final s = t.$2;
                    final top = s.horaInicio * pixelsPerMin;
                    final h = s.duracion * pixelsPerMin;
                    return Positioned(
                      top: top + 2,
                      left: 4,
                      right: 4,
                      height: h - 4,
                      child: _EventCard(materia: m, slot: s),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EVENT CARD ───────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final Materia materia;
  final ClaseSlot slot;
  const _EventCard({required this.materia, required this.slot});

  String _fmt(int minutos) {
    final h = 7 + minutos ~/ 60;
    final m = minutos % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = materia.color;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  materia.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.aula,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt(slot.horaInicio)} – ${_fmt(slot.horaInicio + slot.duracion)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (materia.docente.isNotEmpty && slot.duracion >= 90) ...[
            const SizedBox(height: 2),
            Text(
              materia.docente,
              style: TextStyle(
                color: Colors.white.withOpacity(0.65),
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── MATERIA CARD ─────────────────────────────────────────────────────────────

class _MateriaCard extends StatelessWidget {
  final Materia materia;
  const _MateriaCard({required this.materia});

  static const diasNombre = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'];

  String _fmt(int minutos) {
    final h = 7 + minutos ~/ 60;
    final m = minutos % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = materia.color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                materia.clave,
                style: TextStyle(
                  color: c,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            materia.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (materia.docente.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              materia.docente,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          ...materia.slots.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 12, color: c.withOpacity(0.8)),
                  const SizedBox(width: 4),
                  Text(
                    '${diasNombre[s.dia]}  ${_fmt(s.horaInicio)} – ${_fmt(s.horaInicio + s.duracion)}',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    s.aula,
                    style: TextStyle(
                      color: c,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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