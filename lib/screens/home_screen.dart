import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/display_mode.dart';
import '../core/islamic_events.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';
import '../providers/prayer_provider.dart';
import '../widgets/islamic_event_banner.dart';
import '../widgets/mawaqit_clock.dart';
import '../widgets/overlays.dart';
import '../widgets/prayer_card.dart';
import '../widgets/side_info.dart';
import 'monthly_screen.dart';
import 'qibla_screen.dart';
import 'settings_screen.dart';
import 'simulator_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayer, _) {
        final today = prayer.today;
        final tomorrow = prayer.tomorrow;
        if (today == null || tomorrow == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final ctx = prayer.displayContext;

        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              fit: StackFit.expand,
              children: [
                _BackgroundImage(dimming: prayer.settings.backgroundDimming),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 600),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildForMode(context, prayer, ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildForMode(
    BuildContext context,
    PrayerProvider prayer,
    DisplayContext ctx,
  ) {
    switch (ctx.mode) {
      case DisplayMode.adhan:
        return AdhanOverlay(
          slot: ctx.slot!,
          countdown: ctx.countdown!,
          today: prayer.today!,
        );
      case DisplayMode.postAdhan:
        return PostAdhanOverlay(
          countdown: ctx.countdown!,
          today: prayer.today!,
        );
      case DisplayMode.iqamaCountdown:
        return IqamaCountdownOverlay(
          slot: ctx.slot!,
          countdown: ctx.countdown!,
          today: prayer.today!,
        );
      case DisplayMode.postPrayer:
        return PostPrayerOverlay(
          countdown: ctx.countdown!,
          today: prayer.today!,
        );
      case DisplayMode.normal:
        return _MainView(key: const ValueKey('main'), prayer: prayer);
    }
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.dimming});

  /// 0 = image presque pure (peu lisible), 1 = quasi-noir (texte ultra net).
  final double dimming;

  @override
  Widget build(BuildContext context) {
    final base = dimming.clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/al-masjid-al-haram.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(color: Colors.black),
        ),
        // Voile dégradé pour assurer la lisibilité du texte par-dessus.
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: (base * 1.05).clamp(0.0, 1.0)),
                Colors.black.withValues(alpha: (base * 0.75).clamp(0.0, 1.0)),
                Colors.black.withValues(alpha: (base * 1.40).clamp(0.0, 1.0)),
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _MainView extends StatelessWidget {
  const _MainView({super.key, required this.prayer});
  final PrayerProvider prayer;

  /// Les 5 prières obligatoires affichées en bas du HomeScreen.
  /// Shurûq est volontairement absent ici : il est déjà affiché dans la
  /// pilule SideInfo en haut à gauche, pas besoin de doublon.
  static const _orderedSlots = [
    PrayerSlot.fajr,
    PrayerSlot.dhuhr,
    PrayerSlot.asr,
    PrayerSlot.maghrib,
    PrayerSlot.isha,
  ];

  PrayerCardState _stateFor(
    PrayerSlot slot,
    PrayerSlot? current,
    PrayerSlot? next,
    DateTime time,
    DateTime now,
  ) {
    if (current == slot) return PrayerCardState.current;
    if (next == slot) return PrayerCardState.next;
    if (time.isBefore(now)) return PrayerCardState.passed;
    return PrayerCardState.upcoming;
  }

  /// Calcule la "barre de vie" de la carte de la prière COURANTE uniquement.
  ///
  /// Retourne la fraction de temps restant avant la prochaine prière :
  /// 1.0 juste après l'adhan courant, 0.0 juste avant le suivant.
  /// La jauge se vide (style barre de vie qui descend).
  ///
  /// Renvoie null pour toutes les autres cartes (passées, suivante, à venir) :
  /// seule la prière courante porte la jauge.
  double? _fillFor(
    PrayerSlot slot,
    PrayerSlot? current,
    DateTime now,
    PrayerSchedule today,
    PrayerSchedule tomorrow,
  ) {
    if (current != slot) return null;

    final order = _orderedSlots.where((s) => s != PrayerSlot.sunrise).toList();

    // À ce stade, current == slot (non-null). On utilise slot pour avoir un
    // type non-nullable sans cast.
    final currentTime = today.all[slot];
    if (currentTime == null) return null;

    // Heure de la prière suivante (point d'arrivée de l'intervalle).
    DateTime? nextTime;
    final i = order.indexOf(slot);
    if (i >= 0 && i < order.length - 1) {
      nextTime = today.all[order[i + 1]];
    } else {
      nextTime = tomorrow.fajr;
    }
    if (nextTime == null) return null;

    final total = nextTime.difference(currentTime).inSeconds;
    if (total <= 0) return null;
    final elapsed = now.difference(currentTime).inSeconds.clamp(0, total);
    final progress = elapsed / total; // 0..1, fraction écoulée
    return (1.0 - progress).clamp(0.0, 1.0); // se vide
  }

  @override
  Widget build(BuildContext context) {
    final today = prayer.today!;
    final tomorrow = prayer.tomorrow!;
    final settings = prayer.settings;
    final next = prayer.nextPrayer;
    final current = prayer.currentPrayer;

    return LayoutBuilder(builder: (context, constraints) {
      // Facteur d'ajustement automatique : garantit que les 5 cartes et
      // l'horloge tiennent dans la fenêtre, quelle que soit sa taille.
      // On calcule séparément la contrainte largeur (5 cartes côte-à-côte)
      // et la contrainte hauteur (cartes + horloge + header), puis on prend
      // le minimum. Les paramètres de l'utilisateur (cardScale, clockScale…)
      // sont respectés — on ne réduit que si nécessaire.
      final avW = (constraints.maxWidth - 40.0).clamp(1.0, double.infinity);
      final avH = (constraints.maxHeight - 28.0).clamp(1.0, double.infinity);
      final csCard = settings.cardScale * settings.fontScale;
      final csClock = settings.clockScale * settings.fontScale;

      // Largeur : 5 cartes × 170px + 24px de marge minimale entre elles.
      final wFit = (avW - 24.0) / (170.0 * csCard * 5);
      // Hauteur : header (~60px) + espaces (~20px) + horloge (~242px à
      // scale 1) + cartes (210px à scale 1) doivent tenir dans avH.
      final hFit =
          (avH - 80.0) / (242.0 * csClock + 210.0 * csCard);
      final fit = min(1.0, min(wFit, hFit)).clamp(0.4, 1.0);

      final cCard = csCard * fit;
      final cClock = csClock * fit;
      final cSide = settings.sideScale * settings.fontScale * fit;
      final cHeader = settings.headerScale * settings.fontScale * fit;

      // === Logique Jumu'ah (vendredi) ===
      // Le vendredi avec Jumu'ah activé, la pilule Jumu'ah (à droite) prend
      // la place de Dhuhr dans le compteur et la mise en avant visuelle.
      // La carte Dhuhr reste affichée mais en état neutre (jamais current/next).
      final isFridayJumuah = today.isJumuah && settings.jumuahEnabled;
      final jumuahTime = isFridayJumuah
          ? DateTime(prayer.now.year, prayer.now.month, prayer.now.day,
              settings.jumuahHour, settings.jumuahMinute)
          : null;
      final asrTime = today.all[PrayerSlot.asr];

      bool jumuahSideActive = false;
      String? jumuahClockLabel;
      Duration displayUntilNext = prayer.untilNext;
      PrayerSlot? displayNextSlot = next?.slot;

      if (isFridayJumuah && jumuahTime != null) {
        final now = prayer.now;
        if (now.isBefore(jumuahTime)) {
          // Jumu'ah est à venir → c'est elle la "prochaine prière" à afficher
          jumuahSideActive = true;
          jumuahClockLabel = 'Jumu\'ah';
          displayUntilNext = jumuahTime.difference(now);
          displayNextSlot = next?.slot ?? PrayerSlot.dhuhr;
        } else if (asrTime != null && now.isBefore(asrTime)) {
          // Jumu'ah en cours (entre heure Jumu'ah et Asr)
          jumuahSideActive = true;
        }
      }

      // État d'une carte : sur Dhuhr le vendredi, jamais current ni next.
      PrayerCardState cardState(PrayerSlot slot) {
        var state = _stateFor(
            slot, current, next?.slot, today.all[slot]!, prayer.now);
        if (isFridayJumuah && slot == PrayerSlot.dhuhr) {
          if (state == PrayerCardState.current ||
              state == PrayerCardState.next) {
            state = today.all[slot]!.isBefore(prayer.now)
                ? PrayerCardState.passed
                : PrayerCardState.upcoming;
          }
        }
        return state;
      }

      // Événements islamiques pour la date effective
      final islamicEvent = IslamicCalendar.topEventFor(
        prayer.now,
        hijriOffset: settings.hijriOffset,
      );

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            children: [
              _Header(
                mosqueeName: settings.mosqueeName,
                cityName: settings.cityName,
                hasUpdate: prayer.availableUpdate?.hasUpdate ?? false,
                isAdhanPlaying: prayer.audio.isPlaying,
                onStopAdhan: prayer.stopAdhan,
                scale: cHeader,
                isSimulating: prayer.isSimulating,
                onStopSimulation: prayer.stopSimulation,
              ),
              const SizedBox(height: 6),
              // Bannière islamique + indicateur simulation (slim, n'occupe pas de place si vide)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (prayer.isSimulating) ...[
                    _SimulationBadge(
                        now: prayer.now,
                        onStop: prayer.stopSimulation),
                    const SizedBox(width: 10),
                  ],
                  if (islamicEvent != null)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: IslamicEventBanner(
                          event: islamicEvent, scale: fit),
                    ),
                ],
              ),
              if (islamicEvent != null || prayer.isSimulating)
                const SizedBox(height: 6),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SideInfo(
                      label: 'Shurûq',
                      arabicLabel: 'الشروق',
                      time: today.sunrise,
                      scale: cSide,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MawaqitClock(
                            now: prayer.now,
                            nextSlot: displayNextSlot,
                            untilNext: displayUntilNext,
                            hijriOffset: settings.hijriOffset,
                            scale: cClock,
                            nextSlotLabel: jumuahClockLabel,
                          ),
                          const SizedBox(height: 10),
                          _DigitalClockBar(now: prayer.now),
                        ],
                      ),
                    ),
                    SideInfo(
                      label: 'Jumu\'ah',
                      arabicLabel: 'الجمعة',
                      time: settings.jumuahEnabled
                          ? DateTime(
                              prayer.now.year,
                              prayer.now.month,
                              prayer.now.day,
                              settings.jumuahHour,
                              settings.jumuahMinute,
                            )
                          : null,
                      scale: cSide,
                      isActive: jumuahSideActive,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  for (var i = 0; i < _orderedSlots.length; i++)
                    SizedBox(
                      width: 170 * cCard,
                      height: 210 * cCard,
                      child: PrayerCard(
                        slot: _orderedSlots[i],
                        time: today.all[_orderedSlots[i]]!,
                        iqamaMinutes: settings.iqamaMinutes,
                        showIqama: _orderedSlots[i] != PrayerSlot.sunrise,
                        scale: cCard,
                        now: prayer.now,
                        state: cardState(_orderedSlots[i]),
                        isJumuah: false,
                        fillProgress: isFridayJumuah &&
                                _orderedSlots[i] == PrayerSlot.dhuhr
                            ? null
                            : _fillFor(
                                _orderedSlots[i],
                                current,
                                prayer.now,
                                today,
                                tomorrow,
                              ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Pilule date grégorienne complète (l'heure HH:MM est déjà en gros au-dessus).
class _DigitalClockBar extends StatelessWidget {
  const _DigitalClockBar({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE d MMMM y', 'fr_FR').format(now);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.event_outlined,
              size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 6),
          Text(
            date,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
              shadows: AppTheme.textShadow,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mosqueeName,
    required this.cityName,
    required this.hasUpdate,
    required this.isAdhanPlaying,
    required this.onStopAdhan,
    required this.scale,
    required this.isSimulating,
    required this.onStopSimulation,
  });

  final String mosqueeName;
  final String cityName;
  final bool hasUpdate;
  final ValueListenable<bool> isAdhanPlaying;
  final Future<void> Function() onStopAdhan;
  final double scale;
  final bool isSimulating;
  final VoidCallback onStopSimulation;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // La pilule du nom de mosquée est CENTRÉE indépendamment, et prend
        // juste la largeur de son texte (IntrinsicWidth via la Column avec
        // mainAxisSize.min). Comme ça, "Mosquée de Ganges" ne crée pas une
        // grande bulle vide à droite.
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mosqueeName,
                  style: TextStyle(
                    fontSize: 18 * scale,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.4,
                    height: 1.1,
                    shadows: AppTheme.textShadow,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  cityName,
                  style: TextStyle(
                    fontSize: 11 * scale,
                    color: AppTheme.textPrimary.withValues(alpha: 0.85),
                    shadows: AppTheme.textShadow,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        // Les boutons sont superposés en gauche/droite de la pilule, dans
        // un Row qui prend toute la largeur. Comme ça la pilule reste bien
        // centrée même si on a 2 ou 3 boutons à droite.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _GlassIconButton(
              icon: Icons.explore,
              tooltip: 'Qibla',
              autofocus: true,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QiblaScreen()),
              ),
            ),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: Icons.calendar_month,
              tooltip: 'Calendrier mensuel',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonthlyScreen()),
              ),
            ),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: Icons.science_outlined,
              tooltip: 'Simulateur de temps',
              iconColor: isSimulating ? Colors.redAccent : null,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SimulatorScreen()),
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isAdhanPlaying,
                builder: (context, playing, _) {
                  if (!playing) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _GlassIconButton(
                      icon: Icons.stop_circle,
                      iconColor: AppTheme.highlight,
                      tooltip: 'Stopper l\'adhan',
                      onPressed: onStopAdhan,
                    ),
                  );
                },
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _GlassIconButton(
                    icon: Icons.settings,
                    tooltip: 'Paramètres',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    ),
                  ),
                  if (hasUpdate)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppTheme.highlight,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.black, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          ],
        ),
      ],
    );
  }
}

