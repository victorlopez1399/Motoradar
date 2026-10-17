# Ficha de MotoRadar en las tiendas (copiar y pegar)

Idioma principal: **Español (España)**. Las imágenes están en `app/tienda/graficos/` y `app/tienda/capturas/` (se generan en tu ordenador; no están en GitHub).

---

## Datos comunes

| Campo | Valor |
|---|---|
| Nombre de la app | MotoRadar: ofertas de motos |
| Identificador (paquete / Bundle ID) | `es.motoradar.app` |
| Categoría | Compras (Google Play: *Compras* · App Store: *Compras*, secundaria *Estilo de vida*) |
| Precio | Gratis |
| Web | https://victorlopez1399.github.io/Motoradar/ |
| Política de privacidad | https://victorlopez1399.github.io/Motoradar/legal/privacidad/ |
| Correo de soporte | el de `titular.email` en `data/sitio.js` |
| Países | España (puedes añadir más, pero los precios son de España) |

## Google Play

**Descripción breve (máx. 80):**
> Ofertas oficiales de motos en España, con ficha técnica y precio. Cada día.

**Descripción completa (máx. 4000):**

> Todas las ofertas oficiales de las marcas de motos en España, en una sola app y actualizadas cada día.
>
> MotoRadar revisa a diario las webs oficiales de Honda, Kawasaki, Suzuki, KTM, BMW Motorrad, Triumph, Harley-Davidson, Royal Enfield y más, y te muestra las promociones vigentes con su precio final, el descuento, la fecha de fin y el enlace directo a la oferta en la web de la marca.
>
> QUÉ PUEDES HACER
> • Ver de un vistazo las mayores rebajas, financiaciones y regalos del momento
> • Consultar la ficha técnica de más de 200 motos: potencia, par, peso, altura del asiento, depósito y carnet
> • Filtrar por marca, tipo de moto (naked, trail, scooter, deportiva, custom…) y carnet (A1/B, A2 o A)
> • Ordenar por precio, potencia, peso o mayor ahorro
> • Guardar tus motos favoritas para tenerlas siempre a mano
> • Saber qué ofertas son nuevas desde tu última visita
> • Compartir una moto con tus amigos
> • Pedir la oferta a un concesionario oficial
>
> DATOS FIABLES
> Solo mostramos promociones publicadas en la web oficial de cada marca, con la fecha en que se revisaron. Las ofertas caducadas desaparecen solas.
>
> MotoRadar es un comparador independiente y no tiene relación con los fabricantes. Confirma siempre condiciones y vigencia en la web oficial o en tu concesionario antes de comprar.

**Gráficos:** icono `graficos/icono-play-512.png` · gráfico destacado `graficos/grafico-destacado-1024x500.png` · capturas de teléfono `capturas/android/1…5.png` (1080×1920).

## App Store

**Subtítulo (máx. 30):** `Ofertas oficiales, cada día`

**Texto promocional (máx. 170):**
> Las ofertas oficiales de motos en España en una app: descuentos, financiación y regalos de cada marca, con ficha técnica y enlace directo. Actualizado a diario.

**Descripción:** la misma que la de Google Play.

**Palabras clave (máx. 100, separadas por comas, sin espacios):**
`moto,motos,ofertas,descuentos,A2,125,scooter,Honda,Yamaha,Kawasaki,BMW,KTM,trail,naked,precio,ficha`

**Capturas:** `capturas/iphone-6.9/1…5.png` (1320×2868, iPhone 6,9"). La app es solo para iPhone, así que no hacen falta capturas de iPad.

**Información para la revisión de Apple (notas):**
> MotoRadar es un comparador de ofertas oficiales de motos en España. No requiere cuenta. Los datos se descargan cada día de nuestra web pública. Funciones de la app: filtros por marca, tipo y carnet; ficha técnica; favoritas guardadas en el dispositivo; aviso de ofertas nuevas desde la última visita y compartir. Los enlaces a las ofertas se abren en el navegador integrado.

## Cuestionarios

### Clasificación de contenido (Google Play, IARC) y edad (App Store)
Respuesta a todo: **No** (sin violencia, sexo, lenguaje soez, drogas, apuestas, contenido generado por usuarios ni compras). Resultado esperado: **PEGI 3** / **4+**.
- ¿La app permite comprar? **No** (enlaza a webs de las marcas).
- ¿Contiene anuncios? **No** en la app (si añades enlaces de afiliado, marca **Sí**).

### Seguridad de los datos (Google Play) y Privacidad de la app (App Store)
- **Sin el formulario de leads activado** (`leads` vacío en `data/sitio.js`): la app **no recoge datos**. Las favoritas y la última visita se guardan solo en el dispositivo.
  - Google Play: «¿Tu app recoge o comparte datos de usuario?» → **No**.
  - App Store: **Datos no recopilados**.
- **Con el formulario de leads activado**: declara **Información de contacto → Nombre, Correo electrónico y Teléfono**, y en ubicación el **código postal (ubicación aproximada)**. Recogidos solo si el usuario los envía (opcional), para **funcionalidad de la app**, y **compartidos con terceros** (concesionario). No se usan para seguimiento. Cifrados en tránsito: **Sí**. El usuario puede pedir su eliminación escribiendo al correo de contacto.
- Analítica (GoatCounter o Cloudflare): no usa identificadores ni cookies. Declárala como **Datos de uso → Interacciones con la app, no vinculados al usuario**, o «no recopilados» si no la activas.

### Otros
- Acceso a la app: **toda la funcionalidad está disponible sin credenciales**.
- Público objetivo: **18 años o más** (compra de vehículos).
- Noticias: **No**. App gubernamental o financiera: **No**. Salud: **No**.
- Cifrado (App Store): la app solo usa HTTPS, ya declarado en la propia app (`ITSAppUsesNonExemptEncryption = NO`).
