/*
 * CONFIGURACIÓN DEL SITIO — el único archivo que necesitas editar para conectar servicios.
 * Edítalo en GitHub (lápiz ✎). Al guardar, la web se regenera y publica sola en 1–2 minutos.
 * Deja un campo vacío ("") para desactivar esa función. Guía paso a paso: MONETIZAR.md
 */
window.SITIO = {
  // Dirección pública de la web, sin barra final. Cámbiala si compras un dominio propio.
  url: "https://victorlopez1399.github.io/Motoradar",
  nombre: "MotoRadar",

  // Google Search Console y Bing Webmaster Tools: solo el código "content" de su etiqueta meta
  googleVerificacion: "",
  bingVerificacion: "",

  // Analítica sin cookies (no necesita banner): rellena UNA de las dos
  goatcounter: "",          // ej. "https://motoradar.goatcounter.com/count"
  cloudflareAnalytics: "",  // token de Cloudflare Web Analytics

  // Google AdSense: tu ID de editor, ej. "ca-pub-1234567890123456"
  adsense: "",

  // Canal de Telegram con las ofertas nuevas, ej. "https://t.me/motoradar_ofertas"
  telegram: "",

  // Formulario "Pedir esta oferta" (leads): dirección del formulario de Formspree, ej. "https://formspree.io/f/abcdwxyz"
  leads: "",

  // Enlaces de afiliado que se muestran en cada ficha (marcados como publicidad).
  // {modelo} y {marca} se sustituyen por la moto que se está viendo.
  afiliados: [
    // { titulo: "Calcula tu seguro", texto: "Compara precios de seguro para la {marca} {modelo}", url: "https://..." },
    // { titulo: "Casco y equipación", texto: "Ofertas en cascos y chaquetas", url: "https://..." }
  ],

  // Datos legales obligatorios en España (LSSI) si la web tiene publicidad, afiliados o formularios
  titular: {
    nombre: "",     // nombre y apellidos o razón social
    nif: "",        // NIF / NIE / CIF
    email: "",      // correo de contacto
    direccion: ""   // domicilio (puede ser profesional)
  }
};
