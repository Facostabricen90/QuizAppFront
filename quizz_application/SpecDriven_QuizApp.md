# QuizApp — Spec-Driven Development Guide

> Documento de referencia para mantener alineado el desarrollo de QuizApp.
> Debe consultarse antes de agregar nuevas pantallas, componentes, rutas, lógica de negocio o integraciones.
>
> Última actualización: 6 de agosto de 2026.
> Hito actual: autenticación, persistencia de sesión, navegación declarativa y panel inicial del estudiante integrados.
> La recuperación de contraseña queda sin más cambios por ahora: está implementada en código, pero su configuración SMTP y validación operativa siguen pendientes.

---

## 1. Objetivo del producto

QuizApp es una aplicación educativa multiplataforma construida con Flutter para Web, Android e iOS.

La aplicación permitirá:

1. Inicio de sesión.
2. Registro exclusivo de estudiantes.
3. Inicio del estudiante con selección de materias.
4. Prácticas de preguntas.
5. Quizzes evaluativos.
6. Consulta de notas y promedios.
7. Dashboard compartido para profesores y administradores.
8. Gestión de profesores, preguntas, estudiantes y colegios según el rol.

La primera entrega debe priorizar funcionalidad, simplicidad, claridad, consistencia, rapidez de desarrollo y una buena base arquitectónica sin sobreingeniería.

---

## 2. Filosofía del MVP

### Prioridades

1. La funcionalidad correcta está por encima del refinamiento visual.
2. La interfaz debe ser sencilla, moderna y fácil de usar.
3. La consistencia es más importante que la sofisticación.
4. Solo se crean abstracciones cuando existe una necesidad real.
5. La arquitectura debe permitir crecer sin rehacer la aplicación.
6. Las mejoras visuales avanzadas se dejan para versiones futuras.

### Evitar en la primera entrega

- Animaciones complejas.
- Gradientes innecesarios.
- Ilustraciones personalizadas.
- Componentes excesivamente configurables.
- Microinteracciones costosas.
- Dark mode sin una necesidad real.
- Clean Architecture estricta aplicada de forma ceremonial.
- Carpetas o clases creadas únicamente “por si acaso”.

### Regla de oro

> Antes de agregar algo, preguntar si mejora la experiencia o únicamente hace que se vea más bonito.

---

## 3. Identidad visual

La aplicación debe conservar el ambiente visual de la landing page oficial de QuizApp.

### Personalidad

- Profesional.
- Institucional.
- Educativa.
- Moderna.
- Sobria.
- Clara.
- Con bastante espacio visual.
- No debe parecer una aplicación excesivamente gamificada.

### Paleta principal

```text
Primary Green:      #245B43
Secondary Green:    #3F7B5B
Accent Lime:        #D8E58A
Background:         #F7F9F4
Surface:            #FFFFFF
Surface Secondary:  #E8F0E8
Text Primary:       #14221B
Text Secondary:     #405247
Warning:            #C99446
Info:               #DCE9EE
```

### Tipografía

- `Newsreader`: títulos principales.
- `DM Sans`: textos, formularios, navegación, botones y contenido general.

### Estilo visual

- Tarjetas con radio aproximado de 22 px.
- Inputs con radio aproximado de 12 a 16 px.
- Botones principales tipo píldora.
- Sombras suaves.
- Bordes discretos.
- Mucho espacio en blanco.
- Jerarquía visual clara.
- Efectos hover y focus mínimos.

---

## 4. Arquitectura general

Se utilizará:

```text
Feature-First + arquitectura por capas
```

Patrones principales:

- MVVM para presentación.
- Repository Pattern.
- Service Pattern.
- Dependency Injection.
- Result Pattern.
- Estados cerrados mediante clases `sealed`.
- `go_router` para navegación declarativa.
- Riverpod cuando se incorpore estado global o lógica real.

Flujo previsto:

```text
View
  ↓
ViewModel / Notifier
  ↓
Repository
  ↓
Service / API / almacenamiento
```

No se implementará toda la arquitectura desde el primer día. La autenticación ya incorpora las abstracciones necesarias para backend real: `AuthRepository`, `ApiClient`, almacenamiento seguro y un controlador basado temporalmente en `ChangeNotifier`. La composición de dependencias se realiza manualmente desde `main.dart`; Riverpod y casos de uso independientes quedan para una etapa posterior.

---

## 5. Organización por funcionalidades

La aplicación se organiza así:

```text
lib/
├── app/
├── core/
├── features/
├── shared/
├── shells/
└── main.dart
```

Estructura implementada para autenticación y elementos transversales:

```text
lib/
├── app/
│   ├── app.dart
│   └── theme/
├── core/
│   ├── auth/
│   │   ├── auth_controller.dart
│   │   ├── auth_models.dart
│   │   └── auth_repository.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   └── api_exception.dart
│   └── security/
│       └── token_storage.dart
├── features/
│   └── authentication/
│       └── presentation/
│           ├── pages/
│           └── widgets/
├── shared/
│   └── presentation/
│       └── widgets/
└── main.dart
```

Estructura futura aproximada:

```text
features/
├── authentication/
├── subjects/
├── questions/
├── teachers/
├── students/
├── schools/
├── practice/
├── quiz/
└── results/
```

### Regla

Las páginas de negocio no deben colocarse dentro de `shared`.

`shared` solo contiene componentes genéricos y reutilizables.

---

## 6. Roles y permisos funcionales

### Administrador

Puede:

- Ver colegios registrados y sus códigos.
- Crear, consultar, editar y desactivar profesores.
- Consultar estudiantes registrados.
- Consultar notas y promedios de estudiantes.

No administra materias ni preguntas.

### Profesor

Puede:

- Consultar la lista de materias.
- Crear preguntas asociadas a una materia.
- Consultar, editar y eliminar preguntas según las reglas futuras.
- Consultar estudiantes.
- Consultar notas y promedios.

No puede crear materias, administrar colegios, administrar profesores ni administrar usuarios estudiantes.

### Estudiante

Puede:

- Registrarse desde la aplicación.
- Iniciar sesión.
- Consultar materias.
- Seleccionar una materia.
- Realizar prácticas.
- Realizar quizzes evaluativos.
- Consultar notas y promedios.

### Desarrollo

Responsable de:

- Crear y mantener materias directamente en la base de datos.
- Preparar cuentas administrativas iniciales según el proceso definido.
- Mantener datos maestros que no se administran desde Flutter.

---

## 7. Materias

Las materias son datos maestros del sistema.

Reglas:

- Se crean directamente en la base de datos.
- No existe CRUD de materias en Flutter.
- Profesores y estudiantes únicamente consultan materias.
- Al crear una pregunta, el profesor debe seleccionar una materia existente.
- Flutter deberá enviar `subjectId`, no el nombre libre de la materia.
- El backend deberá verificar que la materia exista y esté activa.

Uso compartido:

```text
Profesor
└── Selector de materia al crear o editar una pregunta

Estudiante
└── Lista de materias para seleccionar una ruta de práctica o quiz
```

---

## 8. Shells de navegación

### Management Shell

Compartido por administrador y profesor.

Debe reutilizar:

- Sidebar.
- Encabezado.
- Navegación.
- Contenedor principal.
- Breadcrumbs si aparecen.

El contenido visible cambia según permisos, pero no se duplicará el dashboard completo.

### Student Shell

Experiencia independiente para estudiantes.

En móvil podrá utilizar bottom navigation o drawer. En web o escritorio podrá utilizar sidebar y navegación adaptativa.

Estado actual:

- Panel inicial implementado en `/student`.
- Navegación inferior en móvil/tablet y `NavigationRail` en Web ancho.
- Destinos compartidos: Inicio, Materias, Progreso y Perfil.
- Inicio es la única sección funcional; las demás muestran un estado temporal.
- Resumen visual de racha, experiencia y nivel con valores iniciales no persistidos.
- Reto diario y materias preparados visualmente, todavía sin datos reales del backend.
- Diseño responsive mediante `LayoutBuilder`, tokens estructurales y grids calculados según el espacio disponible.

---

## 9. Responsive y multiplataforma

La misma base Flutter debe funcionar correctamente en Android, iOS, Web, tablet y escritorio.

### Móvil

- Formularios a una columna.
- Márgenes cómodos.
- Scroll correcto con teclado virtual.
- Controles táctiles con tamaño suficiente.
- Navegación compacta.

### Tablet

- Más espacio horizontal.
- NavigationRail cuando tenga sentido.
- Posibles diseños en dos columnas.

### Web y escritorio

- Sidebar persistente para dashboards.
- Tablas amplias.
- Hover y focus.
- Navegación mediante URL.
- Compatibilidad con atrás y adelante del navegador.
- Navegación por teclado.

### Regla

