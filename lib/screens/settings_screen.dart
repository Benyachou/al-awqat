import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:hijri/hijri_calendar.dart';

import '../core/calculation_preset.dart';
import '../core/constants.dart';
import '../core/hijri_helper.dart';
import '../core/prayer_engine.dart';
import '../core/theme.dart';
import '../providers/prayer_provider.dart';
import '../services/geocoding_service.dart';
import '../services/update_service.dart';
import 'simulator_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: AppTheme.surface,
      ),
      body: Consumer<PrayerProvider>(
        builder: (context, prayer, _) {
          final settings = prayer.settings;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const _SectionTitle('Mosquée'),
              _MosqueeNameField(),
              const SizedBox(height: 24),
              const _SectionTitle('Affichage'),
              _DisplaySection(),
              const SizedBox(height: 24),
              const _SectionTitle('Localisation'),
              _LocationSection(),
              const SizedBox(height: 24),
              const _SectionTitle('Méthode de calcul'),
              DropdownButtonFormField<String>(
                initialValue: settings.calculationPresetKey,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: CalculationPreset.all
                    .map((p) => DropdownMenuItem(
                          value: p.key,
                          child: Text(p.label),
                        ))
                    .toList(),
                onChanged: (key) {
                  if (key == null) return;
                  prayer.updateSettings(
                      settings.copyWith(calculationPresetKey: key));
                },
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Madhab (calcul du Asr)'),
              SegmentedButton<Madhab>(
                segments: const [
                  ButtonSegment(
                    value: Madhab.shafi,
                    label: Text('Shafi / Maliki / Hanbali'),
                  ),
                  ButtonSegment(
                    value: Madhab.hanafi,
                    label: Text('Hanafi'),
                  ),
                ],
                selected: {settings.madhab},
                onSelectionChanged: (selection) {
                  prayer.updateSettings(
                      settings.copyWith(madhab: selection.first));
                },
              ),
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Maliki et Hanbali utilisent le même calcul de Asr que Shafi (ombre = 1× la hauteur de l\'objet).',
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Source des horaires (Mawaqit)'),
              const _MawaqitSection(),
              const SizedBox(height: 24),
              const _SectionTitle('Ajustements fins (par prière)'),
              const _OffsetsSection(),
              const SizedBox(height: 24),
              const _SectionTitle('Jumu\'ah (vendredi)'),
              SwitchListTile(
                title: const Text(
                    'Remplacer Dhuhr par Jumu\'ah le vendredi'),
                value: settings.jumuahEnabled,
                onChanged: (v) => prayer
                    .updateSettings(settings.copyWith(jumuahEnabled: v)),
              ),
              if (settings.jumuahEnabled)
                ListTile(
                  title: const Text('Heure de Jumu\'ah'),
                  subtitle: Text(
                      '${settings.jumuahHour.toString().padLeft(2, '0')}:${settings.jumuahMinute.toString().padLeft(2, '0')}'),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: settings.jumuahHour,
                          minute: settings.jumuahMinute,
                        ),
                      );
                      if (picked != null) {
                        await prayer.updateSettings(settings.copyWith(
                          jumuahHour: picked.hour,
                          jumuahMinute: picked.minute,
                        ));
                      }
                    },
                    child: const Text('Modifier'),
                  ),
                ),
              const SizedBox(height: 24),
              const _SectionTitle('Adhan'),
              SwitchListTile(
                title: const Text('Jouer l\'adhan à l\'heure de la prière'),
                value: settings.playAdhan,
                onChanged: (value) {
                  prayer.updateSettings(settings.copyWith(playAdhan: value));
                },
              ),
              ListTile(
                title: const Text('Volume'),
                subtitle: Text(
                    '${(settings.adhanVolume * 100).round()} %'),
                trailing: SizedBox(
                  width: 220,
                  child: Slider(
                    value: settings.adhanVolume,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    label: '${(settings.adhanVolume * 100).round()} %',
                    onChanged: (v) {
                      prayer.updateSettings(
                          settings.copyWith(adhanVolume: v));
                    },
                  ),
                ),
              ),
              ListTile(
                title: const Text('Tester l\'adhan maintenant'),
                trailing: ElevatedButton.icon(
                  onPressed: () => prayer.audio.playAdhan(),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test'),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Iqama'),
              ListTile(
                title: const Text('Délai après l\'adhan'),
                subtitle: Text('${settings.iqamaMinutes} minutes'),
                trailing: SizedBox(
                  width: 220,
                  child: Slider(
                    value: settings.iqamaMinutes.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${settings.iqamaMinutes} min',
                    onChanged: (v) {
                      prayer.updateSettings(
                          settings.copyWith(iqamaMinutes: v.round()));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Calendrier Hijri'),
              const _HijriSection(),
              const SizedBox(height: 24),
              const _SectionTitle('Heure (été / hiver)'),
              _DstStatusCard(now: prayer.now),
              const SizedBox(height: 24),
              const _SectionTitle('Simulateur'),
              Card(
                color: AppTheme.surface,
                child: ListTile(
                  leading: const Icon(Icons.science_outlined,
                      color: AppTheme.accent),
                  title: const Text('Ouvrir le simulateur'),
                  subtitle: const Text(
                    'Navigue dans le temps, teste chaque phase (adhan, iqama, adhkar) et explore le calendrier islamique.',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SimulatorScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Mises à jour'),
              const _UpdateSection(),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppTheme.accent,
        ),
      ),
    );
  }
}

class _MosqueeNameField extends StatefulWidget {
  @override
  State<_MosqueeNameField> createState() => _MosqueeNameFieldState();
}

class _MosqueeNameFieldState extends State<_MosqueeNameField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: context.read<PrayerProvider>().settings.mosqueeName,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _ctrl,
          decoration: const InputDecoration(
            labelText: 'Nom affiché en haut de l\'écran',
            hintText: 'ex : Mosquée Al-Falah - Ganges',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) {
            final prayer = context.read<PrayerProvider>();
            prayer.updateSettings(
              prayer.settings.copyWith(mosqueeName: v.trim().isEmpty
                  ? prayer.settings.mosqueeName
                  : v.trim()),
            );
          },
          onChanged: (v) {
            final prayer = context.read<PrayerProvider>();
            if (v.trim().isEmpty) return;
            prayer.updateSettings(
              prayer.settings.copyWith(mosqueeName: v.trim()),
            );
          },
        ),
      ),
    );
  }
}

