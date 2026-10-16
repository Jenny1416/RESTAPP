import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/screens/professional_chat_screen.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';

class ProfessionalConversationsScreen extends StatefulWidget {
  const ProfessionalConversationsScreen({super.key});

  @override
  State<ProfessionalConversationsScreen> createState() =>
      _ProfessionalConversationsScreenState();
}

class _ProfessionalConversationsScreenState
    extends State<ProfessionalConversationsScreen> {
  final _service = ProfessionalCareService();
  bool _loading = true;
  String? _error;
  List<ProfessionalChat> _chats = const [];
  List<CareAssignment> _assignments = const [];
  Map<int, Psychologist> _psychologists = const {};

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
        _service.getChats(),
        _service.getMyAssignments(),
        _service.getPsychologists(),
      ]);
      if (!mounted) return;
      final psychologists = results[2] as List<Psychologist>;
      setState(() {
        _chats = (results[0] as List<ProfessionalChat>)
            .where((chat) => !chat.isAi)
            .toList();
        _assignments = results[1] as List<CareAssignment>;
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

  bool _isApproved(int psychologistId) {
    return _assignments.any(
      (item) => item.psychologistId == psychologistId && item.isApproved,
    );
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
              title: 'Conversaciones profesionales',
              subtitle: 'Tus mensajes con psicólogos',
            ),
            Expanded(child: _content(colors)),
          ],
        ),
      ),
    );
  }

  Widget _content(ColorScheme colors) {
    final appColors = context.appColors;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CareEmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'No pudimos cargar las conversaciones',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }
    if (_chats.isEmpty) {
      return const CareEmptyState(
        icon: Icons.forum_outlined,
        title: 'No tienes conversaciones',
        message:
            'El chat estará disponible cuando un psicólogo apruebe tu solicitud.',
      );
    }

    final chats = [..._chats]
      ..sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 30.h),
        itemCount: chats.length,
        separatorBuilder: (_, __) => SizedBox(height: 11.h),
        itemBuilder: (_, index) {
          final chat = chats[index];
          final psychologistId = chat.psychologistId!;
          final psychologist =
              _psychologists[psychologistId] ??
              Psychologist(
                id: psychologistId,
                firstNames: 'Psicólogo',
                lastNames: '#$psychologistId',
              );
          final approved = _isApproved(psychologistId);
          final writable = approved && chat.isActive;

          return Material(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18.r),
            child: InkWell(
              borderRadius: BorderRadius.circular(18.r),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfessionalChatScreen(
                    psychologist: psychologist,
                    assignmentApproved: approved,
                    initialChat: chat,
                    readOnly: !writable,
                  ),
                ),
              ),
              child: Container(
                padding: EdgeInsets.all(15.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Row(
                  children: [
                    PsychologistAvatar(psychologist: psychologist, size: 50),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            psychologist.fullName,
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w800,
                              fontSize: 16.sp,
                              color: colors.onSurface,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            DateFormat(
                              'dd/MM/yyyy · HH:mm',
                            ).format(chat.lastActivity.toLocal()),
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontSize: 12.sp,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                writable ? Icons.circle : Icons.history_rounded,
                                size: writable ? 9.sp : 15.sp,
                                color: writable
                                    ? appColors.successFg
                                    : colors.onSurfaceVariant,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                writable
                                    ? 'Conversación activa'
                                    : 'Solo lectura',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.sp,
                                  color: writable
                                      ? appColors.successFg
                                      : colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
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
