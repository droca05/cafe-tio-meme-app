# CLAUDE.md — Café Tío Meme: App de Gestión de Ventas

> Este archivo es la fuente de verdad del proyecto. Antes de generar o modificar cualquier código, leer este documento completo.

---

## 1. Descripción del Proyecto

Aplicación móvil Android para **Café Tío Meme** que centraliza y controla todas las solicitudes de venta, diferenciando entre dos canales: **Venta Directa** y **FORZA (Redes Sociales)**. La app es usada por exactamente **dos personas** del equipo y los datos se sincronizan en tiempo real entre ambos dispositivos.

**Problema que resuelve:** actualmente no existe un registro centralizado que indique qué pidió cada cliente, por qué canal llegó la solicitud, y si el pago fue realizado y verificado.

---

## 2. Stack Tecnológico

| Capa | Tecnología |
|---|---|
| Framework UI | Flutter (Dart) |
| Lenguaje | Dart 3.x con null safety |
| Estado | Riverpod (flutter_riverpod) |
| Navegación | GoRouter |
| Base de datos | Cloud Firestore (Firebase) |
| Autenticación | Firebase Auth (email + contraseña) |
| Backend | Firebase (sin servidor propio) |
| CI/Control de versiones | GitHub |
| IDE | VS Code |

### Paquetes principales (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  go_router: ^13.2.0
  firebase_core: ^2.27.0
  firebase_auth: ^4.17.0
  cloud_firestore: ^4.15.0
  intl: ^0.19.0
  uuid: ^4.3.3
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  flutter_lints: ^3.0.0
```

---

## 3. Identidad Visual y Design System

### 3.1 Paleta de Colores
Extraída del logo de Café Tío Meme (grano de café en tonos marrón/caramelo sobre fondo crema).

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // Fondos
  static const cream  = Color(0xFFF2EBE0); // Fondo principal
  static const foam   = Color(0xFFFAF6F0); // Fondo de tarjetas y modales
  static const steam  = Color(0xFFE8DDD0); // Bordes, divisores, chips inactivos

  // Marca
  static const caramel  = Color(0xFFA0622A); // Primario: botones, FAB, énfasis
  static const latte    = Color(0xFFC49A6C); // Secundario: acentos, canal FORZA
  static const roast    = Color(0xFF3B1F0A); // TopBar, títulos principales
  static const espresso = Color(0xFF1C1008); // Texto primario, íconos

  // Estados
  static const success = Color(0xFF4A7C59); // Pagado / Entregado
  static const warning = Color(0xFFC8831A); // Pendiente / En proceso
  static const danger  = Color(0xFFB04030); // Sin verificar / Error
}
```

### 3.2 Tipografía
- **Display / Títulos:** Playfair Display (Google Fonts) — peso 600 y 700
- **Cuerpo / UI:** Inter (Google Fonts) — peso 300, 400, 500, 600
- **Labels y chips:** Inter 600, uppercase, letter-spacing 0.08em

### 3.3 Reglas de diseño
- Border-radius de tarjetas: `14px`
- Border-radius de botones primarios: `12px`
- Elevación de tarjetas: sombra sutil `0 2px 8px rgba(28,16,8,0.10)`
- El canal siempre se muestra con un color diferenciado:
  - **Venta Directa** → fondo `#EBF5EE`, texto `success`
  - **FORZA** → fondo `#FEF3E2`, texto `warning`
- La barra superior siempre usa fondo `roast` con texto `latte`

---

## 4. Estructura de Carpetas

