import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/widgets/app_header_bar.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/screens/my_requests_screen.dart';
import 'package:rest/features/professional_care/screens/professional_chat_screen.dart';
import 'package:rest/features/professional_care/screens/professional_conversations_screen.dart';
import 'package:rest/features/professional_care/screens/psychologist_directory_screen.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';
import 'package:rest/features/settings/screens/settings_screen.dart';

class ProfessionalCareScreen extends StatefulWidget {
  const ProfessionalCareScreen({super.key});

  @override
  State<ProfessionalCareScreen> createState() => _ProfessionalCareScreenState();
}

class _ProfessionalCareScreenState extends State<ProfessionalCareScreen> {
  final _service = ProfessionalCareService();
  bool _loading = true;
  Timer? _refreshTimer;
  String? _error;
  List<CareAssignment> _assignments = const [];
  List<ProfessionalChat> _chats = const [];
  Map<int, Psychologist> _psychologists = const {};

  CareAssignment? get _approved {
    for (final item in _assignments) {
      if (item.isApproved) return item;
    }
    return null;
  }

  List<CareAssignment> get _pending =>
      _assignments.where((item) => item.isPending).toList();

  @override
  void initState() {
    super.initState();
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _load(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    setState(() {
      if (!silent) _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _service.getMyAssignments(),
        _service.getPsychologists(),
        _service.getChats(),
      ]);
      if (!mounted) return;
      final psychologists = results[1] as List<Psychologist>;
      setState(() {
        _assignments = results[0] as List<CareAssignment>;
        _psychologists = {for (final item in psychologists) item.id: item};
        _chats = (results[2] as List<ProfessionalChat>)
            .where((chat) => !chat.isAi)
            .toList();
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

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: 'Atención profesional',
              avatarAssetPath: 'assets/images/conversaciones.png',
              onActionTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SettingsScreen()),
              ),
            ),
            Divider(
              color: colors.outlineVariant,
              thickness: 3,
              height: 0,
              indent: 23,
              endIndent: 23,
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
        title: 'No pudimos cargar Atención',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }

    final approved = _approved;
    final assignedPsychologist = approved?.psychologistId == null
        ? null
        : _psychologists[approved!.psychologistId];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 110.h),
        children: [
          if (approved != null && assignedPsychologist != null)
            _AssignedProfessionalCard(
              psychologist: assignedPsychologist,
              onChat: () => _open(
                ProfessionalChatScreen(
                  psychologist: assignedPsychologist,
                  assignmentApproved: true,
                ),
              ),
            )
          else
            _WelcomeCard(displayName: UserSession.displayName),
          if (_pending.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: context.appColors.warmBadgeFg.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: context.appColors.warmBadgeFg.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    color: context.appColors.warmBadgeFg,
                  ),
                  SizedBox(width: 11.w),
                  Expanded(
                    child: Text(
                      '${_pending.length} solicitud${_pending.length == 1 ? '' : 'es'} pendiente${_pending.length == 1 ? '' : 's'}. El chat aparecerá cuando una sea aprobada.',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 22.h),
          Text(
            '¿Qué deseas hacer?',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: 12.h),
          _ActionCard(
            icon: Icons.manage_search_rounded,
            color: context.appColors.accentBlue,
            title: 'Buscar psicólogo',
            subtitle: 'Filtra por especialidad, ciudad e idioma',
            onTap: () =>
                _open(PsychologistDirectoryScreen(onAssignmentChanged: _load)),
          ),
          SizedBox(height: 11.h),
          _ActionCard(
            icon: Icons.assignment_outlined,
            color: context.appColors.accentPurple,
            title: 'Mis solicitudes',
            subtitle: 'Consulta estados, retira o finaliza una relación',
            onTap: () => _open(MyRequestsScreen(onChanged: _load)),
          ),
          if (_chats.isNotEmpty) ...[
            SizedBox(height: 11.h),
            _ActionCard(
              icon: Icons.forum_outlined,
              color: context.appColors.accentTeal,
              title: 'Historial con profesionales',
              subtitle: 'Revisa tus conversaciones anteriores',
              onTap: () => _open(const ProfessionalConversationsScreen()),
            ),
          ],
          SizedBox(height: 20.h),
          if (approved == null || assignedPsychologist == null)
            Container(
              padding: EdgeInsets.all(15.w),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Tu chat profesional es privado y solo se habilita después de que un psicólogo apruebe tu solicitud.',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        height: 1.35,
                        color: colors.onSurfaceVariant,
                      ),
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      padding: EdgeInsets.all(22.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.accentTeal, appColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estamos para acompañarte, $displayName',
                  style: TextStyle(
                    color: appColors.overlayOnGradient,
                    fontFamily: 'Fredoka',
                    fontWeight: FontWeight.w800,
                    fontSize: 21.sp,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Elige un profesional y envía tu solicitud. La conversación se habilitará cuando sea aceptada.',
                  style: TextStyle(
                    color: appColors.overlayOnGradient.withValues(alpha: 0.9),
                    fontFamily: 'Fredoka',
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          Icon(
            Icons.volunteer_activism_rounded,
            color: appColors.overlayOnGradient,
            size: 54.sp,
          ),
        ],
      ),
    );
  }
}

class _AssignedProfessionalCard extends StatelessWidget {
  const _AssignedProfessionalCard({
    required this.psychologist,
    required this.onChat,
  });

  final Psychologist psychologist;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.accentTeal, appColors.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PsychologistAvatar(psychologist: psychologist, size: 66),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu psicólogo asignado',
                      style: TextStyle(
                        color: appColors.overlayOnGradient.withValues(
                          alpha: 0.7,
                        ),
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      psychologist.fullName,
                      style: TextStyle(
                        color: appColors.overlayOnGradient,
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w800,
                        fontSize: 20.sp,
                      ),
                    ),
                    Text(
                      psychologist.specialty ?? 'Psicología y bienestar',
                      style: TextStyle(
                        color: appColors.overlayOnGradient,
                        fontFamily: 'Fredoka',
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.verified_rounded, color: appColors.overlayOnGradient),
            ],
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Abrir conversación'),
              style: FilledButton.styleFrom(
                backgroundColor: appColors.overlayOnGradient,
                foregroundColor: colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                textStyle: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(11.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 25.sp),
              ),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 12.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
