# Publicar MotoRadar en Google Play y App Store

La app ya está programada y se compila sola en GitHub (pestaña *Actions → "App: compilar y publicar"*). Lo que falta solo lo puedes hacer tú, porque exige **tus cuentas, tu identidad y pagos**: crear las cuentas de desarrollador, aceptar sus contratos y guardar las claves en GitHub.

| | Google Play | App Store |
|---|---|---|
| Coste | 25 $ (pago único) | 99 $ al año |
| Verificación | Documento de identidad (y dirección) | Apple ID con verificación en dos pasos + identidad |
| Antes de ser pública | Cuenta personal nueva: **prueba cerrada con 12 testers durante 14 días seguidos** | Revisión de Apple (normalmente 1–3 días) |
| Lo que sube GitHub | Cada versión, a la pista de prueba interna | Cada versión, a TestFlight |

> Con una **cuenta de empresa** (necesita número D-U-N-S, gratuito) Google Play no exige la prueba de 14 días.

**Identificador de la app:** `es.motoradar.app`. Úsalo igual en las dos tiendas: **no se puede cambiar** después de publicar.

---

## Parte 1 · Google Play

### 1. Crear la cuenta
1. https://play.google.com/console/signup → cuenta **Personal** (o *Organización* si tienes empresa y D-U-N-S).
2. Paga los 25 $, verifica tu identidad y tu teléfono. Google puede tardar unos días en verificarte.

### 2. Crear la app
1. Play Console → **Crear aplicación** → nombre `MotoRadar: ofertas de motos`, idioma *Español (España)*, **Aplicación**, **Gratis**. Acepta las declaraciones.
2. Rellena **Panel → Configurar tu app** con los textos y respuestas de [`app/tienda/ficha-tienda.md`](app/tienda/ficha-tienda.md): política de privacidad, acceso a la app, anuncios, clasificación de contenido, público objetivo, seguridad de los datos y ficha de Play Store (con las imágenes de `app/tienda/graficos` y `app/tienda/capturas/android`).

### 3. Clave de firma (ya generada)
En la carpeta **`privado-no-subir/`** de tu ordenador está la clave de subida de Android. Es **tuya y secreta**:
- `clave-subida-android.p12` → la clave
- `contrasena-clave-android.txt` → su contraseña
- `clave-subida-android.base64.txt` → la misma clave en texto, para GitHub

**Guarda una copia de los tres archivos en un sitio seguro** (un USB o un gestor de contraseñas). La carpeta de esta sesión se borra si borras la sesión.

En GitHub: *Settings → Secrets and variables → Actions → New repository secret*:
- `ANDROID_KEYSTORE_BASE64` = todo el contenido de `clave-subida-android.base64.txt`
- `ANDROID_KEYSTORE_PASSWORD` = el contenido de `contrasena-clave-android.txt`

### 4. Primera versión (a mano, una sola vez)
Google obliga a subir la primera versión desde Play Console.
1. GitHub → *Actions → App: compilar y publicar → Run workflow*. Al terminar (unos 10 min), abre la ejecución y descarga el artefacto **motoradar-android-1.0.N** (dentro está `app-release.aab`, ya firmado).
2. Play Console → **Probar y publicar → Pruebas → Prueba cerrada → Crear versión**. Acepta **la firma de apps de Google Play** y sube el `.aab`.
3. Añade testers (una lista de correos de Google) y envía la versión a revisión.
4. **Prueba cerrada: 12 testers durante 14 días seguidos.** Pide a amigos y familia que acepten la invitación desde el enlace de la prueba, instalen la app y la usen. Si baja de 12, la cuenta vuelve a empezar.
5. Pasados los 14 días: *Panel → Solicitar acceso a producción* → responde el cuestionario → cuando lo aprueben, **Producción → Crear versión** con el mismo `.aab` o uno nuevo → **Publicar**. Ya es pública.