```
lib/
├── main.dart
├── firebase_options.dart          # Generado por FlutterFire CLI
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart        # Paleta de colores (sección 3.1)
│   │   ├── app_text_styles.dart   # Estilos tipográficos centralizados
│   │   └── app_theme.dart         # ThemeData de Flutter
│   ├── router/
│   │   └── app_router.dart        # Rutas con GoRouter
│   └── utils/
│       └── date_formatter.dart    # Utilidades de formato de fecha
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── presentation/
│   │   │   ├── login_screen.dart
│   │   │   └── login_controller.dart
│   │   └── providers/
│   │       └── auth_providers.dart
│   │
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   └── dashboard_screen.dart
│   │   └── providers/
│   │       └── dashboard_providers.dart
│   │
│   ├── solicitudes/
│   │   ├── data/
│   │   │   └── solicitudes_repository.dart
│   │   ├── domain/
│   │   │   ├── solicitud_model.dart
│   │   │   └── enums.dart          # CanalVenta, EstadoPedido, EstadoPago
│   │   ├── presentation/
│   │   │   ├── solicitudes_list_screen.dart
│   │   │   ├── solicitud_detail_screen.dart
│   │   │   └── nueva_solicitud_screen.dart
│   │   └── providers/
│   │       └── solicitudes_providers.dart
│   │
│   └── clientes/
│       ├── data/
│       │   └── clientes_repository.dart
│       ├── domain/
│       │   └── cliente_model.dart
│       ├── presentation/
│       │   ├── clientes_list_screen.dart
│       │   └── cliente_detail_screen.dart
│       └── providers/
│           └── clientes_providers.dart
│
└── shared/
    └── widgets/
        ├── canal_badge.dart        # Chip de canal (Directa / FORZA)
        ├── estado_badge.dart       # Badge de estado de pago/pedido
        ├── app_text_field.dart     # Campo de texto reutilizable
        └── loading_overlay.dart   # Indicador de carga global
```

---

## 5. Modelos de Datos

### 5.1 Cliente
```dart
// lib/features/clientes/domain/cliente_model.dart
class Cliente {
  final String id;           // UUID generado localmente
  final String nombre;
  final String telefono;
  final String direccion;
  final DateTime fechaRegistro;
}
```

**Colección Firestore:** `clientes/{clienteId}`

### 5.2 ProductoCatalogo
```dart
// lib/features/solicitudes/domain/producto_catalogo_model.dart
class ProductoCatalogo {
  final String id;
  final String nombre;
  final String? descripcion;               // ej. "Anacafé 14, lavado"
  final int? gramaje;                      // en gramos; null si no aplica (ej. Licor de Café)
  final List<Presentacion> presentaciones; // vacío si el producto no aplica presentación
  final double precioNormal;
  final double? precioPromo;               // null si el producto no tiene precio promocional
}
```

**Catálogo precargado** (constante local en la app — no requiere colección propia en Firestore; cada `Solicitud` guarda una copia desnormalizada del producto elegido en `ProductoItem`):

| Producto | Descripción | Presentación | Gramaje | Precio normal | Precio promo |
|---|---|---|---|---|---|
| Café Premium | Anacafé 14, lavado | Grano / Molido | 350g | Q65 | Q55 |
| Café Clásico | Catuai, lavado | Grano / Molido | 350g | Q60 | Q50 |
| Café Campesino | Mezcla | Molido | 400g | Q35 | Q30 |
| Licor de Café | — | — | — | Q80 | — |

### 5.3 Solicitud
```dart
// lib/features/solicitudes/domain/solicitud_model.dart
class Solicitud {
  final String id;
  final String clienteId;        // Referencia a Cliente
  final String clienteNombre;    // Desnormalizado para mostrar sin query extra
  final CanalVenta canal;        // FORZA | VENTA_DIRECTA
  final List<ProductoItem> productos;
  final double total;            // Suma de los subtotales de productos
  final EstadoPedido estadoPedido;
  final EstadoPago estadoPago;
  final String? notas;
  final DateTime fechaCreacion;
  final String creadoPor;        // UID del usuario que creó la solicitud
}

class ProductoItem {
  final String productoId;          // Referencia a ProductoCatalogo
  final String nombre;              // Desnormalizado
  final Presentacion? presentacion; // null si el producto no aplica presentación
  final int cantidad;
  final bool esPromo;                // si se aplicó el precio promocional
  final double precioUnitario;       // precio aplicado (normal o promo) al momento de la venta
  final double subtotal;             // precioUnitario * cantidad
}
```

