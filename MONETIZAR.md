# Guía: dar a conocer MotoRadar y ganar dinero con ella

Todo se conecta desde **un solo archivo: `data/sitio.js`**. Cada servicio está apagado hasta que rellenas su campo.

**Cómo editarlo:** en GitHub abre `data/sitio.js` → icono del lápiz ✎ → cambia el valor entre comillas → **Commit changes**. En 2–3 minutos la web se regenera y se publica sola (pestaña *Actions*).

> Lo que necesita una cuenta tuya (registrarte, contraseñas, datos bancarios) tienes que hacerlo tú. Cuando tengas los códigos de los pasos 1, 2, 3, 6, 7 y 8, puedes pegármelos y los configuro yo. El token del bot de Telegram (paso 5) es una clave secreta: guárdalo tú en GitHub como se explica, no lo pegues en ningún archivo.

Orden recomendado: **1 → 2 → 3 → 4** la primera semana, **5** cuando tengas el canal, **9** antes de monetizar, y **6, 7, 8** cuando haya visitas.

---

## 1. Google Search Console (que Google te encuentre) — gratis

1. Entra en https://search.google.com/search-console con tu cuenta de Google.
2. *Añadir propiedad* → elige **Prefijo de URL** → escribe la dirección de tu web (la que pone `url` en `data/sitio.js`, con `/` al final).
3. Método de verificación: **Etiqueta HTML**. Te da algo como `<meta name="google-site-verification" content="AbC123…">`.
4. Copia **solo lo que va dentro de `content="…"`** y pégalo en `googleVerificacion` de `data/sitio.js`. Guarda.
5. Espera 3 minutos y pulsa **Verificar**.
6. Menú *Sitemaps* → escribe `sitemap.xml` → **Enviar**.

En unos días verás qué búsquedas traen visitas. El sitemap se actualiza solo cada día con todas las páginas.

## 2. Bing Webmaster Tools (Bing, DuckDuckGo, Copilot) — gratis

1. Entra en https://www.bing.com/webmasters.
2. Lo más rápido: **Importar desde Google Search Console** (cuando hayas hecho el paso 1).
3. Si prefieres verificar a mano: elige *Etiqueta meta HTML* y pega su `content` en `bingVerificacion`.

## 3. Saber cuántas visitas tienes — gratis y sin banner de cookies

Rellena **una** de estas dos opciones (no usan cookies, así que no necesitas pedir consentimiento):

- **Cloudflare Web Analytics:** https://dash.cloudflare.com → *Analytics & Logs → Web Analytics → Add a site* → escribe tu dominio → elige la instalación con *JS snippet*. En el código aparece `"token": "xxxx"`: pega ese token en `cloudflareAnalytics`.
- **GoatCounter:** crea una cuenta en https://www.goatcounter.com (elige un código, por ejemplo `motoradar`). Pega `https://motoradar.goatcounter.com/count` en `goatcounter`.

## 4. Dominio propio (unos 10 €/año) — muy recomendable

Hace la web más fiable y fácil de recordar, y AdSense lo pide en la práctica.

1. Compra un dominio (por ejemplo `motoradar.es`) en cualquier registrador.
2. En GitHub: *Settings → Pages → Custom domain* → escribe el dominio → *Save*.
3. En el panel de tu registrador crea estos registros DNS:
   - 4 registros **A** para `@`: `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
   - 1 registro **CNAME** para `www` → `victorlopez1399.github.io`
4. Cuando GitHub diga que el DNS es correcto (puede tardar horas), marca **Enforce HTTPS**.
5. Cambia `url` en `data/sitio.js` a `https://tudominio.es` (sin barra final). Todas las páginas, el sitemap y las etiquetas se regeneran con la nueva dirección.
6. En Search Console añade también la nueva dirección.

## 5. Canal de Telegram con avisos automáticos — gratis

Cada día, al encontrar ofertas nuevas, se publican solas en tu canal (máximo 10 al día).

1. En Telegram crea un **canal público** (por ejemplo `@motoradar_ofertas`).
2. Habla con **@BotFather** → `/newbot` → ponle nombre → te da un **token** (`123456:ABC…`). Es secreto.
3. En tu canal: *Administradores → Añadir administrador* → busca tu bot → permiso de **publicar mensajes**.
4. En GitHub: *Settings → Secrets and variables → Actions → New repository secret*:
   - Nombre `TELEGRAM_BOT_TOKEN`, valor: el token.
   - Nombre `TELEGRAM_CHAT_ID`, valor: el nombre del canal con @ (por ejemplo `@motoradar_ofertas`).
5. En `data/sitio.js` pon el enlace del canal en `telegram` (`https://t.me/motoradar_ofertas`). Aparecerá un botón «Recibe las ofertas nuevas en Telegram» en toda la web.

