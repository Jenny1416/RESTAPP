# Informe de auditoría: funcionalidades y endpoints

**Fecha:** 17 de septiembre de 2026  
**Alcance:** código Flutter de la rama `feature/3.5-recuperacion-contrasena` y el inventario de endpoints entregado.  
**Objetivo:** identificar qué funciones visibles de la aplicación usan API, cuáles no, y definir el flujo objetivo para que la aplicación sea funcional de extremo a extremo.

## Resumen ejecutivo

La aplicación ya consume una parte importante de la API para usuarios autenticados: autenticación, perfil, registro emocional, rachas, diario básico, actividades diarias, técnicas de relajación, premios, chat con NOA y atención profesional. Sin embargo, no puede considerarse completamente funcional todavía por estas razones:

1. La recuperación de contraseña sin sesión está conectada a una ruta que la propia documentación declara no implementada (`410`).
2. El cambio de contraseña con JWT ya está conectado en el cliente, pero el entorno de pruebas respondió `404`; ese endpoint aún no está desplegado allí o su ruta difiere del contrato.
3. Reportar falla, enviar feedback, cambiar idioma y consultar documentos legales son pantallas funcionales visualmente, pero no consumen los endpoints disponibles para ellas. Algunas muestran confirmación local aunque no persisten datos.
4. La evaluación/semaforización formal está incompleta en Flutter: solo se consulta historial/detalle; no se cargan preguntas ni se envían evaluaciones.
5. Hay una divergencia de contratos: onboarding y atención profesional se consumen desde la app, pero sus rutas no aparecen en la lista recibida. No se pueden certificar ni completar contra esa documentación.
6. Varias experiencias locales (relajación, juegos, música, yoga, actividad física, chistes) no tienen endpoints correspondientes en el inventario. Deben mantenerse explícitamente como contenido local o requerir contratos nuevos si se desea persistir su uso/progreso.

## Cómo leer el estado

| Estado | Significado |
|---|---|
| Conectado | La pantalla llama una ruta documentada con autenticación y maneja la respuesta. Requiere prueba contra el ambiente objetivo. |
| Parcial | Hay lectura o una parte del flujo, pero falta una operación necesaria. |
| No conectado | La función existe en la interfaz o en el contrato, pero no existe llamada HTTP entre ambos. |
| Bloqueado | El cliente llama la ruta, pero el contrato la declara no implementada o el ambiente devolvió una ruta inexistente. |
| Contrato ausente | La app consume una ruta que no está en la lista suministrada; se debe documentar y probar con backend. |

## Matriz de funcionalidades actuales de la app

