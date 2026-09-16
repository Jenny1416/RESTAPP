# Propuesta de integración de RESTAPP, Backend y Panel

Fecha de análisis: 2026-09-16

## 1. Decisión recomendada

Usar `RESTAPP` como **superproyecto Git** y agregar los otros dos repositorios como submódulos, sin modificar su contenido:

- `modules/backend` → `https://github.com/hleonez/Backend_APP_REST-2026_2.git`
- `modules/panel` → `https://github.com/JuanDres7/REST_Panel_Frontend.git`

Los submódulos resolverán qué versión compatible de cada repositorio se despliega. La comunicación entre aplicaciones no la resuelven los submódulos: se resolverá con URLs configurables por entorno, Docker Compose, DNS, HTTPS y CORS.

No se recomienda implementar aún los submódulos ni los archivos de despliegue hasta aprobar esta propuesta.

## 2. Qué se puede hacer sin tocar Backend ni Panel

Desde `RESTAPP` se pueden agregar:

- `.gitmodules` con referencias a ambos repositorios;
- archivos Compose que construyan y conecten los tres proyectos;
- Dockerfiles envoltorio para Panel y RESTAPP Web;
- configuración de proxy inverso para el VPS;
- plantillas de variables de entorno;
- scripts de preparación y despliegue;
- documentación de operación.

Agregar un repositorio como submódulo **no crea commits ni archivos dentro del repositorio enlazado**. `RESTAPP` solo guarda su URL y el commit exacto aprobado.

Hay una limitación importante: la política CORS segura del backend requiere un cambio en el código del backend. El superproyecto no puede corregir de forma confiable esa política sin que el propietario del backend acepte el ajuste.

## 3. Estado encontrado

### RESTAPP

- Es una aplicación Flutter y no tiene Dockerfile.
- Ya acepta `--dart-define=API_BASE_URL=...` en `lib/core/config/api_config.dart`.
- Desarrollo de escritorio/iOS usa `http://localhost:3000`.
- Emulador Android usa `http://10.0.2.2:3000`.
- Release usa actualmente `http://179.197.239.216:3000`.
- El README menciona otra dirección: `http://190.143.117.179:8080`.

La discrepancia entre código y README debe eliminarse. En producción no debe dependerse de una IP HTTP hardcodeada; debe compilarse con una URL HTTPS estable.

### Panel REST

- Es React/Vite y no tiene Dockerfile.
- Ya usa `VITE_API_URL` para Axios y Socket.IO.
- Su valor de respaldo es `http://localhost:3000`.

Por tanto, el Panel no necesita un cambio de código para elegir backend local o público. Sí necesita que el valor correcto exista al ejecutar `vite` o al construir la imagen, porque una variable `VITE_*` queda incorporada en el bundle durante la compilación.

### Backend

- Es Express/TypeScript con Socket.IO.
- Ya tiene Dockerfile y Compose con PostgreSQL, Ollama y Sentiment.
- Escucha correctamente en `0.0.0.0:3000`.
- Declara `CORS_ORIGINS` en `.env.example` y en Compose.
- El código actual no usa esa variable: Express y Socket.IO permiten `origin: '*'`.
- El Compose actual publica PostgreSQL en `5433` y Ollama en `11434`; eso resulta práctico localmente, pero no debe quedar expuesto públicamente en el VPS.
- El Dockerfile imprime `DATABASE_URL` durante el arranque, usa `npm install`, ejecuta como root y espera diez segundos en lugar de usar una comprobación activa de disponibilidad.

## 4. Nombres de repositorios y nombres DNS

Repositorios observados:

| Función | Repositorio |
|---|---|
| Aplicación Flutter y futuro superproyecto | `Jenny1416/RESTAPP` |
| API y servicios internos | `hleonez/Backend_APP_REST-2026_2` |
| Panel React | `JuanDres7/REST_Panel_Frontend` |

No se encontró un dominio DNS real configurado en ninguno de los tres repositorios. Solo existen referencias a `localhost` y a IP públicas inconsistentes. Por eso no es posible afirmar cuáles son los dominios “ya creados” únicamente con el código disponible.

Convención propuesta, reemplazando `<dominio-base>` por el dominio real:

| Servicio público | Nombre propuesto | Destino |
|---|---|---|
| API | `api.<dominio-base>` | Proxy HTTPS → Backend `:3000` |
| Panel | `panel.<dominio-base>` | Archivos estáticos del Panel |
| RESTAPP Web, si se publica | `app.<dominio-base>` | Archivos estáticos de Flutter Web |

