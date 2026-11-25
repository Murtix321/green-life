import 'package:flutter/material.dart';

import '../services/auth.dart';
import '../services/plant_id.dart';
import '../services/store.dart';
import '../services/weather.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final initial = store.firstName.isEmpty ? '?' : store.firstName.characters.first.toUpperCase();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
        children: [
          const Rise(
            child: Text('Profil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          ),
          const SizedBox(height: 14),
          Rise(
            delay: 100,
            child: GLCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: GL.leaf,
                    foregroundImage: store.photoUrl == null ? null : NetworkImage(store.photoUrl!),
                    child: Text(initial,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
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
          ),
          const SizedBox(height: 12),
          Rise(
            delay: 180,
            child: Row(
              children: [
                Expanded(child: _Stat(value: '${store.plants.length}', label: 'bitki')),
                const SizedBox(width: 12),
                Expanded(child: _Stat(value: '${store.dueToday.length}', label: 'bugün sulanacak')),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Rise(
            delay: 260,
            child: GLCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    value: store.alarmOn,
                    onChanged: store.setAlarm,
                    secondary: const Icon(Icons.alarm_rounded, color: GL.forest),
                    title: const Text('Sulama alarmları', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Sulama günü gelince bildirim gönder'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_city_rounded, color: GL.forest),
                    title: const Text('Şehir (hava durumu ipucu)', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Text(store.cityName,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: GL.forest)),
                    onTap: () => _pickCity(context, store),
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_rounded, color: GL.forest),
                    title: const Text('Alarm saati', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: Text(store.alarmTimeText,
                        style: const TextStyle(fontWeight: FontWeight.w800, color: GL.forest)),
                    onTap: () async {
                      final t = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: store.alarmHour, minute: store.alarmMinute),
                      );
                      if (t != null) store.setAlarmTime(t.hour, t.minute);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Rise(
            delay: 340,
            child: GLCard(
              color: GL.mintPale,
              child: Row(
                children: [
                  Icon(
                    PlantIdService.hasPlantNet ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    color: GL.forest,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      PlantIdService.hasPlantNet
                          ? 'Bitki tanıma açık (Pl@ntNet).'
                          : 'Bitki tanıma için Pl@ntNet anahtarı eklenmedi. Şimdilik bitkileri listeden ekleyebilirsin.',
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Rise(
            delay: 420,
            child: PrimaryButton(
              label: 'Çıkış yap',
              bg: Colors.white,
              fg: const Color(0xFFB3261E),
              height: 50,
              onTap: () async {
                await AuthService.signOut();
                await store.signOut();
              },
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
          style: FilledButton.styleFrom(backgroundColor: GL.forest),
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
    return GLCard(
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
