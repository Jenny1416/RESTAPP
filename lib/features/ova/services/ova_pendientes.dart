import 'package:flutter/foundation.dart';

import 'ova_service.dart';

/// Cantidad de actividades OVA que esperan al estudiante (por hacer o con la
/// medición posterior pendiente). Se comparte entre Home y Acompañamiento.
class OvaPendientes {
  OvaPendientes._();

  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  /// Actualiza el contador. Nunca lanza: es un aviso, no debe romper la pantalla.
  static Future<void> refresh({OvaService? service}) async {
    try {
      final items = await (service ?? OvaService()).getAsignaciones();
      count.value = items
          .where((item) => item.porHacer || item.necesitaPostTest)
          .length;
    } catch (_) {
      // Sin red o sesión vencida: se conserva el último valor conocido.
    }
  }
}
