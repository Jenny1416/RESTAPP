import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/services/emotion_service.dart';
import 'package:rest/core/theme/app_colors.dart';

class EmotionalCalendarScreen extends StatefulWidget {
  const EmotionalCalendarScreen({super.key});

  @override
  State<EmotionalCalendarScreen> createState() =>
      _EmotionalCalendarScreenState();
}

class _EmotionalCalendarScreenState extends State<EmotionalCalendarScreen> {
  final EmotionService _emotionService = EmotionService();
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _monthKeys = List.generate(12, (_) => GlobalKey());

  final int _year = DateTime.now().year;
  bool _isLoading = true;
  bool _didAutoScrollToCurrentMonth = false;
  String? _error;
  final Map<String, num> _byDate = {};

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await initializeDateFormatting('es_ES');

      final start = DateTime(_year, 1, 1);
      final end = DateTime(_year, 12, 31);
      final result = await _emotionService.fetchCalendarioEmocional(
        inicio: start,
        fin: end,
      );

      final mapped = <String, num>{};
      for (final item in result) {
        final fecha = (item['fecha'] ?? '').toString();
        final prom = item['promedio'] ?? item['promedio_emocional'];
        if (fecha.isEmpty || prom == null) continue;
        final parsed = prom is num ? prom : num.tryParse(prom.toString());
        final key = _normalizeDateKey(fecha);
        if (parsed != null && key != null) {
          mapped[key] = parsed;
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todayKey = _toDateKey(today);
      final tomorrowKey = _toDateKey(today.add(const Duration(days: 1)));

      if (!mapped.containsKey(todayKey) && mapped.containsKey(tomorrowKey)) {
        final shifted = <String, num>{};
        for (final entry in mapped.entries) {
          shifted[_shiftDateKey(entry.key, days: -1)] = entry.value;
        }
        mapped
          ..clear()
          ..addAll(shifted);
      }

      if (!mounted) return;
      setState(() {
        _byDate
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });

      _autoScrollToCurrentMonth();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildHeader(context),
            ),
            SizedBox(height: 16.h),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildLegend(),
            ),
            SizedBox(height: 18.h),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCalendar,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_error != null)
                        _buildError()
                      else
                        ...List.generate(
                          12,
                          (index) => Padding(
                            key: _monthKeys[index],
                            padding: const EdgeInsets.only(bottom: 26),
                            child: _monthCard(index + 1),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _autoScrollToCurrentMonth() {
    if (_didAutoScrollToCurrentMonth || !mounted) return;

    final currentMonthIndex = DateTime.now().month - 1;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didAutoScrollToCurrentMonth) return;

      final context = _monthKeys[currentMonthIndex].currentContext;
      if (context == null) return;

      _didAutoScrollToCurrentMonth = true;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        alignment: 0.05,
      );
    });
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: colorScheme.primary, size: 28),
        ),
        const Spacer(),
        Text(
          'Registro Global $_year',
          style: TextStyle(
            fontSize: 34.sp,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
            fontFamily: 'Fredoka',
          ),
        ),
        const Spacer(),
        SizedBox(width: 28.w),
      ],
    );
  }

  Widget _buildLegend() {
    final colorScheme = Theme.of(context).colorScheme;

    Widget item(String label, String asset) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              asset,
              width: 22.w,
              height: 22.h,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.emoji_emotions),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outline),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          item('Muy mal', 'assets/images/sadrest.jpg'),
          item('Mal', 'assets/images/yellowrest.jpg'),
          item('Normal', 'assets/images/normalrest.jpg'),
          item('Bien', 'assets/images/goodrest.jpg'),
          item('Excelente', 'assets/images/statesuperexcellent.png'),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          Text(
            'No se pudo cargar tu calendario',
            style: TextStyle(color: context.appColors.dangerFg),
          ),
          SizedBox(height: 8.h),
          TextButton(onPressed: _loadCalendar, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _monthCard(int month) {
    final monthName = DateFormat.MMMM('es_ES').format(DateTime(_year, month));
    final first = DateTime(_year, month, 1);
    final daysInMonth = DateTime(_year, month + 1, 0).day;
    final offset = first.weekday - 1;

    final cells = List<Widget>.generate(offset, (_) => const SizedBox());
    cells.addAll(
      List.generate(daysInMonth, (i) {
        final day = i + 1;
        final date = DateTime(_year, month, day);
        final key = _toDateKey(date);
        return _dayCell(day: day, promedio: _byDate[key]);
      }),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            _capitalize(monthName),
            style: TextStyle(
              fontSize: 36.sp,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'Fredoka',
            ),
          ),
          SizedBox(height: 12.h),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekName('LUN'),
              _WeekName('MAR'),
              _WeekName('MIE'),
              _WeekName('JUE'),
              _WeekName('VIE'),
              _WeekName('SAB'),
              _WeekName('DOM'),
            ],
          ),
          SizedBox(height: 8.h),
          GridView.count(
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 0.9,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: cells,
          ),
        ],
      ),
    );
  }

  Widget _dayCell({required int day, required num? promedio}) {
    final hasData = promedio != null;
    final asset = hasData ? _assetFromPromedio(promedio) : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: Text(
              '$day',
              style: TextStyle(fontSize: 10.sp, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          Center(
            child: hasData
                ? ClipOval(
                    child: Image.asset(
                      asset!,
                      width: 28.w,
                      height: 28.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.emoji_emotions,
                        color: context.appColors.brandSoft,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  String _assetFromPromedio(num promedio) {
    if (promedio >= 3.6) return 'assets/images/statesuperexcellent.png';
    if (promedio >= 2.8) return 'assets/images/goodrest.jpg';
    if (promedio >= 2.0) return 'assets/images/normalrest.jpg';
    if (promedio >= 1.2) return 'assets/images/yellowrest.jpg';
    return 'assets/images/sadrest.jpg';
  }

  String _toDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _shiftDateKey(String key, {required int days}) {
    final parsed = DateTime.tryParse(key);
    if (parsed == null) return key;
    return _toDateKey(parsed.add(Duration(days: days)));
  }

  String? _normalizeDateKey(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return null;

    final parsed = DateTime.tryParse(clean);
    if (parsed != null) {
      final local = parsed.isUtc ? parsed.toLocal() : parsed;
      return _toDateKey(DateTime(local.year, local.month, local.day));
    }

    if (clean.length < 10) return null;
    final iso = clean.substring(0, 10);
    final dateOnly = DateTime.tryParse(iso);
    if (dateOnly == null) return null;
    return _toDateKey(dateOnly);
  }

  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }
}

class _WeekName extends StatelessWidget {
  const _WeekName(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
