# App escolar de pagos

Aplicación Flutter para Android con acceso de alumnos y pagos de prueba por Stripe. La escuela/flavor decide qué API consume la app; las llaves privadas y la selección de pasarela viven en el backend, no en Flutter.

## Proyectos relacionados

| Proyecto | Ruta local | Responsabilidad |
| --- | --- | --- |
| App móvil Flutter | `C:\laragon\www\app_escolar` | Login, tarjetas guardadas, checkout Stripe y recibo. |
| School Control | `C:\laragon\www\school-control` | API Laravel, autenticación contra `alumnos`, integración Stripe y persistencia de pagos. |
| Base de prueba | MySQL `escolarprueba` en `127.0.0.1:3306` | Alumnos y tablas de pagos del entorno local. |

`pagos/mobile` contiene otro proyecto Expo independiente; no participa en esta demo Flutter. No mezclar sus instrucciones, dependencias ni builds con esta app.

## Requisitos

- Flutter **3.47.0** con FVM (versión fijada en `.fvmrc`), Android SDK/ADB y un emulador o dispositivo Android.
- PHP/Composer y MySQL de Laragon; dependencias instaladas en `school-control`.
- Credenciales **de prueba** de Stripe configuradas únicamente en `school-control/.env`.

No copies llaves `sk_...`, secretos webhook ni valores de `.env` a este repo, a Flutter, a un APK, a `--dart-define` ni a capturas de pantalla.

## Levantar el entorno local

1. Inicia MySQL desde Laragon y confirma que existe la base `escolarprueba`.
2. En una terminal, prepara/valida el backend:

   ```powershell
   cd C:\laragon\www\school-control
   composer install
   php artisan migrate
   php artisan route:list --path=v1/mobile
   php artisan serve --host=0.0.0.0 --port=8000
   ```

   `composer install` y `php artisan migrate` se ejecutan cuando el entorno lo requiera. El `.env` local debe apuntar a `DB_DATABASE=escolarprueba`, `DB_HOST=127.0.0.1`, `DB_PORT=3306`, `PAYMENT_GATEWAY=stripe`, `PAYMENT_CURRENCY=mxn` y `DEMO_PAYMENT_AMOUNT_CENTS=1000`. Configura las llaves de test de Stripe en ese archivo privado; no las incluyas en comandos ni documentación.

3. El servidor web/Vite de School Control es opcional para la app móvil: solo hace falta si también se quiere abrir el portal web. Para sus assets, usa otra terminal en `school-control` y ejecuta `npm install` (si hace falta) y `npm run dev`. La app Flutter consume el API de Laravel directamente; no necesita Vite.
4. Confirma que ADB detecta el emulador antes de usarlo. Si ya está iniciado, reutilízalo; no abras otro por duplicado:

   ```powershell
   adb devices -l
   ```

5. Desde la raíz de este proyecto, instala dependencias y ejecuta el flavor Norte:

   ```powershell
   cd C:\laragon\www\app_escolar
   fvm install 3.47.0
   fvm flutter pub get
   fvm flutter run --flavor norte --dart-define=NORTE_API_URL=http://10.0.2.2:8000
   ```

   `10.0.2.2` permite que el emulador Android llegue al puerto `8000` del host. En un teléfono físico usa una dirección IP LAN del equipo y permite ese puerto en el firewall; no uses `10.0.2.2` desde el teléfono.

Para construir el APK Norte de depuración:

```powershell
fvm flutter build apk --debug --flavor norte --dart-define=NORTE_API_URL=http://10.0.2.2:8000
```

El artefacto queda en `build/app/outputs/flutter-apk/app-norte-debug.apk`. Para Valle cambia el flavor y define `VALLE_API_URL` con la URL de la API de esa escuela.

## Flujo de pagos