**Colección Firestore:** `solicitudes/{solicitudId}`

### 5.4 Enums
```dart
// lib/features/solicitudes/domain/enums.dart
enum CanalVenta { forza, ventaDirecta }

enum EstadoPedido { pendiente, enProceso, entregado }

enum EstadoPago { pendiente, transferenciaRecibida, verificado, pagado }

enum Presentacion { grano, molido }
```

---

## 6. Pantallas y Flujo de Navegación

```
/login
    │
    └──> /dashboard          ← pantalla principal tras login
              │
              ├──> /solicitudes           ← lista completa con filtros
              │         │
              │         └──> /solicitudes/:id    ← detalle y edición de estados
              │
              ├──> /solicitudes/nueva     ← crear nueva solicitud
              │
              └──> /clientes              ← lista de clientes
                        │
                        └──> /clientes/:id       ← detalle + historial de pedidos
```

### GoRouter — rutas definidas en `lib/core/router/app_router.dart`

| Ruta | Widget | Descripción |
|---|---|---|
| `/login` | `LoginScreen` | Acceso con email y contraseña |
| `/dashboard` | `DashboardScreen` | Resumen: contadores + lista reciente |
| `/solicitudes` | `SolicitudesListScreen` | Lista filtrable de solicitudes |
| `/solicitudes/nueva` | `NuevaSolicitudScreen` | Formulario de nueva solicitud |
| `/solicitudes/:id` | `SolicitudDetailScreen` | Detalle + cambio de estados |
| `/clientes` | `ClientesListScreen` | Lista de clientes guardados |
| `/clientes/:id` | `ClienteDetailScreen` | Datos del cliente + sus solicitudes |

**Regla de navegación:** Si el usuario no está autenticado, GoRouter redirige automáticamente a `/login`. Si está autenticado, redirige a `/dashboard`.

---

## 7. Pantallas: Especificación Detallada

### 7.1 LoginScreen (`/login`)
- Logo de Café Tío Meme centrado (imagen en `assets/images/logo.png`)
- Campo email + campo contraseña
- Botón "Ingresar" en color `caramel`
- Sin opción de registro (solo los 2 usuarios existentes pueden ingresar)
- En caso de error: mostrar mensaje debajo del formulario en color `danger`

### 7.2 DashboardScreen (`/dashboard`)
- **TopBar:** fondo `roast`, texto "Café Tío Meme" en `Playfair Display` color `latte`, avatar del usuario (iniciales)
- **Fila de estadísticas (3 tarjetas):**
  - Solicitudes activas (total del día)
  - Sin verificar pago (color `danger`)
  - Pagadas hoy (color `success`)
- **Chips de filtro rápido:** Todas · Directa · FORZA · Sin pago
- **Lista de solicitudes** ordenada por fecha descendente (las más recientes primero)
- **FAB** (botón flotante): "＋ Nueva Solicitud" en color `caramel`, ubicado abajo a la derecha
- Los datos se escuchan en **tiempo real** con `StreamProvider` de Riverpod + Firestore `snapshots()`

### 7.3 NuevaSolicitudScreen (`/solicitudes/nueva`)
**Este formulario tiene un orden estricto:**

1. **Selector de canal (OBLIGATORIO, primer campo):**
   - Dos botones grandes: "🤝 Venta Directa" y "📱 FORZA"
   - Ninguno seleccionado por defecto
   - No se puede avanzar sin seleccionar uno
   - El seleccionado se resalta con borde de color correspondiente

2. **Búsqueda/selección de cliente:**
   - Campo de búsqueda por nombre o teléfono
   - Resultados en dropdown de clientes existentes
   - Opción al final del dropdown: "＋ Crear nuevo cliente"
   - Si se crea nuevo: formulario inline (nombre, teléfono, dirección)

