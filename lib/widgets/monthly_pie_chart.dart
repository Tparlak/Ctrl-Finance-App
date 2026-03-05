import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/analytics_provider.dart';
import '../theme/app_colors.dart';

class MonthlyPieChart extends StatefulWidget {
  final List<CategoryTotal> data;
  const MonthlyPieChart({required this.data, super.key});

  @override
  State<MonthlyPieChart> createState() => _MonthlyPieChartState();
}

class _MonthlyPieChartState extends State<MonthlyPieChart> {
  int _touchedIndex = -1;

  static const _colors = [
    Color(0xFF6C63FF), Color(0xFFFF6584), Color(0xFF43E97B),
    Color(0xFFFA8231), Color(0xFF2BCBBA), Color(0xFFFC5C7D),
    Color(0xFF45AAF2), Color(0xFFFED330),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'tr_TR').format(now).toUpperCase();

    if (widget.data.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            'Bu ay henüz gider yok',
            style: GoogleFonts.poppins(color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex =
                            response.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 3,
                  centerSpaceRadius: 72,
                  sections: widget.data.asMap().entries.map((entry) {
                    final isTouched = entry.key == _touchedIndex;
                    final radius = isTouched ? 58.0 : 48.0;
                    final pct = entry.value.percentage;

                    return PieChartSectionData(
                      color: _colors[entry.key % _colors.length],
                      value: entry.value.total,
                      title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                      radius: radius,
                      titleStyle: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 3)
                        ],
                      ),
                      titlePositionPercentageOffset: 1.5,
                      badgeWidget: pct < 5
                          ? null
                          : null,
                    );
                  }).toList(),
                ),
              ),
              // Center text
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthName,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    'GİDERİ',
                    style: GoogleFonts.poppins(
                      color: AppColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (_touchedIndex >= 0 &&
                      _touchedIndex < widget.data.length) ...[
                    Text(
                      widget.data[_touchedIndex].categoryName,
                      style: GoogleFonts.poppins(
                        color: _colors[_touchedIndex % _colors.length],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${widget.data[_touchedIndex].percentage.toStringAsFixed(1)}%',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.asMap().entries.map((e) {
            final color = _colors[e.key % _colors.length];
            return GestureDetector(
              onTap: () => setState(() {
                _touchedIndex = _touchedIndex == e.key ? -1 : e.key;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _touchedIndex == e.key
                      ? color.withOpacity( 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _touchedIndex == e.key
                        ? color.withOpacity( 0.6)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.value.categoryName,
                      style: GoogleFonts.poppins(
                        color: _touchedIndex == e.key
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                        fontWeight: _touchedIndex == e.key
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

