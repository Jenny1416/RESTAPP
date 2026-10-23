import 'package:flutter/foundation.dart';

import '../models/ova_models.dart';
import 'ova_service.dart';

/// Cantidad de actividades OVA que esperan al estudiante (por hacer o con la
/// medición posterior pendiente). Se comparte entre Home y Acompañamiento.
class OvaPendientes {
  OvaPendientes._();

  static final ValueNotifier<int> count = ValueNotifier<int>(0);

  /// Recalcula el contador con una lista ya cargada.
  static void actualizar(List<OvaAsignacion> items) {
    count.value = items
        .where((item) => item.porHacer || item.necesitaPostTest)
        .length;
  }

  /// Consulta el backend y actualiza el contador. Nunca lanza: es un aviso y
  /// no debe romper la pantalla donde se muestra.
  static Future<void> refresh({OvaService? service}) async {
    try {
      actualizar(await (service ?? OvaService()).getAsignaciones());
    } catch (_) {
      // Sin red o sesión vencida: se conserva el último valor conocido.
    }
  }
}