class _DisplaySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final settings = prayer.settings;
    final pct = (settings.backgroundDimming * 100).round();
    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contrast, color: AppTheme.accent),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Assombrissement de l\'arrière-plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '$pct %',
                  style: const TextStyle(
                    color: AppTheme.highlight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Slider(
              value: settings.backgroundDimming.clamp(0.0, 1.0),
              min: 0,
              max: 1,
              divisions: 20,
              label: '$pct %',
              onChanged: (v) => prayer.updateSettings(
                  settings.copyWith(backgroundDimming: v)),
            ),
            const Text(
              'Plus c\'est élevé, plus le fond est sombre et le texte lisible.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const Divider(height: 32, color: AppTheme.divider),
            const Text(
              'Taille générale des polices',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Multiplie toutes les tailles à la fois — pratique pour grossir tout d\'un coup.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            _ScaleSlider(
              icon: Icons.format_size,
              label: 'Toutes les polices',
              value: settings.fontScale,
              onChanged: (v) =>
                  prayer.updateSettings(settings.copyWith(fontScale: v)),
            ),
            const Divider(height: 32, color: AppTheme.divider),
            const Text(
              'Tailles par zone (en %)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pour ajuster une zone précise sans toucher au reste.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            _ScaleSlider(
              icon: Icons.access_time,
              label: 'Horloge centrale',
              value: settings.clockScale,
              onChanged: (v) =>
                  prayer.updateSettings(settings.copyWith(clockScale: v)),
            ),
            _ScaleSlider(
              icon: Icons.view_column,
              label: 'Pilules Shurûq / Jumu\'ah',
              value: settings.sideScale,
              onChanged: (v) =>
                  prayer.updateSettings(settings.copyWith(sideScale: v)),
            ),
            _ScaleSlider(
              icon: Icons.calendar_view_month,
              label: 'Cartes des prières (en bas)',
              value: settings.cardScale,
              onChanged: (v) =>
                  prayer.updateSettings(settings.copyWith(cardScale: v)),
            ),
            _ScaleSlider(
              icon: Icons.title,
              label: 'En-tête (nom mosquée)',
              value: settings.headerScale,
              onChanged: (v) =>
                  prayer.updateSettings(settings.copyWith(headerScale: v)),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Réinitialiser toutes les tailles'),
                onPressed: () => prayer.updateSettings(settings.copyWith(
                  clockScale: 1.0,
                  sideScale: 1.0,
                  cardScale: 1.0,
                  headerScale: 1.0,
                  fontScale: 1.0,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleSlider extends StatelessWidget {
  const _ScaleSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0.4, 2.0),
              min: 0.4,
              max: 2.0,
              divisions: 32,
              label: '$pct %',
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              '$pct %',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppTheme.highlight,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final settings = prayer.settings;

    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: PresetCities.coordinates.containsKey(settings.cityName)
                  ? settings.cityName
                  : null,
              decoration: const InputDecoration(
                labelText: 'Ville préréglée',
                border: OutlineInputBorder(),
              ),
              items: PresetCities.coordinates.keys
                  .map((city) =>
                      DropdownMenuItem(value: city, child: Text(city)))
                  .toList(),
              onChanged: (city) {
                if (city == null) return;
                final coords = PresetCities.coordinates[city]!;
                prayer.updateSettings(settings.copyWith(
                  cityName: city,
                  latitude: coords.$1,
                  longitude: coords.$2,
                ));
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSearch(context),
                    icon: const Icon(Icons.search),
                    label: const Text('Chercher une autre ville'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showManual(context),
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text('Saisir lat/long'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Lat ${settings.latitude.toStringAsFixed(4)} · '
              'Lng ${settings.longitude.toStringAsFixed(4)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSearch(BuildContext context) async {
    final result = await showDialog<GeocodingResult>(
      context: context,
      builder: (_) => const _CitySearchDialog(),
    );
    if (result != null && context.mounted) {
      final prayer = context.read<PrayerProvider>();
      await prayer.updateSettings(prayer.settings.copyWith(
        cityName: result.displayName,
        latitude: result.latitude,
        longitude: result.longitude,
      ));
    }
  }

  Future<void> _showManual(BuildContext context) async {
    final prayer = context.read<PrayerProvider>();
    final result = await showDialog<({double lat, double lng, String name})>(
      context: context,
      builder: (_) => _ManualCoordsDialog(initial: prayer.settings),
    );
    if (result != null && context.mounted) {
      await prayer.updateSettings(prayer.settings.copyWith(
        cityName: result.name,
        latitude: result.lat,
        longitude: result.lng,
      ));
    }
  }
}

class _CitySearchDialog extends StatefulWidget {
  const _CitySearchDialog();

  @override
  State<_CitySearchDialog> createState() => _CitySearchDialogState();
}

class _CitySearchDialogState extends State<_CitySearchDialog> {
  final _service = GeocodingService();
  final _controller = TextEditingController();
  List<GeocodingResult> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = const [];
    });
    final res = await _service.search(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _results = res;
      if (res.isEmpty) _error = 'Aucun résultat (réseau ?)';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rechercher une ville'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ex : Lille, France',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 12),
            if (_loading) const CircularProgressIndicator(),
            if (_error != null)
              Text(_error!,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final r = _results[i];
                  return ListTile(
                    title: Text(
                      r.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                        '${r.latitude.toStringAsFixed(4)}, ${r.longitude.toStringAsFixed(4)}'),
                    onTap: () => Navigator.pop(context, r),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _ManualCoordsDialog extends StatefulWidget {
  const _ManualCoordsDialog({required this.initial});
  final dynamic initial;

  @override
  State<_ManualCoordsDialog> createState() => _ManualCoordsDialogState();
}

class _ManualCoordsDialogState extends State<_ManualCoordsDialog> {
  late final TextEditingController _name;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.cityName);
    _lat = TextEditingController(text: widget.initial.latitude.toString());
    _lng = TextEditingController(text: widget.initial.longitude.toString());
  }

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  void _validate() {
    final lat = double.tryParse(_lat.text);
    final lng = double.tryParse(_lng.text);
    if (lat == null || lng == null) {
      setState(() => _error = 'Latitude / longitude invalides');
      return;
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      setState(() => _error = 'Hors limites (-90..90 / -180..180)');
      return;
    }
    Navigator.pop(
      context,
      (lat: lat, lng: lng, name: _name.text.trim().isEmpty ? 'Coords personnalisées' : _name.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Coordonnées manuelles'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nom du lieu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lat,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
              ],
              decoration: const InputDecoration(
                labelText: 'Latitude (°)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lng,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: true, decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))
              ],
              decoration: const InputDecoration(
                labelText: 'Longitude (°)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFEF5350))),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
        ElevatedButton(onPressed: _validate, child: const Text('Valider')),
      ],
    );
  }
}

class _OffsetsSection extends StatelessWidget {
  const _OffsetsSection();

  static const _slots = [
    PrayerSlot.fajr,
    PrayerSlot.sunrise,
    PrayerSlot.dhuhr,
    PrayerSlot.asr,
    PrayerSlot.maghrib,
    PrayerSlot.isha,
  ];

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final settings = prayer.settings;

    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Ajuste finement chaque prière (en minutes) pour t\'aligner sur la mosquée locale.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12),
              ),
            ),
            ..._slots.map((slot) {
              final value = settings.offsetFor(slot);
              return ListTile(
                dense: true,
                title: Text(PrayerNames.french[slot.name]!),
                subtitle: Text(value == 0
                    ? 'Pas d\'ajustement'
                    : '${value > 0 ? '+' : ''}$value min'),
                trailing: SizedBox(
                  width: 160,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: value > -15
                            ? () => _bump(prayer, slot, -1)
                            : null,
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${value > 0 ? '+' : ''}$value',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: value < 15
                            ? () => _bump(prayer, slot, 1)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _bump(PrayerProvider prayer, PrayerSlot slot, int delta) {
    final settings = prayer.settings;
    final next = Map<PrayerSlot, int>.from(settings.prayerOffsets);
    final v = (next[slot] ?? 0) + delta;
    if (v == 0) {
      next.remove(slot);
    } else {
      next[slot] = v;
    }
    prayer.updateSettings(settings.copyWith(prayerOffsets: next));
  }
}

class _HijriSection extends StatelessWidget {
  const _HijriSection();

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final settings = prayer.settings;
    final adjusted = prayer.now.add(Duration(days: settings.hijriOffset));
    final hijri = HijriCalendar.fromDate(adjusted);

    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.brightness_3, color: AppTheme.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Date hijrie affichée',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${hijri.hDay} ${HijriHelper.monthNames[hijri.hMonth - 1]} ${hijri.hYear}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Définir'),
                  onPressed: () => _openPicker(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Décalage actuel : ${settings.hijriOffset >= 0 ? '+' : ''}${settings.hijriOffset} jour(s)',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 4),
            Slider(
              value: settings.hijriOffset.toDouble().clamp(-15, 15),
              min: -15,
              max: 15,
              divisions: 30,
              label: '${settings.hijriOffset >= 0 ? '+' : ''}${settings.hijriOffset}',
              onChanged: (v) {
                prayer.updateSettings(
                    settings.copyWith(hijriOffset: v.round()));
              },
            ),
            const Text(
              'Ajustement rapide en jours grégoriens, à utiliser si l\'observation '
              'lunaire locale décale d\'un jour ou deux par rapport au calcul.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    final prayer = context.read<PrayerProvider>();
    final adjusted =
        prayer.now.add(Duration(days: prayer.settings.hijriOffset));
    final initial = HijriCalendar.fromDate(adjusted);
    final result = await showDialog<({int year, int month, int day})>(
      context: context,
      builder: (_) => _HijriPickerDialog(
        initialYear: initial.hYear,
        initialMonth: initial.hMonth,
        initialDay: initial.hDay,
      ),
    );
    if (result == null || !context.mounted) return;

    final today = DateTime(prayer.now.year, prayer.now.month, prayer.now.day);
    final newOffset = HijriHelper.offsetForObservedDate(
      todayGregorian: today,
      observedYear: result.year,
      observedMonth: result.month,
      observedDay: result.day,
    );
    if (newOffset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Date trop éloignée de la date calculée (>15 jours). Vérifie l\'année/le mois.'),
        ),
      );
      return;
    }
    await prayer.updateSettings(
        prayer.settings.copyWith(hijriOffset: newOffset));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Décalage défini à ${newOffset >= 0 ? '+' : ''}$newOffset jour(s).'),
      ),
    );
  }
}

class _HijriPickerDialog extends StatefulWidget {
  const _HijriPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.initialDay,
  });

  final int initialYear;
  final int initialMonth;
  final int initialDay;

  @override
  State<_HijriPickerDialog> createState() => _HijriPickerDialogState();
}