3. **Productos:**
   - Selector de producto del catálogo (dropdown o lista), mostrando nombre + descripción (ej. "Café Premium — Anacafé 14, lavado")
   - Campo de presentación (Grano / Molido) cuando el producto seleccionado aplique; se oculta para productos sin presentaciones (ej. Licor de Café)
   - Campo de cantidad
   - Toggle "Aplicar precio promo", deshabilitado si el producto no tiene precio promocional
   - Precio unitario y subtotal se calculan automáticamente según el producto, la presentación y si el toggle promo está activo
   - Botón "＋ Agregar otro producto"
   - Mínimo 1 producto requerido

4. **Estado del pago inicial:**
   - Selector: Pendiente · Transferencia Recibida
   - Por defecto: Pendiente

5. **Notas (opcional):**
   - Campo de texto libre

6. **Total de la solicitud:**
   - Suma de los subtotales de todos los productos agregados
   - Solo lectura, se recalcula automáticamente al agregar/quitar productos o cambiar cantidad/promo
   - Visible al final del formulario, antes del botón de guardar

7. **Botón "Guardar Solicitud"**
   - Valida que canal y al menos 1 producto estén completos
   - Muestra loading mientras guarda en Firestore
   - Al guardar exitosamente: navega de vuelta al dashboard

### 7.4 SolicitudDetailScreen (`/solicitudes/:id`)
- Muestra todos los datos de la solicitud en modo lectura
- **Badge de canal** siempre visible y destacado
- **Selector de estado del pedido** (dropdown o segmented button):
  - Pendiente → En Proceso → Entregado
- **Selector de estado del pago:**
  - Pendiente → Transferencia Recibida → Verificado → Pagado
- Al cambiar cualquier estado: actualiza Firestore inmediatamente
- Muestra nombre del cliente como link que navega a `/clientes/:id`
- Fecha y hora de creación, y quién la creó

### 7.5 ClientesListScreen (`/clientes`)
- Barra de búsqueda por nombre o teléfono
- Lista de clientes ordenada alfabéticamente
- Cada fila muestra: nombre, teléfono, cantidad de solicitudes anteriores

### 7.6 ClienteDetailScreen (`/clientes/:id`)
- Datos del cliente: nombre, teléfono, dirección
- Historial de solicitudes del cliente (listado con canal + estado + fecha)
- Botón para editar datos del cliente

---

## 8. Flujo de Autenticación

```
App inicia
    │
    ├── Firebase Auth escucha cambios de sesión (authStateChanges)
    │
    ├── Usuario NO autenticado → GoRouter redirige a /login
    │       │
    │       └── Ingresa email + contraseña → Firebase Auth signInWithEmailAndPassword
    │               │
    │               ├── Éxito → GoRouter redirige a /dashboard
    │               └── Error → Mostrar mensaje de error
    │
    └── Usuario autenticado → GoRouter redirige a /dashboard
            │
            └── Botón de cerrar sesión → Firebase Auth signOut → /login
```

**Importante:** Los dos usuarios se crean manualmente en Firebase Console. La app NO tiene pantalla de registro.

---