Para probarlo: pestaña *Actions → Actualizar y publicar MotoRadar → Run workflow*. Solo publica ofertas que no estuvieran el día anterior.

## 6. Leads: «Pedir esta oferta a un concesionario» (lo que más paga)

Cada ficha muestra un formulario. Los datos te llegan por correo y tú los haces llegar al concesionario, que te paga por contacto.

1. Crea una cuenta en https://formspree.io (el plan gratuito admite unos 50 envíos al mes).
2. *New form* → te da una dirección como `https://formspree.io/f/abcdwxyz`. Pégala en `leads`.
3. En Formspree activa la protección contra spam. El formulario ya incluye un campo trampa para bots.
4. **Antes de vender contactos:** llega a un acuerdo por escrito con cada concesionario (precio por lead, cómo se los envías y cómo tratan los datos). La política de privacidad ya informa de que los datos se envían a un concesionario oficial; si nombras concesionarios concretos, añádelos allí.
5. Cómo empezar: llama a los concesionarios oficiales de tu zona, enséñales la web y ofrécete a enviarles contactos de compradores interesados en su marca, gratis el primer mes.

## 7. Enlaces de afiliado (seguros, equipación, financiación)

1. Apúntate a programas de afiliados:
   - **Amazon Afiliados** (https://afiliados.amazon.es) para cascos, guantes, intercomunicadores…
   - Redes como **Awin** (https://www.awin.com/es) o **TradeTracker**, donde busca tiendas de equipación de moto y aseguradoras o comparadores de seguros.
2. Cada programa te da enlaces con tu código. Añádelos en `afiliados`:

```js
afiliados: [
  { titulo: "Calcula tu seguro", texto: "Compara el seguro de la {marca} {modelo}", url: "https://enlace-de-afiliado..." },
  { titulo: "Cascos y equipación", texto: "Ofertas en cascos y chaquetas", url: "https://enlace-de-afiliado..." }
],
```

`{marca}` y `{modelo}` se sustituyen por la moto de cada ficha. Los enlaces se muestran marcados como **«Publicidad · enlaces patrocinados»**, como exige la ley, y con `rel="sponsored"`, como pide Google.

## 8. Google AdSense (anuncios)

Empieza cuando tengas visitas constantes (cientos al día). Antes casi no paga.

1. Requisitos: dominio propio (paso 4), datos legales completos (paso 9) y algunas semanas de contenido.
2. Regístrate en https://adsense.google.com y añade tu sitio.
3. Copia tu ID de editor (`ca-pub-1234567890123456`) en `adsense`. Se cargan los anuncios automáticos y se crea solo el archivo **`ads.txt`** que Google exige.
4. **Obligatorio en España (UE):** en AdSense ve a *Privacidad y mensajes → Europa* y crea el **mensaje de consentimiento de Google** (es gratuito y está certificado). Sin él, Google no muestra anuncios a usuarios europeos.
5. En *Anuncios → Por sitio* activa **Anuncios automáticos**.

## 9. Datos legales (obligatorio antes de monetizar)

Rellena `titular` en `data/sitio.js`: nombre o empresa, NIF, correo y dirección. Las páginas **Aviso legal, Privacidad y Cookies** ya están creadas y se completan solas con esos datos. Mientras falten, aparecen marcadas en amarillo como «pendiente de completar».

Si cobras regularmente, consulta con una gestoría el alta como autónomo o la forma de declarar los ingresos. Los textos legales son una base razonable, pero no sustituyen el consejo de un profesional.

## 10. Cuando empieces a ganar dinero: mudarse a Cloudflare Pages

Las condiciones de GitHub Pages no permiten webs cuyo fin principal sea comercial. Cloudflare Pages también es gratis y sí lo permite. La actualización diaria sigue funcionando igual en GitHub.

1. https://dash.cloudflare.com → *Workers & Pages → Create → Pages → Connect to Git* → elige el repositorio `Motoradar`.
2. *Build command:* vacío. *Build output directory:* `/`. → *Save and Deploy*.
3. *Custom domains* → añade tu dominio y sigue sus instrucciones de DNS (sustituyen a las del paso 4).
4. En GitHub: *Settings → Pages* → desactiva GitHub Pages.
5. Cada vez que la actualización diaria guarda cambios, Cloudflare publica la web automáticamente.

---

### Qué ya está hecho y funciona solo

- Una página indexable por cada moto (220), por cada marca (12) y por búsquedas clave: *ofertas de motos del mes*, *motos A2* y *motos 125*. Cada una tiene su título, su descripción y datos estructurados de producto y precio. Se regeneran cada día.
- `sitemap.xml`, `robots.txt`, la imagen para compartir en redes (`og.png`), una página 404 y los enlaces internos entre páginas.
- Formulario de leads, bloques de afiliados, botón de Telegram, AdSense y analítica: solo se activan al rellenar su campo.
