# MotoRadar

Comparador de motos a la venta en España: ofertas activas de cada marca con enlace directo a la oferta oficial, ficha técnica con foto y filtros por marca, tipo y carnet.

Web estática (HTML + CSS + JavaScript, sin dependencias). Se actualiza sola cada día. Coste: 0 €.

## Estructura

| Archivo | Qué contiene |
|---|---|
| `index.html`, `styles.css`, `app.js` | La web |
| `data/catalogo.js` | Catálogo revisado a mano: 12 marcas y 88 modelos |
| `data/ofertas.js` | Ofertas manuales (solo marcas que no se pueden leer automáticamente) |
| `data/fotos.js` | Fotos de Wikimedia Commons con autor y licencia |
| `data/auto.js` | **Generado automáticamente**: modelos nuevos y ofertas vigentes |
| `data/auto.json` | **Generado automáticamente**: estado que usa el actualizador |
| `scripts/actualizar.ps1` | El actualizador: lee las webs oficiales y genera `data/auto.*` |
| `scripts/generar-paginas.ps1` | Genera las páginas para Google (`moto/`, `marca/`, `ofertas/`, `motos-a2/`, `motos-125/`, `legal/`), `sitemap.xml`, `robots.txt`, `og.png` |
| `scripts/telegram.ps1` | Publica las ofertas nuevas en tu canal de Telegram |
| `data/sitio.js` | **Configuración**: dirección de la web, Search Console, analítica, AdSense, Telegram, leads, afiliados y datos legales |
| `extras.js` | Activa los servicios configurados en `data/sitio.js` |
| `.github/workflows/actualizar.yml` | Lo ejecuta cada día y publica la web |

> **Para dar a conocer la web y monetizarla, sigue [MONETIZAR.md](MONETIZAR.md).** Las carpetas `moto/`, `marca/`, etc. se generan solas: no las edites a mano.

## Actualización automática

Cada día, `scripts/actualizar.ps1` lee las webs oficiales y:

| Marca | Ofertas | Modelos nuevos |
|---|---|---|
| Honda, Kawasaki, Suzuki, KTM, BMW | ✔ se sustituyen por las vigentes | ✔ |
| Triumph, Harley-Davidson, Royal Enfield | — (no publican ofertas en un formato legible) | ✔ |
| Yamaha, Ducati, Aprilia, CFMoto | ✘ a mano en `data/ofertas.js` | ✘ a mano en `data/catalogo.js` |

- Las ofertas que desaparecen de la web oficial desaparecen también de MotoRadar, y las que tienen fecha de fin se ocultan solas al pasar esa fecha.
- Los modelos nuevos se añaden con los datos que publica la marca (cilindrada, potencia, par, peso, asiento, depósito y precio). El carnet se calcula con la potencia. No llevan foto: se muestra el marcador con enlace a la web oficial.
- Se ignoran los modelos de competición o de campo (motocross, enduro de carreras, versiones de circuito) y los triciclos.
- **Si una marca cambia su web y deja de leerse**, se conservan sus datos del día anterior y el aviso aparece en el registro de la ejecución. Nunca se tocan `catalogo.js`, `ofertas.js` ni `fotos.js`.

### Ponerla en marcha gratis (GitHub)

1. Crea una cuenta en https://github.com y un repositorio **público** nuevo (por ejemplo `motoradar`).
2. Sube todos los archivos de esta carpeta a la rama `main` (botón *Add file → Upload files*; incluye la carpeta `.github`).
3. En el repositorio: *Settings → Pages → Build and deployment → Source:* **GitHub Actions**.
4. En *Settings → Actions → General → Workflow permissions:* marca **Read and write permissions**.
5. Ve a la pestaña *Actions*, elige *Actualizar y publicar MotoRadar* y pulsa **Run workflow** para la primera ejecución.

A partir de ahí se ejecuta solo todos los días a las 05:00 UTC y la web queda publicada en `https://TU-USUARIO.github.io/motoradar/`. También puedes lanzarlo a mano cuando quieras desde la pestaña *Actions*.

### Ejecutarlo en tu ordenador (Windows)

```
powershell -ExecutionPolicy Bypass -File scripts\actualizar.ps1
```

Tarda unos 3 minutos. Para que se ejecute solo sin GitHub, crea una tarea diaria en el Programador de tareas de Windows con esa misma orden.

## Edición manual

- **Oferta de Yamaha, Ducati, Aprilia o CFMoto**: añádela en `data/ofertas.js` (formato explicado al principio del archivo).
- **Modelo**: copia una línea en `data/catalogo.js`. Los datos revisados a mano tienen prioridad sobre los automáticos.
- **Foto**: añade una línea en `data/fotos.js` con la URL de Wikimedia Commons, el autor y la licencia.

## Datos

- Catálogo manual revisado en las webs oficiales el 16/10/2026; la fecha que muestra la web es la de la última actualización automática.
- BMW, Ducati y Aprilia bloquean la lectura de su web principal: de BMW se usa su web oficial de promociones (`promociones.bmw-motorrad.es`), que sí se puede leer.
- Las fotos son ilustrativas y pueden corresponder a otro año, color o versión.
