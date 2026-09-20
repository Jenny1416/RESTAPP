# RESTAPP

Aplicacion Flutter enfocada en acompanamiento emocional, registro diario y seguimiento de progreso personal para estudiantes.

## 1) Proposito

RESTAPP busca ofrecer un flujo simple para:

- autenticacion de usuario;
- test emocional diario con semaforo de resultado;
- conversacion con asistente IA (NOA) y escalamiento a "Salvavidas" cuando hay alerta;
- seguimiento de progreso personal (racha, estrellas, emociones frecuentes, evolucion);
- actividades/tecnicas de relajacion y diario personal.

## 2) Stack tecnologico

- `Flutter` + `Dart` (SDK `^3.9.0`)
- Dependencias principales:
  - `http` para consumo de API REST
  - `google_fonts` para tipografia
  - `flutter_svg`
  - `intl`
  - `url_launcher`
- Linting base: `flutter_lints`

Referencia: `pubspec.yaml`.

## 3) Arquitectura y estructura del proyecto

El proyecto esta organizado por features dentro de `lib/`, con una capa `core/` para rutas, configuracion y servicios HTTP.

```text
lib/
  core/
    config/      # API config
    routes/      # Route names
    services/    # Integracion con backend
  features/
    intro_auth/  # Intro, login, register, forgot password
    emotion/     # Test emocional, chat, semaforo y consejo
    home/        # Home principal y accesos
    progress/    # Progreso global y personal
    relax/       # Tecnicas/actividades de relajacion
    help/        # Salvavidas / ayuda
    settings/    # Configuracion y pantallas informativas
    navigation/  # Bottom navigation
  main.dart      # Entry point + route table
```

Archivos clave:

- `lib/main.dart`: define `MaterialApp`, `initialRoute` y registro de rutas.
- `lib/core/routes/app_routes.dart`: constantes de rutas.
- `lib/core/config/api_config.dart`: seleccion de `baseUrl` backend.
- `lib/core/services/*.dart`: capa de acceso a API (auth, chat, emotion, progress, diary).

## 4) Requisitos

- Flutter SDK compatible con Dart `^3.9.0`
- Android Studio / VS Code con plugin Flutter
- Emulador Android/iOS o dispositivo fisico
- Backend REST disponible y accesible desde el dispositivo/emulador

## 5) Instalacion

```bash
flutter pub get
```

## 6) Configuracion del entorno

La aplicacion selecciona dinamicamente su API. `API_BASE_URL`, cuando se
proporciona, tiene prioridad sobre `API_ENV`. Si no se proporciona ninguna de
las dos variables, usa el backend local.

| Entorno | URL |
|---|---|
| `local` | `http://localhost:3000` |
| `local` en emulador Android | `http://10.0.2.2:3000` |
| `test` | `https://api-test.restapp.site` |
| `production` | `https://api.restapp.site` |
| `university` | `http://179.197.239.216:3000` |

La seleccion se resuelve en:

- `lib/core/config/api_config.dart`

## 7) Ejecutar localmente

Ejecutar contra el backend local, que es el comportamiento predeterminado:

```bash
flutter run
```

Ejecutar contra cada API remota:

```bash
flutter run --dart-define=API_ENV=test
flutter run --dart-define=API_ENV=production
flutter run --dart-define=API_ENV=university
```

Una URL personalizada siempre tiene prioridad:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:3000
```

Generar APK:

```bash
# Local: Android usa automaticamente 10.0.2.2
flutter build apk --release

flutter build apk --release --dart-define=API_ENV=test
flutter build apk --release --dart-define=API_ENV=production
flutter build apk --release --dart-define=API_ENV=university
```

Para listar dispositivos:

```bash
flutter devices
```

## 8) Ejecutar en contenedor

El contenedor publica Flutter Web en `http://localhost:8081`. En PowerShell:

```powershell
# Local (predeterminado)
docker compose -p restapp up -d --build --force-recreate

# Pruebas
$env:API_ENV = "test"
$env:API_BASE_URL = ""
docker compose -p restapp up -d --build --force-recreate

# Produccion
$env:API_ENV = "production"
$env:API_BASE_URL = ""
docker compose -p restapp up -d --build --force-recreate

# Universidad
$env:API_ENV = "university"
$env:API_BASE_URL = ""
docker compose -p restapp up -d --build --force-recreate

Remove-Item Env:API_ENV -ErrorAction SilentlyContinue
Remove-Item Env:API_BASE_URL -ErrorAction SilentlyContinue
```

Para desarrollo con el codigo montado como volumen y hot reload:

```powershell
docker compose -p restapp-dev -f docker-compose.dev.yml up -d
docker attach restapp-dev-app-1
```

Pulsa `r` para hot reload y separa la terminal con `Ctrl+P`, `Ctrl+Q`.

Detener los contenedores:

```powershell
docker compose -p restapp down
docker compose -p restapp-dev -f docker-compose.dev.yml down
```

## Comandos utiles

- Analisis estatico: `flutter analyze`
- Pruebas: `flutter test`
- Formateo: `dart format .`

### Importante para pruebas en Android emulator/device

- `localhost` en movil/emulador no siempre apunta a tu maquina host.
- Si usas Android emulator, normalmente debes usar `10.0.2.2` en lugar de `localhost`.

## 9) Flujo principal de la aplicacion

1. **Intro** (`/intro`) con animacion de bienvenida.
2. **Login/Register**:
   - Login consume `/api/auth/login`
   - Guarda token e info basica en `UserSession` (memoria de ejecucion)
3. **Validacion de test diario**:
   - Si no hay test hoy, abre `EmotionRegisterScreen`
   - Si ya existe, entra a `MainApp`
4. **Test emocional diario**:
   - Consulta preguntas desde backend
   - Envia respuestas a `/api/registro-emocional`
   - Navega a semaforo emocional y consejos
5. **Home**:
   - Acceso a chat NOA, historial, actividades y ayuda
6. **Chat IA (NOA)**:
   - Endpoint principal: `/api/chats/ia`
   - Si backend marca `requiere_salvavidas`, redirige a ayuda
7. **Progreso personal**:
   - Rachas, estrellas, emociones frecuentes, evolucion y activacion diaria

## 10) Variables de entorno

Variables de compilacion admitidas:

- `API_ENV=local|test|production|university` (opcional; por defecto `local`)
- `API_BASE_URL=<url>` (opcional; tiene prioridad sobre `API_ENV`)

Las URLs publicas de una API siempre son visibles en el trafico del navegador o
de la aplicacion y no deben considerarse secretos.

## 11) Convenciones del proyecto

- Estructura por modulo funcional (`features/*`).
- Servicios HTTP en `core/services`.
- Rutas centralizadas en `core/routes`.
- Tipografia principal `Fredoka` (assets y `google_fonts`).
- Lints base desde `flutter_lints`.

## 12) Troubleshooting basico

### Error de conexion al backend

- Verifica URL activa en `api_config.dart`.
- Confirma que el backend este corriendo y accesible desde el dispositivo.
- En emulador Android, evita `localhost` y prueba `10.0.2.2`.

### Login exitoso pero fallan endpoints protegidos

- Revisa si `UserSession.authToken` se esta asignando correctamente.
- Valida que el backend acepte header `Authorization: Bearer <token>`.

### No cargan preguntas del test emocional

- Revisa disponibilidad de `/api/registro-emocional/preguntas`.
- El servicio implementa fallback sin token cuando recibe `403`; revisar roles/backend.

### Overflow/UI rota en pantallas pequenas

- Ejecuta en distintos tamanos (`flutter run` en emulator pequeno y grande).
- Revisa `SingleChildScrollView` en pantallas de formularios.

## 13) Pendientes / por definir

- Documentacion oficial de API backend (OpenAPI/Postman): **pendiente/por definir**.
- Estrategia formal de entornos (`dev/staging/prod`): **pendiente/por definir**.
- Persistencia segura de sesion (actualmente en memoria con `UserSession`): **pendiente/por definir**.
- Evidencia de cobertura de pruebas automatizadas: **pendiente/por definir**.

## 14) Recursos Flutter

- [Flutter docs](https://docs.flutter.dev/)
- [Dart docs](https://dart.dev/)
