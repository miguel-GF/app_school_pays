# Instrucciones para agentes

## Proyectos y límites

- Este directorio es la app Flutter móvil `app_escolar` (Dart), con flavors Android `norte` y `valle`.
- El backend que trabaja con esta app está en `C:\laragon\www\school-control`: Laravel 10/PHP, API móvil y estrategia de pagos Stripe.
- Ambos consumen la base MySQL local `escolarprueba`; no asumas que datos de la app se simulan en Flutter cuando se use `HttpSchoolApi`.
- `pagos/mobile` es un proyecto Expo separado y tiene su propio repositorio e instrucciones. No cambies ese subproyecto al trabajar en la app Flutter.
- Mantén llaves secretas Stripe, tokens, `.env` y datos de tarjeta fuera del código, commits, mensajes, capturas y video.

## Pagos y seguridad

- El gateway se selecciona en el API (`PAYMENT_GATEWAY`), nunca desde un selector del alumno. Flutter solo implementa el cliente/estrategia de pago.
- El importe de la demo lo define el API: `DEMO_PAYMENT_AMOUNT_CENTS=1000` y `PAYMENT_CURRENCY=mxn` ($10 MXN). No confíes en un importe enviado por el cliente.
- Para pruebas usa solo llaves Stripe `sk_test`/`pk_test` y tarjetas de prueba oficiales. Cada checkout confirmado crea un PaymentIntent y una fila nueva; advierte antes de crear cargos adicionales o borrar tarjetas/pagos de prueba.
- No registres PAN/CVC. Las tarjetas se ingresan en Stripe PaymentSheet; School Control conserva identificadores y metadatos.
- El API local configura `STRIPE_API_VERSION=2026-10-28.endive`; no lo cambies sin verificar compatibilidad de SetupIntent/PaymentIntent.
- La base local tiene estado demo persistente. No reinicies ni migres destructivamente sin revisar antes las migraciones y los datos existentes.

## Entorno local de prueba

- Versión Flutter fijada: **3.47.0** (`.fvmrc`). Usa `fvm flutter`, no una versión global distinta.
- API: `cd C:\laragon\www\school-control`; inicia Laragon/MySQL y usa `php artisan serve --host=0.0.0.0 --port=8000`.
- En emulador Android, apunta Norte a `http://10.0.2.2:8000`; en equipo host, la API responde en `http://127.0.0.1:8000`.
- Emulador de prueba observado: `emulator-5554`. Antes de crear otra VM, revisa `adb devices -l` y reutiliza la ya activa; evita arrancar emuladores duplicados.
- Para la app: `fvm flutter pub get`, `fvm flutter analyze`, `fvm flutter test` y, si aplica, `fvm flutter build apk --debug --flavor norte --dart-define=NORTE_API_URL=http://10.0.2.2:8000`.
- El Vite de School Control (`npm run dev`) sirve assets del portal web; no es el API ni hace falta para ejecutar la app Android.
- La grabación validada está en `demo-video/stripe-android-demo.mp4`. `screenrecord` limita cada segmento a 180 segundos; FFmpeg se usó para concatenar segmentos H.264 sin recodificarlos.

## Cambios y validación

- Mantén cambios acotados al proyecto pedido y sigue sus patrones. Para cambios de API, valida también la integración con `school-control`.
- Si modificas pagos, revisa el flujo completo: login → SetupIntent/guardar tarjeta → PaymentIntent → confirmación servidor → historial/recibo.
- Prefiere pruebas automatizadas locales; evita enviar pagos Stripe de prueba innecesarios, porque modifican el estado del dashboard y la base.
- Los APK de debug usan firma de depuración y no son artefactos de producción.