| Módulo / pantalla | Estado | Endpoints usados por Flutter | Brecha o decisión pendiente |
|---|---|---|---|
| Registro e inicio de sesión | Conectado | `POST /api/auth/register`, `POST /api/auth/login` | Validar respuestas y roles reales en cada ambiente. El JWT e id se guardan en `UserSession`. |
| Recuperar contraseña (sin sesión) | Bloqueado | `POST /api/auth/recover-password` | La documentación indica que devuelve `410`. No debe presentarse como flujo disponible hasta que backend lo implemente de manera segura (token/código de recuperación). |
| Cambiar contraseña (sesión activa) | Bloqueado en test | `PUT /api/settings/change-password` | El cliente envía JWT y el body correcto. `api-test` respondió `404`; backend debe desplegar la ruta o corregir el contrato. |
| Perfil | Conectado | `GET /api/users/profile`, `PUT /api/settings/profile` | Probar edición de todos los campos y los errores de autorización. |
| Racha / meta | Conectado con fallback local | `GET/PUT /api/users/streak-commitment`, `POST /api/users/streak-commitment/register-daily` | Evitar que el fallback local oculte fallas de API en producción; registrar/mostrar el error de sincronización. |
| Registro emocional diario | Conectado | `GET /api/registro-emocional/preguntas`, `GET /api/registro-emocional/usuarios/{id}/fecha/{DD-MM-YYYY}`, `POST /api/registro-emocional` | Alinear el manejo de `403`: el contrato exige JWT para preguntas, pero el cliente reintenta sin token. |
| Calendario emocional | Conectado con discrepancia | `GET /api/registro-emocional/calendario` | La app añade `inicio` y `fin`; el documento no los especifica. Backend debe confirmar que admite esos filtros. |
| Progreso personal y estrella diaria | Conectado | `GET /api/registro-emocional/pantalla-personal`, `POST /api/registro-emocional/pantalla-personal/activar-racha` | Validar forma exacta de `data`, métricas y regla de una estrella por día. |
| Diario | Parcial | `GET /api/diario`, `POST /api/diario` | Faltan detalle, edición y eliminación: `GET/PUT/PATCH/DELETE /api/diario/{id}`. |
| Actividades diarias | Conectado | `GET /api/registro-actividades/diarias`, `POST /api/registro-actividades/diarias/asignar` | Verificar significado de "asignar" frente a "completar" y respuesta `409`. |
| Técnicas de relajación | Conectado | `GET /api/registro-actividades/tecnicas-relajacion`, `POST /api/registro-actividades/tecnicas-relajacion/practicar` | Probar que la práctica actualice progreso/estrellas. |
| Premios | Conectado | `GET /api/premios/catalogo`, `POST /api/premios/solicitar` | No hay interfaz de gestión BU; el usuario solo solicita. |
| Chat NOA | Conectado | `POST /api/chats/ia`, `GET /api/chats/ia/historial`, `GET /api/chats/{id}/mensajes`, `POST /api/chats/ia/detener` | El historial también consulta `GET /api/chats` para filtrar; validar que el backend marque chats IA de forma consistente. |
| Atención profesional y chat profesional | Contrato ausente | `/api/psicologos`, `/api/asignaciones/*`, `/api/chats`, `/api/chats/{id}/mensajes` | Los endpoints de psicólogos/asignaciones no aparecen en el inventario. Deben añadirse con métodos, roles, body y respuestas. |
| Onboarding | Contrato ausente | `GET /api/onboarding/estado`, `GET /api/onboarding/preguntas`, `POST /api/onboarding/respuestas` | No existen en el documento. Sin contrato no es posible certificar respuestas, idempotencia o errores. |
| Evaluaciones / semáforo | Parcial | `GET /api/evaluaciones`, `GET /api/evaluaciones/{id}` | Faltan UI y servicio para `GET /preguntas`, `POST /evaluaciones` y `POST /asignacion-semaforo`. La pantalla de semáforo actual no sustituye ese flujo. |
| Reportar falla técnica | No conectado | Ninguno | Debe usar `POST /api/settings/report`; hoy solo muestra un diálogo de éxito. |
| Enviar feedback | No conectado | Ninguno | Debe usar `POST /api/settings/feedback`; hoy solo muestra un aviso local. |
| Idioma | No conectado y oculto | Ninguno | Debe usar `PUT /api/settings/preferences`; además la opción está marcada como "Próximamente" en Configuración. |
| Código de conducta, privacidad y términos | No conectado | Ninguno | Las pantallas muestran contenido estático; se deben alimentar con `GET /api/settings/code-of-conduct`, `/privacy-policy` y `/terms` si backend es fuente de verdad. |
| Modo oscuro / cerrar sesión | Local intencional | Ninguno | Tema se persiste localmente; logout limpia sesión local. Son válidos sin API, salvo que se requiera invalidar el JWT en servidor. |
| Juegos, música, yoga, ejercicio y chistes | Local sin contrato | Ninguno | No hay endpoints asociados en la documentación. Definir si son recursos offline o crear APIs de catálogo y registro de práctica. |
| Contacto urgente por WhatsApp | Externo | URL `wa.me` | No es endpoint REST. Si debe auditarse o registrarse, se requiere un endpoint nuevo. |

## Endpoints documentados que no están aprovechados por la app

### Prioridad alta: necesarios para flujos visibles