class _HijriPickerDialogState extends State<_HijriPickerDialog> {
  late int _year;
  late int _month;
  late int _day;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear;
    _month = widget.initialMonth;
    _day = widget.initialDay;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Date hijrie observée aujourd\'hui'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indique la date hijrie réelle d\'aujourd\'hui (selon ton observation '
              'ou ta mosquée). L\'app calculera automatiquement le décalage à '
              'appliquer pour les jours suivants.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: DropdownButtonFormField<int>(
                    initialValue: _day,
                    decoration: const InputDecoration(
                      labelText: 'Jour',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(30, (i) => i + 1)
                        .map((d) => DropdownMenuItem(
                              value: d,
                              child: Text('$d'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _day = v ?? _day),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _month,
                    decoration: const InputDecoration(
                      labelText: 'Mois',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(12, (i) => i + 1)
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(HijriHelper.monthNames[m - 1]),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _month = v ?? _month),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: DropdownButtonFormField<int>(
                    initialValue: _year,
                    decoration: const InputDecoration(
                      labelText: 'Année',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(7, (i) => widget.initialYear - 3 + i)
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _year = v ?? _year),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(
            context,
            (year: _year, month: _month, day: _day),
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}

class _DstStatusCard extends StatelessWidget {
  const _DstStatusCard({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final offset = now.timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60).abs();
    final sign = hours >= 0 ? '+' : '-';
    final offsetStr =
        'UTC$sign${hours.abs().toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';

    final winterOffset = DateTime(now.year, 1, 1).timeZoneOffset;
    final summerOffset = DateTime(now.year, 7, 1).timeZoneOffset;
    final maxOffset = winterOffset > summerOffset ? winterOffset : summerOffset;
    final inDst = offset == maxOffset && winterOffset != summerOffset;

    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  inDst ? Icons.wb_sunny : Icons.ac_unit,
                  color: inDst ? AppTheme.highlight : AppTheme.accent,
                ),
                const SizedBox(width: 12),
                Text(
                  inDst ? 'Heure d\'été (DST)' : 'Heure d\'hiver',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Fuseau : ${now.timeZoneName} ($offsetStr)'),
            const SizedBox(height: 4),
            const Text(
              'Le passage été/hiver est géré automatiquement par le système.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdateSection extends StatefulWidget {
  const _UpdateSection();

  @override
  State<_UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<_UpdateSection> {
  final _controller = TextEditingController();
  String? _status;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    final initial =
        context.read<PrayerProvider>().settings.updateRepoUrl ?? '';
    _controller.text = initial;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final repo = _controller.text.trim();
    if (repo.isEmpty) {
      setState(() => _status = 'Indique le dépôt GitHub (owner/repo)');
      return;
    }
    setState(() {
      _checking = true;
      _status = null;
    });
    final prayer = context.read<PrayerProvider>();
    await prayer.updateSettings(
        prayer.settings.copyWith(updateRepoUrl: repo));

    final result = await prayer.checkForUpdates();
    if (!mounted) return;

    setState(() {
      _checking = false;
      if (result == null) {
        _status =
            'Impossible de vérifier (réseau ? dépôt introuvable ? aucune release ?)';
      } else if (!result.hasUpdate) {
        _status =
            'À jour (version actuelle ${result.currentVersion}, dernière ${result.latestVersion})';
      } else {
        _status =
            'Nouvelle version disponible : ${result.latestVersion} (actuelle ${result.currentVersion})';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prayer = context.watch<PrayerProvider>();
    final info = prayer.availableUpdate;

    return Card(
      color: AppTheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Dépôt GitHub (owner/repo)',
                hintText: 'ex: yassine/al-awqat',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Vérifier automatiquement (1x/jour)'),
              value: prayer.settings.autoCheckUpdates,
              onChanged: (v) => prayer.updateSettings(
                  prayer.settings.copyWith(autoCheckUpdates: v)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _checking ? null : _check,
                  icon: _checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: const Text('Vérifier maintenant'),
                ),
                const SizedBox(width: 12),
                if (info != null && info.hasUpdate)
                  TextButton.icon(
                    onPressed: () =>
                        _open(info.apkDownloadUrl ?? info.releaseUrl),
                    icon: const Icon(Icons.download),
                    label: Text(info.apkDownloadUrl != null
                        ? 'Télécharger APK'
                        : 'Voir la release'),
                  ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: TextStyle(
                  color: info?.hasUpdate == true
                      ? AppTheme.highlight
                      : AppTheme.textSecondary,
                ),
              ),
            ],
            if (info?.releaseNotes.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                info!.releaseNotes,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _open(String url) async {
    final ok = await UpdateService().openUrl(url);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d\'ouvrir $url')),
      );
    }
  }
}

// =============================================================================
// Section Mawaqit dans les Paramètres
// =============================================================================

class _MawaqitSection extends StatefulWidget {
  const _MawaqitSection();

  @override
  State<_MawaqitSection> createState() => _MawaqitSectionState();
}

class _MawaqitSectionState extends State<_MawaqitSection> {
  late final TextEditingController _slugCtrl;

  @override
  void initState() {
    super.initState();
    final slug =
        context.read<PrayerProvider>().settings.mawaqitSlug ?? '';
    _slugCtrl = TextEditingController(text: slug);
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerProvider>(
      builder: (context, prayer, _) {
        final settings = prayer.settings;
        final status = prayer.mawaqitStatus;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Utiliser Mawaqit'),
              subtitle: const Text(
                'Remplace le calcul local par les horaires de ta mosquée sur mawaqit.net.',
                style: TextStyle(fontSize: 12),
              ),
              value: settings.useMawaqit,
              onChanged: (v) {
                prayer.updateSettings(settings.copyWith(useMawaqit: v));
              },
            ),
            if (settings.useMawaqit) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _slugCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Slug de la mosquée',
                          hintText: 'ex: ascg-ganges-34190-france',
                          border: OutlineInputBorder(),
                          helperText:
                              'Visible dans l\'URL de ta mosquée sur mawaqit.net/fr/{slug}',
                          helperMaxLines: 2,
                        ),
                        onSubmitted: (v) => _applySlug(prayer, v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _applySlug(prayer, _slugCtrl.text),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _StatusBadge(status),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => prayer.refreshMawaqit(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Rafraîchir'),
                    ),
                  ],
                ),
              ),
              if (status == MawaqitStatus.error)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Text(
                    'Impossible de joindre Mawaqit. Vérifie le slug et ta connexion.\nLes horaires calculés localement sont utilisés en attendant.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }

  void _applySlug(PrayerProvider prayer, String value) {
    final trimmed = value.trim();
    prayer.updateSettings(
      trimmed.isEmpty
          ? prayer.settings.copyWith(clearMawaqitSlug: true)
          : prayer.settings.copyWith(mawaqitSlug: trimmed),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final MawaqitStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, String label) = switch (status) {
      MawaqitStatus.ok => (Colors.green, Icons.check_circle, 'Connecté'),
      MawaqitStatus.loading => (Colors.orange, Icons.sync, 'Connexion…'),
      MawaqitStatus.error => (Colors.red, Icons.error_outline, 'Erreur'),
      MawaqitStatus.disabled => (Colors.grey, Icons.cloud_off, 'Désactivé'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
