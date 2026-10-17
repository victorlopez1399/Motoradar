(() => {
  "use strict";

  const { marcas, modelos, revisado } = window.CATALOGO;
  const FOTOS = window.FOTOS || {};
  const marcaById = Object.fromEntries(marcas.map((m) => [m.id, m]));
  const modeloById = Object.fromEntries(modelos.map((m) => [m.id, m]));
  const $ = (id) => document.getElementById(id);
  const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)").matches;
  const finePointer = matchMedia("(hover: hover) and (pointer: fine)").matches;

  // ── Utilidades ──────────────────────────────────────────────
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
  const norm = (s) => s.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase().replace(/[\s\-_.]/g, "");
  const fmtNum = (n) => {
    const [ent, dec] = String(n).split(".");
    return ent.replace(/\B(?=(\d{3})+(?!\d))/g, ".") + (dec ? "," + dec : "");
  };
  const eur = (n) => (n == null ? "Consultar" : fmtNum(Math.round(n)) + " €");
  const val = (n, unit) => (n == null ? "—" : fmtNum(n) + (unit ? " " + unit : ""));
  const iso = (d) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
  const fechaLarga = (s) => new Date(s + "T12:00:00").toLocaleDateString("es-ES", { day: "numeric", month: "short", year: "numeric" });
  const initials = (n) => n.replace(/[^A-Za-z ]/g, " ").split(/\s+/).filter(Boolean).map((w) => w[0]).join("").slice(0, 2).toUpperCase();
  const safeUrl = (u) => (/^https:\/\//.test(u || "") ? u : "#");
  const urlModelo = (m) => safeUrl(m.url || marcaById[m.marca].web);
  const vtName = (prefix, id) => `${prefix}-${id.replace(/[^a-z0-9-]/gi, "")}`;

  // ── Ofertas vigentes (las caducadas se ocultan solas) ───────
  const hoy = iso(new Date());
  const ofertas = (window.OFERTAS || []).filter((o) => modeloById[o.modelo] && (!o.hasta || o.hasta >= hoy));
  const peso = (o) => (o.descuento || 0) * 10 + (o.cuota ? 1 : 0) + (o.regalo ? 1 : 0);
  const ofertasPorModelo = {};
  for (const o of ofertas) (ofertasPorModelo[o.modelo] ||= []).push(o);
  for (const k in ofertasPorModelo) ofertasPorModelo[k].sort((a, b) => peso(b) - peso(a));
  const mejorOferta = (id) => (ofertasPorModelo[id] || [])[0];
  const precioFinal = (m) => { const o = mejorOferta(m.id); return o && o.precioOferta != null ? o.precioOferta : m.precio; };

  // ── Favoritas y ofertas nuevas desde la última visita (se guardan solo en este dispositivo) ──
  const almacen = {
    leer(k, d) { try { const v = localStorage.getItem(k); return v ? JSON.parse(v) : d; } catch (_) { return d; } },
    guardar(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch (_) { /* almacenamiento no disponible */ } },
  };
  const favs = new Set(almacen.leer("mr_favs", []).filter((id) => modeloById[id]));
  const esFav = (id) => favs.has(id);
  const claveOferta = (o) => [o.modelo, o.precioOferta, o.cuota, o.descuento, o.regalo].join("|");
  const vistas = almacen.leer("mr_vistas", null);
  const nuevas = new Set(Array.isArray(vistas) ? ofertas.filter((o) => !vistas.includes(claveOferta(o))).map((o) => o.id) : []);
  setTimeout(() => almacen.guardar("mr_vistas", ofertas.map(claveOferta)), 4000);

  // Titular corto de una oferta: "−1.025 €", "69 €/mes" o "Regalo"
  const titular = (o) => {
    if (o.descuento) return { txt: "−" + eur(o.descuento), cls: "" };
    if (o.cuota) return { txt: fmtNum(o.cuota) + " €<small>/mes</small>", cls: " save--cuota" };
    return { txt: "REGALO", cls: " save--regalo" };
  };

  // ── Fotos ───────────────────────────────────────────────────
  const sinFoto = (m) => `<span class="nophoto"><b>${esc(initials(marcaById[m.marca].nombre))}</b><span>Foto no disponible</span></span>`;
  const foto = (m, grande) => {
    const f = FOTOS[m.id];
    if (!f) return sinFoto(m);
    const src = safeUrl(grande ? f.src : f.thumb);
    return `<img src="${src}" alt="${esc(marcaById[m.marca].nombre + " " + m.modelo)}" loading="${grande ? "eager" : "lazy"}" decoding="async" data-ph="${esc(m.id)}">`;
  };
  // Si una foto no carga, se sustituye por el marcador
  document.addEventListener("error", (e) => {
    const img = e.target;
    if (img.tagName === "IMG" && img.dataset.ph && modeloById[img.dataset.ph]) {
      const credit = img.parentElement && img.parentElement.querySelector(".d-credit");
      if (credit) credit.remove();
      img.outerHTML = sinFoto(modeloById[img.dataset.ph]);
    }
  }, true);

  // ── Estado (sincronizado con la URL para poder compartir) ───
  const params = new URLSearchParams(location.search);
  const ordenes = ["marca", "ahorro", "precio-asc", "precio-desc", "cv-desc", "peso-asc"];
  const state = {
    marca: marcaById[params.get("marca")] ? params.get("marca") : "",
    q: params.get("q") || "",
    tipo: params.get("tipo") || "",
    carnet: ["A1", "A2", "A"].includes(params.get("carnet")) ? params.get("carnet") : "",
    orden: ordenes.includes(params.get("orden")) ? params.get("orden") : "marca",
    soloOferta: params.get("oferta") === "1",
    soloFavs: params.get("fav") === "1",
    moto: modeloById[params.get("moto")] ? params.get("moto") : "",
  };
  const syncUrl = () => {
    const p = new URLSearchParams();
    if (state.marca) p.set("marca", state.marca);
    if (state.q) p.set("q", state.q);
    if (state.tipo) p.set("tipo", state.tipo);
    if (state.carnet) p.set("carnet", state.carnet);
    if (state.orden !== "marca") p.set("orden", state.orden);
    if (state.soloOferta) p.set("oferta", "1");
    if (state.soloFavs) p.set("fav", "1");
    if (state.moto) p.set("moto", state.moto);
    const qs = p.toString();
    try { history.replaceState(null, "", (qs ? "?" + qs : location.pathname) + location.hash); } catch (_) { /* file:// en algunos navegadores */ }
  };

  // Carnet: con A2 puedes llevar motos A1 y A2; con A, todas.
  const permitidos = { A1: ["A1"], A2: ["A1", "A2"], A: ["A1", "A2", "A"] };

  const filtrar = (ignorarMarca = false) => {
    const q = norm(state.q.trim());
    return modelos.filter((m) =>
      (ignorarMarca || !state.marca || m.marca === state.marca) &&
      (!q || norm(m.modelo).includes(q) || norm(marcaById[m.marca].nombre + m.modelo).includes(q)) &&
      (!state.tipo || m.tipo === state.tipo) &&
      (!state.carnet || permitidos[state.carnet].includes(m.carnet)) &&
      (!state.soloOferta || mejorOferta(m.id)) &&
      (!state.soloFavs || favs.has(m.id))
    );
  };

  const ordenar = (lista) => {
    const n = (v, fallback) => (v == null ? fallback : v);
    const ahorro = (m) => { const o = mejorOferta(m.id); return o ? peso(o) : -1; };
    const cmp = {
      ahorro: (a, b) => ahorro(b) - ahorro(a),
      "precio-asc": (a, b) => n(precioFinal(a), Infinity) - n(precioFinal(b), Infinity),
      "precio-desc": (a, b) => n(precioFinal(b), -Infinity) - n(precioFinal(a), -Infinity),
      "cv-desc": (a, b) => n(b.cv, 0) - n(a.cv, 0),
      "peso-asc": (a, b) => n(a.peso, Infinity) - n(b.peso, Infinity),
      marca: (a, b) => marcaById[a.marca].nombre.localeCompare(marcaById[b.marca].nombre, "es") || n(a.precio, Infinity) - n(b.precio, Infinity),
    }[state.orden];
    return [...lista].sort(cmp);
  };

  // ── Efectos: aparición, inclinación, brillo, contadores ─────
  let primerRender = true;
  const io = "IntersectionObserver" in window && !reducedMotion
    ? new IntersectionObserver((entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          e.target.classList.add("in");
          io.unobserve(e.target);
          setTimeout(() => e.target.style.setProperty("--i", 0), 1200);
        }
      }, { threshold: 0.08, rootMargin: "0px 0px -40px 0px" })
    : null;
  const activarReveal = (root) => {
    root.querySelectorAll(".reveal:not(.in)").forEach((el) => {
      if (io && primerRender) io.observe(el); else el.classList.add("in");
    });
  };

  if (finePointer && !reducedMotion) {
    const glow = document.querySelector(".glow");
    let gx = 0, gy = 0, raf = 0;
    document.addEventListener("pointermove", (e) => {
      gx = e.clientX; gy = e.clientY;
      glow.classList.add("on");
      if (!raf) raf = requestAnimationFrame(() => { glow.style.transform = `translate(${gx}px, ${gy}px)`; raf = 0; });
      const t = e.target.closest && e.target.closest(".tilt");
      if (!t) return;
      const r = t.getBoundingClientRect();
      const px = (e.clientX - r.left) / r.width, py = (e.clientY - r.top) / r.height;
      t.style.setProperty("--ry", ((px - 0.5) * 8).toFixed(2) + "deg");
      t.style.setProperty("--rx", ((0.5 - py) * 8).toFixed(2) + "deg");
      t.style.setProperty("--mx", (px * 100).toFixed(1) + "%");
      t.style.setProperty("--my", (py * 100).toFixed(1) + "%");
    }, { passive: true });
    document.addEventListener("pointerleave", () => glow.classList.remove("on"));
  }

  const contar = (el) => {
    const to = Number(el.dataset.count), pre = el.dataset.pre || "", suf = el.dataset.suf || "";
    if (reducedMotion || !to) { el.textContent = pre + fmtNum(to) + suf; return; }
    const t0 = performance.now(), dur = 1300;
    const paso = (t) => {
      const k = Math.min(1, (t - t0) / dur), v = Math.round(to * (1 - Math.pow(1 - k, 3)));
      el.textContent = pre + fmtNum(v) + suf;
      if (k < 1) requestAnimationFrame(paso);
    };
    requestAnimationFrame(paso);
  };

  const conTransicion = (fn) => {
    if (document.startViewTransition && !reducedMotion) {
      // Si se encadenan filtros rápido, el navegador salta la transición anterior: no es un error
      const vt = document.startViewTransition(fn);
      vt.ready.catch(() => {}); vt.finished.catch(() => {});
    } else fn();
  };

  // ── Cabecera: estadísticas, radar y cinta de ofertas ────────
  const renderHero = () => {
    $("fechaRev").textContent = (nuevas.size ? `${nuevas.size} ${nuevas.size === 1 ? "oferta nueva" : "ofertas nuevas"} desde tu última visita · ` : "") + `${ofertas.length} ofertas vivas · revisado el ${fechaLarga(revisado)}`;
    const maxDto = Math.max(0, ...ofertas.map((o) => o.descuento || 0));
    const marcasConOferta = new Set(ofertas.map((o) => modeloById[o.modelo].marca));
    $("stats").innerHTML = `
      <div class="stat"><b data-count="${marcas.length}">0</b><span>marcas</span></div>
      <div class="stat"><b data-count="${modelos.length}">0</b><span>fichas técnicas</span></div>
      <div class="stat stat--hot"><b data-count="${ofertas.length}">0</b><span>ofertas activas</span></div>
      <div class="stat stat--hot"><b data-count="${maxDto}" data-pre="−" data-suf=" €">0</b><span>mayor ahorro</span></div>`;
    $("stats").querySelectorAll("[data-count]").forEach(contar);

    // Un punto en el radar por cada marca con ofertas, sincronizado con el barrido
    const lista = marcas.filter((m) => marcasConOferta.has(m.id));
    const vuelta = 5.5;
    $("blips").innerHTML = lista.map((m, i) => {
      const ang = (i * (360 / lista.length) + 28) % 360;
      const r = 22 + ((i * 37) % 18);
      const rad = (ang * Math.PI) / 180;
      const delay = (ang / 360) * vuelta - 0.44 - vuelta;
      return `<span class="blip" data-l="${esc(m.nombre.toUpperCase())}" style="left:${(50 + r * Math.sin(rad)).toFixed(2)}%;top:${(50 - r * Math.cos(rad)).toFixed(2)}%;animation-delay:${delay.toFixed(2)}s"></span>`;
    }).join("");

    const items = [...ofertas].sort((a, b) => peso(b) - peso(a)).map((o) => {
      const m = modeloById[o.modelo], b = marcaById[m.marca];
      const t = o.descuento ? "−" + eur(o.descuento) : o.cuota ? fmtNum(o.cuota) + " €/mes" : "Regalo";
      return `<button type="button" class="tick" data-ficha="${esc(m.id)}">${esc(b.nombre)} ${esc(m.modelo)} <em>${t}</em></button>`;
    }).join("");
    $("ticker").innerHTML = items ? items + `<span aria-hidden="true" style="display:contents">${items.replace(/<button /g, '<button tabindex="-1" ')}</span>` : "";
    if (!items) $("ticker").parentElement.hidden = true;
  };

  // ── Marcas ──────────────────────────────────────────────────
  const renderBrands = () => {
    const base = filtrar(true);
    const chip = (id, nombre, color, total, nOfertas) => `
      <button type="button" class="chip${id ? "" : " chip--all"}" data-marca="${id}" aria-pressed="${state.marca === id}">
        ${id ? `<span class="chip__dot" style="background:${color}">${esc(initials(nombre))}</span>` : ""}
        ${esc(nombre)} <span class="chip__n">${total}</span>
        ${nOfertas ? `<span class="chip__badge" title="${nOfertas} ofertas activas">${nOfertas}</span>` : ""}
      </button>`;
    $("brands").innerHTML =
      chip("", "Todas", "", base.length, base.reduce((s, m) => s + (ofertasPorModelo[m.id] || []).length, 0)) +
      marcas.map((b) => {
        const de = base.filter((m) => m.marca === b.id);
        return chip(b.id, b.nombre, b.color, de.length, de.reduce((s, m) => s + (ofertasPorModelo[m.id] || []).length, 0));
      }).join("");
  };

  // ── Ofertas ─────────────────────────────────────────────────
  const estadoBadge = (o) => o.estado === "confirmada"
    ? `<span class="status status--ok">Comprobada en web oficial</span>`
    : `<span class="status status--warn">Publicada por la marca · confirmar</span>`;

  const bloquePrecio = (o, m) => {
    if (o.precioOferta != null) {
      const antes = o.descuento ? o.precioOferta + o.descuento : m.precio;
      return `<b>${eur(o.precioOferta)}</b>${antes && antes !== o.precioOferta ? `<s>${eur(antes)}</s>` : ""}`;
    }
    if (o.cuota) return `<b>${fmtNum(o.cuota)} €</b><span class="per">/mes${m.precio ? ` · PVP desde ${eur(m.precio)}` : ""}</span>`;
    return `<b>Regalo</b><span class="per">${esc(o.regalo || "")}</span>`;
  };

  const renderOffers = (lista) => {
    const ids = new Set(lista.map((m) => m.id));
    const items = ofertas.filter((o) => ids.has(o.modelo)).sort((a, b) => peso(b) - peso(a));
    $("ofertasCount").textContent = items.length;

    const link = $("brandPromoLink");
    const mb = state.marca && marcaById[state.marca];
    if (mb) { link.hidden = false; link.href = safeUrl(mb.ofertas || mb.web); link.textContent = `${mb.ofertas ? "Todas las promociones" : "Web oficial"} de ${mb.nombre} ↗`; }
    else link.hidden = true;

    if (!items.length) {
      const destino = mb ? [mb] : marcas;
      $("offers").innerHTML = `
        <div class="empty">
          <h3>${mb ? `Sin ofertas comprobadas de ${esc(mb.nombre)} ahora mismo` : "Sin ofertas para estos filtros"}</h3>
          <p>Solo mostramos promociones publicadas en la web oficial de cada marca. Echa un vistazo por si han lanzado alguna nueva:</p>
          <div class="empty__links">${destino.map((b) => `<a class="btn btn--ghost btn--sm" href="${safeUrl(b.ofertas || b.web)}" target="_blank" rel="noopener">${esc(b.nombre)} ↗</a>`).join("")}</div>
        </div>`;
      return;
    }

    $("offers").innerHTML = items.map((o, i) => {
      const m = modeloById[o.modelo], b = marcaById[m.marca], t = titular(o);
      return `
      <article class="offer tilt reveal${i === 0 && items.length >= 3 ? " offer--hero" : ""}" style="--brand:${b.color};--i:${i % 12};view-transition-name:${vtName("o", o.id)}">
        <div class="offer__media">
          ${foto(m, i === 0)}
          <span class="offer__brand"><i></i>${esc(b.nombre)}${nuevas.has(o.id) ? `<em class="nueva">Nueva</em>` : ""}</span>
          <span class="save${t.cls}">${t.txt}</span>
        </div>
        <div class="offer__body">
          <h3 class="offer__model">${esc(m.modelo)}</h3>
          <div class="offer__price">${bloquePrecio(o, m)}</div>
          <p class="offer__camp">${esc(o.campana)}${o.hasta ? ` · hasta el ${fechaLarga(o.hasta)}` : " · sin fecha de fin publicada"}</p>
          <ul class="tags">
            ${(o.extras || []).map((e) => `<li class="tag">${esc(e)}</li>`).join("")}
            <li>${estadoBadge(o)}</li>
          </ul>
          <p class="offer__meta">Revisada el ${fechaLarga(o.revisada)}</p>
          <div class="offer__actions">
            <a class="btn btn--lime" href="${safeUrl(o.enlace)}" target="_blank" rel="noopener">Ver oferta oficial <span aria-hidden="true">↗</span></a>
            <button class="btn btn--ghost" type="button" data-ficha="${esc(m.id)}">Ficha</button>
          </div>
        </div>
      </article>`;
    }).join("");
  };

  // ── Catálogo ────────────────────────────────────────────────
  const renderGrid = (lista) => {
    $("catalogoCount").textContent = lista.length;
    $("resetBtn").hidden = !(state.marca || state.q || state.tipo || state.carnet || state.soloOferta || state.soloFavs);
    $("favCount").textContent = favs.size ? `(${favs.size})` : "";
    if (!lista.length) {
      $("grid").innerHTML = state.soloFavs && !favs.size
        ? `<div class="empty"><h3>Aún no tienes favoritas</h3><p>Abre la ficha de una moto y pulsa «☆ Guardar» para tenerla siempre a mano.</p><button class="btn btn--ghost btn--sm" type="button" data-reset>Ver todas las motos</button></div>`
        : `<div class="empty"><h3>Ningún modelo coincide</h3><p>Prueba a quitar algún filtro o a buscar otro nombre.</p><button class="btn btn--ghost btn--sm" type="button" data-reset>Quitar filtros</button></div>`;
      return;
    }
    $("grid").innerHTML = ordenar(lista).map((m, i) => {
      const b = marcaById[m.marca], o = mejorOferta(m.id);
      const pf = precioFinal(m);
      const badge = o ? (o.descuento ? `<span class="card__hot">−${eur(o.descuento)}</span>` : `<span class="card__hot card__hot--lime">${o.cuota ? fmtNum(o.cuota) + " €/MES" : "REGALO"}</span>`) : "";
      return `
      <button type="button" class="card tilt reveal" style="--brand:${b.color};--i:${i % 12};view-transition-name:${vtName("c", m.id)}" data-ficha="${esc(m.id)}" aria-label="Ficha técnica de ${esc(b.nombre)} ${esc(m.modelo)}">
        <span class="card__media">${foto(m, false)}${badge}${esFav(m.id) ? `<span class="card__fav" title="Favorita">★</span>` : ""}</span>
        <span class="card__body">
          <span class="card__brand"><i></i>${esc(b.nombre)}</span>
          <span class="card__title">${esc(m.modelo)}</span>
          <span class="card__type">${esc(m.tipo)} · Carnet ${esc(m.carnet)}</span>
          <span class="specs">
            <span class="spec"><b>${m.electrica ? "Eléc." : val(m.cc)}</b><span>${m.electrica ? "motor" : "cc"}</span></span>
            <span class="spec"><b>${val(m.cv)}</b><span>CV</span></span>
            <span class="spec"><b>${val(m.peso)}</b><span>kg</span></span>
          </span>
          <span class="card__foot">
            <span class="card__price"><small>${o && o.precioOferta != null ? "Con oferta" : "Precio desde"}</small>${o && o.precioOferta != null && m.precio && m.precio !== pf ? `<s>${eur(m.precio)}</s>` : ""}${eur(pf)}</span>
            <span class="card__cta" aria-hidden="true">→</span>
          </span>
        </span>
      </button>`;
    }).join("");
  };

  // ── Ficha técnica (cajón lateral) ───────────────────────────
  const drawer = $("drawer");
  const maximo = (k) => Math.max(...modelos.map((m) => m[k] || 0));
  const max = { cv: maximo("cv"), nm: maximo("nm"), peso: maximo("peso"), asiento: maximo("asiento") };

  const abrirFicha = (id) => {
    const m = modeloById[id]; if (!m) return;
    const b = marcaById[m.marca], os = ofertasPorModelo[id] || [], f = FOTOS[id];
    const o = os[0];
    const filas = [
      ["Tipo", m.tipo],
      ["Motor", m.electrica ? "Eléctrico" : val(m.cc, "cc")],
      ["Potencia máxima", val(m.cv, "CV")],
      ["Par máximo", val(m.nm, "Nm")],
      ["Peso", val(m.peso, "kg")],
      ["Altura del asiento", val(m.asiento, "mm")],
      ["Depósito", m.electrica ? "—" : val(m.deposito, "L")],
      ["Carnet", m.carnet === "A2" ? "A2 (o versión limitada para A2)" : m.carnet === "A1" ? "A1 / B con 3 años de antigüedad" : "A"],
      ["Precio recomendado", m.precio != null ? "desde " + eur(m.precio) : "Consultar en la web oficial"],
    ];
    const barra = (label, v, k, unit) => v == null ? "" :
      `<div class="bar"><span>${label}</span><i style="--w:${Math.max(6, (v / max[k]) * 100).toFixed(1)}%"></i><b>${fmtNum(v)} ${unit}</b></div>`;
    const precioTop = o && o.precioOferta != null
      ? `<b>${eur(o.precioOferta)}</b>${o.descuento ? `<s>${eur(o.precioOferta + o.descuento)}</s>` : ""}<small>Oferta: ${esc(o.campana)}${o.hasta ? ` · hasta el ${fechaLarga(o.hasta)}` : ""}</small>`
      : `<b>${eur(m.precio)}</b><small>${m.precio != null ? (m.precioOk ? "PVP recomendado desde, según la web oficial" : "PVP orientativo") : "La marca no publica el precio en su web"}${o && o.cuota ? ` · o ${fmtNum(o.cuota)} €/mes (${esc(o.campana)})` : ""}</small>`;

    $("drawerBody").innerHTML = `
      <button class="d-close" type="button" data-close aria-label="Cerrar ficha">✕</button>
      <div class="d-media" style="--brand:${b.color}">
        ${foto(m, true)}
        ${f ? `<span class="d-credit">Foto: <a href="${safeUrl(f.pagina)}" target="_blank" rel="noopener">${esc(f.autor || "Wikimedia Commons")}</a> · ${esc(f.licencia || "")} · Wikimedia Commons. Imagen ilustrativa.</span>` : ""}
      </div>
      <div class="d-body" style="--brand:${b.color}">
        <div class="d-kicker">${esc(b.nombre)} · ${esc(b.pais)}</div>
        <h2 class="d-title" id="dTitle">${esc(m.modelo)}</h2>
        <div class="d-price">${precioTop}</div>
        <div class="bars">
          ${barra("Potencia", m.cv, "cv", "CV")}
          ${barra("Par", m.nm, "nm", "Nm")}
          ${barra("Peso", m.peso, "peso", "kg")}
          ${barra("Asiento", m.asiento, "asiento", "mm")}
        </div>
        <table class="table"><tbody>${filas.map(([k, v]) => `<tr><th scope="row">${k}</th><td>${esc(v)}</td></tr>`).join("")}</tbody></table>
        <h3 class="d-h3">Ofertas activas (${os.length})</h3>
        ${os.length ? os.map((x) => `
          <div class="d-offer">
            <div><b>${x.descuento ? "−" + eur(x.descuento) : x.cuota ? fmtNum(x.cuota) + " €/mes" : "Regalo"}</b>${x.precioOferta != null ? ` <span style="color:var(--muted)">· ${eur(x.precioOferta)}</span>` : ""}
              <p>${esc(x.campana)}${x.regalo ? " · " + esc(x.regalo) : ""}${(x.extras || []).length ? " · " + x.extras.map(esc).join(" · ") : ""}${x.hasta ? ` · hasta el ${fechaLarga(x.hasta)}` : ""}</p>
              <div style="margin-top:8px">${estadoBadge(x)}</div></div>
            <a class="btn btn--lime btn--sm" href="${safeUrl(x.enlace)}" target="_blank" rel="noopener">Ver oferta ↗</a>
          </div>`).join("") : `<p class="note" style="margin-top:0">No hay ofertas comprobadas para este modelo ahora mismo.</p>`}
        <div class="d-actions">
          <button class="btn btn--ghost" type="button" data-fav="${esc(id)}" aria-pressed="${esFav(id)}">${esFav(id) ? "★ Guardada" : "☆ Guardar"}</button>
          <button class="btn btn--ghost" type="button" data-share="${esc(id)}">Compartir</button>
        </div>
        <div class="mr-slot"></div>
        <div class="d-actions">
          <a class="btn btn--lime" href="${urlModelo(m)}" target="_blank" rel="noopener">${m.url ? "Ficha oficial" : "Web oficial de " + esc(b.nombre)} <span aria-hidden="true">↗</span></a>
          ${b.ofertas ? `<a class="btn btn--ghost" href="${safeUrl(b.ofertas)}" target="_blank" rel="noopener">Promociones ${esc(b.nombre)}</a>` : ""}
          ${window.PAGINAS && window.PAGINAS[id] && !window.MR_APP ? `<a class="btn btn--ghost" href="${esc(window.PAGINAS[id])}">Página de esta moto</a>` : ""}
        </div>
        <p class="note">Datos según la web oficial de ${esc(b.nombre)} (revisado el ${fechaLarga(revisado)}). Pueden variar según versión y año del modelo. «—» = dato no publicado o no comprobado.</p>
      </div>`;
    if (window.MotoRadarExtras) window.MotoRadarExtras.montar($("drawerBody").querySelector(".mr-slot"), { marca: b.nombre, modelo: m.modelo });
    drawer.scrollTop = 0;
    if (!drawer.open) { drawer.classList.remove("closing"); drawer.showModal(); document.documentElement.style.overflow = "hidden"; }
    state.moto = id; syncUrl();
  };

  let cerrando = false;
  const cerrarFicha = () => {
    if (!drawer.open || cerrando) return;
    cerrando = true;
    const fin = () => { drawer.classList.remove("closing"); drawer.close(); cerrando = false; document.documentElement.style.overflow = ""; state.moto = ""; syncUrl(); };
    if (reducedMotion) return fin();
    drawer.classList.add("closing");
    setTimeout(fin, 300);
  };
  drawer.addEventListener("cancel", (e) => { e.preventDefault(); cerrarFicha(); });
  drawer.addEventListener("click", (e) => { if (e.target === drawer) cerrarFicha(); });

  // ── Render principal ────────────────────────────────────────
  const render = () => {
    const lista = filtrar();
    renderBrands();
    renderOffers(lista);
    renderGrid(lista);
    activarReveal(document);
    primerRender = false;
    syncUrl();
  };
  const renderAnimado = () => conTransicion(render);

  const reset = () => {
    Object.assign(state, { marca: "", q: "", tipo: "", carnet: "", soloOferta: false, soloFavs: false });
    $("q").value = ""; $("tipo").value = ""; $("carnet").value = ""; $("soloOferta").checked = false; $("soloFavs").checked = false;
    renderAnimado();
  };

  // ── Guardar en favoritas y compartir ────────────────────────
  const aviso = (txt) => {
    let el = document.querySelector(".toast");
    if (!el) { el = document.createElement("div"); el.className = "toast"; el.setAttribute("role", "status"); document.body.appendChild(el); }
    el.textContent = txt; el.classList.add("on");
    clearTimeout(aviso.t); aviso.t = setTimeout(() => el.classList.remove("on"), 2400);
  };
  const alternarFav = (id, boton) => {
    if (favs.has(id)) favs.delete(id); else favs.add(id);
    almacen.guardar("mr_favs", [...favs]);
    if (boton) { boton.textContent = esFav(id) ? "★ Guardada" : "☆ Guardar"; boton.setAttribute("aria-pressed", esFav(id)); }
    aviso(esFav(id) ? "Guardada en tus favoritas" : "Quitada de tus favoritas");
    render();
  };
  const compartir = async (id) => {
    const m = modeloById[id], b = marcaById[m.marca], o = mejorOferta(id);
    const base = ((window.SITIO && window.SITIO.url) || location.origin).replace(/\/$/, "");
    const url = base + "/" + ((window.PAGINAS && window.PAGINAS[id]) || "?moto=" + encodeURIComponent(id));
    const text = `${b.nombre} ${m.modelo}: ` + (o && o.precioOferta != null ? `${eur(o.precioOferta)} con oferta oficial` : `desde ${eur(m.precio)}`) + " · MotoRadar";
    const nativo = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.Share;
    try {
      if (nativo) await nativo.share({ title: `${b.nombre} ${m.modelo}`, text, url, dialogTitle: "Compartir moto" });
      else if (navigator.share) await navigator.share({ title: `${b.nombre} ${m.modelo}`, text, url });
      else { await navigator.clipboard.writeText(`${text} ${url}`); aviso("Enlace copiado"); }
    } catch (_) { /* compartir cancelado */ }
  };

  // ── Eventos ─────────────────────────────────────────────────
  const tipos = [...new Set(modelos.map((m) => m.tipo))].sort((a, b) => a.localeCompare(b, "es"));
  $("tipo").insertAdjacentHTML("beforeend", tipos.map((t) => `<option value="${esc(t)}">${esc(t)}</option>`).join(""));
  if (!tipos.includes(state.tipo)) state.tipo = "";

  $("q").value = state.q;
  $("tipo").value = state.tipo;
  $("carnet").value = state.carnet;
  $("orden").value = state.orden;
  $("soloOferta").checked = state.soloOferta;
  $("soloFavs").checked = state.soloFavs;

  let t;
  $("q").addEventListener("input", (e) => { clearTimeout(t); t = setTimeout(() => { state.q = e.target.value; render(); }, 140); });
  $("tipo").addEventListener("change", (e) => { state.tipo = e.target.value; renderAnimado(); });
  $("carnet").addEventListener("change", (e) => { state.carnet = e.target.value; renderAnimado(); });
  $("orden").addEventListener("change", (e) => { state.orden = e.target.value; renderAnimado(); });
  $("soloOferta").addEventListener("change", (e) => { state.soloOferta = e.target.checked; renderAnimado(); });
  $("soloFavs").addEventListener("change", (e) => { state.soloFavs = e.target.checked; renderAnimado(); });
  $("resetBtn").addEventListener("click", reset);

  $("brands").addEventListener("click", (e) => {
    const c = e.target.closest("[data-marca]"); if (!c) return;
    state.marca = c.dataset.marca === state.marca ? "" : c.dataset.marca;
    renderAnimado();
  });

  document.addEventListener("click", (e) => {
    const f = e.target.closest("[data-ficha]");
    if (f) return abrirFicha(f.dataset.ficha);
    const fav = e.target.closest("[data-fav]");
    if (fav) return alternarFav(fav.dataset.fav, fav);
    const sh = e.target.closest("[data-share]");
    if (sh) return compartir(sh.dataset.share);
    if (e.target.closest("[data-reset]")) return reset();
    if (e.target.closest("[data-close]")) cerrarFicha();
  });

  renderHero();
  render();
  if (state.moto) abrirFicha(state.moto);
})();
