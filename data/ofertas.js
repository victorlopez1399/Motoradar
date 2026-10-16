/*
 * Ofertas MANUALES: solo las de marcas cuya web no se puede leer automáticamente
 * (Ducati, Yamaha, Aprilia, CFMoto).
 *
 * Las de Honda, Kawasaki, Suzuki, KTM y BMW se actualizan solas cada día con
 * scripts/actualizar.ps1 y se guardan en data/auto.js: no hace falta tocarlas aquí
 * (si se añaden aquí, data/auto.js las sustituye por las vigentes).
 *
 * Campos:
 *   id            único
 *   modelo        id del modelo (data/catalogo.js)
 *   campana       nombre de la campaña
 *   descuento     euros de ahorro, o null
 *   precioOferta  precio final con la promoción, o null
 *   cuota         euros al mes si la promoción es de financiación, o null
 *   regalo        texto del regalo si la promoción es un regalo, o null
 *   extras        otras ventajas o condiciones importantes
 *   hasta         fecha de fin "AAAA-MM-DD"; null si la marca no la publica.
 *                 Pasada la fecha, la oferta se oculta sola.
 *   estado        "confirmada"    → leída directamente en la web oficial
 *                 "por-confirmar" → publicada por la marca, pero no hemos podido abrir la página
 *   enlace        página oficial de la oferta
 *   revisada      fecha de la última comprobación "AAAA-MM-DD"
 */
window.OFERTAS = [
  // ───── Ducati · promociones (ducati.com no permite la lectura automática) ─────
  {
    id: "ducati-multistradav4-campana", modelo: "ducati-multistradav4", campana: "Promoción Multistrada V4",
    descuento: 2500, precioOferta: 20290, cuota: null, regalo: null,
    extras: ["Península y Baleares"],
    hasta: "2026-10-31", estado: "por-confirmar",
    enlace: "https://www.ducati.com/es/es/editorial/promociones/promocion-multistrada-v4", revisada: "2026-10-16"
  },
  {
    id: "ducati-desertx-campana", modelo: "ducati-desertx", campana: "Promoción DesertX",
    descuento: 1000, precioOferta: 16590, cuota: null, regalo: null,
    extras: [],
    hasta: null, estado: "por-confirmar",
    enlace: "https://www.ducati.com/es/es/editorial/promociones", revisada: "2026-10-16"
  }
];