Ejemplo de lista CORS de producción:

```dotenv
CORS_ORIGINS=https://panel.<dominio-base>,https://app.<dominio-base>
```

La API no se agrega a su propia lista CORS. Las aplicaciones móviles nativas, Postman y llamadas servidor-servidor normalmente llegan sin encabezado `Origin`; el backend debe permitir explícitamente ese caso.

## 5. Modos de funcionamiento

### 5.1 Todo local

- Backend: `http://localhost:3000`.
- Panel local: `VITE_API_URL=http://localhost:3000`.
- RESTAPP en escritorio/iOS simulator: `API_BASE_URL=http://localhost:3000`.
- RESTAPP en emulador Android: `API_BASE_URL=http://10.0.2.2:3000`.
- RESTAPP en teléfono físico: `API_BASE_URL=http://<IP-LAN-DEL-PORTATIL>:3000` y puerto permitido por el firewall.

### 5.2 Frontend local con backend publicado

- Panel: `VITE_API_URL=https://api.<dominio-base>`.
- RESTAPP: `flutter run --dart-define=API_BASE_URL=https://api.<dominio-base>`.
- El backend debe admitir en CORS el origen real del Panel local, normalmente `http://localhost:5173`.
- Una aplicación Flutter nativa no depende de CORS, pero Flutter Web sí.

### 5.3 Todo publicado en VPS

- Los clientes consumen únicamente HTTPS.
- Un proxy inverso termina TLS y enruta por hostname.
- Backend, PostgreSQL, Ollama y Sentiment comparten una red Docker privada.
- Solo se publican los puertos `80` y `443` del proxy.
- PostgreSQL, Ollama y Sentiment no publican puertos al exterior.

## 6. Cambio mínimo requerido en Backend

Estos cambios deben ser realizados o aprobados en el repositorio del backend:

1. Leer y validar `CORS_ORIGINS` al iniciar.
2. Usar la misma función de autorización de origen para Express y Socket.IO.
3. Permitir:
   - los dominios públicos exactos;
   - `localhost` y `127.0.0.1` con puerto variable únicamente en desarrollo;
   - solicitudes sin `Origin` para clientes nativos y servidor-servidor.
4. Rechazar el arranque de producción si la lista está vacía.
5. Configurar Swagger con la URL pública por variable, no solo `localhost`.
6. Separar exposición local y producción:
   - local: API, PostgreSQL y Ollama pueden exponer puertos para diagnóstico;
   - VPS: solo la API queda accesible para el proxy; los demás servicios permanecen internos.
7. Eliminar del log el valor de `DATABASE_URL`.
8. Añadir healthcheck al contenedor API y sustituir la espera fija por dependencias saludables.
9. Recomendado: Dockerfile multi-stage, `npm ci`, usuario no root y versión Node LTS soportada.
10. Definir secretos solo en el VPS o en un gestor de secretos: `POSTGRES_PASSWORD`, `JWT_SECRET`, `OPENAI_API_KEY` y demás credenciales nunca deben entrar al repositorio.

La copia `src/index.ts.backup` ya contiene una aproximación a la lista CORS, pero no debe copiarse sin revisión: la implementación definitiva debe compartir exactamente la política con Socket.IO y distinguir desarrollo de producción.

## 7. Cambio mínimo requerido en Panel

No se requiere cambiar su código fuente para seleccionar la API. Para contenerizarlo desde `RESTAPP` se necesita:

- construir con Node mediante un Dockerfile envoltorio del superproyecto;
- pasar `VITE_API_URL` como argumento/variable de compilación;
- servir `dist/` con Nginx o Caddy;
- configurar fallback de SPA hacia `index.html`;
- no guardar secretos en `VITE_*`, porque esos valores son públicos en el navegador;
- construir una imagen distinta cuando cambie la URL de API, salvo que en el futuro el Panel implemente configuración en tiempo de ejecución.

## 8. Cambio mínimo requerido en RESTAPP

RESTAPP ya puede seleccionar la API mediante `--dart-define`. Al implementar la propuesta conviene:

- retirar la IP pública como decisión automática de release;
- exigir `API_BASE_URL` para builds de producción;
- documentar comandos para local, híbrido y producción;
- crear un Dockerfile envoltorio para Flutter Web;
- servir `build/web` como SPA estática;
- usar siempre `https://api.<dominio-base>` en producción;
- verificar permisos de red y políticas de tráfico claro en Android/iOS.

