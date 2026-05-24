// =============================================================================
// SimulatorScreen : outil de test et de prévisualisation.
//
// Permet de :
//   - Naviguer dans le calendrier pour tester n'importe quel jour
//     (vendredi/Jumu'ah, Ramadan, Eid, Arafa, etc.)
//   - Choisir une heure précise et voir quel écran s'afficherait
//   - Sauter directement à une phase (Adhan, Post-Adhan, Iqama, Adhkar)
//     pour tester les overlays
//   - Consulter le calendrier islamique pour la date choisie
//   - Activer la simulation → le HomeScreen affiche le résultat en direct
// =============================================================================

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/display_mode.dart';
import '../core/hijri_helper.dart';
import '../core/islamic_events.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';
import '../providers/prayer_provider.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final n = context.read<PrayerProvider>().now;
    _selectedDate = DateTime(n.year, n.month, n.day);
    _hour = n.hour;
    _minute = n.minute;
  }

  DateTime get _simDt => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _hour,
        _minute,
      );

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.highlight,
            onPrimary: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _shiftDay(int delta) =>
      setState(() => _selectedDate = _selectedDate.add(Duration(days: delta)));

  void _goToNextFriday() {
    var d = _selectedDate.add(const Duration(days: 1));
    while (d.weekday != DateTime.friday) {
      d = d.add(const Duration(days: 1));
    }
    setState(() => _selectedDate = d);
  }

  void _goToPrevFriday() {
    var d = _selectedDate.subtract(const Duration(days: 1));
    while (d.weekday != DateTime.friday) {
      d = d.subtract(const Duration(days: 1));
    }
    setState(() => _selectedDate = d);
  }

  void _goToNextRamadan() {
    var d = _selectedDate.add(const Duration(days: 1));
    final settings = context.read<PrayerProvider>().settings;
    for (int i = 0; i < 400; i++) {
      final hd = HijriCalendar.fromDate(d.add(Duration(days: settings.hijriOffset)));
      if (hd.hMonth == 9) {
        setState(() => _selectedDate = d);
        return;
      }
      d = d.add(const Duration(days: 1));
    }
  }

  void _goToNextEid() {
    var d = _selectedDate.add(const Duration(days: 1));
    final settings = context.read<PrayerProvider>().settings;
    for (int i = 0; i < 400; i++) {
      final hd = HijriCalendar.fromDate(d.add(Duration(days: settings.hijriOffset)));
      if ((hd.hMonth == 10 && hd.hDay == 1) ||
          (hd.hMonth == 12 && hd.hDay == 10)) {
        setState(() => _selectedDate = d);
        return;
      }
      d = d.add(const Duration(days: 1));
    }
  }

  void _goToArafa() {
    var d = _selectedDate.add(const Duration(days: 1));
    final settings = context.read<PrayerProvider>().settings;
    for (int i = 0; i < 400; i++) {
      final hd = HijriCalendar.fromDate(d.add(Duration(days: settings.hijriOffset)));
      if (hd.hMonth == 12 && hd.hDay == 9) {
        setState(() => _selectedDate = d);
        return;
      }
      d = d.add(const Duration(days: 1));
    }
  }

  void _changeHour(int delta) =>
      setState(() => _hour = (_hour + delta).clamp(0, 23));

  void _changeMinute(int delta) {
    int m = _minute + delta;
    if (m < 0) {
      m = 59;
      _changeHour(-1);
    } else if (m > 59) {
      m = 0;
      _changeHour(1);
    }
    setState(() => _minute = m);
  }

  /// Saute directement à un instant de la phase [phase] pour [slot].
  void _jumpToPhase(PrayerSlot slot, _Phase phase, PrayerSchedule schedule,
      int iqamaMinutes) {
    final pt = schedule.all[slot]!;
    final iqamaTime = pt.add(Duration(minutes: iqamaMinutes));
    final target = switch (phase) {
      _Phase.adhan =>
        pt.add(const Duration(seconds: 5)),
      _Phase.postAdhan => pt.add(
          const Duration(seconds: DisplayModeMachine.adhanDurationSec + 5)),
      _Phase.iqamaCountdown =>
        iqamaTime.subtract(const Duration(seconds: 25)),
      _Phase.adhkar => iqamaTime.add(const Duration(
          seconds: DisplayModeMachine.prayerDurationSec + 30)),
    };
    setState(() {
      _selectedDate = DateTime(target.year, target.month, target.day);
      _hour = target.hour;
      _minute = target.minute;
    });
  }

  void _activate() {
    context.read<PrayerProvider>().simulateTo(_simDt);
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _stop() {
    context.read<PrayerProvider>().stopSimulation();
    setState(() {}); // refresh chip
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerProvider>();
    final settings = provider.settings;
    final schedule = provider.scheduleForDay(_selectedDate);
    final events =
        IslamicCalendar.eventsFor(_selectedDate, hijriOffset: settings.hijriOffset);
    final simCtx = DisplayModeMachine.compute(
      now: _simDt,
      today: schedule,
      iqamaMinutes: settings.iqamaMinutes,
    );
    final hd = HijriCalendar.fromDate(
        _selectedDate.add(Duration(days: settings.hijriOffset)));
    final hijriStr =
        '${hd.hDay} ${HijriHelper.monthNames[hd.hMonth - 1]} ${hd.hYear} H';
    final gregStr = DateFormat('EEEE d MMMM y', 'fr_FR').format(_selectedDate);
    final isFriday = _selectedDate.weekday == DateTime.friday;

    return Scaffold(
      backgroundColor: const Color(0xFF080818),
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        foregroundColor: AppTheme.textPrimary,
        title: Row(
          children: [
            Icon(Icons.science_outlined,
                color: AppTheme.highlight, size: 20),
            const SizedBox(width: 10),
            const Text('Simulateur de temps',
                style:
                    TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            if (provider.isSimulating) ...[
              const SizedBox(width: 12),
              _SimBadge(label: 'ACTIF'),
            ],
          ],
        ),
        actions: [
          if (provider.isSimulating)
            TextButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_circle, color: Colors.redAccent, size: 18),
              label: const Text('Arrêter',
                  style: TextStyle(color: Colors.redAccent)),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === Sélecteur de date ===
            _SectionTitle(title: 'Date', icon: Icons.calendar_today),
            const SizedBox(height: 10),
            _DateRow(
              gregStr: gregStr,
              hijriStr: hijriStr,
              isFriday: isFriday,
              onPick: _pickDate,
              onPrev: () => _shiftDay(-1),
              onNext: () => _shiftDay(1),
              onPrevWeek: () => _shiftDay(-7),
              onNextWeek: () => _shiftDay(7),
              onPrevFriday: _goToPrevFriday,
              onNextFriday: _goToNextFriday,
            ),
            const SizedBox(height: 10),
            // Raccourcis islamiques rapides
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _QuickJumpChip(
                    label: '🕌 Vendredi →',
                    color: AppTheme.highlight,
                    onTap: _goToNextFriday),
                _QuickJumpChip(
                    label: '🌙 Ramadan →',
                    color: const Color(0xFF66BB6A),
                    onTap: _goToNextRamadan),
                _QuickJumpChip(
                    label: '🎊 Eid →',
                    color: const Color(0xFFFFD700),
                    onTap: _goToNextEid),
                _QuickJumpChip(
                    label: '⛰ Arafa →',
                    color: const Color(0xFFFFA000),
                    onTap: _goToArafa),
                _QuickJumpChip(
                    label: "Aujourd'hui",
                    color: AppTheme.textSecondary,
                    onTap: () {
                      final n = DateTime.now();
                      setState(() {
                        _selectedDate = DateTime(n.year, n.month, n.day);
                        _hour = n.hour;
                        _minute = n.minute;
                      });
                    }),
              ],
            ),

            const SizedBox(height: 22),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === Sélecteur d'heure ===
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          title: 'Heure', icon: Icons.access_time_filled),
                      const SizedBox(height: 10),
                      _TimeSelector(
                        hour: _hour,
                        minute: _minute,
                        onHourUp: () => _changeHour(1),
                        onHourDown: () => _changeHour(-1),
                        onMinuteUp: () => _changeMinute(1),
                        onMinuteDown: () => _changeMinute(-1),
                        onMinutePlus5: () => _changeMinute(5),
                        onMinuteMinus5: () => _changeMinute(-5),
                      ),
                      const SizedBox(height: 12),
                      _ModeChip(ctx: simCtx),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // === Événements islamiques ===
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                          title: 'Calendrier islamique',
                          icon: Icons.brightness_3),
                      const SizedBox(height: 10),
                      if (events.isEmpty)
                        _EmptyEvents()
                      else
                        ...events.map((e) => _EventTile(event: e)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // === Phases des prières ===
            _SectionTitle(
                title: 'Phases des prières', icon: Icons.mosque),
            const SizedBox(height: 10),
            _PrayerPhasesTable(
              schedule: schedule,
              iqamaMinutes: settings.iqamaMinutes,
              simDt: _simDt,
              onJump: (slot, phase) =>
                  _jumpToPhase(slot, phase, schedule, settings.iqamaMinutes),
            ),

            const SizedBox(height: 30),

            // === Bouton d'activation ===
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.highlight,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _activate,
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  'Simuler  ${_hour.toString().padLeft(2, '0')}:${_minute.toString().padLeft(2, '0')}  du  ${DateFormat('d MMM', 'fr_FR').format(_selectedDate)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Enum des phases
// ============================================================================

enum _Phase { adhan, postAdhan, iqamaCountdown, adhkar }

// ============================================================================
// Widgets internes
// ============================================================================

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.highlight, size: 16),
        const SizedBox(width: 7),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.highlight,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.highlight.withValues(alpha: 0.22),
          ),
        ),
      ],
    );
  }
}