### 5. Subidas automáticas (opcional, recomendado)
Para que GitHub suba cada versión nueva a Play sin descargar nada:
1. Google Cloud Console (https://console.cloud.google.com) → crea un proyecto → *IAM → Cuentas de servicio → Crear* → en *Claves* → **Añadir clave → JSON** (se descarga un archivo).
2. Activa la **Google Play Android Developer API** en ese proyecto.
3. Play Console → *Usuarios y permisos → Invitar usuario* → el correo de la cuenta de servicio → permisos de **Publicar en pistas de prueba** para MotoRadar.
4. GitHub secret `PLAY_SERVICE_ACCOUNT_JSON` = el contenido completo del JSON.

Desde entonces, cada *Run workflow* deja la versión como **borrador en la pista de prueba interna**. Desde Play Console la pasas a producción.

---

## Parte 2 · App Store (iPhone)

No necesitas un Mac: GitHub compila la app en sus Mac.

### 1. Crear la cuenta
1. https://developer.apple.com/programs/enroll/ con tu Apple ID (con verificación en dos pasos activada). Inscríbete como **Individual** (o *Organización* con D-U-N-S).
2. Paga los 99 $/año. Apple puede tardar hasta 48 h en activarla.
3. Anota tu **Team ID**: https://developer.apple.com/account → *Membership details* (10 caracteres, por ejemplo `AB12CD34EF`).

### 2. Crear la app en App Store Connect
1. https://appstoreconnect.apple.com → *Apps → + → Nueva app* → plataforma **iOS**, nombre `MotoRadar: ofertas de motos`, idioma *Español (España)*, **Bundle ID**: si no aparece `es.motoradar.app`, créalo antes en https://developer.apple.com/account/resources/identifiers → *+ → App IDs → App* → Bundle ID explícito `es.motoradar.app`. SKU: `motoradar`.
2. Rellena la ficha con [`app/tienda/ficha-tienda.md`](app/tienda/ficha-tienda.md): subtítulo, descripción, palabras clave, URL de soporte y de privacidad, capturas de `app/tienda/capturas/iphone-6.9`, clasificación por edad, categoría, *Privacidad de la app* y precio **Gratis**.

### 3. Clave de la API (para que GitHub firme y suba)
1. App Store Connect → *Usuarios y acceso → Integraciones → App Store Connect API → Claves del equipo → +* → nombre `GitHub`, acceso **App Manager** → *Generar*.
2. Descarga el archivo `AuthKey_XXXXXXXXXX.p8` (**solo se puede descargar una vez**) y anota el **Key ID** y el **Issuer ID** que aparecen en esa página.
3. GitHub → *Settings → Secrets and variables → Actions*:
   - `APPSTORE_KEY_ID` = Key ID
   - `APPSTORE_ISSUER_ID` = Issuer ID
   - `APPSTORE_KEY_P8` = todo el contenido del archivo `.p8` (ábrelo con el Bloc de notas, incluidas las líneas `-----BEGIN…` y `…END-----`)
   - `APPLE_TEAM_ID` = tu Team ID

### 4. Compilar, probar y publicar
1. GitHub → *Actions → App: compilar y publicar → Run workflow*. GitHub crea los certificados, firma la app y la sube a App Store Connect en unos 15–20 min.
2. App Store Connect → *TestFlight*: la versión aparece tras unos minutos de procesamiento. Instálala en tu iPhone con la app **TestFlight** para probarla.
3. En la página de la versión (*1.0*) → *Compilación → +* → elige la que subió GitHub → **Añadir para revisión** → **Enviar a revisión**.
4. Cuando Apple la apruebe, se publica (o pulsas *Publicar* si elegiste publicación manual).

> **Aviso sobre la revisión de Apple:** Apple rechaza apps que son solo una web metida en una app (norma 4.2). Por eso MotoRadar incluye funciones propias: favoritas, aviso de ofertas nuevas desde tu última visita, compartir y funcionamiento sin conexión. Aun así, si la rechazan, responde a la revisión explicando estas funciones (están en las notas de `ficha-tienda.md`) o pídeme que añada notificaciones push de ofertas nuevas, que es lo que más pesa en estos casos.

---

## Cómo se mantiene al día

- **Ofertas y modelos:** la app descarga cada vez que se abre los datos que GitHub actualiza a diario en la web. **No hace falta publicar versiones nuevas** para eso. Sin conexión, usa la última copia incluida.
- **Versiones nuevas** (cambios de diseño o funciones): *Run workflow*. El número de versión sube solo (1.0.N).
- **AdSense no se carga dentro de la app** (sus normas no lo permiten). Para anuncios en la app habría que usar AdMob. Los leads, los afiliados y Telegram sí funcionan.

## Lista de secretos de GitHub

| Secreto | Para qué |
|---|---|
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD` | Firmar la app de Android |
| `PLAY_SERVICE_ACCOUNT_JSON` | Subir a Google Play automáticamente (opcional) |
| `APPSTORE_KEY_ID`, `APPSTORE_ISSUER_ID`, `APPSTORE_KEY_P8`, `APPLE_TEAM_ID` | Firmar y subir a App Store |
| `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` | Canal de Telegram (ver MONETIZAR.md) |