No utilizar anchos rígidos sin restricciones. Preferir `ConstrainedBox` con `maxWidth`.

Los breakpoints y límites estructurales pertenecen a `AppLayout`. Las dimensiones internas deben usar `AppSpacing` y `AppRadius`; las columnas se calculan según el espacio disponible.

---

## 10. Seguridad desde el frontend

Estado implementado:

- Las contraseñas nunca se almacenan en el cliente.
- Los tokens se persisten mediante `flutter_secure_storage`.
- El access token se envía como Bearer token.
- Ante un `401`, el cliente intenta renovar la sesión y repite una sola vez la petición original.
- El refresh token es rotado por el backend y puede revocarse durante el cierre de sesión.
- La URL base se configura con `--dart-define=API_BASE_URL=...`.
- No se incluyen secretos, claves privadas, `JWT_SECRET` ni credenciales SMTP en Flutter.
- No se registran tokens ni información sensible.
- Ocultar una pantalla no constituye autorización real.
- El backend valida roles y permisos en cada endpoint sensible.
- La aplicación muestra mensajes de error seguros y comprensibles.
- Las respuestas correctas de quizzes no deben enviarse anticipadamente cuando eso comprometa la evaluación.

Pendiente: evaluar una estrategia específica de sesión para Flutter Web, como cookies `HttpOnly`, si la arquitectura de despliegue futura lo permite.

---

## 11. Sistema visual implementado

Ubicación:

```text
lib/app/theme/
```

Archivos creados:

```text
app_colors.dart
app_theme.dart
app_spacing.dart
app_radius.dart
app_layout.dart
app_typography.dart
```

Componentes compartidos creados:

```text
lib/shared/presentation/widgets/
├── app_button.dart
├── app_card.dart
├── app_gap.dart
├── app_logo.dart
├── app_password_field.dart
└── app_text_field.dart
```

### Convenciones

- Todo componente del sistema visual usa el prefijo `App`.
- No repetir estilos directamente en las pantallas.
- Preferir `AppButton` sobre `ElevatedButton`.
- Preferir `AppTextField` sobre `TextFormField` cuando aplique.
- Preferir `AppCard` sobre `Card`.
- Preferir `AppGap` sobre `SizedBox` para separaciones estándar.
- Evitar números mágicos.

### Regla práctica

> Las Pages organizan; los Widgets construyen.

---

## 12. Autenticación implementada

Estructura actual:

```text
features/
└── authentication/
    └── presentation/
        ├── pages/
        │   ├── login_page.dart
        │   ├── register_page.dart
        │   ├── forgot_password_page.dart
        │   ├── reset_password_page.dart
        │   └── welcome_page.dart
        └── widgets/
            ├── login_form.dart
            ├── login_header.dart
            ├── register_form.dart
            ├── register_header.dart
            ├── forgot_password_form.dart
            └── reset_password_form.dart
```

### Login

Incluye correo electrónico, contraseña, mostrar y ocultar contraseña, acceso a recuperación, navegación al registro, consumo del backend y manejo de estados de carga y error. Cuando la autenticación termina correctamente se limpia el stack de acceso y se muestra la bienvenida autenticada.

### Registro

Solo para estudiantes. Incluye nombres, apellidos, correo electrónico, contraseña, confirmación, aceptación de términos y validaciones locales. El código de colegio fue retirado porque el contrato público actual del backend no lo recibe. El rol público lo determina el backend y no puede seleccionarse desde Flutter.

El registro consume el API y conserva la sesión entregada por el backend, por lo que un registro exitoso entra directamente a la bienvenida temporal.

### Sesión

Flujo implementado:

1. El usuario inicia sesión o se registra.
2. El backend devuelve access token, refresh token y los datos básicos del usuario.
3. Los tokens se guardan mediante `flutter_secure_storage`.
4. Al iniciar la aplicación, `AuthController.restoreSession()` intenta recuperar y validar la sesión.
5. Las peticiones autenticadas incluyen el access token.
6. Si expira, `ApiClient` intenta renovarlo, actualiza los tokens y reintenta una sola vez.
7. Al cerrar sesión se intenta revocar el refresh token y siempre se elimina la sesión local.

### Recuperación de contraseña

El flujo queda implementado y sin más cambios por ahora:

- `forgot_password_page.dart` solicita únicamente el correo.
- `POST /api/auth/forgot-password` inicia la solicitud sin revelar si la cuenta existe.
- El correo genera un enlace hacia `/reset-password?email=...&token=...`.
- `reset_password_page.dart` obtiene correo y token del enlace, muestra la cuenta objetivo y solicita la contraseña nueva.
- `POST /api/auth/reset-password` envía correo, token y contraseña nueva.

El backend aún requiere valores reales para `Email:Username`, `Email:Password` y `Email:FromEmail`, preferiblemente mediante .NET User Secrets durante el desarrollo. El código está integrado, pero el envío real sigue pendiente de configuración y validación.

### Endpoints consumidos

```text
POST /api/auth/register
POST /api/auth/login
GET  /api/auth/me
POST /api/auth/refresh
POST /api/auth/revoke
POST /api/auth/forgot-password
POST /api/auth/reset-password
```

### Estado actual

- UI conectada al backend.
- Responsive probado en resoluciones web.
- Validaciones locales y manejo de errores del API.
- Persistencia, restauración y renovación de sesión.
- Pantalla temporal de bienvenida autenticada.
- Navegación temporal mediante `MaterialApp`, `Navigator` y `onGenerateRoute`.
- `go_router` integrado; Riverpod todavía no está incorporado.

---

## 13. Navegación con go_router

La navegación declarativa está integrada y centralizada.

### Dependencia

```bash
flutter pub add go_router
```

### Estructura

```text
lib/app/router/
├── app_routes.dart
└── app_router.dart
```

### Rutas iniciales

```text
/login
/register
/forgot-password
/reset-password?email={email}&token={token}
/welcome
/student
```

### Comportamiento implementado

1. `AppRoutes` centraliza nombres y paths.
2. `AppRouter` centraliza la construcción de `GoRouter`.
3. `QuizApp` utiliza `MaterialApp.router` y administra el ciclo de vida del router.
4. `AuthController` notifica cambios de sesión mediante `refreshListenable`.
5. Los usuarios no autenticados son enviados a `/login` al intentar abrir `/welcome`.
6. Los usuarios autenticados son enviados a `/welcome` al abrir `/login` o `/register`.
7. `/forgot-password` y `/reset-password` permanecen accesibles como rutas de recuperación.
8. Correo y token se leen desde los query parameters del enlace de restablecimiento.
9. El estado `initializing` conserva los enlaces públicos directos y utiliza `/` como splash para rutas protegidas.
10. Los formularios usan `goNamed` o `pushNamed`; ya no crean `MaterialPageRoute` directamente.
11. Los usuarios con rol `Student` son dirigidos a `/student`.
12. Los roles `Teacher` y `Admin` permanecen en `/welcome` y no pueden abrir `/student`.

### Rutas futuras previstas

```text
/login
/register
/forgot-password
/reset-password
/welcome

/student
/student/subjects
/student/practice/:subjectId
/student/quiz/:quizId
/student/results/:attemptId

/management
/management/students
/management/questions
/management/teachers
/management/schools
```

Pendiente para el crecimiento funcional: agregar rutas por rol para `StudentShell` y `ManagementShell`, además de validar navegación móvil y comportamiento de hosting ante recargas directas.

---

## 14. Componentes profesionales

No deben construirse todos de forma anticipada.

Componentes previstos:

```text
AppScaffold
AppPageHeader
AppSection
AppEmptyState
AppLoader
AppDataTable
AppSearchField
AppStatusBadge
AppDialog
AppSnackbar
AppPagination
```

### Regla

Crear un componente nuevo solo cuando exista una necesidad real, se reutilice o centralizarlo mejore la consistencia sin aumentar demasiado la complejidad.

---

## 15. Próximos pasos aprobados

### Fase 1 — Navegación

- [x] Instalar `go_router`.
- [x] Crear `app_routes.dart`.
- [x] Crear `app_router.dart`.
- [x] Migrar `QuizApp` a `MaterialApp.router`.
- [x] Migrar Login, Registro, Recuperación, Restablecimiento y Bienvenida.
- [x] Agregar redirecciones declarativas por estado de autenticación.
- [x] Probar navegación y compilación web.
- [ ] Probar navegación en dispositivos Android e iOS.

### Fase 2 — Completar autenticación visual

- [x] Crear recuperación de contraseña.
- [x] Crear restablecimiento de contraseña.
- [x] Consumir endpoints de recuperación.
- [ ] Configurar credenciales SMTP fuera del repositorio.
- [ ] Validar el envío y el enlace real por ambiente.
- [ ] Probar teclado virtual real.
- [ ] Verificar scroll al enfocar inputs.
- [ ] Verificar autofill.
- [ ] Mejorar mensajes de validación si es necesario.
- [ ] Definir enlaces reales de términos y tratamiento de datos.
- [ ] Revisar accesibilidad básica.

