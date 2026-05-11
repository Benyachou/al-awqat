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
  });
  final PrayerSlot slot;
  final Duration countdown;
  final PrayerSchedule today;

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
              _MiniSchedule(today: today),
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

/// Fait défiler les invocations à réciter juste après l'adhan : témoignage
/// (Muslim 386), salât 'alâ-n-Nabî, puis dou'a du wasîla (Bukhârî 614).
///
/// Les 3 dou'as s'enchaînent dans la fenêtre de 60 s (≈ 20 s chacune).
/// La mini-barre des horaires reste visible en bas pour ne jamais perdre
/// la fonction première de l'app.
class PostAdhanOverlay extends StatefulWidget {
  const PostAdhanOverlay({
    super.key,
    required this.countdown,
    required this.today,
  });
  final Duration countdown;
  final PrayerSchedule today;

  @override
  State<PostAdhanOverlay> createState() => _PostAdhanOverlayState();
}

class _PostAdhanOverlayState extends State<PostAdhanOverlay> {
  int _index = 0;
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

  void _scheduleNext() {
    final dua = Duas.afterAdhan[_index];
    final double seconds = dua.displaySeconds != null
        ? dua.displaySeconds!.toDouble()
        : (dua.wordCount * 0.5).clamp(6.0, 20.0);
    _timer = Timer(Duration(milliseconds: (seconds * 1000).round()), () {
      if (!mounted) return;
      final isLast = _index == Duas.afterAdhan.length - 1;
      if (isLast) return; // on fige la dernière slide jusqu'à l'iqama
      setState(() => _index += 1);
      _scheduleNext();
    });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final dua = Duas.afterAdhan[_index];
    final total = Duas.afterAdhan.length;
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
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    key: ValueKey(_index),
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
                        '${dua.titleFr} — ${_index + 1} / $total',
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
                            fontSize: 32,
                            height: 1.7,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        dua.transliteration,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              AppTheme.textSecondary.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        dua.translation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textPrimary.withValues(alpha: 0.92),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _CountdownChip(
                          label: 'Iqama dans', value: _fmt(widget.countdown)),
                    ],
                  ),
                ),
              ),
            ),
            _MiniSchedule(today: widget.today),
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
  });
  final PrayerSlot slot;
  final Duration countdown;
  final PrayerSchedule today;

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
                  Text(
                    'IQAMA DANS',
                    style: TextStyle(
                      fontSize: 56,
                      letterSpacing: 14,
                      color: AppTheme.textPrimary.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w300,
                      shadows: AppTheme.textShadow,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                        const Shadow(
                          color: Colors.black87,
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'SECONDES',
                    style: TextStyle(
                      fontSize: 32,
                      color: AppTheme.highlight.withValues(alpha: 0.85),
                      letterSpacing: 12,
                      fontWeight: FontWeight.w500,
                      shadows: AppTheme.textShadow,
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'Préparez-vous pour $french',
                    style: const TextStyle(
                      fontSize: 24,
                      color: AppTheme.textPrimary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            _MiniSchedule(today: today),
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
  });
  final Duration countdown;

  /// Schedule du jour, nécessaire pour la mini-barre du bas qui affiche
  /// les horaires des 5 prières.
  final PrayerSchedule today;

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

  /// Programme le passage à la slide suivante après la durée définie pour
  /// le dhikr courant. Si `displaySeconds` est renseigné on l'utilise tel quel
  /// (utile pour les répétitions × 33). Sinon on calibre sur le nombre de
  /// mots : 0.5 s/mot, plancher 6 s, plafond 20 s — aucune slide ne reste
  /// plus de 20 secondes pour garder un rythme soutenu. Au 3ᵉ tour, la
  /// dernière slide est figée.
  void _scheduleNext() {
    final dua = Duas.afterPrayer[_index];
    final double seconds = dua.displaySeconds != null
        ? dua.displaySeconds!.toDouble()
        : (dua.wordCount * 0.5).clamp(6.0, 20.0);
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
              large: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau en bas d'écran : nom mosquée + 5 prières + heure courante.
/// Présent sur TOUS les overlays (adhan, post-adhan, iqama, post-prière)
/// pour ne jamais masquer la fonction première de l'app.
///
/// [large] = true → typographie + padding agrandis (utilisé pendant les
/// adhkar post-prière où l'écran reste sur ce mode plusieurs minutes).
class _MiniSchedule extends StatelessWidget {
  const _MiniSchedule({
    required this.today,
    this.large = false,
  });
  final PrayerSchedule today;
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
    // === Échelle des tailles selon le mode ===
    final hPad = large ? 36.0 : 26.0;
    final vPad = large ? 22.0 : 16.0;
    final clockSize = large ? 56.0 : 42.0;
    final separatorGap = large ? 14.0 : 10.0;

    // L'horloge est rafraîchie à chaque rebuild du parent (les overlays sont
    // dans un Consumer<PrayerProvider> qui notifie chaque seconde).
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        // Dégradé subtil de fond pour donner de la profondeur au bandeau.
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.45),
            Colors.black.withValues(alpha: 0.80),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppTheme.highlight.withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // === Bloc central : horloge en gros, centrée ===
          // Pilule glass légèrement liserée d'or pour la mettre en valeur.
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: large ? 40 : 32,
                vertical: large ? 10 : 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  color: AppTheme.highlight.withValues(alpha: 0.40),
                  width: 1.3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.highlight.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '$hh:$mm:$ss',
                style: TextStyle(
                  fontSize: clockSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.highlight,
                  letterSpacing: 3,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: [
                    Shadow(
                      color: AppTheme.highlight.withValues(alpha: 0.55),
                      blurRadius: 22,
                    ),
                    const Shadow(
                      color: Colors.black87,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: separatorGap),
          // === Séparateur doré dégradé ===
          // Trait fin qui s'estompe sur les bords pour un effet élégant.
          Container(
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.highlight.withValues(alpha: 0.0),
                  AppTheme.highlight.withValues(alpha: 0.55),
                  AppTheme.highlight.withValues(alpha: 0.55),
                  AppTheme.highlight.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.28, 0.72, 1.0],
              ),
            ),
          ),
          SizedBox(height: separatorGap),
          // === Pilules glass des 5 prières, bien espacées ===
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final slot in _slots)
                _MiniSlot(
                  name: PrayerNames.french[slot.name]!,
                  time: today.all[slot]!,
                  large: large,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pilule glass d'une prière dans la mini-barre. Style cohérent avec
/// le reste de l'app (bulles arrondies, fond sombre semi-transparent,
/// liseré subtil). Le nom est en uppercase espacé pour évoquer les
/// affichages typographiques des grandes mosquées.
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
    final timeSize = large ? 30.0 : 22.0;
    final hPad = large ? 22.0 : 16.0;
    final vPad = large ? 12.0 : 9.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.07),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name.toUpperCase(),
            style: TextStyle(
              fontSize: nameSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary.withValues(alpha: 0.85),
              letterSpacing: 3,
              shadows: AppTheme.textShadow,
            ),
          ),
          SizedBox(height: large ? 4 : 2),
          Text(
            '$hh:$mm',
            style: TextStyle(
              fontSize: timeSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1,
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: AppTheme.textShadow,
            ),
          ),
        ],
      ),
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
