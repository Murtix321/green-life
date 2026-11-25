import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../services/plant_id.dart';
import '../services/store.dart';
import '../services/weather.dart';
import '../theme.dart';
import '../widgets/glass.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const credits = [
    'Keman yapraklı incir — Marc Riera, iNaturalist (CC BY)',
    'Salon sarmaşığı — Spnq, Wikimedia Commons (CC BY-SA 4.0)',
    'Zamia — Dbwolfe, Wikimedia Commons (CC BY-SA 4.0)',
    'Aloe vera — Serah04, Wikimedia Commons (CC BY-SA 4.0)',
    'Barış çiçeği, kurdele çiçeği, paşa kılıcı — zebedeugalinha, iNaturalist (CC BY)',
    'Paşa kılıcı (orta boy) — Mokkie, Wikimedia Commons (kamu malı)',
    'Orkide — Nielbert Raner, iNaturalist (CC BY)',
    'Arka plan yaprakları — Jacqui Geux, Wesley Webb, iNaturalist (CC BY)',
    'Bitki verisi: Pl@ntNet, iNaturalist, Vikipedi · Hava: Open-Meteo',
  ];

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final initial = store.firstName.isEmpty ? '?' : store.firstName.characters.first.toUpperCase();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          const Text('Profil', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 12),
          Glass(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: GL.green,
                  foregroundImage: store.photoUrl == null ? null : NetworkImage(store.photoUrl!),
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(store.userName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      Text(store.userEmail, style: const TextStyle(fontSize: 13, color: GL.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Stat(value: '${store.plants.length}', label: 'bitki')),
              const SizedBox(width: 10),
              Expanded(child: _Stat(value: '${store.dueToday.length}', label: 'bugün su istiyor')),
            ],
          ),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                SwitchListTile(
                  value: store.alarmOn,
                  onChanged: store.setAlarm,
                  secondary: const Icon(Icons.alarm_rounded, color: GL.greenDark),
                  title: const Text('Sulama alarmları', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Sulama günü gelince bildirim gönder'),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule_rounded, color: GL.greenDark),
                  title: const Text('Alarm saati', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Text(store.alarmTimeText, style: const TextStyle(fontWeight: FontWeight.w800, color: GL.greenDark)),
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: store.alarmHour, minute: store.alarmMinute),
                    );
                    if (t != null) store.setAlarmTime(t.hour, t.minute);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.location_city_rounded, color: GL.greenDark),
                  title: const Text('Şehir (hava durumu)', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Text(store.cityName, style: const TextStyle(fontWeight: FontWeight.w800, color: GL.greenDark)),
                  onTap: () => _pickCity(context, store),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Glass(
            child: Row(
              children: [
                Icon(PlantIdService.hasPlantNet ? Icons.check_circle_rounded : Icons.info_outline_rounded, color: GL.greenDark),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    PlantIdService.hasPlantNet
                        ? 'Fotoğrafla bitki tanıma açık (Pl@ntNet).'
                        : 'Fotoğrafla tanıma için Pl@ntNet anahtarı eklenmedi. Bitkileri "Bitki ara" ile ekleyebilirsin.',
                    style: const TextStyle(fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Glass(
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: const Text('Fotoğraf ve veri kaynakları', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                children: [
                  for (final c in credits)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(c, style: const TextStyle(fontSize: 12, color: GL.muted, height: 1.4)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Glass(
            key: const ValueKey('sign-out'),
            radius: 18,
            padding: EdgeInsets.zero,
            onTap: () async {
              await store.signOut();
              AuthService.signOut();
            },
            child: const SizedBox(
              height: 50,
              child: Center(child: Text('Çıkış yap', style: TextStyle(fontWeight: FontWeight.w700, color: GL.danger))),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _pickCity(BuildContext context, AppStore store) async {
  final ctrl = TextEditingController(text: store.cityName);
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('Hangi şehirdesin?'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Örn. Ankara'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Vazgeç')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: GL.green),
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: const Text('Kaydet'),
        ),
      ],
    ),
  );
  if (name == null || name.trim().isEmpty) return;
  final city = await WeatherService.findCity(name);
  if (!context.mounted) return;
  if (city == null) {
    showGLSnack(context, 'Şehir bulunamadı. İnternet bağlantını ve yazımı kontrol et.');
    return;
  }
  store.setCity(city.name, city.lat, city.lon);
  showGLSnack(context, 'Şehir ${city.name} olarak ayarlandı.');
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(fontSize: 12, color: GL.muted)),
        ],
      ),
    );
  }
}
