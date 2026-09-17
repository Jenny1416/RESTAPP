import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/core/utils/app_toast.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/screens/my_requests_screen.dart';
import 'package:rest/features/professional_care/screens/professional_chat_screen.dart';
import 'package:rest/features/professional_care/screens/psychologist_directory_screen.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';
import 'package:rest/features/professional_care/widgets/professional_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _service = ProfessionalCareService();
  bool _loading = true;
  String? _error;
  List<CareAssignment> _assignments = const [];
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
      if (!mounted) return;
      final psychologists = results[1] as List<Psychologist>;
      setState(() {
        _assignments = results[0] as List<CareAssignment>;
        _psychologists = {for (final item in psychologists) item.id: item};
        _loading = false;
      });
    } on ProfessionalCareException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) await _load();
  }

  Future<void> _openUrgentContact() async {
    const phone = '573015460169';
    final message = Uri.encodeComponent(
      'Hola, soy ${UserSession.displayName}. Necesito apoyo urgente desde REST.',
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppToast.error(
          context,
          'No fue posible abrir el contacto de emergencia.',
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'No fue posible abrir el contacto de emergencia.',
        );
      }
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
            CarePageHeader(
              title: 'Pedir ayuda',
              subtitle: 'No tienes que pasar por esto a solas',
              action: Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
                size: 28.sp,
              ),
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
        title: 'No pudimos consultar tu atención',
        message: _error!,
        actionLabel: 'Reintentar',
        onAction: _load,
      );
    }

    final assignment = _approved;
    final psychologist = assignment?.psychologistId == null
        ? null
        : _psychologists[assignment!.psychologistId];

    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
      children: [
        Container(
          padding: EdgeInsets.all(22.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF7A59), Color(0xFFE53955)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28.r),
          ),
          child: Column(
            children: [
              Container(
                width: 76.w,
                height: 76.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volunteer_activism_rounded,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
              SizedBox(height: 15.h),
              Text(
                'Estamos contigo, ${UserSession.displayName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Fredoka',
                  fontWeight: FontWeight.w800,
                  fontSize: 23.sp,
                ),
              ),
              SizedBox(height: 7.h),
              Text(
                'Puedes solicitar acompañamiento profesional. La conversación privada se habilita solo después de la aprobación.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontFamily: 'Fredoka',
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        if (assignment != null && psychologist != null)
          _ApprovedHelp(
            psychologist: psychologist,
            onChat: () => _open(
              ProfessionalChatScreen(
                psychologist: psychologist,
                assignmentApproved: true,
              ),
            ),
          )
        else if (_pending.isNotEmpty)
          _PendingHelp(
            count: _pending.length,
            onView: () => _open(MyRequestsScreen(onChanged: _load)),
          )
        else
          _NoRequestHelp(
            onFind: () =>
                _open(PsychologistDirectoryScreen(onAssignmentChanged: _load)),
          ),
        SizedBox(height: 22.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.emergency_rounded, color: Colors.redAccent),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      '¿Necesitas atención inmediata?',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                'Si estás en peligro o atraviesas una crisis, no esperes la aprobación de una solicitud.',
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  height: 1.35,
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _openUrgentContact,
                  icon: const Icon(Icons.phone_in_talk_rounded),
                  label: const Text('Contactar ayuda urgente'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: EdgeInsets.symmetric(vertical: 13.h),
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
      ],
    );
  }
}

class _ApprovedHelp extends StatelessWidget {
  const _ApprovedHelp({required this.psychologist, required this.onChat});

  final Psychologist psychologist;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFF219653).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF219653).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              PsychologistAvatar(psychologist: psychologist, size: 58),
              SizedBox(width: 13.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Solicitud aprobada',
                      style: TextStyle(
                        color: Color(0xFF219653),
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      psychologist.fullName,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontWeight: FontWeight.w800,
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified_rounded, color: Color(0xFF219653)),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Hablar con mi psicólogo'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF219653),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingHelp extends StatelessWidget {
  const _PendingHelp({required this.count, required this.onView});

  final int count;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF2A51A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFF2A51A).withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: const Color(0xFFF2A51A),
            size: 38.sp,
          ),
          SizedBox(height: 9.h),
          Text(
            'Tu solicitud está en revisión',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w800,
              fontSize: 19.sp,
            ),
          ),
          SizedBox(height: 6.h),
          const Text(
            'Te avisaremos cuando un psicólogo la acepte. Hasta entonces no se mostrará ningún chat profesional.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Fredoka', height: 1.35),
          ),
          SizedBox(height: 13.h),
          TextButton.icon(
            onPressed: onView,
            icon: const Icon(Icons.assignment_outlined),
            label: Text('Ver ${count == 1 ? 'solicitud' : 'solicitudes'}'),
          ),
        ],
      ),
    );
  }
}

class _NoRequestHelp extends StatelessWidget {
  const _NoRequestHelp({required this.onFind});

  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.person_search_rounded, color: careBlue, size: 42.sp),
          SizedBox(height: 10.h),
          Text(
            'Solicita acompañamiento',
            style: TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.w800,
              fontSize: 19.sp,
            ),
          ),
          SizedBox(height: 6.h),
          const Text(
            'Revisa el directorio, elige un psicólogo y envía un mensaje opcional con tu solicitud.',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Fredoka', height: 1.35),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onFind,
              icon: const Icon(Icons.manage_search_rounded),
              label: const Text('Buscar psicólogo'),
              style: FilledButton.styleFrom(
                backgroundColor: careBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
