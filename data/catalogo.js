/*
 * Catálogo de marcas y modelos a la venta en España.
 * Revisado contra las webs oficiales el 16/10/2026.
 *
 * Campos de cada modelo:
 *   cc, cv, nm      cilindrada, potencia (CV) y par (Nm)
 *   peso            kg (en orden de marcha o en vacío, según publica cada marca)
 *   asiento         altura del asiento en mm
 *   deposito        litros
 *   carnet          A1 | A2 | A  (A2 = apta o con versión limitada para A2)
 *   precio          PVP recomendado "desde" en euros; null = la marca no lo publica
 *   precioOk        true si el precio se ha comprobado en la web oficial
 *   url             página oficial del modelo; si falta, se enlaza la web de la marca
 *   null en cualquier dato = no publicado o no comprobado (se muestra "—")
 *
 * Para añadir un modelo: copia una línea y cambia sus valores.
 * El `id` debe ser único: lo usan data/ofertas.js y data/fotos.js.
 */
window.CATALOGO = {
  revisado: "2026-10-16",

  marcas: [
    { id: "honda", nombre: "Honda", pais: "Japón", color: "#e40521", web: "https://www.honda.es/motorcycles.html", ofertas: "https://www.honda.es/motorcycles/range/offers/ofertas-honda.html" },
    { id: "yamaha", nombre: "Yamaha", pais: "Japón", color: "#3d5ccc", web: "https://www.yamaha-motor.eu/es/es/" },
    { id: "kawasaki", nombre: "Kawasaki", pais: "Japón", color: "#6cc24a", web: "https://www.kawasaki.es/", ofertas: "https://www.kawasaki.es/es_es/kawa-go----promociones.html" },
    { id: "suzuki", nombre: "Suzuki", pais: "Japón", color: "#2f6fd6", web: "https://moto.suzuki.es/", ofertas: "https://moto.suzuki.es/promociones" },
    { id: "bmw", nombre: "BMW Motorrad", pais: "Alemania", color: "#1c8cff", web: "https://www.bmw-motorrad.es/es/models/modeloverview.html" },
    { id: "ktm", nombre: "KTM", pais: "Austria", color: "#ff6a00", web: "https://www.ktm.com/es-es.html" },
    { id: "ducati", nombre: "Ducati", pais: "Italia", color: "#e3000f", web: "https://www.ducati.com/es/es/home", ofertas: "https://www.ducati.com/es/es/editorial/promociones" },
    { id: "triumph", nombre: "Triumph", pais: "Reino Unido", color: "#b9b9b9", web: "https://www.triumphmotorcycles.es/" },
    { id: "harley", nombre: "Harley-Davidson", pais: "EE. UU.", color: "#f26f21", web: "https://www.harley-davidson.com/es/es/motorcycles/index.html" },
    { id: "aprilia", nombre: "Aprilia", pais: "Italia", color: "#9b5cff", web: "https://www.aprilia.com/es_ES/" },
    { id: "royalenfield", nombre: "Royal Enfield", pais: "India", color: "#c8a45c", web: "https://www.royalenfield.com/es/es/motorcycles/" },
    { id: "cfmoto", nombre: "CFMoto", pais: "China", color: "#00b8c8", web: "https://www.cfmoto.com/global" }
  ],

  modelos: [
    // ───── Honda ─────
    { id: "honda-cb125r", marca: "honda", modelo: "CB125R", tipo: "Naked", cc: 125, cv: 15, nm: 11.6, peso: 130, asiento: 816, deposito: 10.1, carnet: "A1", precio: null, url: "https://www.honda.es/motorcycles/range/street/cb125r/overview.html" },
    { id: "honda-pcx125", marca: "honda", modelo: "PCX125", tipo: "Scooter", cc: 125, cv: 12.5, nm: 11.7, peso: 130, asiento: 763, deposito: 8.1, carnet: "A1", precio: 3449, precioOk: true, url: "https://www.honda.es/motorcycles/range/scooter/pcx-125/overview.html" },
    { id: "honda-shmode", marca: "honda", modelo: "SH Mode 125", tipo: "Scooter", cc: 125, cv: 11.7, nm: 12, peso: null, asiento: 765, deposito: 5.5, carnet: "A1", precio: 2750, precioOk: true, url: "https://www.honda.es/motorcycles/range/scooter/sh-mode-125/overview.html" },
    { id: "honda-forza125", marca: "honda", modelo: "Forza 125", tipo: "Scooter", cc: 125, cv: 15, nm: 12.3, peso: 164, asiento: 780, deposito: 11.5, carnet: "A1", precio: 5600, precioOk: true, url: "https://www.honda.es/motorcycles/range/scooter/forza-125/overview.html" },
    { id: "honda-cb500hornet", marca: "honda", modelo: "CB500 Hornet", tipo: "Naked", cc: 471, cv: 47, nm: 43, peso: 191, asiento: 785, deposito: 17.1, carnet: "A2", precio: 6850, precioOk: true, url: "https://www.honda.es/motorcycles/range/street/cb500-hornet/overview.html" },
    { id: "honda-nx500", marca: "honda", modelo: "NX500", tipo: "Trail", cc: 471, cv: 47, nm: 43, peso: 199, asiento: 830, deposito: 17.5, carnet: "A2", precio: 7425, precioOk: true, url: "https://www.honda.es/motorcycles/range/adventure/nx500/overview.html" },
    { id: "honda-rebel500", marca: "honda", modelo: "CMX500 Rebel", tipo: "Custom", cc: 471, cv: 46, nm: 43.3, peso: 191, asiento: 690, deposito: 11.2, carnet: "A2", precio: 6450, precioOk: true, url: "https://www.honda.es/motorcycles/range/street/cmx500-rebel/overview.html" },
    { id: "honda-cbr650r", marca: "honda", modelo: "CBR650R E-Clutch", tipo: "Deportiva", cc: 649, cv: 95, nm: 63, peso: 211, asiento: 810, deposito: 15.4, carnet: "A2", precio: 10650, precioOk: true, url: "https://www.honda.es/motorcycles/range/super-sport/cbr650r/overview.html" },
    { id: "honda-cb750hornet", marca: "honda", modelo: "CB750 Hornet", tipo: "Naked", cc: 755, cv: 91.8, nm: 75, peso: 196, asiento: 795, deposito: 15.2, carnet: "A2", precio: 8350, precioOk: true, url: "https://www.honda.es/motorcycles/range/street/hornet/overview.html" },
    { id: "honda-transalp", marca: "honda", modelo: "XL750 Transalp", tipo: "Trail", cc: 755, cv: 91.8, nm: 75, peso: 216, asiento: 850, deposito: 16.9, carnet: "A2", precio: 9990, precioOk: true, url: "https://www.honda.es/motorcycles/range/adventure/xl750_transalp/overview.html" },
    { id: "honda-xadv", marca: "honda", modelo: "X-ADV", tipo: "Scooter", cc: 745, cv: 59, nm: 69, peso: 237, asiento: 820, deposito: 13.2, carnet: "A2", precio: 13500, precioOk: true, url: "https://www.honda.es/motorcycles/range/adventure/x-adv/overview.html" },
    { id: "honda-forza750", marca: "honda", modelo: "Forza 750", tipo: "Scooter", cc: 745, cv: 59, nm: 69, peso: null, asiento: 790, deposito: 13.2, carnet: "A2", precio: 12490, precioOk: true, url: "https://www.honda.es/motorcycles/range/scooter/forza-750/overview.html" },
    { id: "honda-cb1000hornet", marca: "honda", modelo: "CB1000 Hornet", tipo: "Naked", cc: 1000, cv: 157, nm: 107, peso: 212, asiento: 809, deposito: 17, carnet: "A", precio: 11190, precioOk: true, url: "https://www.honda.es/motorcycles/range/street/cb1000-hornet/overview.html" },
    { id: "honda-africatwin", marca: "honda", modelo: "CRF1100L Africa Twin", tipo: "Trail", cc: 1084, cv: 102, nm: 112, peso: 231, asiento: 850, deposito: 18.8, carnet: "A", precio: 15975, precioOk: true, url: "https://www.honda.es/motorcycles/range/adventure/crf1100l-africa-twin/overview.html" },
    { id: "honda-nt1100", marca: "honda", modelo: "NT1100", tipo: "Touring", cc: 1084, cv: 102, nm: 112, peso: 238, asiento: 820, deposito: 20.4, carnet: "A", precio: 15700, precioOk: true, url: "https://www.honda.es/motorcycles/range/touring/nt1100/overview.html" },

    // ───── Yamaha ─────
    { id: "yamaha-nmax125", marca: "yamaha", modelo: "NMAX 125", tipo: "Scooter", cc: 125, cv: 12.2, nm: 11.2, peso: 132, asiento: 765, deposito: 7.1, carnet: "A1", precio: 3599, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/scooters/sport/pdp/nmax-125/" },
    { id: "yamaha-mt125", marca: "yamaha", modelo: "MT-125", tipo: "Naked", cc: 125, cv: 15, nm: 11.5, peso: 142, asiento: 810, deposito: 10, carnet: "A1", precio: 5499, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/motorcycles/125cc/pdp/mt-125/" },
    { id: "yamaha-xmax300", marca: "yamaha", modelo: "XMAX 300", tipo: "Scooter", cc: 292, cv: 28, nm: 29, peso: 180, asiento: 795, deposito: 13, carnet: "A2", precio: 6499, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/scooters/sport/pdp/xmax-300/" },
    { id: "yamaha-tmax", marca: "yamaha", modelo: "TMAX", tipo: "Scooter", cc: 562, cv: 47.6, nm: 55.7, peso: 220, asiento: 800, deposito: 15, carnet: "A2", precio: 14299, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/scooters/sport/pdp/tmax/" },
    { id: "yamaha-mt07", marca: "yamaha", modelo: "MT-07", tipo: "Naked", cc: 690, cv: 73.4, nm: 67, peso: 183, asiento: 805, deposito: 14, carnet: "A2", precio: 8299, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/motorcycles/hyper-naked/pdp/mt-07/" },
    { id: "yamaha-xsr700", marca: "yamaha", modelo: "XSR700", tipo: "Retro", cc: 689, cv: 73.4, nm: 67, peso: 187, asiento: 835, deposito: 14, carnet: "A2", precio: 8499, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/motorcycles/sport-heritage/pdp/xsr700/" },
    { id: "yamaha-r7", marca: "yamaha", modelo: "R7", tipo: "Deportiva", cc: 689, cv: 73.4, nm: 67, peso: 188, asiento: 835, deposito: 13, carnet: "A2", precio: 10499, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/motorcycles/supersport/pdp/r7/" },
    { id: "yamaha-tenere700", marca: "yamaha", modelo: "Ténéré 700", tipo: "Trail", cc: 689, cv: 73.4, nm: 68, peso: 205, asiento: 875, deposito: 16, carnet: "A2", precio: null, url: "https://www.yamaha-motor.eu/es/es/motorcycles/adventure/pdp/t-n-r-700/" },
    { id: "yamaha-mt09", marca: "yamaha", modelo: "MT-09", tipo: "Naked", cc: 890, cv: 119, nm: 93, peso: 193, asiento: 825, deposito: 14, carnet: "A", precio: null, url: "https://www.yamaha-motor.eu/es/es/motorcycles/hyper-naked/pdp/mt-09/" },
    { id: "yamaha-tracer9", marca: "yamaha", modelo: "Tracer 9", tipo: "Touring", cc: 890, cv: 119, nm: 93, peso: 213, asiento: 810, deposito: 19, carnet: "A", precio: 12799, precioOk: true, url: "https://www.yamaha-motor.eu/es/es/motorcycles/sport-touring/pdp/tracer-9/" },

    // ───── Kawasaki ─────
    { id: "kawasaki-z500", marca: "kawasaki", modelo: "Z500", tipo: "Naked", cc: 451, cv: 45, nm: 42.6, peso: 167, asiento: 785, deposito: 14, carnet: "A2", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Supernaked/Z500_2026.html" },
    { id: "kawasaki-ninja500", marca: "kawasaki", modelo: "Ninja 500", tipo: "Deportiva", cc: 451, cv: 45, nm: 42.6, peso: 171, asiento: 785, deposito: 14, carnet: "A2", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Supersport_Sport/Ninja_500_2026.html" },
    { id: "kawasaki-kle500", marca: "kawasaki", modelo: "KLE500", tipo: "Trail", cc: 451, cv: 45, nm: 42.6, peso: 194, asiento: 870, deposito: 16, carnet: "A2", precio: 6500, precioOk: true, url: "https://www.kawasaki.es/es_es/Motorcycles/Adventure/KLE500_2026.html" },
    { id: "kawasaki-z650s", marca: "kawasaki", modelo: "Z650S", tipo: "Naked", cc: 649, cv: 68, nm: 64, peso: 190, asiento: 805, deposito: 15, carnet: "A2", precio: 7875, precioOk: true, url: "https://www.kawasaki.es/es_es/Motorcycles/Supernaked/Z650_S_2026.html" },
    { id: "kawasaki-ninja650", marca: "kawasaki", modelo: "Ninja 650", tipo: "Deportiva", cc: 649, cv: 68, nm: 64, peso: 194, asiento: 785, deposito: 15, carnet: "A2", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Supersport_Sport/Ninja_650_2027.html" },
    { id: "kawasaki-versys650", marca: "kawasaki", modelo: "Versys 650", tipo: "Trail", cc: 649, cv: 67, nm: 61, peso: 219, asiento: 845, deposito: 21, carnet: "A2", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Adventure_Tourer/Versys_650_2027.html" },
    { id: "kawasaki-z900", marca: "kawasaki", modelo: "Z900", tipo: "Naked", cc: 948, cv: 124, nm: 97.4, peso: 213, asiento: 830, deposito: 17, carnet: "A2", precio: 10425, precioOk: true, url: "https://www.kawasaki.es/es_es/Motorcycles/Supernaked/Z900_2027.html" },
    { id: "kawasaki-z900rs", marca: "kawasaki", modelo: "Z900RS", tipo: "Retro", cc: 948, cv: 116, nm: 98, peso: 216, asiento: 835, deposito: 17, carnet: "A2", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Retro_Sport/Z900RS_2026.html" },
    { id: "kawasaki-zx6r", marca: "kawasaki", modelo: "Ninja ZX-6R", tipo: "Deportiva", cc: 636, cv: 124, nm: 69, peso: 198, asiento: 830, deposito: 17, carnet: "A", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Supersport_Sport/Ninja_ZX-6R_2027.html" },
    { id: "kawasaki-versys1100", marca: "kawasaki", modelo: "Versys 1100", tipo: "Touring", cc: 1099, cv: 135, nm: 112, peso: 255, asiento: 840, deposito: 21, carnet: "A", precio: null, url: "https://www.kawasaki.es/es_es/Motorcycles/Adventure_Tourer/Versys_1100_2026.html" },

    // ───── Suzuki ─────
    { id: "suzuki-burgman400", marca: "suzuki", modelo: "Burgman 400", tipo: "Scooter", cc: 400, cv: 29, nm: 36, peso: 218, asiento: 755, deposito: 13.5, carnet: "A2", precio: 6999, precioOk: true, url: "https://moto.suzuki.es/motos/scooter/2027/burgman-400" },
    { id: "suzuki-gsx8s", marca: "suzuki", modelo: "GSX-8S", tipo: "Naked", cc: 776, cv: 82, nm: 78, peso: 202, asiento: 810, deposito: 14, carnet: "A2", precio: 7999, precioOk: true, url: "https://moto.suzuki.es/motos/carretera/2027/gsx-8s" },
    { id: "suzuki-gsx8r", marca: "suzuki", modelo: "GSX-8R", tipo: "Deportiva", cc: 776, cv: 82, nm: 78, peso: 205, asiento: 810, deposito: 14, carnet: "A", precio: 9999, precioOk: true, url: "https://moto.suzuki.es/motos/deportivas/2027/gsx-8r" },
    { id: "suzuki-vstrom800de", marca: "suzuki", modelo: "V-Strom 800DE", tipo: "Trail", cc: 776, cv: 83, nm: 78, peso: 230, asiento: 855, deposito: 20, carnet: "A2", precio: 10499, precioOk: true, url: "https://moto.suzuki.es/motos/trail-sport-turismo/2027/v-strom-800DE" },
    { id: "suzuki-gsxs1000", marca: "suzuki", modelo: "GSX-S1000", tipo: "Naked", cc: 999, cv: 152, nm: 106, peso: 214, asiento: 810, deposito: 19, carnet: "A", precio: 12999, precioOk: true, url: "https://moto.suzuki.es/motos/carretera/2027/gsx-s1000" },
    { id: "suzuki-hayabusa", marca: "suzuki", modelo: "Hayabusa Edición Especial", tipo: "Deportiva", cc: 1340, cv: 190, nm: 150, peso: 264, asiento: 800, deposito: 20, carnet: "A", precio: 22499, precioOk: true, url: "https://moto.suzuki.es/motos/deportivas/2027/hayabusa-edicion-especial" },

    // ───── BMW Motorrad ─────
    { id: "bmw-f450r", marca: "bmw", modelo: "F 450 R", tipo: "Naked", cc: 420, cv: 48, nm: 43, peso: null, asiento: null, deposito: null, carnet: "A2", precio: 6799, precioOk: true, url: "https://www.bmw-motorrad.es/es/models/roadster/f450r.html" },
    { id: "bmw-ce04", marca: "bmw", modelo: "CE 04", tipo: "Scooter", cc: null, cv: 42, nm: 62, peso: 231, asiento: 780, deposito: null, carnet: "A2", precio: 12260, precioOk: true, electrica: true, url: "https://www.bmw-motorrad.es/es/models/urban_mobility/ce04.html" },
    { id: "bmw-f900r", marca: "bmw", modelo: "F 900 R", tipo: "Naked", cc: 895, cv: 105, nm: 93, peso: 211, asiento: 815, deposito: 13, carnet: "A2", precio: 9960, precioOk: true, url: "https://www.bmw-motorrad.es/es/models/roadster/f900r.html" },
    { id: "bmw-f900gs", marca: "bmw", modelo: "F 900 GS", tipo: "Trail", cc: 895, cv: 105, nm: 93, peso: 219, asiento: 870, deposito: 14.5, carnet: "A", precio: 14210, precioOk: true, url: "https://www.bmw-motorrad.es/es/models/adventure/f900gs.html" },
    { id: "bmw-r12ninet", marca: "bmw", modelo: "R 12 nineT", tipo: "Retro", cc: 1170, cv: 109, nm: 115, peso: 220, asiento: 795, deposito: 16, carnet: "A", precio: 18250, precioOk: true, url: "https://www.bmw-motorrad.es/es/models/heritage/r12-ninet.html" },
    { id: "bmw-r1300gs", marca: "bmw", modelo: "R 1300 GS", tipo: "Trail", cc: 1300, cv: 145, nm: 149, peso: 237, asiento: 850, deposito: 19, carnet: "A", precio: 22230, precioOk: true, url: "https://www.bmw-motorrad.es/es/models/adventure/r1300gs.html" },
    { id: "bmw-s1000rr", marca: "bmw", modelo: "S 1000 RR", tipo: "Deportiva", cc: 999, cv: 210, nm: 113, peso: 197, asiento: 832, deposito: 16.5, carnet: "A", precio: 24430, precioOk: true, url: "https://www.bmw-motorrad.es/es/models/sport/s1000rr.html" },

    // ───── KTM ─────
    { id: "ktm-125duke", marca: "ktm", modelo: "125 Duke", tipo: "Naked", cc: 125, cv: 15, nm: 11.5, peso: null, asiento: 800, deposito: 15, carnet: "A1", precio: 5299, precioOk: true, url: "https://www.ktm.com/es-es/models/naked-bike/2026-ktm-125-duke.html" },
    { id: "ktm-390duke", marca: "ktm", modelo: "390 Duke", tipo: "Naked", cc: 399, cv: 45, nm: 39, peso: 165, asiento: 820, deposito: 15, carnet: "A2", precio: 6099, precioOk: true, url: "https://www.ktm.com/es-es/models/naked-bike/2026-ktm-390-duke.html" },
    { id: "ktm-390adventure", marca: "ktm", modelo: "390 Adventure R", tipo: "Trail", cc: 399, cv: 45, nm: 39, peso: null, asiento: null, deposito: null, carnet: "A2", precio: 6999, precioOk: true, url: "https://www.ktm.com/es-es/models/adventure/2026-ktm-390-adventurer.html" },
    { id: "ktm-790duke", marca: "ktm", modelo: "790 Duke", tipo: "Naked", cc: 799, cv: 105, nm: 87, peso: null, asiento: null, deposito: null, carnet: "A2", precio: 8799, precioOk: true, url: "https://www.ktm.com/es-es/models/naked-bike/2027-ktm-790-duke.html" },
    { id: "ktm-990duke", marca: "ktm", modelo: "990 Duke", tipo: "Naked", cc: 947, cv: 123, nm: 103, peso: null, asiento: null, deposito: 14.8, carnet: "A", precio: 13699, precioOk: true, url: "https://www.ktm.com/es-es/models/naked-bike/2026-ktm-990-duke.html" },
    { id: "ktm-890adventure", marca: "ktm", modelo: "890 Adventure R", tipo: "Trail", cc: 889, cv: 105, nm: 100, peso: null, asiento: null, deposito: 20, carnet: "A", precio: 15299, precioOk: true, url: "https://www.ktm.com/es-es/models/adventure/2026-ktm-890-adventurer.html" },
    { id: "ktm-1390superduke", marca: "ktm", modelo: "1390 Super Duke R", tipo: "Naked", cc: 1350, cv: 190, nm: 145, peso: null, asiento: null, deposito: 17.5, carnet: "A", precio: 22499, precioOk: true, url: "https://www.ktm.com/es-es/models/naked-bike/2026-ktm-1390-superduker.html" },

    // ───── Ducati ─────
    { id: "ducati-scrambler", marca: "ducati", modelo: "Scrambler Icon", tipo: "Retro", cc: 803, cv: 73, nm: 65.2, peso: 185, asiento: 795, deposito: 13.5, carnet: "A2", precio: null, url: "https://www.ducati.com/es/es/motocicletas/scrambler" },
    { id: "ducati-monster", marca: "ducati", modelo: "Monster", tipo: "Naked", cc: 890, cv: 111, nm: 91, peso: 175, asiento: null, deposito: 14, carnet: "A", precio: 13190, precioOk: true, url: "https://www.ducati.com/es/es/motocicletas/monster/monster-v2" },
    { id: "ducati-panigalev2", marca: "ducati", modelo: "Panigale V2", tipo: "Deportiva", cc: 890, cv: 120, nm: 93, peso: 179, asiento: null, deposito: 15, carnet: "A", precio: 17990, precioOk: true, url: "https://www.ducati.com/es/es/motocicletas/panigale/panigale-v2" },
    { id: "ducati-multistradav2", marca: "ducati", modelo: "Multistrada V2", tipo: "Trail", cc: 890, cv: 115, nm: 92.1, peso: 199, asiento: 830, deposito: 19, carnet: "A", precio: 17190, precioOk: true, url: "https://www.ducati.com/es/es/motocicletas/multistrada/multistrada-v2" },
    { id: "ducati-desertx", marca: "ducati", modelo: "DesertX", tipo: "Trail", cc: 937, cv: 110, nm: 92, peso: 223, asiento: 875, deposito: 21, carnet: "A", precio: 17590, precioOk: true },
    { id: "ducati-multistradav4", marca: "ducati", modelo: "Multistrada V4", tipo: "Touring", cc: 1158, cv: 170, nm: 124, peso: null, asiento: null, deposito: 22, carnet: "A", precio: 22790, precioOk: true, url: "https://www.ducati.com/es/es/motocicletas/multistrada/multistrada-v4" },
    { id: "ducati-diavelv4", marca: "ducati", modelo: "Diavel V4", tipo: "Custom", cc: 1158, cv: 168, nm: 126, peso: 223, asiento: 790, deposito: 20, carnet: "A", precio: 31090, precioOk: true, url: "https://www.ducati.com/es/es/motocicletas/diavel/diavel-v4" },

    // ───── Triumph ─────
    { id: "triumph-speed400", marca: "triumph", modelo: "Speed 400", tipo: "Retro", cc: 398, cv: 40, nm: 37.5, peso: 170, asiento: 790, deposito: 13, carnet: "A2", precio: 5645, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/classic/speed-400" },
    { id: "triumph-scrambler400x", marca: "triumph", modelo: "Scrambler 400 X", tipo: "Retro", cc: 398, cv: 40, nm: 37.5, peso: 179, asiento: 835, deposito: 13, carnet: "A2", precio: 6345, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/classic/scrambler-400-x" },
    { id: "triumph-trident660", marca: "triumph", modelo: "Trident 660", tipo: "Naked", cc: 660, cv: 81, nm: 64, peso: 190, asiento: 805, deposito: 14, carnet: "A2", precio: 8595, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/roadsters/trident" },
    { id: "triumph-tigersport660", marca: "triumph", modelo: "Tiger Sport 660", tipo: "Touring", cc: 660, cv: 81, nm: 64, peso: 207, asiento: 835, deposito: 17.2, carnet: "A2", precio: 9695, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/adventure/tiger-sport-660" },
    { id: "triumph-streettriple", marca: "triumph", modelo: "Street Triple 765 R", tipo: "Naked", cc: 765, cv: 120, nm: 80, peso: 189, asiento: 826, deposito: 15, carnet: "A2", precio: 11095, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/roadsters/street-triple-765" },
    { id: "triumph-tiger900", marca: "triumph", modelo: "Tiger 900 GT", tipo: "Trail", cc: 888, cv: 108, nm: 90, peso: 222, asiento: 820, deposito: 20, carnet: "A2", precio: 14395, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/adventure/tiger-900" },
    { id: "triumph-speedtwin1200", marca: "triumph", modelo: "Speed Twin 1200", tipo: "Retro", cc: 1200, cv: 105, nm: 112, peso: null, asiento: 805, deposito: 14.5, carnet: "A", precio: 15695, precioOk: true, url: "https://www.triumphmotorcycles.es/bikes/classic/bonneville-speed-twin-1200" },

    // ───── Harley-Davidson ─────
    { id: "harley-nightster", marca: "harley", modelo: "Nightster", tipo: "Custom", cc: 975, cv: 89, nm: 95, peso: 220, asiento: 705, deposito: 11.7, carnet: "A", precio: 12300, precioOk: true, url: "https://www.harley-davidson.com/es/es/motorcycles/nightster.html" },
    { id: "harley-sportsters", marca: "harley", modelo: "Sportster S", tipo: "Custom", cc: 1252, cv: 121, nm: 125, peso: 228, asiento: 765, deposito: 11.8, carnet: "A", precio: 17800, precioOk: true, url: "https://www.harley-davidson.com/es/es/motorcycles/sportster-s.html" },
    { id: "harley-streetbob", marca: "harley", modelo: "Street Bob", tipo: "Custom", cc: 1923, cv: 91, nm: 156, peso: 293, asiento: 680, deposito: 13.2, carnet: "A", precio: 17900, precioOk: true, url: "https://www.harley-davidson.com/es/es/motorcycles/street-bob.html" },
    { id: "harley-panamerica", marca: "harley", modelo: "Pan America 1250 Special", tipo: "Trail", cc: 1252, cv: 150, nm: 128, peso: 258, asiento: 850, deposito: 21.2, carnet: "A", precio: 22400, precioOk: true, url: "https://www.harley-davidson.com/es/es/motorcycles/pan-america-1250-special.html" },

    // ───── Aprilia ─────
    { id: "aprilia-rs457", marca: "aprilia", modelo: "RS 457", tipo: "Deportiva", cc: 457, cv: 47.6, nm: 43.5, peso: 175, asiento: 800, deposito: 12.7, carnet: "A2", precio: null, url: "https://www.aprilia.com/es_ES/models/rs-457/rs-457-457-parallel-twin-4-stroke-2026/" },
    { id: "aprilia-tuono457", marca: "aprilia", modelo: "Tuono 457", tipo: "Naked", cc: 457, cv: 47.6, nm: 43.5, peso: null, asiento: null, deposito: 12.7, carnet: "A2", precio: null, url: "https://www.aprilia.com/es_ES/models/tuono-457/tuono-457-457-parallel-twin-4-stroke-2025/" },
    { id: "aprilia-rs660", marca: "aprilia", modelo: "RS 660", tipo: "Deportiva", cc: 659, cv: 105, nm: 67, peso: 183, asiento: 820, deposito: 15, carnet: "A2", precio: null },
    { id: "aprilia-tuareg660", marca: "aprilia", modelo: "Tuareg 660", tipo: "Trail", cc: 659, cv: 80, nm: 70, peso: 204, asiento: 860, deposito: 18, carnet: "A", precio: null },
    { id: "aprilia-tuonov4", marca: "aprilia", modelo: "Tuono V4", tipo: "Naked", cc: 1099, cv: 180, nm: null, peso: null, asiento: null, deposito: null, carnet: "A", precio: null },

    // ───── Royal Enfield ─────
    { id: "re-hunter350", marca: "royalenfield", modelo: "HNTR 350", tipo: "Retro", cc: 349, cv: 20.2, nm: 27, peso: 181, asiento: 790, deposito: 13, carnet: "A2", precio: null, url: "https://www.royalenfield.com/es/es/motorcycles/hntr-350/" },
    { id: "re-classic350", marca: "royalenfield", modelo: "Classic 350", tipo: "Retro", cc: 349, cv: 20.2, nm: 27, peso: 195, asiento: 805, deposito: 13, carnet: "A2", precio: 4887, precioOk: true, url: "https://www.royalenfield.com/es/es/motorcycles/classic-350/" },
    { id: "re-himalayan450", marca: "royalenfield", modelo: "Himalayan 450", tipo: "Trail", cc: 452, cv: 40, nm: 40, peso: 196, asiento: 825, deposito: 17, carnet: "A2", precio: 5887, precioOk: true, url: "https://www.royalenfield.com/es/es/motorcycles/new-himalayan/" },
    { id: "re-interceptor650", marca: "royalenfield", modelo: "Interceptor 650", tipo: "Retro", cc: 648, cv: 47, nm: 52, peso: 218, asiento: 804, deposito: 13.7, carnet: "A2", precio: 6987, precioOk: true, url: "https://www.royalenfield.com/es/es/motorcycles/interceptor/" },
    { id: "re-continentalgt650", marca: "royalenfield", modelo: "Continental GT 650", tipo: "Retro", cc: 648, cv: 47, nm: 52, peso: 214, asiento: 804, deposito: 12.5, carnet: "A2", precio: 6987, precioOk: true, url: "https://www.royalenfield.com/es/es/motorcycles/continental-gt/" },
    { id: "re-bear650", marca: "royalenfield", modelo: "Bear 650", tipo: "Retro", cc: 648, cv: 47.4, nm: 56.5, peso: 216, asiento: 830, deposito: 13.7, carnet: "A2", precio: null, url: "https://www.royalenfield.com/es/es/motorcycles/bear-650/" },

    // ───── CFMoto ─────
    { id: "cfmoto-450sr", marca: "cfmoto", modelo: "450SR", tipo: "Deportiva", cc: 449, cv: 47, nm: 39, peso: 179, asiento: null, deposito: null, carnet: "A2", precio: null, url: "https://www.cfmoto.com/global/motorcycles/sportracing/450sr.html" },
    { id: "cfmoto-450mt", marca: "cfmoto", modelo: "450MT", tipo: "Trail", cc: 449, cv: 44, nm: 44, peso: null, asiento: 820, deposito: null, carnet: "A2", precio: null, url: "https://www.cfmoto.com/global/motorcycles/mult-touring/450mt.html" },
    { id: "cfmoto-700clx", marca: "cfmoto", modelo: "700CL-X Heritage", tipo: "Retro", cc: 693, cv: 70, nm: null, peso: null, asiento: null, deposito: 13, carnet: "A", precio: null },
    { id: "cfmoto-800mtx", marca: "cfmoto", modelo: "800MT-X", tipo: "Trail", cc: 799, cv: 95, nm: 87, peso: null, asiento: null, deposito: 22.5, carnet: "A", precio: null, url: "https://www.cfmoto.com/global/motorcycles/mult-touring/800mt-x.html" }
  ]
};
