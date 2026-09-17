import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/screens/professional_chat_screen.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key, this.onChanged});

  final VoidCallback? onChanged;

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final _service = ProfessionalCareService();
  bool _loading = true;
  String? _error;
  List<CareAssignment> _assignments = const [];
  Map<int, Psychologist> _psychologists = const {};
  int? _processingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getMyAssignments(),
        _service.getPsychologists(),
      ]);
      final assignments = results[0] as List<CareAssignment>;
      final psychologists = results[1] as List<Psychologist>;
      if (!mounted) return;
      setState(() {
        _assignments = assignments;
        _psychologists = {for (final item in psychologists) item.id: item};
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

  Future<void> _close(CareAssignment assignment) async {
    final isApproved = assignment.isApproved;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isApproved ? 'Finalizar relación' : 'Retirar solicitud'),
        content: Text(
          isApproved
              ? 'La conversación quedará en el historial, pero ya no podrás enviar mensajes. ¿Deseas continuar?'
              : '¿Deseas retirar esta solicitud pendiente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: Text(isApproved ? 'Finalizar' : 'Retirar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingId = assignment.id);
    try {
      await _service.closeAssignment(assignment.id);
      if (!mounted) return;
      AppToast.success(
        context,
        isApproved
            ? 'La relación fue finalizada.'
            : 'La solicitud fue retirada.',
      );
      widget.onChanged?.call();
      await _load();
    } on ProfessionalCareException catch (error) {
      if (mounted) AppToast.error(context, error.message);
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
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
              title: 'Mis solicitudes',
              subtitle: 'Consulta el estado de tu atención',
            ),
            Expanded(child: _content(colors)),
          ],
        ),
      ),
    );
  }

  Widget _content(ColorScheme colors) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CareEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar tus solicitudes',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }
    if (_assignments.isEmpty) {
      return const CareEmptyState(
        icon: Icons.inbox_outlined,
        title: 'Aún no tienes solicitudes',
        message:
            'Cuando solicites atención a un psicólogo, podrás seguir su estado desde aquí.',
      );
    }

    final sorted = [..._assignments]
      ..sort(
        (a, b) => (b.requestedAt ?? DateTime(0)).compareTo(
          a.requestedAt ?? DateTime(0),
        ),
      );
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
        itemCount: sorted.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (_, index) {
          final assignment = sorted[index];
          final psychologist = _psychologists[assignment.psychologistId];
          return _AssignmentCard(
            assignment: assignment,
            psychologist: psychologist,
            processing: _processingId == assignment.id,
            onClose: assignment.canBeClosed ? () => _close(assignment) : null,
            onChat: assignment.isApproved && psychologist != null
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfessionalChatScreen(
                        psychologist: psychologist,
                        assignmentApproved: true,
                      ),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.psychologist,
    required this.processing,
    this.onClose,
    this.onChat,
  });

  final CareAssignment assignment;
  final Psychologist? psychologist;
  final bool processing;
  final VoidCallback? onClose;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = assignmentStatusColor(assignment.status);
    final date = assignment.requestedAt == null
        ? 'Fecha no disponible'
        : DateFormat(
            'dd/MM/yyyy · HH:mm',
          ).format(assignment.requestedAt!.toLocal());

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (psychologist != null)
                PsychologistAvatar(psychologist: psychologist!, size: 48)
              else
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: careBlue.withValues(alpha: 0.12),
                  child: const Icon(Icons.person_rounded, color: careBlue),
                ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      psychologist?.fullName ??
                          'Profesional #${assignment.psychologistId ?? '-'}',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  assignmentStatusLabel(assignment.status),
                  style: TextStyle(
                    color: statusColor,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w700,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          if (assignment.message != null) ...[
            SizedBox(height: 12.h),
            Text(
              assignment.message!,
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          if (assignment.isPending) ...[
            SizedBox(height: 12.h),
            Text(
              'El chat aparecerá cuando el profesional acepte tu solicitud.',
              style: TextStyle(
                fontFamily: 'Fredoka',
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (onChat != null || onClose != null) ...[
            SizedBox(height: 14.h),
            Row(
              children: [
                if (onChat != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onChat,
                      icon: const Icon(Icons.chat_bubble_rounded, size: 19),
                      label: const Text('Conversar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: careBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (onChat != null && onClose != null) SizedBox(width: 8.w),
                if (onClose != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: processing ? null : onClose,
                      child: processing
                          ? SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              assignment.isApproved ? 'Finalizar' : 'Retirar',
                            ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
