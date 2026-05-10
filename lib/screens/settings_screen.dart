import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/calculation_preset.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/prayer_provider.dart';
import '../services/update_service.dart';

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
              const _SectionTitle('Localisation'),
              DropdownButtonFormField<String>(
                initialValue:
                    PresetCities.coordinates.containsKey(settings.cityName)
                        ? settings.cityName
                        : null,
                decoration: const InputDecoration(
                  labelText: 'Ville',
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
                  ButtonSegment(value: Madhab.shafi, label: Text('Shafi')),
                  ButtonSegment(value: Madhab.hanafi, label: Text('Hanafi')),
                ],
                selected: {settings.madhab},
                onSelectionChanged: (selection) {
                  prayer.updateSettings(
                      settings.copyWith(madhab: selection.first));
                },
              ),
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
              ListTile(
                title: const Text('Décalage (jours)'),
                subtitle: Text(
                    'Pour ajuster avec l\'observation lunaire : ${settings.hijriOffset >= 0 ? '+' : ''}${settings.hijriOffset} jour(s)'),
                trailing: SizedBox(
                  width: 220,
                  child: Slider(
                    value: settings.hijriOffset.toDouble(),
                    min: -2,
                    max: 2,
                    divisions: 4,
                    label: '${settings.hijriOffset >= 0 ? '+' : ''}${settings.hijriOffset}',
                    onChanged: (v) {
                      prayer.updateSettings(
                          settings.copyWith(hijriOffset: v.round()));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Heure (été / hiver)'),
              _DstStatusCard(now: prayer.now),
              const SizedBox(height: 24),
              const _SectionTitle('Mises à jour'),
              _UpdateSection(),
              const SizedBox(height: 24),
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Coordonnées actuelles',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${settings.latitude.toStringAsFixed(4)}'),
                      Text(
                          'Longitude: ${settings.longitude.toStringAsFixed(4)}'),
                    ],
                  ),
                ),
              ),
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
  @override
  State<_UpdateSection> createState() => _UpdateSectionState();
}

class _UpdateSectionState extends State<_UpdateSection> {
  final _service = UpdateService();
  final _controller = TextEditingController();
  String? _status;
  UpdateInfo? _info;
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
      _info = null;
    });
    if (!mounted) return;
    final prayer = context.read<PrayerProvider>();
    await prayer.updateSettings(
        prayer.settings.copyWith(updateRepoUrl: repo));

    final result = await _service.checkLatestRelease(repo);
    if (!mounted) return;

    setState(() {
      _checking = false;
      _info = result;
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
                if (_info?.hasUpdate == true && _info?.apkDownloadUrl != null)
                  TextButton.icon(
                    onPressed: () {
                      // TODO: open URL on Android (url_launcher)
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger APK'),
                  ),
              ],
            ),
            if (_status != null) ...[
              const SizedBox(height: 12),
              Text(
                _status!,
                style: TextStyle(
                  color: _info?.hasUpdate == true
                      ? AppTheme.highlight
                      : AppTheme.textSecondary,
                ),
              ),
            ],
            if (_info?.releaseNotes.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                _info!.releaseNotes,
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
}