### Fase 3 — Inicio del estudiante

- [x] Crear estructura visual inicial del `StudentShell`.
- [x] Crear página inicial del estudiante.
- [x] Crear listado visual temporal de materias ICFES.
- [x] Crear tarjetas responsive de materias.
- [x] Agregar navegación inferior para móvil/tablet y lateral para Web ancho.
- [x] Separar el panel en widgets reutilizables por responsabilidad.
- [ ] Consumir materias reales desde el backend.
- [ ] Preparar navegación funcional a práctica y quiz.
- [ ] Consumir racha, experiencia, nivel y reto diario desde el backend.

### Fase 4 — Sesión de preguntas

- [ ] Definir entidad visual de pregunta.
- [ ] Crear estado de sesión.
- [ ] Mostrar pregunta actual.
- [ ] Permitir seleccionar respuesta.
- [ ] Navegar entre preguntas.
- [ ] Mostrar progreso.
- [ ] Preparar temporizador si el producto lo requiere.
- [ ] Diferenciar práctica y quiz real.
- [ ] No incluir respuesta correcta en datos expuestos al cliente cuando comprometa la evaluación.

### Fase 5 — Management Shell

- [ ] Crear shell compartido para profesor y administrador.
- [ ] Sidebar responsive.
- [ ] Encabezado.
- [ ] Navegación por permisos.
- [ ] Diseño web, tablet y móvil.
- [ ] No duplicar layouts por rol.

### Fase 6 — Profesor

- [ ] Lista de preguntas.
- [ ] Crear pregunta.
- [ ] Seleccionar materia.
- [ ] Editar pregunta.
- [ ] Eliminar o desactivar pregunta.
- [ ] Lista de estudiantes.
- [ ] Consulta de notas y promedios.

### Fase 7 — Administrador

- [ ] Lista de colegios y códigos.
- [ ] CRUD de profesores.
- [ ] Lista de estudiantes.
- [ ] Consulta de notas y promedios.
- [ ] Reutilizar la misma funcionalidad de estudiantes usada por profesores.

### Fase 8 — Integración de backend

- [x] Configurar URL base mediante `API_BASE_URL`.
- [ ] Formalizar configuraciones por ambiente.
- [x] Configurar cliente HTTP.
- [x] Crear repositorio de autenticación.
- [ ] Incorporar Riverpod.
- [x] Crear controlador temporal con `ChangeNotifier`.
- [x] Manejar loading, success y failure en autenticación.
- [x] Integrar almacenamiento seguro.
- [x] Implementar sesión y renovación de tokens.
- [x] Agregar guards y redirecciones iniciales de autenticación.
- [x] Validar roles y permisos desde el backend.

---

## 16. Reglas de implementación

### Código

- Usar nombres descriptivos.
- Evitar archivos excesivamente largos.
- Extraer widgets cuando una vista crezca demasiado.
- Evitar funciones genéricas tipo `Utils`.
- Evitar un único `ApiService` gigantesco.
- Evitar un único estado global para toda la aplicación.
- Evitar singletons manuales.
- Evitar lógica de negocio dentro de widgets.
- Mantener imports organizados.
- Ejecutar análisis estático con frecuencia.

### UI

- No repetir colores directamente.
- No repetir radios directamente.
- No repetir tipografías directamente.
- No usar `SizedBox` arbitrarios si existe un `AppGap`.
- Mantener formularios con ancho máximo.
- Usar `Wrap` cuando un `Row` pueda desbordarse.
- Garantizar scroll en formularios largos.
- Añadir `SafeArea` cuando corresponda.
- Tener en cuenta teclado, mouse y navegación por teclado.

### Navegación

- No utilizar `MaterialPageRoute` después de integrar `go_router`.
- Las rutas deben centralizarse.
- No codificar strings de rutas dispersos.
- Preparar rutas para web desde el inicio.

### Seguridad

- No confiar en el rol mostrado por Flutter.
- No almacenar secretos.
- No exponer información sensible en logs.
- No usar variables de frontend como mecanismo de autorización.
- Validar todas las acciones sensibles en backend.

---

## 17. Decisiones aún pendientes