/// Bouton glass focus-aware. En mode TV (télécommande), le focus apparaît
/// avec un halo orange + agrandissement, ce qui rend la navigation D-pad
/// claire à l'écran.
class _GlassIconButton extends StatefulWidget {
  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.iconColor,
    this.autofocus = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? iconColor;
  final bool autofocus;

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

/// Pilule rouge "SIMULATION" affichée dans le HomeScreen quand le mode
/// simulation est actif. Indique l'heure simulée et offre un bouton stop.
class _SimulationBadge extends StatelessWidget {
  const _SimulationBadge({required this.now, required this.onStop});
  final DateTime now;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final dateStr = DateFormat('d MMM', 'fr_FR').format(now);
    return GestureDetector(
      onTap: onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.75)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.science_outlined,
                size: 12, color: Colors.redAccent),
            const SizedBox(width: 5),
            Text(
              'SIM  $timeStr  $dateStr',
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.close, size: 11, color: Colors.redAccent),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? AppTheme.highlight
        : Colors.white.withValues(alpha: 0.20);
    final bgColor = _focused
        ? AppTheme.highlight.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.40);

    final btn = AnimatedScale(
      duration: const Duration(milliseconds: 150),
      scale: _focused ? 1.12 : 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppTheme.highlight.withValues(alpha: 0.55),
                    blurRadius: 18,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Material(
          color: bgColor,
          shape: CircleBorder(
            side: BorderSide(
              color: borderColor,
              width: _focused ? 2.5 : 1.2,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onFocusChange: (f) => setState(() => _focused = f),
            autofocus: widget.autofocus,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(
                widget.icon,
                size: 28,
                color: widget.iconColor ??
                    (_focused
                        ? AppTheme.highlight
                        : AppTheme.textPrimary.withValues(alpha: 0.85)),
              ),
            ),
          ),
        ),
      ),
    );
    return widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: btn)
        : btn;
  }
}