Un build móvil o web de Flutter también debe reconstruirse si cambia `API_BASE_URL`.

## 9. Estructura propuesta del superproyecto

La aplicación Flutter puede seguir en la raíz de `RESTAPP`. Los repositorios externos quedarían aislados debajo de `modules/`:

```text
RESTAPP/
├── .gitmodules
├── lib/                         # Flutter existente
├── android/ ios/ web/ ...       # Flutter existente
├── modules/
│   ├── backend/                 # submódulo, commit fijado
│   └── panel/                   # submódulo, commit fijado
├── deploy/
│   ├── compose.local.yml
│   ├── compose.prod.yml
│   ├── docker/
│   │   ├── Dockerfile.restapp-web
│   │   └── Dockerfile.panel
│   └── proxy/
│       ├── Caddyfile            # o configuración Nginx/Traefik
│       └── snippets/
├── env/
│   ├── local.env.example
│   └── production.env.example
└── scripts/
    ├── bootstrap.ps1
    └── deploy.sh
```

Los Dockerfiles envoltorio usarían el contexto del superproyecto para leer los submódulos sin escribir dentro de ellos.

## 10. Flujo Git con submódulos

Clonado inicial:

```bash
git clone --recurse-submodules https://github.com/Jenny1416/RESTAPP.git
```

Si ya fue clonado:

```bash
git submodule update --init --recursive
```

Actualizar versiones no significa seguir automáticamente la última rama. El flujo seguro es:

1. probar un commit concreto del Backend o Panel;
2. actualizar el puntero del submódulo en una rama feature de `RESTAPP`;
3. validar los tres modos de ejecución;
4. integrar el puntero aprobado a `develop`;
5. promover a `main`.

Esto permite reproducir en el VPS exactamente las versiones probadas. Si un submódulo es privado, cada desarrollador y el VPS necesitarán credenciales de lectura para clonarlo.

## 11. Contenerización local y VPS

### Compose local

Debe ofrecer perfiles para no obligar a levantar todo:

- `backend`: API + PostgreSQL + Ollama + Sentiment;
- `panel`: Panel apuntando a API local o pública;
- `restapp-web`: Flutter Web apuntando a API local o pública;
- `full`: todos los servicios.

Así, un desarrollador puede levantar solo el Panel o RESTAPP y configurarlos contra el backend público.

### Compose de producción

Debe incluir:

- proxy HTTPS;
- Panel estático;
- RESTAPP Web, únicamente si se desea publicar esa variante;
- Backend;
- PostgreSQL con volumen y política de backup;
- Ollama con volumen de modelos;
- Sentiment con caché persistente;
- redes separadas de entrada e interna;
- políticas de reinicio, healthchecks y límites de recursos.

No se recomienda montar el código fuente como volumen en producción. Las imágenes deben construirse desde los commits fijados por los submódulos.

## 12. Flujo de despliegue propuesto

```text
feature → develop → validación integrada → main → VPS
```

En el VPS:

```bash
git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive
docker compose -f deploy/compose.prod.yml build --pull
docker compose -f deploy/compose.prod.yml up -d
```

Antes de promover deben probarse:

- `GET /health` por HTTPS;
- login desde ambos frontends;
- petición REST autenticada;
- conexión y reconexión Socket.IO;
- persistencia de PostgreSQL tras recrear contenedores;
- resolución interna de Ollama y Sentiment;
- rechazo CORS desde un origen no autorizado.

## 13. Plan de implementación si se aprueba

1. Confirmar el dominio base y quién administra DNS/TLS.
2. Obtener aprobación del responsable del backend para el cambio CORS mínimo.
3. Agregar los dos submódulos a `RESTAPP`.
4. Crear Dockerfiles envoltorio y Compose local.
5. Validar los escenarios local completo e híbrido.
6. Crear Compose y proxy de producción.
7. Probar en un entorno de ensayo del VPS.
8. Documentar promoción de commits de submódulos entre `develop` y `main`.

## 14. Criterio para aprobar o dejar en espera

La propuesta es viable sin alterar ahora Backend ni Panel, pero la salida segura a producción depende de dos datos externos:

- el dominio base real y acceso a su DNS;
- aprobación del cambio CORS en Backend.

Si no se dispone todavía de ambos, conviene dejar la conversión a submódulos en espera. RESTAPP puede seguir consumiendo el backend mediante `API_BASE_URL` mientras se acuerdan esos puntos.

El diagrama interactivo asociado se genera desde `ARQUITECTURA_DESPLIEGUE.json`.