| Endpoint | Falta en Flutter | Flujo esperado |
|---|---|---|
| `POST /api/settings/report` | Servicio y envío real desde Reportar falla técnica. | Validar título/descripción → mostrar carga → POST JWT → éxito solo con `2xx` → limpiar y volver; mostrar error si falla. |
| `POST /api/settings/feedback` | Servicio y envío real desde Feedback. | Calificación 1–5 → convertir selección en `que_mas_te_gusto` → enviar comentarios opcionales → confirmar respuesta del servidor. |
| `PUT /api/settings/preferences` | Servicio y conexión desde Idioma. | Cargar preferencia actual desde perfil → elegir `es/en/pt/fr/de` → PUT JWT → actualizar UI solo tras éxito. |
| `GET /api/settings/code-of-conduct` | Carga remota para Código de conducta. | Skeleton/carga → GET JWT → renderizar contenido seguro → reintentar ante error. |
| `GET /api/settings/privacy-policy` | Carga remota para Aviso de privacidad. | Igual al flujo anterior. |
| `GET /api/settings/terms` | Carga remota para Términos y condiciones. | Igual al flujo anterior. |
| `GET /api/evaluaciones/preguntas` | Pantalla/cuestionario de evaluación. | Cargar preguntas públicas → responder 0–4 → validación de todas → POST evaluación. |
| `POST /api/evaluaciones` | Persistencia de evaluación. | Enviar `{respuestas:[{pregunta_id,respuesta}]}` con JWT → mostrar puntaje, semáforo y dimensiones recibidas. |
| `POST /api/evaluaciones/asignacion-semaforo` | Actualización explícita del semáforo. | Ejecutar tras la evaluación (sin puntaje manual) y refrescar dashboard/progreso. |
| `GET/PUT/PATCH/DELETE /api/diario/{id}` | Detalle y gestión de una entrada. | Lista → abrir detalle → editar o borrar con confirmación → refrescar lista. |

### Prioridad media: cobertura de producto y roles

| Grupo de endpoints | Estado en Flutter | Decisión requerida |
|---|---|---|
| `/api/dashboard` | Sin uso. | Usarlo como agregado principal del inicio o eliminarlo del contrato si `pantalla-personal`, actividades y premios son la estrategia. |
| `/api/chats/actividades/recomendadas`, `/api/chats/estado-psicologico` | Sin uso. | Añadir tarjetas de recomendaciones/estado en inicio o progreso; definir cuándo se refrescan. |
| CRUD de usuarios (`/api/users`, `/api/users/{id}`) | Sin interfaz de psicólogo/admin. | Crear panel por roles P/A o declararlo fuera del alcance de esta app de estudiante. |
| CRUD encuestas y respuestas (`/api/encuestas*`) | Sin interfaz. | Diseñar módulo de encuestas, o retirar del alcance móvil. |
| CRUD de opciones/registro de actividades genérico | Solo se usan las rutas diarias y de técnicas. | Crear catálogo/historial si es requisito; no sustituirlo con datos hardcodeados. |
| Gestión BU de premios (`GET/PATCH /api/premios/panel/solicitudes`) | Sin interfaz. | Requiere panel web/rol BU, no una pantalla de estudiante. |
| Administración (`/api/admin/*`) | Sin interfaz. | Requiere panel de administrador y pruebas de autorización. |

### Endpoint que no debe implementarse en Flutter como está

`POST /api/auth/recover-password` está descrito como reservado/no implementado y responde `410`. La pantalla actual permite ingresar correo y nueva clave, pero un cambio de contraseña por correo sin verificación es inseguro.

**Flujo seguro requerido para backend y frontend:** solicitar correo → enviar código o enlace de un solo uso → validar código/token → definir nueva contraseña → invalidar token. Hasta tener esas rutas, la pantalla debe informar que la recuperación no está disponible o dirigirse al soporte institucional.

## Rutas usadas por la app que faltan en la documentación

Estas rutas no deben asumirse funcionales solo porque Flutter las llama. Se necesita anexar su contrato y probarlas en `local`, `test` y `production`.

| Grupo | Rutas que consume Flutter |
|---|---|
| Onboarding | `GET /api/onboarding/estado`, `GET /api/onboarding/preguntas`, `POST /api/onboarding/respuestas` |
| Atención profesional | `GET /api/psicologos`, `GET /api/psicologos/{id}`, `GET /api/asignaciones/mis-solicitudes`, `POST /api/asignaciones/solicitar`, `DELETE /api/asignaciones/{id}` |

Para cada una se debe documentar: rol permitido, parámetros, body, respuesta exitosa, respuestas `400/401/403/404/409`, y reglas de propiedad del recurso.

## Flujos objetivo de la aplicación

### 1. Acceso y sesión

```text
Inicio → Registro o Login → recibir JWT + usuario → persistir sesión
      → consultar estado de onboarding → MainApp
      → cada petición privada incluye Authorization: Bearer <JWT>
      → 401: limpiar sesión y volver a Login
```

Después de registro, el onboarding debe completarse o permitir continuarlo. No debe depender de respuestas locales ni de una ruta no documentada.

