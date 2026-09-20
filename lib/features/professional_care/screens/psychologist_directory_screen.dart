import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/screens/psychologist_detail_screen.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

class PsychologistDirectoryScreen extends StatefulWidget {
  const PsychologistDirectoryScreen({super.key, this.onAssignmentChanged});

  final VoidCallback? onAssignmentChanged;

  @override
  State<PsychologistDirectoryScreen> createState() =>
      _PsychologistDirectoryScreenState();
}

class _PsychologistDirectoryScreenState
    extends State<PsychologistDirectoryScreen> {
  final _service = ProfessionalCareService();
  final _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Psychologist> _items = const [];
  String? _specialty;
  String? _city;
  String? _language;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshFilters);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilters)
      ..dispose();
    super.dispose();
  }

  void _refreshFilters() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.getPsychologists();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ProfessionalCareException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  List<String> _values(String? Function(Psychologist) pick) {
    final result = _items
        .map(pick)
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList();
    result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  List<Psychologist> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final searchable = [
        item.fullName,
        item.specialty ?? '',
        item.city ?? '',
        item.language ?? '',
      ].join(' ').toLowerCase();
      return (query.isEmpty || searchable.contains(query)) &&
          (_specialty == null || item.specialty == _specialty) &&
          (_city == null || item.city == _city) &&
          (_language == null || item.language == _language);
    }).toList();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _specialty = null;
      _city = null;
      _language = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CarePageHeader(
              title: 'Directorio de psicólogos',
              subtitle: 'Encuentra el profesional adecuado para ti',
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o especialidad',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: colors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18.r),
                    borderSide: BorderSide(color: colors.outlineVariant),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 42.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                children: [
                  _FilterMenu(
                    label: _specialty ?? 'Especialidad',
                    selected: _specialty != null,
                    values: _values((item) => item.specialty),
                    onSelected: (value) => setState(() => _specialty = value),
                  ),
                  SizedBox(width: 8.w),
                  _FilterMenu(
                    label: _city ?? 'Ciudad',
                    selected: _city != null,
                    values: _values((item) => item.city),
                    onSelected: (value) => setState(() => _city = value),
                  ),
                  SizedBox(width: 8.w),
                  _FilterMenu(
                    label: _language ?? 'Idioma',
                    selected: _language != null,
                    values: _values((item) => item.language),
                    onSelected: (value) => setState(() => _language = value),
                  ),
                  if (_specialty != null ||
                      _city != null ||
                      _language != null) ...[
                    SizedBox(width: 8.w),
                    ActionChip(
                      onPressed: _clearFilters,
                      avatar: const Icon(
                        Icons.filter_alt_off_rounded,
                        size: 18,
                      ),
                      label: const Text('Limpiar'),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Expanded(child: _buildContent(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CareEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar el directorio',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return CareEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'No encontramos resultados',
        message: 'Prueba cambiando la búsqueda o limpiando los filtros.',
        actionLabel: 'Limpiar filtros',
        onAction: _clearFilters,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
        itemCount: items.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final item = items[index];
          return Material(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PsychologistDetailScreen(
                    psychologist: item,
                    onAssignmentChanged: widget.onAssignmentChanged,
                  ),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    PsychologistAvatar(psychologist: item),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fullName,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w800,
                              fontSize: 17.sp,
                              color: colors.onSurface,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            item.specialty ?? 'Psicología y bienestar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              color: careBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 7.h),
                          Wrap(
                            spacing: 10.w,
                            runSpacing: 4.h,
                            children: [
                              _TinyInfo(
                                icon: Icons.location_on_outlined,
                                text: item.city ?? 'Sin ciudad',
                              ),
                              _TinyInfo(
                                icon: Icons.language_rounded,
                                text: item.language ?? 'Sin idioma',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.selected,
    required this.values,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final List<String> values;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      enabled: values.isNotEmpty,
      onSelected: onSelected,
      itemBuilder: (_) => [
        const PopupMenuItem<String?>(value: null, child: Text('Todos')),
        ...values.map(
          (value) => PopupMenuItem(value: value, child: Text(value)),
        ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
        decoration: BoxDecoration(
          color: selected
              ? careBlue
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: selected
                ? careBlue
                : Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontFamily: 'Fredoka',
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: selected ? Colors.white : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyInfo extends StatelessWidget {
  const _TinyInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15.sp,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        SizedBox(width: 3.w),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
