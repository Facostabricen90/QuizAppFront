# QuizApp

Aplicación Flutter para autenticación y recuperación de contraseña.

## Configuración del backend

La URL del backend no está fija para los distintos entornos. Se inyecta en
tiempo de compilación mediante `API_BASE_URL`.

Para desarrollo local:

```bash
flutter run --dart-define=API_BASE_URL=https://localhost:7126
```

Para probar en Flutter Web los enlaces enviados por correo para confirmar la
cuenta o restablecer la contraseña, ejecuta el front en el puerto configurado
por la API:

```bash
flutter run -d chrome --web-port=4200 --dart-define=API_BASE_URL=https://localhost:7126
```

La navegación web usa rutas limpias (`/confirm-email` y `/reset-password`) para
que los enlaces del correo abran directamente la pantalla correspondiente.

Para usar un archivo local de configuración, copia
`config/env.example.json` como `config/env.json`, cambia únicamente la URL
del entorno correspondiente y ejecuta:

```bash
flutter run --dart-define-from-file=config/env.json
flutter build apk --release --dart-define-from-file=config/env.json
```

`config/env.json` está excluido por `.gitignore`. No incluyas en el cliente
credenciales, claves privadas, secretos, tokens persistentes ni cadenas de
conexión. Todo valor compilado en una aplicación Flutter puede ser extraído;
la autenticación y los secretos deben permanecer en el backend.

## Desarrollo

```bash
flutter pub get
flutter analyze
flutter test
```

Los archivos generados, rutas locales, configuraciones de IDE y material de
firma están excluidos del repositorio. `pubspec.lock` se conserva porque esta
es una aplicación Flutter y permite reproducir las versiones de dependencias.
