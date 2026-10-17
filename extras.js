/*
 * Servicios externos opcionales, configurados en data/sitio.js:
 * analítica sin cookies, Google AdSense, canal de Telegram, formulario de leads y enlaces de afiliado.
 * Si un campo de data/sitio.js está vacío, la función correspondiente no se carga.
 */
(function () {
  "use strict";
  var C = window.SITIO || {};
  var yo = document.currentScript && document.currentScript.src;
  var raiz = yo ? yo.replace(/extras\.js(\?.*)?$/, "") : "./";
  // En la app las páginas legales no van incluidas: se abren en la web publicada
  if (window.MR_APP && /^https:\/\//.test(C.url || "")) raiz = C.url.replace(/\/$/, "") + "/";

  function esc(s) {
    return String(s == null ? "" : s).replace(/[&<>"']/g, function (c) {
      return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
    });
  }
  function https(u) { return /^https:\/\//.test(u || "") ? u : ""; }
  function script(src, attrs) {
    var s = document.createElement("script");
    s.src = src; s.async = true;
    for (var k in attrs) s.setAttribute(k, attrs[k]);
    document.head.appendChild(s);
  }

  // ── Analítica sin cookies (no requiere banner de consentimiento) ──
  if (https(C.goatcounter)) script("https://gc.zgo.at/count.js", { "data-goatcounter": C.goatcounter });
  else if (C.cloudflareAnalytics) script("https://static.cloudflareinsights.com/beacon.min.js", { defer: "", "data-cf-beacon": JSON.stringify({ token: C.cloudflareAnalytics }) });

  // ── Google AdSense (anuncios automáticos; el consentimiento lo gestiona el mensaje de privacidad de Google) ──
  // En la app de las tiendas no se carga AdSense: sus normas no permiten anuncios web dentro de apps
  if (!window.MR_APP && /^ca-pub-\d{10,20}$/.test(C.adsense || "")) {
    script("https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=" + C.adsense, { crossorigin: "anonymous" });
  }

  // ── Canal de Telegram ──
  function montarTelegram() {
    if (!https(C.telegram)) return;
    var els = document.querySelectorAll("[data-mr-telegram]");
    for (var i = 0; i < els.length; i++) {
      els[i].innerHTML =
        '<a class="mr-tg" href="' + esc(C.telegram) + '" target="_blank" rel="noopener">' +
        '<span class="mr-tg__icon" aria-hidden="true">✈</span>' +
        '<span><b>Recibe las ofertas nuevas en Telegram</b><small>Te avisamos en cuanto una marca lanza una promoción. Gratis.</small></span>' +
        '<span class="mr-tg__cta">Unirme →</span></a>';
    }
  }

  // ── Afiliados y formulario "Pedir esta oferta" en cada ficha ──
  function rellenar(t, d) {
    return String(t || "").replace(/\{modelo\}/g, d.modelo || "").replace(/\{marca\}/g, d.marca || "");
  }
  function rellenarUrl(u, d) {
    return String(u || "").replace(/\{modelo\}/g, encodeURIComponent(d.modelo || "")).replace(/\{marca\}/g, encodeURIComponent(d.marca || ""));
  }

  function montar(el, d) {
    if (!el) return;
    var html = "";
    var af = (C.afiliados || []).filter(function (a) { return a && https(a.url); });
    if (af.length) {
      html += '<div class="mr-af"><p class="mr-af__tag">Publicidad · enlaces patrocinados</p><div class="mr-af__grid">';
      af.forEach(function (a) {
        html += '<a class="mr-af__item" href="' + esc(rellenarUrl(a.url, d)) + '" target="_blank" rel="sponsored noopener">' +
          "<b>" + esc(rellenar(a.titulo, d)) + "</b><span>" + esc(rellenar(a.texto, d)) + "</span></a>";
      });
      html += "</div></div>";
    }
    if (https(C.leads)) {
      html +=
        '<details class="mr-lead"><summary class="btn btn--lime">Pedir esta oferta a un concesionario</summary>' +
        '<form class="mr-lead__form" novalidate>' +
        '<p class="mr-lead__intro">Te enviamos la mejor oferta disponible para la <b>' + esc(d.marca + " " + d.modelo) + "</b> en tu zona. Sin compromiso.</p>" +
        '<input type="hidden" name="marca" value="' + esc(d.marca) + '"><input type="hidden" name="modelo" value="' + esc(d.modelo) + '">' +
        '<input type="text" name="_gotcha" tabindex="-1" autocomplete="off" class="mr-hp" aria-hidden="true">' +
        '<label>Nombre<input name="nombre" required autocomplete="name"></label>' +
        '<label>Correo electrónico<input name="email" type="email" required autocomplete="email"></label>' +
        '<label>Teléfono<input name="telefono" type="tel" required autocomplete="tel" pattern="[0-9 +]{9,15}"></label>' +
        '<label>Código postal<input name="codigo_postal" required inputmode="numeric" pattern="[0-9]{5}" maxlength="5"></label>' +
        '<label class="mr-lead__full">Comentario (opcional)<textarea name="comentario" rows="2"></textarea></label>' +
        '<label class="mr-lead__ok mr-lead__full"><input type="checkbox" name="consentimiento" value="si" required> Acepto que mis datos se envíen a un concesionario oficial para recibir una oferta, según la <a href="' + raiz + 'legal/privacidad/" target="_blank">política de privacidad</a>.</label>' +
        '<button class="btn btn--lime mr-lead__full" type="submit">Enviar solicitud</button>' +
        '<p class="mr-lead__msg mr-lead__full" role="status"></p></form></details>';
    }
    el.innerHTML = html;
    var form = el.querySelector(".mr-lead__form");
    if (form) form.addEventListener("submit", enviar);
  }

  function enviar(e) {
    e.preventDefault();
    var form = e.target, msg = form.querySelector(".mr-lead__msg"), btn = form.querySelector("button[type=submit]");
    if (!form.checkValidity()) { msg.textContent = "Revisa los campos marcados y acepta la política de privacidad."; form.reportValidity(); return; }
    btn.disabled = true; msg.textContent = "Enviando…";
    fetch(C.leads, { method: "POST", body: new FormData(form), headers: { Accept: "application/json" } })
      .then(function (r) {
        if (!r.ok) throw new Error(r.status);
        form.innerHTML = '<p class="mr-lead__done">✔ Solicitud enviada. Un concesionario te contactará con su oferta.</p>';
      })
      .catch(function () { btn.disabled = false; msg.textContent = "No se ha podido enviar. Inténtalo de nuevo en unos minutos."; });
  }

  window.MotoRadarExtras = { montar: montar, telegram: montarTelegram };

  function iniciar() {
    montarTelegram();
    var els = document.querySelectorAll("[data-mr-extras]");
    for (var i = 0; i < els.length; i++) montar(els[i], { marca: els[i].getAttribute("data-marca"), modelo: els[i].getAttribute("data-modelo") });
  }
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", iniciar);
  else iniciar();
})();