class _SimBadge extends StatelessWidget {
  const _SimBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.7)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 10,
            color: Colors.redAccent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.gregStr,
    required this.hijriStr,
    required this.isFriday,
    required this.onPick,
    required this.onPrev,
    required this.onNext,
    required this.onPrevWeek,
    required this.onNextWeek,
    required this.onPrevFriday,
    required this.onNextFriday,
  });

  final String gregStr;
  final String hijriStr;
  final bool isFriday;
  final VoidCallback onPick;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onPrevFriday;
  final VoidCallback onNextFriday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ArrowBtn(icon: Icons.keyboard_double_arrow_left, onTap: onPrevWeek, tooltip: '−7 jours'),
              const SizedBox(width: 4),
              _ArrowBtn(icon: Icons.chevron_left, onTap: onPrev, tooltip: '−1 jour'),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            gregStr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.edit_calendar_outlined,
                              size: 14, color: AppTheme.textSecondary),
                        ],
                      ),
                      Text(
                        hijriStr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ArrowBtn(icon: Icons.chevron_right, onTap: onNext, tooltip: '+1 jour'),
              const SizedBox(width: 4),
              _ArrowBtn(icon: Icons.keyboard_double_arrow_right, onTap: onNextWeek, tooltip: '+7 jours'),
            ],
          ),
          if (isFriday) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.highlight.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.highlight.withValues(alpha: 0.6)),
                ),
                child: const Text(
                  'VENDREDI — JUMU\'AH',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.highlight,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
          // Accès rapide aux vendredi prochain/précédent
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vendredi : ',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              _QuickChip(label: '← Précédent', onTap: onPrevFriday),
              const SizedBox(width: 6),
              _QuickChip(label: 'Prochain →', onTap: onNextFriday),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  const _ArrowBtn({required this.icon, required this.onTap, this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, size: 18, color: AppTheme.textSecondary),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.hour,
    required this.minute,
    required this.onHourUp,
    required this.onHourDown,
    required this.onMinuteUp,
    required this.onMinuteDown,
    required this.onMinutePlus5,
    required this.onMinuteMinus5,
  });
  final int hour;
  final int minute;
  final VoidCallback onHourUp;
  final VoidCallback onHourDown;
  final VoidCallback onMinuteUp;
  final VoidCallback onMinuteDown;
  final VoidCallback onMinutePlus5;
  final VoidCallback onMinuteMinus5;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SpinColumn(
            value: hour,
            label: 'H',
            onUp: onHourUp,
            onDown: onHourDown,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              ':',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.highlight,
                height: 1,
              ),
            ),
          ),
          _SpinColumn(
            value: minute,
            label: 'M',
            onUp: onMinuteUp,
            onDown: onMinuteDown,
            onUpFast: onMinutePlus5,
            onDownFast: onMinuteMinus5,
            fastLabel: '±5',
          ),
        ],
      ),
    );
  }
}

