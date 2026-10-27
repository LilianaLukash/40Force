import 'package:core40/core40.dart';
import 'package:flutter/material.dart';

import 'demo_data.dart';

void main() => runApp(const Force40App());

class Force40App extends StatelessWidget {
  const Force40App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '40 Force',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final List<DayData> _days = buildDemoDays();

  void _addDay(DayData day) {
    setState(() {
      _days.add(day);
      _days.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      CalendarScreen(days: _days),
      CheckInScreen(onSave: _addDay),
      GraphsScreen(days: _days),
      CardScreen(days: _days),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('40 Force')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Check-in'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Graphs'),
          NavigationDestination(icon: Icon(Icons.insights), label: 'Card'),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  final List<DayData> days;
  const CalendarScreen({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, DayData>{
      for (final d in days) dayKeyForWake(d.date): d,
    };
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final count = DateTime(now.year, now.month + 1, 0).day;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: count + (first.weekday - 1),
      itemBuilder: (context, i) {
        if (i < first.weekday - 1) return const SizedBox.shrink();
        final dayNum = i - (first.weekday - 2);
        final date = DateTime(now.year, now.month, dayNum);
        final data = byDay[date];
        final dots = data == null ? 0 : data.factors.length.clamp(0, 3);
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal.shade100),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$dayNum'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var d = 0; d < dots; d++)
                    const Padding(
                      padding: EdgeInsets.all(1),
                      child: Icon(Icons.circle, size: 6, color: Colors.teal),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class CheckInScreen extends StatefulWidget {
  final ValueChanged<DayData> onSave;
  const CheckInScreen({super.key, required this.onSave});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  double _sleep = 0.7;
  double _energy = 0.6;
  double _mood = 0.6;
  final Set<String> _factors = <String>{};
  static const List<String> _allFactors = <String>[
    'coffee',
    'late_dinner',
    'stress',
    'walk',
    'alcohol',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('How was today?', style: TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        _slider('Sleep', _sleep, (v) => setState(() => _sleep = v)),
        _slider('Energy', _energy, (v) => setState(() => _energy = v)),
        _slider('Mood', _mood, (v) => setState(() => _mood = v)),
        const SizedBox(height: 8),
        const Text('What was present today?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final f in _allFactors)
              FilterChip(
                label: Text(f),
                selected: _factors.contains(f),
                onSelected: (on) => setState(() {
                  if (on) {
                    _factors.add(f);
                  } else {
                    _factors.remove(f);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () {
            widget.onSave(DayData(
              date: dayKeyForWake(DateTime.now()),
              targets: <String, double>{
                'sleep': _sleep,
                'energy': _energy,
                'mood': _mood,
              },
              factors: Set<String>.of(_factors),
            ));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved. Graphs update right away.')),
            );
          },
          child: const Text('Save check-in'),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 64, child: Text(label)),
        Expanded(child: Slider(value: value, onChanged: onChanged)),
        Text(value.toStringAsFixed(1)),
      ],
    );
  }
}

class GraphsScreen extends StatelessWidget {
  final List<DayData> days;
  const GraphsScreen({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _chartBlock('Sleep', 'sleep'),
        _chartBlock('Energy', 'energy'),
        _chartBlock('Mood', 'mood'),
        const Text('Graphs are drawn from the first day. With few points: not enough data yet.'),
      ],
    );
  }

  Widget _chartBlock(String title, String targetId) {
    final values = <double>[
      for (final d in days)
        if (d.targets[targetId] != null) d.targets[targetId]!,
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(height: 90, child: LineChart(values: values)),
          ],
        ),
      ),
    );
  }
}

class LineChart extends StatelessWidget {
  final List<double> values;
  const LineChart({super.key, required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const Center(child: Text('Not enough data yet'));
    }
    return CustomPaint(painter: _LinePainter(values), child: const SizedBox.expand());
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  _LinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), axis..style = PaintingStyle.stroke);
    final line = Paint()
      ..color = Colors.teal
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - values[i].clamp(0, 1));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.values != values;
}

class CardScreen extends StatelessWidget {
  final List<DayData> days;
  const CardScreen({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final full = CardEngine.fullCards(days, targetId: 'sleep');
    final early = full.isEmpty
        ? CardEngine.earlyObservations(days, targetId: 'sleep')
        : const <InsightCard>[];
    final cards = full.isNotEmpty ? full : early;
    if (cards.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Not enough data yet. Early observations appear on day 5-6, full cards on day 14.'),
        ),
      );
    }
    final card = cards.first;
    String pct(double v) => '${(v * 100).round()}%';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.early ? 'Early observation' : 'Card of the day',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('You noted ${card.factorId} on ${card.factorDays} days.'),
                Text('Low sleep on those days: ${pct(card.factorLowShare)} (base level ${pct(card.baseLowShare)}, ${card.totalDays} days noted).'),
                if (card.lagDays > 0) Text('Time shift: ${card.lagDays} day(s).'),
                const SizedBox(height: 8),
                const Text('Coincided in time. This does not show a cause. Another possible reason could be present.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
