import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/duas.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';

// _PulsingHalo (en bas du fichier) anime le glow doré derrière le mot
// "الأذان" pendant que l'adhan résonne — détail visuel pour appuyer
// l'effet "moment sacré" du Mawaqit-style.

/// Plein écran « الأذان » pendant la lecture de l'adhan.
/// Décor : photo de la Mosquée du Prophète à Médine en background.
///
/// La mini-barre des horaires est conservée en bas pour ne jamais perdre
/// la fonction première (afficher l'heure des prières).
class AdhanOverlay extends StatelessWidget {
  const AdhanOverlay({
    super.key,
    required this.slot,
    required this.countdown,
    required this.today,
    required this.mosqueeName,
  });
  final PrayerSlot slot;
  final Duration countdown;
  final PrayerSchedule today;
  final String mosqueeName;

  @override
  Widget build(BuildContext context) {
    final french = PrayerNames.french[slot.name]!;
    final secondsLeft = countdown.inSeconds.clamp(0, 999);
    return Container(
      key: const ValueKey('adhan'),
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/al-masjid-an-nabawi.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.30),
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _PulsingHalo(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.45),
                              border: Border.all(
                                color: AppTheme.highlight.withValues(alpha: 0.7),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.mosque,
                              size: 88,
                              color: AppTheme.highlight,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'الأذان',
                            style: TextStyle(
                              fontSize: 180,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              height: 1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.9),
                                  blurRadius: 24,
                                  offset: const Offset(0, 4),
                                ),
                                Shadow(
                                  color:
                                      AppTheme.highlight.withValues(alpha: 0.6),
                                  blurRadius: 60,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Adhan de $french',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                        letterSpacing: 4,
                        shadows: AppTheme.textShadow,
                      ),
                    ),
                    const Spacer(flex: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: AppTheme.highlight.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_outlined,
                              color: AppTheme.highlight, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Fin de l\'adhan dans $secondsLeft s',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                              fontFeatures: [FontFeature.tabularFigures()],
                              shadows: AppTheme.textShadow,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              _MiniSchedule(today: today, mosqueeName: mosqueeName),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halo orange pulsant placé autour de l'icône+texte adhan.
class _PulsingHalo extends StatefulWidget {
  const _PulsingHalo({required this.child});
  final Widget child;

  @override
  State<_PulsingHalo> createState() => _PulsingHaloState();
}

class _PulsingHaloState extends State<_PulsingHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color:
                    AppTheme.highlight.withValues(alpha: 0.25 + 0.25 * t),
                blurRadius: 80 + 40 * t,
                spreadRadius: 4 + 8 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Affiche l'invocation à réciter juste après l'adhan.
///
/// Comme pour les adhkar post-prière, on garde en permanence la mini-barre
/// des horaires en bas d'écran : afficher les horaires reste la fonction
/// première de l'app, on ne la masque jamais entièrement.
class PostAdhanOverlay extends StatelessWidget {
  const PostAdhanOverlay({
    super.key,
    required this.countdown,
    required this.today,
    required this.mosqueeName,
  });
  final Duration countdown;
  final PrayerSchedule today;
  final String mosqueeName;

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dua = Duas.afterAdhan;
    return Container(
      key: const ValueKey('postAdhan'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E3D2C), Color(0xFF071324)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dua.titleAr,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFD54F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dua.titleFr,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        dua.arabic,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          height: 1.7,
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      dua.translation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.textPrimary.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _CountdownChip(label: 'Iqama dans', value: _fmt(countdown)),
                  ],
                ),
              ),
            ),
            _MiniSchedule(today: today, mosqueeName: mosqueeName),
          ],
        ),
      ),
    );
  }
}

/// Compte à rebours géant des dernières secondes avant l'iqama.
/// La mini-barre des horaires reste visible en bas.
class IqamaCountdownOverlay extends StatelessWidget {
  const IqamaCountdownOverlay({
    super.key,
    required this.slot,
    required this.countdown,
    required this.today,
    required this.mosqueeName,
  });
  final PrayerSlot slot;
  final Duration countdown;
  final PrayerSchedule today;
  final String mosqueeName;