- El login `POST /api/v1/mobile/auth/login` autentica la matrícula en School Control y entrega un token Sanctum.
- La app obtiene el importe y la configuración de pasarela de `GET /api/v1/mobile/payment-config`.
- La app usa un layout de pago propio con `CardField` de Stripe (sin PaymentSheet ni "Pay with Link"): el alumno elige una tarjeta guardada o captura una nueva en la misma pantalla. El PAN y CVC se capturan en el componente nativo de Stripe; el API conserva referencias y metadatos, no el número/CVC.
- Para guardar una tarjeta se confirma un SetupIntent; para cobrar, el API crea el PaymentIntent con monto del servidor (en esta demo, `1000` centavos MXN) y la app lo confirma con `confirmPayment`, usando la tarjeta seleccionada o el `CardField`. Después consulta la confirmación al backend.
- Las rutas protegidas incluyen `GET/POST /api/v1/mobile/payments`, `GET /api/v1/mobile/payment-methods`, `POST /api/v1/mobile/payment-methods/setup-intent` y `DELETE /api/v1/mobile/payment-methods/{paymentMethodId}`. El webhook Stripe es `POST /api/v1/mobile/payments/stripe/webhook`.
- Persistencia local: `payment_customers`, `payments` y `payment_attempts`. El historial de la app refleja solo pagos confirmados.

El backend local usa Stripe API `2026-10-28.endive`. Para otra escuela, configura la pasarela y sus credenciales privadas en el servidor de esa escuela; no permitas que el alumno elija el gateway.

## Datos seguros de prueba

- Matrícula demo: `999999`; contraseña demo: `123456`.
- Tarjeta de prueba Stripe: `4242 4242 4242 4242`, vencimiento `12/30`, CVC `123`, ZIP `94107`.
- El pago demo es de **$10.00 MXN**. Las llaves `sk_test` no mueven dinero real; no cambies a `sk_live` para esta demo.
- Cada repetición del checkout crea otro PaymentIntent y, si se confirma, otro registro pagado de prueba. No borres pagos ni tarjetas del entorno salvo que se busque reiniciar expresamente esos datos.

Al terminar la grabación de este demo, la base muestra una tarjeta Visa terminación `4242` y dos pagos `paid` de `1000` centavos MXN cada uno (total de prueba: $20.00). Es estado del entorno al **13 de noviembre de 2026**; no es un requisito fijo del código.

## Video demo

El video verificado está en `demo/video/stripe-android-demo.mp4` (Android vertical, 1080 × 2400). Muestra login, alta de Visa de prueba, checkout Stripe de $10, comprobante e historial. Se grabó en el emulador existente `emulator-5554`, sin iniciar una segunda máquina virtual; API y MySQL corrieron localmente.

ADB `screenrecord` limita cada segmento a 180 segundos. Para repetir una grabación larga, registra segmentos y cópialos con `adb pull`. Si se necesita unirlos, FFmpeg puede concatenar segmentos H.264 compatibles sin recodificar:

```text
file 'part-1.mp4'
file 'part-2.mp4'
```

```powershell
ffmpeg -f concat -safe 0 -i segments.txt -map 0:v:0 -c:v copy -an -movflags +faststart demo.mp4
ffprobe -v error -show_entries format=duration,size -show_entries stream=codec_name,width,height -of default=noprint_wrappers=1 demo.mp4
```

Antes de compartir capturas, verifica que no contengan llaves, información personal ni datos de pago distintos de la tarjeta de prueba.

## Validación

```powershell
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug --flavor norte --dart-define=NORTE_API_URL=http://10.0.2.2:8000
```

En School Control, valida cambios del API con `php artisan test` y `php artisan route:list --path=v1/mobile`. No ejecutes pruebas que creen cobros salvo que sean deliberadamente con Stripe test mode.

## Pendiente antes de producción

- Usar HTTPS y llaves Stripe live aprobadas, webhook registrado por escuela y una API desplegada por entorno/escuela.
- Validar los eventos del webhook y conciliación de pagos antes de depender del estado en el cliente.
- Migrar el login legado de alumnos a contraseñas con hash; el endpoint móvil conserva temporalmente la comparación heredada.
- Revisar montos, límites, idempotencia, privacidad, retención y términos legales con cada escuela.