class _SpinColumn extends StatelessWidget {
  const _SpinColumn({
    required this.value,
    required this.label,
    required this.onUp,
    required this.onDown,
    this.onUpFast,
    this.onDownFast,
    this.fastLabel,
  });
  final int value;
  final String label;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback? onUpFast;
  final VoidCallback? onDownFast;
  final String? fastLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onUpFast != null)
          _TinyBtn(label: '+${fastLabel ?? ''}', onTap: onUpFast!),
        _SpinBtn(icon: Icons.expand_less, onTap: onUp),
        Text(
          value.toString().padLeft(2, '0'),
          style: const TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              letterSpacing: 1),
        ),
        _SpinBtn(icon: Icons.expand_more, onTap: onDown),
        if (onDownFast != null)
          _TinyBtn(label: '-${fastLabel ?? ''}', onTap: onDownFast!),
      ],
    );
  }
}

class _SpinBtn extends StatelessWidget {
  const _SpinBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Icon(icon, size: 26, color: AppTheme.highlight),
      ),
    );
  }
}

class _TinyBtn extends StatelessWidget {
  const _TinyBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.highlight.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: 10,
              color: AppTheme.highlight,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.ctx});
  final DisplayContext ctx;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (ctx.mode) {
      DisplayMode.normal => ('Normal — Horaires', AppTheme.textSecondary, Icons.home),
      DisplayMode.adhan => ('Adhan en cours', AppTheme.highlight, Icons.volume_up),
      DisplayMode.postAdhan => ('Post-Adhan — Dou\'a', const Color(0xFF4CAF50), Icons.menu_book),
      DisplayMode.iqamaCountdown => ('Iqama dans ${ctx.countdown?.inSeconds ?? 0} s', AppTheme.highlight, Icons.timer),
      DisplayMode.postPrayer => ('Adhkar post-prière', const Color(0xFF9575CD), Icons.auto_awesome),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 7),
          Text(
            'MODE : $label',
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Text(
        'Aucun événement islamique particulier ce jour.',
        style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});
  final IslamicEvent event;

  static Color _color(IslamicEventType t) => switch (t) {
        IslamicEventType.eid => const Color(0xFFFFD700),
        IslamicEventType.arafat => const Color(0xFFFFA000),
        IslamicEventType.laylatulQadr => const Color(0xFFCE93D8),
        IslamicEventType.ramadan => const Color(0xFF66BB6A),
        IslamicEventType.ashura ||
        IslamicEventType.tasuaa =>
          const Color(0xFF64B5F6),
        IslamicEventType.dhulHijja => const Color(0xFF4DB6AC),
        IslamicEventType.ayyamBeedh => const Color(0xFF90CAF9),
        IslamicEventType.mondayFast ||
        IslamicEventType.thursdayFast =>
          const Color(0xFFB0BEC5),
      };

  @override
  Widget build(BuildContext context) {
    final c = _color(event.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                event.nameAr,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: c,
                    height: 1),
              ),
              const SizedBox(width: 8),
              Text(
                '— ${event.nameFr}',
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    height: 1),
              ),
              const Spacer(),
              if (event.isFasting)
                _Badge(label: '🌙 Jeûne', color: c),
              if (event.isHoliday)
                _Badge(label: '🎊 Fête', color: c),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            event.descFr,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _PrayerPhasesTable extends StatelessWidget {
  const _PrayerPhasesTable({
    required this.schedule,
    required this.iqamaMinutes,
    required this.simDt,
    required this.onJump,
  });

  final PrayerSchedule schedule;
  final int iqamaMinutes;
  final DateTime simDt;
  final void Function(PrayerSlot, _Phase) onJump;

  static const _slots = [
    PrayerSlot.fajr,
    PrayerSlot.dhuhr,
    PrayerSlot.asr,
    PrayerSlot.maghrib,
    PrayerSlot.isha,
  ];

  static const _names = {
    PrayerSlot.fajr: 'Fajr',
    PrayerSlot.dhuhr: 'Dhuhr',
    PrayerSlot.asr: 'Asr',
    PrayerSlot.maghrib: 'Maghrib',
    PrayerSlot.isha: 'Isha',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 80, child: Text('Prière', style: _hStyle)),
                const SizedBox(width: 56, child: Text('Heure', style: _hStyle)),
                const SizedBox(width: 56, child: Text('Iqama', style: _hStyle)),
                const Text('Simuler phase →', style: _hStyle),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x22FFFFFF)),
          ...ListTile.divideTiles(
            context: context,
            color: const Color(0x11FFFFFF),
            tiles: _slots.map((slot) {
              final pt = schedule.all[slot]!;
              final iqamaTime = pt.add(Duration(minutes: iqamaMinutes));
              final isActive = _isActivePhase(slot, simDt, pt, iqamaTime);
              return _SlotRow(
                name: _names[slot]!,
                prayerTime: pt,
                iqamaTime: iqamaTime,
                isActive: isActive,
                onJump: (phase) => onJump(slot, phase),
              );
            }),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              'Iqama = T + $iqamaMinutes min  •  Adhan 3 min  •  Dou\'a 1 min  •  Adhkar 10 min après iqama + 10 min prière',
              style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  static const _hStyle = TextStyle(
      fontSize: 10,
      color: AppTheme.textSecondary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.5);

  bool _isActivePhase(PrayerSlot slot, DateTime simDt, DateTime pt, DateTime iqamaTime) {
    final adhanEnd = pt.add(const Duration(seconds: DisplayModeMachine.adhanDurationSec));
    final postAdhanEnd = adhanEnd.add(const Duration(seconds: DisplayModeMachine.postAdhanDurationSec));
    final prayerEnd = iqamaTime.add(const Duration(seconds: DisplayModeMachine.prayerDurationSec));
    final adhkarEnd = prayerEnd.add(const Duration(seconds: DisplayModeMachine.adhkarDurationSec));
    return !simDt.isBefore(pt) && simDt.isBefore(adhkarEnd);
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.name,
    required this.prayerTime,
    required this.iqamaTime,
    required this.isActive,
    required this.onJump,
  });

  final String name;
  final DateTime prayerTime;
  final DateTime iqamaTime;
  final bool isActive;
  final void Function(_Phase) onJump;

  @override
  Widget build(BuildContext context) {
    final ptStr = DateFormat('HH:mm').format(prayerTime);
    final iqStr = DateFormat('HH:mm').format(iqamaTime);

    return Container(
      color: isActive
          ? AppTheme.highlight.withValues(alpha: 0.07)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    isActive ? AppTheme.highlight : AppTheme.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              ptStr,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          SizedBox(
            width: 56,
            child: Text(
              iqStr,
              style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          Wrap(
            spacing: 6,
            children: [
              _PhaseBtn(
                  label: 'Adhan',
                  color: AppTheme.highlight,
                  onTap: () => onJump(_Phase.adhan)),
              _PhaseBtn(
                  label: 'Dou\'a',
                  color: const Color(0xFF4CAF50),
                  onTap: () => onJump(_Phase.postAdhan)),
              _PhaseBtn(
                  label: 'Iqama',
                  color: const Color(0xFFFF8A65),
                  onTap: () => onJump(_Phase.iqamaCountdown)),
              _PhaseBtn(
                  label: 'Adhkar',
                  color: const Color(0xFF9575CD),
                  onTap: () => onJump(_Phase.adhkar)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickJumpChip extends StatelessWidget {
  const _QuickJumpChip(
      {required this.label,
      required this.color,
      required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.55)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PhaseBtn extends StatelessWidget {
  const _PhaseBtn(
      {required this.label,
      required this.color,
      required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