  @override
  Widget build(BuildContext context) {
    final french = PrayerNames.french[slot.name]!;
    final seconds = countdown.inSeconds.clamp(0, 999);
    return Container(
      key: const ValueKey('iqamaCountdown'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7A4F00), Color(0xFF1A1100)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'IQAMA',
                    style: TextStyle(
                      fontSize: 48,
                      letterSpacing: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    seconds.toString(),
                    style: TextStyle(
                      fontSize: 280,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.highlight,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      height: 1,
                      shadows: [
                        Shadow(
                          color: AppTheme.highlight.withValues(alpha: 0.6),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'secondes',
                    style: TextStyle(
                      fontSize: 24,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Préparez-vous pour $french',
                    style: const TextStyle(
                      fontSize: 22,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            _MiniSchedule(today: today, mosqueeName: mosqueeName),
          ],
        ),
      ),
    );
  }
}

/// Adhkar récités après la prière obligatoire.
///
/// Caractéristiques :
///   - défile à travers TOUTES les invocations de Duas.afterPrayer ;
///   - chaque slide reste affichée un temps proportionnel à sa longueur
///     en mots (3 mots = ~3 s, 30 mots = ~18 s, plafonné à 25 s) ;
///   - en bas de l'écran, mini-barre des 5 prières avec leurs horaires
///     pour ne pas perdre la fonction principale de l'app.
class PostPrayerOverlay extends StatefulWidget {
  const PostPrayerOverlay({
    super.key,
    required this.countdown,
    required this.today,
    required this.mosqueeName,
  });
  final Duration countdown;

  /// Schedule du jour, nécessaire pour la mini-barre du bas qui affiche
  /// les horaires des 5 prières.
  final PrayerSchedule today;

  /// Nom de la mosquée affiché en bas à gauche de la mini-barre.
  final String mosqueeName;

  @override
  State<PostPrayerOverlay> createState() => _PostPrayerOverlayState();
}

class _PostPrayerOverlayState extends State<PostPrayerOverlay> {
  /// Nombre total de cycles à jouer avant de figer la dernière slide.
  static const int _maxCycles = 3;

  int _index = 0;
  int _cycle = 1; // 1..3
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Programme le passage à la slide suivante après une durée calibrée sur
  /// le nombre de mots. Au 3e tour, on s'arrête sur la dernière slide
  /// (la fenêtre temporelle de 10 min suffit largement pour 3 cycles).
  void _scheduleNext() {
    final dua = Duas.afterPrayer[_index];
    // 0.55 s par mot de la traduction française, plancher 4 s, plafond 25 s.
    final words = dua.wordCount;
    final seconds = (words * 0.55).clamp(4.0, 25.0);
    _timer = Timer(Duration(milliseconds: (seconds * 1000).round()), () {
      if (!mounted) return;
      final isLastSlide = _index == Duas.afterPrayer.length - 1;
      if (isLastSlide && _cycle >= _maxCycles) {
        // Dernier cycle terminé → on fige la dernière slide.
        return;
      }
      setState(() {
        if (isLastSlide) {
          _cycle += 1;
          _index = 0;
        } else {
          _index += 1;
        }
      });
      _scheduleNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dua = Duas.afterPrayer[_index];
    return Container(
      key: const ValueKey('postPrayer'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2A4A), Color(0xFF000A1A)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Zone principale (défilement des adhkar) — prend l'essentiel
            // de la hauteur disponible.
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 18, 28, 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'أذكار بعد الصلاة',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adhkar après la prière — cycle $_cycle / $_maxCycles',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600),
                        child: SingleChildScrollView(
                          key: ValueKey(_index),
                          child: Column(
                            children: [
                              Text(
                                dua.titleAr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Color(0xFFFFD54F),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  dua.arabic,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 34,
                                    height: 1.7,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                dua.transliteration,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.9),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                dua.translation,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Indicateur de progression (un point par dhikr,
                    // le point courant en barre élargie).
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        Duas.afterPrayer.length,
                        (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: i == _index ? 20 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: i == _index
                                ? const Color(0xFF66BB6A)
                                : AppTheme.textSecondary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // === Mini-barre des horaires en bas ===
            // Affichée en permanence pendant les adhkar pour ne pas perdre
            // la fonction principale de l'app (afficher les horaires de prière).
            // Version "large" : plus grosse car les adhkar prennent du temps
            // et l'utilisateur a besoin de voir clairement les horaires.
            _MiniSchedule(
              today: widget.today,
              mosqueeName: widget.mosqueeName,
              large: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau en bas d'écran : nom mosquée + 5 prières + heures.
/// Présent sur TOUS les overlays (adhan, post-adhan, iqama, post-prière)
/// pour ne jamais masquer la fonction première de l'app.
///
/// [large] = true → typographie + padding agrandis (utilisé pendant les
/// adhkar post-prière où l'écran reste sur ce mode plusieurs minutes).
class _MiniSchedule extends StatelessWidget {
  const _MiniSchedule({
    required this.today,
    required this.mosqueeName,
    this.large = false,
  });
  final PrayerSchedule today;
  final String mosqueeName;
  final bool large;

  static const _slots = [
    PrayerSlot.fajr,
    PrayerSlot.dhuhr,
    PrayerSlot.asr,
    PrayerSlot.maghrib,
    PrayerSlot.isha,
  ];

  @override
  Widget build(BuildContext context) {
    final hPad = large ? 26.0 : 18.0;
    final vPad = large ? 16.0 : 10.0;
    final mosqueeSize = large ? 18.0 : 13.0;
    final gap = large ? 22.0 : 14.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              mosqueeName,
              style: TextStyle(
                fontSize: mosqueeSize,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                shadows: AppTheme.textShadow,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: gap),
          for (final slot in _slots) ...[
            SizedBox(width: gap),
            _MiniSlot(
              name: PrayerNames.french[slot.name]!,
              time: today.all[slot]!,
              large: large,
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniSlot extends StatelessWidget {
  const _MiniSlot({
    required this.name,
    required this.time,
    required this.large,
  });
  final String name;
  final DateTime time;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    final nameSize = large ? 14.0 : 11.0;
    final timeSize = large ? 24.0 : 16.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: nameSize,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
            shadows: AppTheme.textShadow,
          ),
        ),
        Text(
          '$hh:$mm',
          style: TextStyle(
            fontSize: timeSize,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
            shadows: AppTheme.textShadow,
          ),
        ),
      ],
    );
  }
}

class _CountdownChip extends StatelessWidget {
  const _CountdownChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.highlight.withValues(alpha: 0.2),
        border: Border.all(color: AppTheme.highlight, width: 2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, color: AppTheme.highlight, size: 20),
          const SizedBox(width: 10),
          Text(
            '$label  ',
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppTheme.highlight,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