### 2. Evaluación, semáforo y registro emocional

```text
MainApp → Evaluación inicial → GET preguntas → responder todas
        → POST evaluación → mostrar puntaje/dimensiones/semaforo
        → POST asignación-semaforo → refrescar progreso

Cada día → validar registro existente → GET preguntas emocionales
          → enviar POST registro emocional → refrescar calendario, racha y pantalla personal
```

Separar claramente evaluación (0–4, `evaluaciones`) de registro emocional (opciones, `registro-emocional`); son contratos distintos y no deben usarse de forma intercambiable.

### 3. Progreso, actividades y premios

```text
Progreso → cargar pantalla personal + actividades diarias + técnicas + catálogo de premios
         → completar actividad/practicar técnica → refrescar totales
         → solicitar premio si está habilitado → mostrar estado de solicitud
```

El backend debe ser la fuente de verdad de estrellas, rachas y permisos de canje. El cliente no debe aumentar saldos localmente.

### 4. Diario

```text
Mi diario → GET lista → crear, abrir, editar o eliminar entrada
          → POST/GET/PUT o PATCH/DELETE según acción
          → recargar lista solo después de respuesta exitosa
```

### 5. Atención y conversaciones

```text
Atención profesional → directorio → detalle → solicitar atención
                       → ver estado de solicitud → abrir/cerrar chat profesional

Inicio → chat NOA → enviar mensajes → historial → detener sesión
       → mostrar retroalimentación/alerta y rutas de apoyo cuando aplique
```

Las rutas de atención profesional deben formalizarse en el contrato antes de declarar este flujo listo.

### 6. Configuración y soporte

```text
Configuración → Perfil / Contraseña / Preferencias
              → documentos legales remotos
              → Reporte técnico o Feedback
              → cada formulario muestra carga, éxito real o error real
```

No se debe mostrar "enviado" o "actualizado" hasta recibir una respuesta `2xx` del servidor.

## Plan de implementación recomendado

1. **Cerrar contratos y ambientes.** Publicar la especificación de onboarding y atención profesional; desplegar en `api-test` `PUT /api/settings/change-password`; confirmar filtros del calendario y forma de todas las respuestas.
2. **Completar configuración y soporte.** Implementar servicios/pantallas para reporte, feedback, preferencias y documentos legales. Es trabajo acotado y elimina confirmaciones falsas.
3. **Completar evaluación/semaforización.** Añadir cuestionario, envío de evaluación, asignación de semáforo y actualización de inicio/progreso.
4. **Completar diario y decisiones de contenido.** Añadir CRUD de diario; decidir y documentar qué experiencias de relajación son offline y cuáles deben registrar actividad.
5. **Cubrir roles secundarios.** Implementar o separar en otro producto los paneles P/A/BU, encuestas y catálogos administrativos.
6. **Pruebas de integración.** Para cada flujo, probar éxito, `400`, `401`, `403`, `404`, `409` y `500` con un usuario de prueba. Ejecutar en local y test antes de producción.

## Criterios de salida para declarar la app funcional

- Ningún botón visible confirma una acción sin una respuesta exitosa de API, salvo las funciones declaradas explícitamente offline.
- Toda pantalla privada envía JWT y trata `401` con cierre de sesión controlado.
- Cada endpoint usado tiene contrato documentado y está desplegado en el ambiente de pruebas.
- Recuperación de contraseña tiene un flujo seguro completo o permanece deshabilitada con un mensaje claro.
- Evaluación, registro emocional, progreso y premios se refrescan desde backend después de cada mutación.
- Las pantallas por rol (U, P, A, BU) solo muestran acciones permitidas y sus rutas se prueban con cuentas de cada rol.
- Existe una matriz de pruebas de integración automatizable para los flujos anteriores.

## Evidencia revisada

- Servicios Flutter en `lib/core/services/` y `lib/features/**/services/`.
- Pantallas de autenticación, configuración, emoción, progreso, inicio, onboarding, atención profesional y relajación.
- Configuración de URL en `lib/core/config/api_config.dart` y build Docker.
- Documento de endpoints suministrado por el equipo.

Este informe es una auditoría estática del cliente y del contrato entregado. Un estado marcado como "Conectado" significa que existe integración en código, no que el endpoint haya respondido correctamente en todos los ambientes. La prueba de `PUT /api/settings/change-password` contra `api-test` sí produjo `404` durante esta revisión.
