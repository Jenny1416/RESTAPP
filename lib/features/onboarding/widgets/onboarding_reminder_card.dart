import 'package:flutter/material.dart';

import 'package:rest/core/theme/app_colors.dart';
import '../screens/onboarding_status_screen.dart';
import '../services/onboarding_service.dart';

class OnboardingReminderCard extends StatefulWidget {
  const OnboardingReminderCard({super.key});

  @override
  State<OnboardingReminderCard> createState() => _OnboardingReminderCardState();
}

class _OnboardingReminderCardState extends State<OnboardingReminderCard> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await OnboardingService().getEstado();
      if (mounted) setState(() => _visible = !status.completado);
    } catch (_) {
      // El recordatorio nunca debe bloquear ni ensuciar el inicio.
    }
  }

  Future<void> _open() async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OnboardingStatusScreen()),
    );
    if (mounted && completed == true) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final appColors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: appColors.reminderCardBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _open,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.assignment_outlined, color: appColors.reminderCardFg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completa tu onboarding',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appColors.reminderCardFg,
                        ),
                      ),
                      Text(
                        'Ayuda a NOA a conocerte mejor.',
                        style: TextStyle(color: appColors.reminderCardFg),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: appColors.reminderCardFg,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