- Reglas exactas de contraseña.
- Flujo de verificación de correo.
- Configuración SMTP segura por ambiente.
- URL pública definitiva para los enlaces de recuperación.
- Estrategia de almacenamiento de sesión específica para Flutter Web.
- Migración futura del controlador de autenticación a Riverpod.
- Política de eliminación o desactivación de preguntas.
- Relación exacta entre profesor, colegio y estudiantes.
- Si un profesor ve todos los estudiantes o solo estudiantes asociados.
- Tipos de pregunta soportados.
- Número de opciones por pregunta.
- Dificultad.
- Temporizador.
- Cálculo de notas.
- Reintentos.
- Banco aleatorio de preguntas.
- Publicación o aprobación de preguntas.
- Tratamiento legal de datos de menores.
- Términos y política de privacidad.
- Internacionalización.
- Analítica y monitoreo.

No asumir estas reglas sin confirmación.

Decisiones ya tomadas en la implementación actual:

- Cliente HTTP: paquete `http`.
- Almacenamiento de tokens: `flutter_secure_storage`.
- Renovación de sesión: access token y refresh token rotativo administrados por el backend.
- Estado temporal de autenticación: `ChangeNotifier` con composición manual de dependencias.

---

## 18. Criterio para no perder el contexto

Antes de implementar cualquier cambio, verificar:

1. ¿Pertenece al MVP?
2. ¿Respeta los roles definidos?
3. ¿Reutiliza los componentes existentes?
4. ¿Funciona en web, Android e iOS?
5. ¿Mantiene la identidad visual de QuizApp?
6. ¿Evita duplicación entre profesor y administrador?
7. ¿Añade valor real ahora?
8. ¿Está preparado para integrar backend después?
9. ¿Evita exponer o almacenar datos sensibles?
10. ¿Es la solución más sencilla que cumple el objetivo?

Si una propuesta contradice este documento, debe revisarse antes de implementarse.

---

## 19. Estado actual del proyecto

### Completado

- [x] Dirección arquitectónica.
- [x] Definición funcional de roles.
- [x] Definición de materias como datos maestros.
- [x] Base visual.
- [x] Theme.
- [x] Design tokens.
- [x] Componentes base.
- [x] Login responsive.
- [x] Registro de estudiante.
- [x] Validaciones visuales iniciales.
- [x] Navegación temporal entre login y registro.
- [x] Integración de registro y login con backend.
- [x] Almacenamiento seguro de tokens.
- [x] Restauración y renovación automática de sesión.
- [x] Cierre de sesión con limpieza local.
- [x] Pantalla temporal de bienvenida autenticada.
- [x] Recuperación y restablecimiento de contraseña integrados en código.
- [x] Corrección de inicialización de `AppGap` durante hot reload.
- [x] Pruebas de widgets y repositorio de recuperación.
- [x] Compilación Flutter Web validada.
- [x] Navegación centralizada con `go_router`.
- [x] Rutas nombradas para login, registro, recuperación, restablecimiento y bienvenida.
- [x] Redirecciones reactivas por estado de autenticación.
- [x] Protección de la ruta temporal `/welcome`.
- [x] Análisis estático sin observaciones.
- [x] Doce pruebas automatizadas aprobadas.
- [x] Panel inicial responsive para estudiantes.
- [x] Redirección autenticada según rol entre `/student` y `/welcome`.
- [x] Tarjetas visuales de métricas, reto diario y materias.
- [x] Navegación adaptativa inicial del estudiante.

### Pendiente operativo

- [ ] Configurar credenciales SMTP mediante User Secrets o variables de entorno.
- [ ] Validar el envío real del correo de recuperación.
- [ ] Probar navegación en Android e iOS.
- [ ] Configurar el hosting web para admitir recargas directas de rutas si se elimina el hash routing.
- [ ] Obtener nombres del usuario desde `/api/auth/me`; actualmente el panel muestra el rol y correo.
- [ ] Reemplazar métricas y materias temporales por información del backend.

### Siguiente tarea

> Conectar el panel del estudiante con materias reales y definir el primer flujo de práctica, manteniendo la bienvenida temporal para profesores y administradores.

---

## 20. Principio final

> Construir una base sólida, no un castillo.

QuizApp debe avanzar con disciplina y pragmatismo. La meta de la primera entrega no es demostrar cuántas capas o componentes podemos crear, sino entregar una experiencia funcional, clara y mantenible que pueda evolucionar con la startup.
