/*
 * Arranque de la app (solo en la versión de Google Play y App Store).
 *
 * 1. Descarga los datos del día desde la web publicada (ofertas y modelos siempre al día
 *    sin tener que publicar una versión nueva en las tiendas). Si no hay conexión, usa la
 *    copia incluida en la app.
 * 2. Abre los enlaces externos en el navegador integrado del sistema.
 * 3. Botón «atrás» de Android: cierra la ficha y, en la portada, sale de la app.
 */
(function () {
  "use strict";
  var BASE = "__BASE_URL__";
  var DATOS = ["data/catalogo.js", "data/ofertas.js", "data/fotos.js", "data/auto.js", "data/paginas.js", "data/sitio.js"];
  var APP = ["extras.js", "app.js"];
  window.MR_APP = true;
  document.documentElement.classList.add("app");

  function cargar(src, cb) {
    var s = document.createElement("script");
    var listo = false;
    var t = setTimeout(function () { if (!listo) { listo = true; cb(false); } }, 8000);
    s.src = src;
    s.onload = function () { if (!listo) { listo = true; clearTimeout(t); cb(true); } };
    s.onerror = function () { if (!listo) { listo = true; clearTimeout(t); cb(false); } };
    document.body.appendChild(s);
  }
  function enOrden(lista, prefijo, sufijo, fin) {
    var i = 0;
    (function sig(ok) {
      if (!ok) return fin(false);
      if (i >= lista.length) return fin(true);
      cargar(prefijo + lista[i++] + sufijo, sig);
    })(true);
  }
  function arrancarApp() { enOrden(APP, "", "", function () {}); }

  // Datos del día (la caché se renueva cada hora); si falla cualquier archivo, todo desde la copia local
  var version = "?v=" + Math.floor(Date.now() / 3600000);
  var remoto = BASE && navigator.onLine !== false;
  if (remoto) {
    enOrden(DATOS, BASE + "/", version, function (ok) {
      if (ok && window.CATALOGO && window.CATALOGO.modelos && window.CATALOGO.modelos.length) return arrancarApp();
      enOrden(DATOS, "", "", function () { arrancarApp(); });
    });
  } else {
    enOrden(DATOS, "", "", function () { arrancarApp(); });
  }

  var P = function () { return (window.Capacitor && window.Capacitor.Plugins) || {}; };

  // Enlaces externos → navegador integrado (Custom Tabs en Android, Safari en iOS)
  document.addEventListener("click", function (e) {
    var a = e.target.closest && e.target.closest("a[href]");
    if (!a) return;
    var href = a.href;
    if (!/^https?:\/\//.test(href) || href.indexOf(location.origin) === 0) return;
    if (P().Browser) { e.preventDefault(); P().Browser.open({ url: href, toolbarColor: "#07070a" }); }
  }, true);

  // Botón atrás de Android
  if (P().App) {
    P().App.addListener("backButton", function () {
      var d = document.getElementById("drawer");
      if (d && d.open) { var c = document.querySelector("#drawerBody [data-close]"); if (c) c.click(); return; }
      P().App.exitApp();
    });
  }

  // Barra de estado oscura
  if (P().StatusBar) {
    try { P().StatusBar.setStyle({ style: "DARK" }); P().StatusBar.setBackgroundColor({ color: "#07070a" }); } catch (_) { /* solo Android */ }
  }
})();
