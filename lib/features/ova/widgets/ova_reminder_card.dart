import 'package:flutter/material.dart';
import 'package:rest/core/theme/app_colors.dart';

import '../screens/ova_list_screen.dart';
import '../services/ova_pendientes.dart';

/// Aviso en Home cuando hay actividades por hacer. Si no hay, no ocupa espacio.
class OvaReminderCard extends StatefulWidget {
  const OvaReminderCard({super.key});

  @override
  State<OvaReminderCard> createState() => _OvaReminderCardState();
}

class _OvaReminderCardState extends State<OvaReminderCard> {
  @override
  void initState() {
    super.initState();
    OvaPendientes.refresh();
  }

  Future<void> _open() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const OvaListScreen()));
    if (mounted) await OvaPendientes.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return ValueListenableBuilder<int>(
      valueListenable: OvaPendientes.count,
      builder: (context, pendientes, _) {
        if (pendientes <= 0) return const SizedBox.shrink();
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
                    Icon(Icons.spa_outlined, color: appColors.reminderCardFg),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pendientes == 1
                                ? 'Tienes 1 actividad para ti'
                                : 'Tienes $pendientes actividades para ti',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: appColors.reminderCardFg,
                            ),
                          ),
                          Text(
                            'Mira los ejercicios que te recomendamos.',
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
      },
    );
  }
}
