import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

class PsychologistDetailScreen extends StatefulWidget {
  const PsychologistDetailScreen({
    super.key,
    required this.psychologist,
    this.onAssignmentChanged,
  });

  final Psychologist psychologist;
  final VoidCallback? onAssignmentChanged;

  @override
  State<PsychologistDetailScreen> createState() =>
      _PsychologistDetailScreenState();
}

class _PsychologistDetailScreenState extends State<PsychologistDetailScreen> {
  final _service = ProfessionalCareService();
  bool _loading = true;
  bool _sending = false;
  List<CareAssignment> _assignments = const [];

  CareAssignment? get _approved {
    for (final item in _assignments) {
      if (item.isApproved) return item;
    }
    return null;
  }

  CareAssignment? get _pendingForThisPsychologist {
    for (final item in _assignments) {
      if (item.isPending && item.psychologistId == widget.psychologist.id) {
        return item;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final assignments = await _service.getMyAssignments();
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _requestCare() async {
    final controller = TextEditingController();
    final shouldSend = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 18.h, 22.w, 24.h),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),
                  Text(
                    'Solicitar atención',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontWeight: FontWeight.w800,
                      fontSize: 22.sp,
                      color: colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Tu solicitud será enviada a ${widget.psychologist.fullName}. El chat se habilitará cuando sea aprobada.',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      height: 1.35,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  TextField(
                    controller: controller,
                    maxLength: 1000,
                    minLines: 3,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Mensaje opcional',
                      hintText: 'Cuéntale brevemente por qué deseas conversar.',
                      filled: true,
                      fillColor: colors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Enviar solicitud'),
                      style: FilledButton.styleFrom(
                        backgroundColor: careAccent(context),
                        foregroundColor: context.appColors.overlayOnGradient,
                        padding: EdgeInsets.symmetric(vertical: 15.h),
                        textStyle: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldSend != true || !mounted) {
      controller.dispose();
      return;
    }

    setState(() => _sending = true);
    try {
      await _service.requestCare(
        psychologistId: widget.psychologist.id,
        message: controller.text,
      );
      if (!mounted) return;
      AppToast.success(
        context,
        'Solicitud enviada. Te avisaremos cuando sea aprobada.',
      );
      widget.onAssignmentChanged?.call();
      await _loadStatus();
    } on ProfessionalCareException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } finally {
      controller.dispose();
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final psychologist = widget.psychologist;
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final approved = _approved;
    final pending = _pendingForThisPsychologist;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const CarePageHeader(title: 'Perfil profesional'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
                children: [
                  Container(
                    padding: EdgeInsets.all(22.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [appColors.accentTeal, appColors.brandBorder],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                    child: Column(
                      children: [
                        PsychologistAvatar(
                          psychologist: psychologist,
                          size: 88,
                        ),
                        SizedBox(height: 14.h),
                        Text(
                          psychologist.fullName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: appColors.overlayOnGradient,
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w800,
                            fontSize: 24.sp,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          psychologist.specialty ?? 'Psicología y bienestar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: appColors.overlayOnGradient.withValues(alpha: 0.9),
                            fontFamily: 'Fredoka',
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  _InfoTile(
                    icon: Icons.psychology_alt_rounded,
                    label: 'Especialidad',
                    value: psychologist.specialty ?? 'No especificada',
                  ),
                  _InfoTile(
                    icon: Icons.location_on_outlined,
                    label: 'Ciudad',
                    value: psychologist.city ?? 'No especificada',
                  ),
                  _InfoTile(
                    icon: Icons.language_rounded,
                    label: 'Idioma',
                    value: psychologist.language ?? 'No especificado',
                  ),
                  SizedBox(height: 18.h),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (approved != null)
                    _StatusNotice(
                      icon: Icons.verified_rounded,
                      color: appColors.successFg,
                      title: approved.psychologistId == psychologist.id
                          ? 'Es tu psicólogo asignado'
                          : 'Ya tienes un psicólogo asignado',
                      message: approved.psychologistId == psychologist.id
                          ? 'Puedes conversar con este profesional desde la sección Atención.'
                          : 'Finaliza primero la relación activa si deseas solicitar otro profesional.',
                    )
                  else if (pending != null)
                    _StatusNotice(
                      icon: Icons.schedule_rounded,
                      color: appColors.warmBadgeFg,
                      title: 'Solicitud pendiente',
                      message:
                          'El chat se habilitará únicamente cuando el profesional acepte tu solicitud.',
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _sending ? null : _requestCare,
                        icon: _sending
                            ? SizedBox(
                                width: 18.w,
                                height: 18.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: appColors.overlayOnGradient,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(
                          _sending ? 'Enviando...' : 'Solicitar atención',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: careAccent(context),
                          foregroundColor: appColors.overlayOnGradient,
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          textStyle: const TextStyle(
                            fontFamily: 'Fredoka',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  SizedBox(height: 12.h),
                  Text(
                    'Por privacidad, el directorio no muestra correo ni teléfono del profesional.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 12.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(9.w),
            decoration: BoxDecoration(
              color: careAccent(context).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: careAccent(context), size: 21.sp),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 12.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: 15.sp,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusNotice extends StatelessWidget {
  const _StatusNotice({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  message,
                  style: const TextStyle(fontFamily: 'Fredoka', height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
