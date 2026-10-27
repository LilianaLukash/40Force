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

class CalendarScreen extends StatefulWidget {
  final List<DayData> days;
  const CalendarScreen({super.key, required this.days});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _mode = 0; // 0 month, 1 week, 2 list
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = dayKeyForWake(now);
  }

  Map<DateTime, DayData> get _byDay => <DateTime, DayData>{
        for (final d in widget.days) dayKeyForWake(d.date): d,
      };

  static double _mental(DayData? d) => d?.targets['mood'] ?? 0;
  static double _physical(DayData? d) => d?.targets['energy'] ?? 0;
  static bool _isPeriod(DayData? d) => d?.factors.contains('period') ?? false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Month')),
              ButtonSegment(value: 1, label: Text('Week')),
              ButtonSegment(value: 2, label: Text('List')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month - 1, 1);
              }),
            ),
            Text(
              '${_month.year}-${_month.month.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month + 1, 1);
              }),
            ),
          ],
        ),
        Expanded(child: _mode == 0 ? _monthGrid() : _mode == 1 ? _weekStrip() : _listView()),
        _legend(),
        _dayPanel(_byDay[_selected]),
      ],
    );
  }

  Widget _monthGrid() {
    final first = _month;
    final count = DateTime(first.year, first.month + 1, 0).day;
    final lead = first.weekday - 1;
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 4,
      ),
      itemCount: count + lead,
      itemBuilder: (context, i) {
        if (i < lead) return const SizedBox.shrink();
        final date = DateTime(first.year, first.month, i - lead + 1);
        final data = _byDay[date];
        return GestureDetector(
          onTap: () => setState(() => _selected = date),
          child: ActivityCircle(
            mental: _mental(data),
            physical: _physical(data),
            label: '${date.day}',
            period: _isPeriod(data),
            selected: date == _selected,
            size: 46,
          ),
        );
      },
    );
  }

  Widget _weekStrip() {
    final monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Builder(builder: (context) {
                  final date = monday.add(Duration(days: i));
                  final data = _byDay[date];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = date),
                    child: Column(
                      children: [
                        Text(const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
                            style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 4),
                        ActivityCircle(
                          mental: _mental(data),
                          physical: _physical(data),
                          label: '${date.day}',
                          period: _isPeriod(data),
                          selected: date == _selected,
                          size: 44,
                        ),
                      ],
                    ),
                  );
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _listView() {
    final sorted = [...widget.days]..sort((a, b) => b.date.compareTo(a.date));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final d = sorted[i];
        return ListTile(
          leading: ActivityCircle(
            mental: _mental(d),
            physical: _physical(d),
            label: '${d.date.day}',
            period: _isPeriod(d),
            selected: false,
            size: 40,
          ),
          title: Text('${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}'),
          subtitle: Text(
              'Sleep ${(d.targets['sleep'] ?? 0).toStringAsFixed(1)} · Energy ${(d.targets['energy'] ?? 0).toStringAsFixed(1)} · Mood ${(d.targets['mood'] ?? 0).toStringAsFixed(1)}'),
          onTap: () => setState(() => _selected = dayKeyForWake(d.date)),
        );
      },
    );
  }

  Widget _legend() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: Color(0xFF2F80FF)),
          SizedBox(width: 4),
          Text('Mental', style: TextStyle(fontSize: 12)),
          SizedBox(width: 12),
          Icon(Icons.circle, size: 10, color: Color(0xFFFF4D5E)),
          SizedBox(width: 4),
          Text('Physical', style: TextStyle(fontSize: 12)),
          SizedBox(width: 12),
          Icon(Icons.circle_outlined, size: 12, color: Color(0xFFF29D9D)),
          SizedBox(width: 4),
          Text('Period', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _dayPanel(DayData? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: data == null
          ? Text('No entry for ${_selected.day}. Tap Check-in to add one.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Day ${_selected.day}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _bar('Sleep', data.targets['sleep'] ?? 0),
                _bar('Energy', data.targets['energy'] ?? 0),
                _bar('Mood', data.targets['mood'] ?? 0),
                if (data.factors.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final f in data.factors)
                        Chip(label: Text(f), visualDensity: VisualDensity.compact),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _bar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 58, child: Text(label, style: const TextStyle(fontSize: 12))),
          Expanded(child: LinearProgressIndicator(value: value.clamp(0, 1))),
          const SizedBox(width: 8),
          Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

/// Day circle from the owner spec: left half (blue) = mental,
/// right half (red) = physical. Each half fills from the bottom
/// 0..1 of its half-disc; unfilled part is gray #E5E7EB.
/// White center always shows the day number. Pink outline = period.
class ActivityCircle extends StatelessWidget {
  final double mental;
  final double physical;
  final String label;
  final bool period;
  final bool selected;
  final double size;

  const ActivityCircle({
    super.key,
    required this.mental,
    required this.physical,
    required this.label,
    required this.period,
    required this.selected,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ActivityCirclePainter(
              mental: mental.clamp(0, 1),
              physical: physical.clamp(0, 1),
              period: period,
              selected: selected,
            ),
          ),
          Container(
            width: size * 0.56,
            height: size * 0.56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: size * 0.30,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCirclePainter extends CustomPainter {
  final double mental;
  final double physical;
  final bool period;
  final bool selected;

  _ActivityCirclePainter({
    required this.mental,
    required this.physical,
    required this.period,
    required this.selected,
  });

  static const _blue = Color(0xFF2F80FF);
  static const _red = Color(0xFFFF4D5E);
  static const _gray = Color(0xFFE5E7EB);
  static const _pink = Color(0xFFF29D9D);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2 - 2,
    );
    // Gray base halves.
    canvas.save();
    canvas.clipPath(Path()..addOval(circle));
    canvas.drawRect(rect, Paint()..color = _gray);
    // Left half: blue fills from the bottom.
    final mh = circle.height * mental;
    canvas.drawRect(
      Rect.fromLTWH(circle.left, circle.bottom - mh, circle.width / 2, mh),
      Paint()..color = _blue,
    );
    // Right half: red fills from the bottom.
    final ph = circle.height * physical;
    canvas.drawRect(
      Rect.fromLTWH(circle.center.dx, circle.bottom - ph, circle.width / 2, ph),
      Paint()..color = _red,
    );
    canvas.restore();
    if (period) {
      canvas.drawCircle(
        circle.center,
        circle.width / 2,
        Paint()
          ..color = _pink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
    if (selected) {
      _drawDashedCircle(canvas, circle);
    }
  }

  void _drawDashedCircle(Canvas canvas, Rect circle) {
    final paint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    const dash = 0.22;
    const gap = 0.16;
    var start = 0.0;
    while (start < 6.2832) {
      canvas.drawArc(
        circle.inflate(2.5),
        start,
        dash,
        false,
        paint,
      );
      start += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ActivityCirclePainter old) =>
      old.mental != mental ||
      old.physical != physical ||
      old.period != period ||
      old.selected != selected;
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
