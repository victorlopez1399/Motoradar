// Copia la web al directorio www/ de la app y la adapta:
//  - incluye una copia de los datos (para funcionar sin conexión)
//  - sustituye la carga de datos por app-datos.js, que descarga los del día desde la web publicada
//  - quita lo que no tiene sentido dentro de la app (páginas para Google, legales se abren en web)
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const app = dirname(fileURLToPath(import.meta.url));
const raiz = join(app, "..");
const www = join(app, "www");

rmSync(www, { recursive: true, force: true });
mkdirSync(www, { recursive: true });

for (const f of ["index.html", "styles.css", "app.js", "extras.js", "favicon.svg", "manifest.webmanifest"]) {
  cpSync(join(raiz, f), join(www, f));
}
for (const d of ["data", "icons"]) {
  if (existsSync(join(raiz, d))) cpSync(join(raiz, d), join(www, d), { recursive: true });
}
rmSync(join(www, "data", "auto.json"), { force: true });

// Dirección de la web publicada, desde data/sitio.js
const sitio = readFileSync(join(raiz, "data", "sitio.js"), "utf8");
const m = sitio.match(/url:\s*"([^"]+)"/);
const base = m ? m[1].replace(/\/$/, "") : "";
if (!base.startsWith("https://")) throw new Error('data/sitio.js debe tener una "url" https');

writeFileSync(join(www, "app-datos.js"), readFileSync(join(app, "web-extra", "app-datos.js"), "utf8").replace("__BASE_URL__", base));

let html = readFileSync(join(www, "index.html"), "utf8");
const inicio = html.indexOf('<script src="data/catalogo.js">');
const fin = html.indexOf('<script src="app.js"></script>');
if (inicio < 0 || fin < 0) throw new Error("index.html no tiene los scripts esperados");
html = html.slice(0, inicio) + '<script src="app-datos.js"></script>' + html.slice(fin + '<script src="app.js"></script>'.length);
// Los enlaces a páginas de la web (legales, marcas…) se abren en la web publicada
html = html.replace(/href="((?:legal|marca|ofertas|motos-a2|motos-125|moto)\/[^"]*)"/g, `href="${base}/$1"`);
html = html.replace('<link rel="manifest" href="manifest.webmanifest">', "");
writeFileSync(join(www, "index.html"), html);

console.log(`www/ preparado (datos en vivo desde ${base})`);