## 9. Reglas de Firestore (Security Rules)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Solo usuarios autenticados pueden leer/escribir
    match /clientes/{clienteId} {
      allow read, write: if request.auth != null;
    }

    match /solicitudes/{solicitudId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 10. Fases de Desarrollo

### Fase 1 — Base funcional ✅
**Objetivo:** poder crear y ver solicitudes en tiempo real entre los dos dispositivos.

- [ ] Configurar proyecto Flutter + Firebase (FlutterFire CLI)
- [ ] Implementar Firebase Auth (login / logout)
- [ ] Crear modelos `Cliente` y `Solicitud`
- [ ] Crear repositorios de Firestore (`ClientesRepository`, `SolicitudesRepository`)
- [ ] Implementar `LoginScreen`
- [ ] Implementar `DashboardScreen` básico (lista de solicitudes en tiempo real)
- [ ] Implementar `NuevaSolicitudScreen` con selector de canal obligatorio
- [ ] Configurar GoRouter con redirección por auth

### Fase 2 — Gestión de clientes ✅
**Objetivo:** los clientes quedan guardados y se reutilizan en solicitudes futuras.

- [ ] Implementar búsqueda de clientes al crear solicitud
- [ ] Implementar creación de cliente nuevo desde `NuevaSolicitudScreen`
- [ ] Implementar `ClientesListScreen`
- [ ] Implementar `ClienteDetailScreen` con historial de solicitudes

### Fase 3 — Gestión de estados ✅
**Objetivo:** poder actualizar el estado de cada pedido y pago.

- [ ] Implementar `SolicitudDetailScreen` con selectores de estado
- [ ] Actualizaciones de estado en tiempo real en Firestore
- [ ] Filtros en el dashboard (por canal, por estado de pago)
- [ ] Chips de filtro rápido en el listado

### Fase 4 — Pulido visual y UX ✅
**Objetivo:** la app se siente terminada y profesional.

- [ ] Aplicar design system completo (paleta, tipografía, badges)
- [ ] Estadísticas en el dashboard (contadores del día)
- [ ] Estados vacíos ("No hay solicitudes aún")
- [ ] Manejo de errores con mensajes claros al usuario
- [ ] Loading states en todas las operaciones async
- [ ] Probar en dispositivo físico Android

---

## 11. Convenciones de Código

- **Idioma del código:** inglés (nombres de variables, funciones, clases)
- **Idioma de la UI:** español (textos visibles al usuario)
- **Nomenclatura:**
  - Clases: `PascalCase`
  - Variables y funciones: `camelCase`
  - Archivos: `snake_case`
  - Constantes: `camelCase` dentro de clases `const`
- **Providers de Riverpod:** un archivo por feature en carpeta `providers/`
- **Commits (Conventional Commits):**
  - `feat:` nueva funcionalidad
  - `fix:` corrección de bug
  - `style:` cambios visuales sin lógica
  - `refactor:` refactoring sin cambiar comportamiento
  - `docs:` cambios en documentación

---

## 12. Archivos que NUNCA se suben a GitHub

Agregar al `.gitignore`:

```
# Firebase
google-services.json
GoogleService-Info.plist
lib/firebase_options.dart

# Flutter
.dart_tool/
build/
*.g.dart  # Generados por build_runner — sí se suben si son estables

# Android
local.properties
*.jks
*.keystore
```

---

## 13. Comandos Frecuentes

```bash
# Instalar dependencias
flutter pub get

# Generar código de Riverpod
dart run build_runner build --delete-conflicting-outputs

# Compilar APK debug para instalar en dispositivo
flutter build apk --debug
# El APK queda en: build/app/outputs/flutter-apk/app-debug.apk

# Compilar APK release
flutter build apk --release

# Instalar directo en dispositivo conectado por USB
flutter install

# Ver logs en tiempo real
flutter logs

# Limpiar build
flutter clean && flutter pub get
```

---

## 14. Notas Importantes

1. **Sincronización en tiempo real:** usar `StreamProvider` de Riverpod con `.snapshots()` de Firestore. Nunca usar `.get()` para datos que necesiten estar al día entre los dos dispositivos.

2. **El campo `canal` es obligatorio** en `NuevaSolicitudScreen`. El botón de guardar debe estar deshabilitado hasta que se seleccione un canal.

3. **Desnormalización de `clienteNombre`** en el modelo `Solicitud`: guardar el nombre del cliente directamente en la solicitud evita hacer un segundo query a Firestore cada vez que se muestra la lista.

4. **Paquete `uuid`** para generar IDs locales antes de enviar a Firestore, así se puede referenciar el documento inmediatamente sin esperar el ID de Firestore.

5. **No hay pantalla de registro.** Los dos usuarios se crean en Firebase Console → Authentication → Add user.
