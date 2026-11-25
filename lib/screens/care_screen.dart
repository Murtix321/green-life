import 'package:flutter/material.dart';

import '../services/store.dart';
import '../theme.dart';
import '../widgets/glass.dart';
import '../widgets/plant_visual.dart';
import 'plant_detail_screen.dart';

/// Bakım: Bugün · Yaklaşan · Tamamlanan (3. referansın sağ ekranı).
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final tasks = switch (_tab) {
      0 => store.todayTasks,
      1 => store.upcomingTasks,
      _ => store.completedTasks,
    };
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        children: [
          const Text('Bakım', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5)),
          const SizedBox(height: 12),
          GlassSegmented(
            labels: const ['Bugün', 'Yaklaşan', 'Tamamlanan'],
            index: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            child: Column(
              key: ValueKey(_tab),
              children: [
                if (tasks.isEmpty)
                  Glass(
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        _tab == 0 ? 'Bugün yapılacak bakım yok. Bitkilerin keyifte.' : 'Burada henüz bir şey yok.',
                        style: const TextStyle(color: GL.muted),
                      ),
                    ),
                  ),
                for (var i = 0; i < tasks.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Rise(
                      delay: 50 * i,
                      child: Glass(
                        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                        onTap: () => Navigator.of(context).push(glRoute(PlantDetailScreen(plantId: tasks[i].plant.id))),
                        child: Row(
                          children: [
                            SizedBox(width: 62, height: 62, child: PlantVisual(tasks[i].plant, radius: 14)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tasks[i].title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.water_drop_rounded, size: 13, color: tasks[i].done ? GL.green : GL.muted),
                                      const SizedBox(width: 4),
                                      Text(tasks[i].sub,
                                          style: TextStyle(fontSize: 12, color: tasks[i].done ? GL.greenDark : GL.muted)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            CheckCircle(
                              key: ValueKey('check-${tasks[i].plant.id}'),
                              done: tasks[i].done,
                              label: '${tasks[i].plant.name} sulandı',
                              onTap: _tab == 0 ? () => store.toggleTodayTask(tasks[i].plant) : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          _AlarmCard(store: store),
          const SizedBox(height: 10),
          Glass(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bakım rehberi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Sulamadan önce parmağınla toprağı yokla: üst 2–3 cm kuruysa sula. Saksının dibinde su birikmesin.',
                          style: TextStyle(fontSize: 12, height: 1.45, color: GL.muted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset('assets/plants/aloe.webp', width: 78, height: 92, fit: BoxFit.contain),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AppStore store;
  const _AlarmCard({required this.store});

  Future<void> _pickTime(BuildContext context) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: store.alarmHour, minute: store.alarmMinute),
      helpText: 'Sulama alarmı saati',
    );
    if (t != null) store.setAlarmTime(t.hour, t.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.alarm_rounded, color: GL.greenDark),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => _pickTime(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sulama alarmı', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Her sulama günü ${store.alarmTimeText} · değiştirmek için dokun',
                        style: const TextStyle(fontSize: 12, color: GL.muted)),
                  ],
                ),
              ),
            ),
          ),
          Switch(key: const ValueKey('alarm-switch'), value: store.alarmOn, onChanged: store.setAlarm),
        ],
      ),
    );
  }
}
