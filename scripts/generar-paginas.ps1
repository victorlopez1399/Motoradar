#requires -Version 5.1
<#
  Genera las páginas estáticas que Google puede indexar, a partir de los datos de la web:

    moto/<modelo>/      una página por moto (ficha, precio, ofertas, datos estructurados)
    marca/<marca>/      una página por marca
    ofertas/            todas las ofertas vigentes del mes
    motos-a2/           motos para carnet A2
    motos-125/          motos de 125 cc (carnet A1 o B)
    legal/…             aviso legal, privacidad y cookies (con los datos de data/sitio.js)
    sitemap.xml, robots.txt, 404.html, og.png, data/paginas.js
    index.html          solo actualiza los bloques entre <!--MR:…--> (etiquetas SEO y enlaces)

  Se ejecuta a diario después de scripts/actualizar.ps1. No necesita conexión a Internet.
  Uso:  powershell -ExecutionPolicy Bypass -File scripts/generar-paginas.ps1
#>
param([string]$Raiz = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$Utf8 = New-Object Text.UTF8Encoding $false
$Es = [Globalization.CultureInfo]::GetCultureInfo('es-ES')
$Ahora = Get-Date
$Hoy = $Ahora.ToString('yyyy-MM-dd')
$MesAnio = $Ahora.ToString('MMMM yyyy', $Es)
$EUR = [string][char]0x20AC

# ───────────────────────── Lectura de datos ─────────────────────────

function Remove-Comentarios([string]$t) {
  $t = [regex]::Replace($t, '(?s)/\*.*?\*/', '')
  $sb = New-Object Text.StringBuilder
  foreach ($linea in ($t -split "`n")) {
    $dentro = $false; $corte = -1
    for ($i = 0; $i -lt $linea.Length - 1; $i++) {
      $c = $linea[$i]
      if ($c -eq '"' -and ($i -eq 0 -or $linea[$i - 1] -ne '\')) { $dentro = -not $dentro }
      elseif (-not $dentro -and $c -eq '/' -and $linea[$i + 1] -eq '/') { $corte = $i; break }
    }
    if ($corte -ge 0) { $linea = $linea.Substring(0, $corte) }
    [void]$sb.AppendLine($linea)
  }
  return $sb.ToString()
}

# Lee un archivo de datos "window.X = {...};" como objeto (convierte la sintaxis JS a JSON)
function Read-JsData([string]$Ruta) {
  $t = Remove-Comentarios ([IO.File]::ReadAllText($Ruta, [Text.Encoding]::UTF8))
  $m = [regex]::Match($t, 'window\.[A-Za-z_]+\s*=\s*')
  if (-not $m.Success) { throw "Formato no reconocido en $Ruta" }
  $t = $t.Substring($m.Index + $m.Length).Trim().TrimEnd(';')
  $t = [regex]::Replace($t, '([{,]\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:', '$1"$2":')
  $t = [regex]::Replace($t, ',(\s*[}\]])', '$1')
  return ($t | ConvertFrom-Json)
}

$Sitio = Read-JsData (Join-Path $Raiz 'data\sitio.js')
$Cat = Read-JsData (Join-Path $Raiz 'data\catalogo.js')
$OfManual = @(Read-JsData (Join-Path $Raiz 'data\ofertas.js'))
$Fotos = Read-JsData (Join-Path $Raiz 'data\fotos.js')
$Auto = $null
$rutaAuto = Join-Path $Raiz 'data\auto.json'
if (Test-Path $rutaAuto) { $Auto = [IO.File]::ReadAllText($rutaAuto, [Text.Encoding]::UTF8) | ConvertFrom-Json }

$Base = ([string]$Sitio.url).TrimEnd('/')
if (-not $Base) { throw 'Falta "url" en data/sitio.js' }
$Nombre = $(if ($Sitio.nombre) { [string]$Sitio.nombre } else { 'MotoRadar' })

# Mismas reglas que data/auto.js: modelos manuales + nuevos; ofertas automáticas sustituyen a las manuales de esas marcas
$Marcas = @($Cat.marcas)
$MarcaPor = @{}; foreach ($b in $Marcas) { $MarcaPor[$b.id] = $b }
$Modelos = New-Object Collections.ArrayList
$ids = @{}
foreach ($m in @($Cat.modelos)) { [void]$Modelos.Add($m); $ids[$m.id] = $true }
$autoMarcas = @{}
$autoOfertas = @()
if ($Auto) {
  foreach ($k in $Auto.marcas.PSObject.Properties.Name) {
    $e = $Auto.marcas.$k
    foreach ($m in @($e.modelos)) { if ($m -and -not $ids[$m.id]) { [void]$Modelos.Add($m); $ids[$m.id] = $true } }
    if ($e.revisado -and @($e.ofertas).Count -ge 0 -and $k -in @('honda', 'kawasaki', 'suzuki', 'ktm', 'bmw')) { $autoMarcas[$k] = $true }
    $autoOfertas += @($e.ofertas | Where-Object { $_ })
  }
}
$ModeloPor = @{}; foreach ($m in $Modelos) { $ModeloPor[$m.id] = $m }
$Ofertas = @($OfManual | Where-Object { $_ -and $ModeloPor[$_.modelo] -and -not $autoMarcas[$ModeloPor[$_.modelo].marca] }) + @($autoOfertas | Where-Object { $ModeloPor[$_.modelo] })
$Ofertas = @($Ofertas | Where-Object { -not $_.hasta -or $_.hasta -ge $Hoy })
function Get-Peso($o) { $d = 0; if ($o.descuento) { $d = [double]$o.descuento }; return $d * 10 + $(if ($o.cuota) { 1 } else { 0 }) + $(if ($o.regalo) { 1 } else { 0 }) }
$Ofertas = @($Ofertas | Sort-Object @{ e = { Get-Peso $_ }; Descending = $true })
$OfertasPor = @{}
foreach ($o in $Ofertas) { if (-not $OfertasPor.ContainsKey($o.modelo)) { $OfertasPor[$o.modelo] = @() }; $OfertasPor[$o.modelo] += $o }
Write-Host "Datos: $($Modelos.Count) modelos, $($Ofertas.Count) ofertas vigentes"

# ───────────────────────── Utilidades HTML ─────────────────────────

function Enc($s) { if ($null -eq $s) { return '' }; return ([string]$s).Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
function Remove-Tildes([string]$s) {
  if (-not $s) { return '' }
  $sb = New-Object Text.StringBuilder
  foreach ($c in $s.Normalize([Text.NormalizationForm]::FormD).ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
  }
  return $sb.ToString()
}
function Get-Slug([string]$s) { return ((Remove-Tildes $s).ToLowerInvariant() -replace '[^a-z0-9]+', '-').Trim('-') }
function Format-Num($n) {
  if ($null -eq $n) { return $null }
  $d = [double]$n
  if ($d -eq [math]::Floor($d)) { return $d.ToString('#,0', $Es) }
  return $d.ToString('#,0.#', $Es)
}
# es-ES no agrupa los números de 4 cifras; se fuerza el punto de miles como en la web
function Format-Eur($n) {
  if ($null -eq $n) { return 'Consultar' }
  $s = ([math]::Round([double]$n)).ToString('0', [Globalization.CultureInfo]::InvariantCulture)
  return ([regex]::Replace($s, '\B(?=(\d{3})+(?!\d))', '.')) + ' ' + $EUR
}
function Format-Fecha([string]$f) { return ([datetime]::ParseExact($f, 'yyyy-MM-dd', $null)).ToString('d MMM yyyy', $Es) }
function Val($n, [string]$u) { if ($null -eq $n -or $n -eq '') { return '—' }; return (Format-Num $n) + $(if ($u) { " $u" } else { '' }) }
function Get-Foto([string]$id) { $p = $Fotos.PSObject.Properties[$id]; if ($p) { return $p.Value }; return $null }
function Get-PrecioFinal($m) { $o = @($OfertasPor[$m.id])[0]; if ($o -and $null -ne $o.precioOferta) { return $o.precioOferta }; return $m.precio }
function Get-UrlOficial($m) { if ($m.url) { return $m.url }; return $MarcaPor[$m.marca].web }

# Direcciones de las páginas de cada moto (marca + nombre, sin repetir)
$Slug = @{}; $usados = @{}
foreach ($m in $Modelos) {
  $s = Get-Slug ($m.marca + ' ' + $m.modelo)
  $s2 = $s; $n = 2
  while ($usados[$s2]) { $s2 = "$s-$n"; $n++ }
  $usados[$s2] = $true; $Slug[$m.id] = $s2
}

$Generadas = New-Object Collections.ArrayList   # para el sitemap
function Write-Pagina([string]$Ruta, [string]$Html, [string]$Prioridad = '0.6') {
  $abs = Join-Path $Raiz $Ruta
  New-Item -ItemType Directory -Force (Split-Path $abs -Parent) | Out-Null
  [IO.File]::WriteAllText($abs, $Html, $Utf8)
  $url = $Base + '/' + ($Ruta -replace '\\', '/' -replace 'index\.html$', '')
  [void]$Generadas.Add([pscustomobject]@{ url = $url; prioridad = $Prioridad })
}

function New-Html {
  param([string]$Titulo, [string]$Descripcion, [string]$Ruta, [string]$Cuerpo, [object[]]$JsonLd = @(), [string]$Imagen = '', [int]$Profundidad = 2, [switch]$NoIndex)
  $pre = '../' * $Profundidad
  $canon = $Base + '/' + ($Ruta -replace 'index\.html$', '')
  $img = $(if ($Imagen) { $Imagen } else { "$Base/og.png" })
  $ld = ($JsonLd | Where-Object { $_ } | ForEach-Object { '<script type="application/ld+json">' + (ConvertTo-Json -InputObject $_ -Depth 8 -Compress) + '</script>' }) -join "`n  "
  $marcasNav = ($Marcas | ForEach-Object { "<a href=""${pre}marca/$($_.id)/"">$(Enc $_.nombre)</a>" }) -join ' · '
  return @"
<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$(Enc $Titulo)</title>
  <meta name="description" content="$(Enc $Descripcion)">
  <link rel="canonical" href="$(Enc $canon)">
  $(if ($NoIndex) { '<meta name="robots" content="noindex">' })
  <meta property="og:type" content="website">
  <meta property="og:site_name" content="$(Enc $Nombre)">
  <meta property="og:locale" content="es_ES">
  <meta property="og:title" content="$(Enc $Titulo)">
  <meta property="og:description" content="$(Enc $Descripcion)">
  <meta property="og:url" content="$(Enc $canon)">
  <meta property="og:image" content="$(Enc $img)">
  <meta name="twitter:card" content="summary_large_image">
  <meta name="theme-color" content="#07070a">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Unbounded:wght@500;700;900&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="${pre}styles.css">
  <link rel="icon" href="${pre}favicon.svg" type="image/svg+xml">
  $ld
</head>
<body class="st">
  <header class="topbar">
    <div class="wrap topbar__in">
      <a class="logo" href="${pre}" aria-label="$(Enc $Nombre), inicio"><span class="logo__mark" aria-hidden="true"></span><span>MOTO<b>RADAR</b></span></a>
      <nav class="nav" aria-label="Secciones">
        <a href="${pre}ofertas/">Ofertas</a>
        <a href="${pre}motos-a2/">Motos A2</a>
        <a href="${pre}motos-125/">Motos 125</a>
      </nav>
      <a class="btn btn--lime btn--sm topbar__cta" href="${pre}./#catalogo">Comparar motos</a>
    </div>
  </header>
  <main class="wrap st-main">
$Cuerpo
    <div data-mr-telegram></div>
  </main>
  <footer class="footer">
    <div class="wrap footer__in">
      <p class="st-marcas"><b>Marcas:</b> $marcasNav</p>
      <p><a href="${pre}legal/aviso-legal/">Aviso legal</a> · <a href="${pre}legal/privacidad/">Privacidad</a> · <a href="${pre}legal/cookies/">Cookies</a></p>
      <p>$(Enc $Nombre) es un comparador independiente, sin relación con los fabricantes. Precios y ofertas según las webs oficiales; confírmalos siempre antes de comprar. Actualizado el $(Format-Fecha $Hoy).</p>
    </div>
  </footer>
  <script src="${pre}data/sitio.js"></script>
  <script src="${pre}extras.js"></script>
</body>
</html>
"@
}

function Get-TextoOferta($o) {
  if ($o.descuento -and $null -ne $o.precioOferta) { return "−$(Format-Eur $o.descuento) · $(Format-Eur $o.precioOferta)" }
  if ($o.cuota) { return "$(Format-Num $o.cuota) $EUR/mes" }
  if ($o.regalo) { return "Regalo: $($o.regalo)" }
  return ''
}

function Get-TarjetaOferta($o, [string]$pre) {
  $m = $ModeloPor[$o.modelo]; $b = $MarcaPor[$m.marca]; $f = Get-Foto $m.id
  $img = $(if ($f) { "<img src=""$(Enc $f.thumb)"" alt=""$(Enc ($b.nombre + ' ' + $m.modelo))"" loading=""lazy"">" } else { "<span class=""st-nofoto"">$(Enc $b.nombre)</span>" })
  $hasta = $(if ($o.hasta) { "hasta el $(Format-Fecha $o.hasta)" } else { 'sin fecha de fin publicada' })
  return @"
      <article class="st-card" style="--brand:$($b.color)">
        <a class="st-card__media" href="${pre}moto/$($Slug[$m.id])/">$img</a>
        <div class="st-card__body">
          <span class="st-kicker">$(Enc $b.nombre)</span>
          <h3><a href="${pre}moto/$($Slug[$m.id])/">$(Enc $m.modelo)</a></h3>
          <p class="st-precio">$(Enc (Get-TextoOferta $o))</p>
          <p class="st-meta">$(Enc $o.campana) · $hasta</p>
          <a class="btn btn--lime btn--sm" href="$(Enc $o.enlace)" target="_blank" rel="noopener">Ver oferta oficial ↗</a>
        </div>
      </article>
"@
}

function Get-TablaModelos($lista, [string]$pre) {
  $filas = foreach ($m in ($lista | Sort-Object @{ e = { if ($null -ne $_.precio) { [double]$_.precio } else { 1e9 } } })) {
    $b = $MarcaPor[$m.marca]; $o = @($OfertasPor[$m.id])[0]
    $precio = Format-Eur (Get-PrecioFinal $m)
    $of = $(if ($o) { "<span class=""st-tag"">$(Enc (Get-TextoOferta $o))</span>" } else { '' })
    "        <tr><td><a href=""${pre}moto/$($Slug[$m.id])/"">$(Enc ($b.nombre + ' ' + $m.modelo))</a></td><td>$(Enc $m.tipo)</td><td>$(Val $m.cc 'cc')</td><td>$(Val $m.cv 'CV')</td><td>$(Enc $m.carnet)</td><td>$precio $of</td></tr>"
  }
  return @"
    <div class="st-tablewrap"><table class="table st-table">
      <thead><tr><th>Modelo</th><th>Tipo</th><th>Motor</th><th>Potencia</th><th>Carnet</th><th>Precio desde</th></tr></thead>
      <tbody>
$($filas -join "`n")
      </tbody>
    </table></div>
"@
}

function Get-Migas($items, [string]$pre) {
  $html = ($items | ForEach-Object { if ($_.url) { "<a href=""$($_.url)"">$(Enc $_.nombre)</a>" } else { "<span>$(Enc $_.nombre)</span>" } }) -join ' <span aria-hidden="true">/</span> '
  $ld = [ordered]@{ '@context' = 'https://schema.org'; '@type' = 'BreadcrumbList'; itemListElement = @() }
  $pos = 1
  foreach ($i in $items) {
    $ld.itemListElement += [ordered]@{ '@type' = 'ListItem'; position = $pos; name = $i.nombre; item = $(if ($i.abs) { $i.abs } else { $null }) }
    $pos++
  }
  return @{ html = "    <nav class=""st-crumbs"" aria-label=""Migas de pan"">$html</nav>"; ld = $ld }
}

# ───────────────────────── Páginas de cada moto ─────────────────────────

foreach ($m in $Modelos) {
  $b = $MarcaPor[$m.marca]; $s = $Slug[$m.id]; $pre = '../../'
  $f = Get-Foto $m.id
  $os = @(); if ($OfertasPor.ContainsKey($m.id)) { $os = @($OfertasPor[$m.id]) }
  $o = $(if ($os.Count) { $os[0] } else { $null })
  $nombreCompleto = "$($b.nombre) $($m.modelo)"
  $pf = Get-PrecioFinal $m
  $titulo = "${nombreCompleto}: precio, ficha técnica y ofertas ($MesAnio)"
  $partes = @()
  if ($m.cc) { $partes += "$(Format-Num $m.cc) cc" } elseif ($m.electrica) { $partes += 'motor eléctrico' }
  if ($m.cv) { $partes += "$(Format-Num $m.cv) CV" }
  $desc = "$nombreCompleto" + $(if ($partes) { " (" + ($partes -join ', ') + ")" } else { '' }) + ". " +
    $(if ($o) { "Oferta: $(Get-TextoOferta $o). " } elseif ($null -ne $m.precio) { "Precio desde $(Format-Eur $m.precio). " } else { '' }) +
    "Ficha técnica, carnet $($m.carnet) y enlace a la web oficial."
  $intro = "La $nombreCompleto es una moto de tipo $($m.tipo.ToLower())" +
    $(if ($partes) { " de " + ($partes -join ' y ') } else { '' }) +
    ", apta para carnet $($m.carnet)." +
    $(if ($null -ne $m.precio) { " Su precio recomendado en España es desde $(Format-Eur $m.precio)." } else { " La marca no publica su precio en la web." }) +
    $(if ($o -and $null -ne $o.precioOferta) { " Ahora mismo tiene una oferta oficial por $(Format-Eur $o.precioOferta)." } elseif ($o -and $o.cuota) { " Ahora mismo se puede financiar desde $(Format-Num $o.cuota) $EUR al mes." } else { '' })
  $datos = [ordered]@{}
  $datos['Marca'] = $b.nombre
  $datos['Tipo'] = $m.tipo
  $datos['Motor'] = $(if ($m.electrica) { 'Eléctrico' } else { Val $m.cc 'cc' })
  $datos['Potencia máxima'] = Val $m.cv 'CV'
  $datos['Par máximo'] = Val $m.nm 'Nm'
  $datos['Peso'] = Val $m.peso 'kg'
  $datos['Altura del asiento'] = Val $m.asiento 'mm'
  $datos['Depósito'] = Val $m.deposito 'L'
  $datos['Carnet'] = $(if ($m.carnet -eq 'A1') { 'A1 / B con 3 años de antigüedad' } elseif ($m.carnet -eq 'A2') { 'A2 (o versión limitada para A2)' } else { 'A' })
  $datos['Precio recomendado'] = $(if ($null -ne $m.precio) { 'desde ' + (Format-Eur $m.precio) } else { 'Consultar en la web oficial' })
  $filas = foreach ($k in $datos.Keys) { "        <tr><th scope=""row"">$(Enc $k)</th><td>$(Enc $datos[$k])</td></tr>" }
  $ofertasHtml = $(if ($os.Count) {
      ($os | ForEach-Object {
        "      <div class=""d-offer""><div><b>$(Enc (Get-TextoOferta $_))</b><p>$(Enc $_.campana)$(if ($_.extras) { ' · ' + (Enc ((@($_.extras)) -join ' · ')) })$(if ($_.hasta) { ' · hasta el ' + (Format-Fecha $_.hasta) })</p></div><a class=""btn btn--lime btn--sm"" href=""$(Enc $_.enlace)"" target=""_blank"" rel=""noopener"">Ver oferta ↗</a></div>"
      }) -join "`n"
    } else { "      <p class=""note"">No hay ofertas oficiales vigentes para este modelo ahora mismo. Revisamos las webs oficiales cada día.</p>" })
  $fotoHtml = $(if ($f) {
      "    <figure class=""st-foto""><img src=""$(Enc $f.src)"" alt=""$(Enc $nombreCompleto)"" width=""960""><figcaption>Foto: <a href=""$(Enc $f.pagina)"" target=""_blank"" rel=""noopener"">$(Enc $f.autor)</a> · $(Enc $f.licencia) · Wikimedia Commons. Imagen ilustrativa.</figcaption></figure>"
    } else { '' })
  $rel = @($Modelos | Where-Object { $_.marca -eq $m.marca -and $_.id -ne $m.id } | Sort-Object @{ e = { [math]::Abs(([double]$(if ($_.cc) { $_.cc } else { 0 })) - ([double]$(if ($m.cc) { $m.cc } else { 0 }))) } } | Select-Object -First 6)
  $relHtml = ($rel | ForEach-Object { "<a class=""st-chip"" href=""../$($Slug[$_.id])/"">$(Enc $_.modelo)</a>" }) -join ' '
  $migas = Get-Migas @(
    @{ nombre = 'Inicio'; url = $pre; abs = "$Base/" },
    @{ nombre = $b.nombre; url = "${pre}marca/$($b.id)/"; abs = "$Base/marca/$($b.id)/" },
    @{ nombre = $m.modelo }
  ) $pre
  $producto = [ordered]@{ '@context' = 'https://schema.org'; '@type' = 'Product'; name = $nombreCompleto; brand = [ordered]@{ '@type' = 'Brand'; name = $b.nombre }; category = "Motocicleta $($m.tipo)"; description = $desc }
  if ($f) { $producto.image = $f.src }
  if ($null -ne $pf) {
    $producto.offers = [ordered]@{ '@type' = 'Offer'; priceCurrency = 'EUR'; price = [int][math]::Round([double]$pf); url = $(if ($o) { $o.enlace } else { Get-UrlOficial $m }); seller = [ordered]@{ '@type' = 'Organization'; name = $b.nombre } }
    if ($o -and $o.hasta) { $producto.offers.priceValidUntil = $o.hasta }
  }
  $cuerpo = @"
$($migas.html)
    <article class="st-ficha" style="--brand:$($b.color)">
      <p class="st-kicker">$(Enc $b.nombre) · $(Enc $m.tipo)</p>
      <h1 class="st-h1">$(Enc $nombreCompleto)</h1>
      <p class="st-lead">$(Enc $intro)</p>
$fotoHtml
      <div class="d-price"><b>$(Enc (Format-Eur $pf))</b>$(if ($o -and $null -ne $o.precioOferta -and $o.descuento) { "<s>$(Format-Eur ($o.precioOferta + $o.descuento))</s>" })<small>$(if ($o) { 'Con ' + (Enc $o.campana) } else { 'Precio recomendado desde' })</small></div>
      <h2 class="d-h3">Ofertas activas</h2>
$ofertasHtml
      <div data-mr-extras data-modelo="$(Enc $m.modelo)" data-marca="$(Enc $b.nombre)"></div>
      <h2 class="d-h3">Ficha técnica</h2>
      <table class="table"><tbody>
$($filas -join "`n")
      </tbody></table>
      <div class="d-actions">
        <a class="btn btn--lime" href="$(Enc (Get-UrlOficial $m))" target="_blank" rel="noopener">Web oficial de $(Enc $b.nombre) ↗</a>
        <a class="btn btn--ghost" href="${pre}?moto=$(Enc $m.id)#catalogo">Comparar con otras motos</a>
      </div>
      <p class="note">Datos según la web oficial de $(Enc $b.nombre). Pueden variar según versión y año. «—» = dato no publicado.</p>
    </article>
    $(if ($relHtml) { "<section class=""st-sec""><h2 class=""d-h3"">Otras motos de $(Enc $b.nombre)</h2><p>$relHtml</p></section>" })
"@
  $html = New-Html -Titulo $titulo -Descripcion $desc -Ruta "moto/$s/index.html" -Cuerpo $cuerpo -JsonLd @($producto, $migas.ld) -Imagen $(if ($f) { $f.src } else { '' })
  Write-Pagina "moto\$s\index.html" $html $(if ($o) { '0.8' } else { '0.6' })
}
Write-Host "Páginas de motos: $($Modelos.Count)"

# ───────────────────────── Páginas de marca ─────────────────────────

foreach ($b in $Marcas) {
  $pre = '../../'
  $lista = @($Modelos | Where-Object { $_.marca -eq $b.id })
  $ofs = @($Ofertas | Where-Object { $ModeloPor[$_.modelo].marca -eq $b.id })
  $titulo = "Ofertas $($b.nombre) ${MesAnio}: precios y fichas de todas sus motos"
  $desc = "$($lista.Count) motos $($b.nombre) a la venta en España con precio, ficha técnica y " + $(if ($ofs.Count) { "$($ofs.Count) ofertas oficiales activas" } else { 'enlace a sus promociones oficiales' }) + ". Actualizado a diario."
  $migas = Get-Migas @(@{ nombre = 'Inicio'; url = $pre; abs = "$Base/" }, @{ nombre = $b.nombre }) $pre
  $cards = ($ofs | ForEach-Object { Get-TarjetaOferta $_ $pre }) -join "`n"
  $promo = $(if ($b.ofertas) { $b.ofertas } else { $b.web })
  $cuerpo = @"
$($migas.html)
    <h1 class="st-h1">Ofertas y precios de $(Enc $b.nombre) en $MesAnio</h1>
    <p class="st-lead">Todas las motos de $(Enc $b.nombre) a la venta en España con su precio recomendado, ficha técnica y las promociones oficiales vigentes hoy. Los datos se revisan cada día en la <a href="$(Enc $promo)" target="_blank" rel="noopener">web oficial de $(Enc $b.nombre)</a>.</p>
    <h2 class="d-h3">$($ofs.Count) ofertas activas</h2>
    $(if ($ofs.Count) { "<div class=""st-grid"">`n$cards`n    </div>" } else { "<p class=""note"">$(Enc $b.nombre) no tiene ofertas que podamos comprobar ahora mismo. <a href=""$(Enc $promo)"" target=""_blank"" rel=""noopener"">Ver sus promociones ↗</a></p>" })
    <h2 class="d-h3">Gama completa ($($lista.Count) modelos)</h2>
$(Get-TablaModelos $lista $pre)
"@
  $html = New-Html -Titulo $titulo -Descripcion $desc -Ruta "marca/$($b.id)/index.html" -Cuerpo $cuerpo -JsonLd @($migas.ld)
  Write-Pagina "marca\$($b.id)\index.html" $html '0.8'
}

# ───────────────────────── Páginas temáticas ─────────────────────────

function New-PaginaListado([string]$Ruta, [string]$Titulo, [string]$H1, [string]$Desc, [string]$Lead, $Lista, [string]$Prioridad) {
  $pre = '../'
  $idsLista = @{}; foreach ($m in $Lista) { $idsLista[$m.id] = $true }
  $ofs = @($Ofertas | Where-Object { $idsLista[$_.modelo] })
  $migas = Get-Migas @(@{ nombre = 'Inicio'; url = $pre; abs = "$Base/" }, @{ nombre = $H1 }) $pre
  $cards = ($ofs | ForEach-Object { Get-TarjetaOferta $_ $pre }) -join "`n"
  $cuerpo = @"
$($migas.html)
    <h1 class="st-h1">$(Enc $H1)</h1>
    <p class="st-lead">$(Enc $Lead)</p>
    $(if ($ofs.Count) { "<h2 class=""d-h3"">$($ofs.Count) ofertas activas</h2>`n    <div class=""st-grid"">`n$cards`n    </div>" })
    $(if (@($Lista).Count -gt 0) { "<h2 class=""d-h3"">$(@($Lista).Count) modelos</h2>`n" + (Get-TablaModelos $Lista $pre) })
"@
  $html = New-Html -Titulo $Titulo -Descripcion $Desc -Ruta "$Ruta/index.html" -Cuerpo $cuerpo -JsonLd @($migas.ld) -Profundidad 1
  Write-Pagina "$Ruta\index.html" $html $Prioridad
}

$conOferta = @($Modelos | Where-Object { $OfertasPor[$_.id] })
$maxDto = ($Ofertas | Where-Object { $_.descuento } | Measure-Object -Property descuento -Maximum).Maximum
New-PaginaListado 'ofertas' "Ofertas de motos ${MesAnio}: $($Ofertas.Count) promociones oficiales" "Ofertas de motos en $MesAnio" `
  "$($Ofertas.Count) ofertas oficiales de motos en España: descuentos de hasta $(Format-Eur $maxDto), financiación y regalos. Comprobadas a diario en las webs de las marcas." `
  "Todas las promociones oficiales de las marcas de motos en España, comprobadas hoy en sus webs. Cada oferta enlaza directamente a la página oficial donde se publica." `
  $conOferta '0.9'
New-PaginaListado 'motos-a2' "Motos para carnet A2 ${MesAnio}: precios y ofertas" "Motos para carnet A2" `
  "$(@($Modelos | Where-Object { $_.carnet -eq 'A2' }).Count) motos para carnet A2 a la venta en España con precio, ficha técnica y ofertas oficiales actualizadas a diario." `
  "Motos que se pueden conducir con el carnet A2, de serie o con su versión limitada a 35 kW, con su precio y las ofertas oficiales vigentes." `
  @($Modelos | Where-Object { $_.carnet -eq 'A2' }) '0.9'
New-PaginaListado 'motos-125' "Motos y scooters de 125 cc ${MesAnio}: precios y ofertas" "Motos y scooters de 125 cc" `
  "Motos y scooters de 125 cc que puedes conducir con el carnet A1 o con el B y 3 años de antigüedad: precios, fichas y ofertas oficiales." `
  "Modelos de 125 cc que se pueden conducir con el carnet A1, o con el carnet B y 3 años de antigüedad, con su precio y las ofertas oficiales." `
  @($Modelos | Where-Object { $_.carnet -eq 'A1' }) '0.9'

# ───────────────────────── Páginas legales ─────────────────────────

$T = $Sitio.titular
$falta = '[pendiente de completar en data/sitio.js]'
function Dato($v) { if ($v) { return Enc $v }; return "<mark>$falta</mark>" }
$conAds = [bool]$Sitio.adsense
$legal = @{
  'aviso-legal' = @{ t = 'Aviso legal'; c = @"
    <p>En cumplimiento de la Ley 34/2002, de Servicios de la Sociedad de la Información y de Comercio Electrónico (LSSI-CE), se informa de los datos del titular de este sitio web:</p>
    <ul><li>Titular: $(Dato $T.nombre)</li><li>NIF: $(Dato $T.nif)</li><li>Domicilio: $(Dato $T.direccion)</li><li>Correo electrónico: $(Dato $T.email)</li></ul>
    <h2 class="d-h3">Objeto</h2>
    <p>$(Enc $Nombre) es un comparador independiente que recopila información pública de las webs oficiales de los fabricantes de motocicletas. No vende vehículos ni tiene relación con las marcas citadas, cuyos nombres pertenecen a sus propietarios y se usan solo para identificar sus productos.</p>
    <h2 class="d-h3">Exactitud de la información</h2>
    <p>Precios, fichas técnicas y ofertas se obtienen de las webs oficiales y pueden cambiar en cualquier momento. El usuario debe confirmarlos en la web oficial o en un concesionario antes de comprar. $(Enc $Nombre) no se responsabiliza de errores u omisiones de las fuentes.</p>
    <h2 class="d-h3">Publicidad y enlaces de afiliado</h2>
    <p>Este sitio puede mostrar publicidad y enlaces de afiliado, siempre identificados como tales. Si compras o contratas a través de ellos, $(Enc $Nombre) puede recibir una comisión sin coste adicional para ti.</p>
    <h2 class="d-h3">Propiedad intelectual</h2>
    <p>Las fotografías proceden de Wikimedia Commons con licencias libres y se muestran con su autor y licencia. El diseño y los textos de este sitio pertenecen a su titular.</p>
"@ }
  'privacidad' = @{ t = 'Política de privacidad'; c = @"
    <p><b>Responsable:</b> $(Dato $T.nombre), NIF $(Dato $T.nif), $(Dato $T.direccion). Contacto: $(Dato $T.email).</p>
    <h2 class="d-h3">Qué datos tratamos y para qué</h2>
    <p>Este sitio no requiere registro. Solo tratamos datos personales si los envías voluntariamente en el formulario «Pedir esta oferta»: nombre, correo, teléfono, código postal y el modelo que te interesa. Los usamos para hacer llegar tu solicitud a un concesionario oficial de la marca, que podrá contactarte con su oferta.</p>
    <h2 class="d-h3">Base legal y conservación</h2>
    <p>La base legal es tu consentimiento, que das al marcar la casilla del formulario y que puedes retirar en cualquier momento. Conservamos los datos el tiempo necesario para gestionar tu solicitud y un máximo de 12 meses.</p>
    <h2 class="d-h3">Destinatarios</h2>
    <p>El concesionario al que se envía tu solicitud y el proveedor del formulario (Formspree), que actúa como encargado del tratamiento. No vendemos tus datos a terceros.</p>
    <h2 class="d-h3">Tus derechos</h2>
    <p>Puedes ejercer los derechos de acceso, rectificación, supresión, oposición, limitación y portabilidad escribiendo a $(Dato $T.email). También puedes reclamar ante la Agencia Española de Protección de Datos (www.aepd.es).</p>
"@ }
  'cookies' = @{ t = 'Política de cookies'; c = @"
    <p>$(Enc $Nombre) no instala cookies propias. La analítica de visitas se hace sin cookies ni datos personales identificables.</p>
    $(if ($conAds) { "<h2 class=""d-h3"">Cookies de publicidad</h2><p>Este sitio muestra anuncios de Google AdSense. Google y sus socios pueden usar cookies para mostrar y medir anuncios, personalizados o no según tu elección. La primera vez que visitas la web se te pide el consentimiento mediante el mensaje de privacidad de Google, y puedes cambiar tu elección en cualquier momento desde el enlace «Opciones de privacidad». Más información: <a href=""https://policies.google.com/technologies/ads"" target=""_blank"" rel=""noopener"">cómo usa Google las cookies en publicidad</a>.</p>" } else { "<p>Actualmente no se muestra publicidad con cookies.</p>" })
    <p>Los enlaces a webs externas (marcas, concesionarios, afiliados) te llevan a sitios con sus propias políticas de cookies.</p>
"@ }
}
foreach ($k in $legal.Keys) {
  $pre = '../../'
  $cuerpo = "    <article class=""st-legal""><h1 class=""st-h1"">$($legal[$k].t)</h1>`n$($legal[$k].c)`n    <p class=""note"">Última actualización: $(Format-Fecha $Hoy).</p></article>"
  Write-Pagina "legal\$k\index.html" (New-Html -Titulo "$($legal[$k].t) · $Nombre" -Descripcion "$($legal[$k].t) de $Nombre." -Ruta "legal/$k/index.html" -Cuerpo $cuerpo) '0.2'
}
if (-not ($T.nombre -and $T.nif -and $T.email -and $T.direccion)) { Write-Host 'AVISO: faltan datos del titular en data/sitio.js (necesarios antes de monetizar)' }

# 404
$html404 = New-Html -Titulo "Página no encontrada · $Nombre" -Descripcion 'Esta página no existe.' -Ruta '404.html' -Profundidad 0 -NoIndex -Cuerpo @"
    <h1 class="st-h1">Esta página ya no existe</h1>
    <p class="st-lead">Puede que el modelo haya dejado de venderse o que la dirección esté mal escrita.</p>
    <p><a class="btn btn--lime" href="./">Ver todas las ofertas</a></p>
"@
# En 404.html las rutas deben ser absolutas porque se sirve desde cualquier dirección
$raizRel = ([Uri]$Base).AbsolutePath.TrimEnd('/') + '/'
[IO.File]::WriteAllText((Join-Path $Raiz '404.html'), ($html404 -replace '(href|src)="(?!https?:|#|mailto:)(\./)?', ('$1="' + $raizRel)), $Utf8)

# ───────────────────────── Portada: bloques SEO ─────────────────────────

$rutaIndex = Join-Path $Raiz 'index.html'
$index = [IO.File]::ReadAllText($rutaIndex, [Text.Encoding]::UTF8)
$webLd = [ordered]@{ '@context' = 'https://schema.org'; '@type' = 'WebSite'; name = $Nombre; url = "$Base/"; inLanguage = 'es-ES'; description = 'Ofertas oficiales y fichas técnicas de motos en España, actualizadas cada día.' }
$cabecera = @(
  "<link rel=""canonical"" href=""$Base/"">",
  "<meta property=""og:type"" content=""website"">",
  "<meta property=""og:site_name"" content=""$(Enc $Nombre)"">",
  "<meta property=""og:locale"" content=""es_ES"">",
  "<meta property=""og:title"" content=""$(Enc "$Nombre · $($Ofertas.Count) ofertas de motos en España ($MesAnio)")"">",
  "<meta property=""og:description"" content=""$(Enc "Promociones oficiales de $(@($Marcas).Count) marcas con descuentos de hasta $(Format-Eur $maxDto), fichas técnicas y enlace directo a cada oferta. Actualizado a diario.")"">",
  "<meta property=""og:url"" content=""$Base/"">",
  "<meta property=""og:image"" content=""$Base/og.png"">",
  "<meta name=""twitter:card"" content=""summary_large_image"">"
)
if ($Sitio.googleVerificacion) { $cabecera += "<meta name=""google-site-verification"" content=""$(Enc $Sitio.googleVerificacion)"">" }
if ($Sitio.bingVerificacion) { $cabecera += "<meta name=""msvalidate.01"" content=""$(Enc $Sitio.bingVerificacion)"">" }
$cabecera += '<script type="application/ld+json">' + (ConvertTo-Json -InputObject $webLd -Compress) + '</script>'
$enlaces = @(
  '<nav class="footer__links" aria-label="Más páginas">',
  ('<p><b>Por marca:</b> ' + (($Marcas | ForEach-Object { "<a href=""marca/$($_.id)/"">Ofertas $(Enc $_.nombre)</a>" }) -join ' · ') + '</p>'),
  '<p><b>Guías:</b> <a href="ofertas/">Ofertas de motos del mes</a> · <a href="motos-a2/">Motos para carnet A2</a> · <a href="motos-125/">Motos de 125 cc</a></p>',
  '<p><a href="legal/aviso-legal/">Aviso legal</a> · <a href="legal/privacidad/">Privacidad</a> · <a href="legal/cookies/">Cookies</a></p>',
  '</nav>'
)
function Set-Bloque([string]$Html, [string]$Nombre, [string[]]$Lineas, [string]$Sangria) {
  $patron = "(?s)<!--MR:$Nombre-->.*?<!--/MR:$Nombre-->"
  if (-not [regex]::IsMatch($Html, $patron)) { throw "Falta el bloque <!--MR:$Nombre--> en index.html" }
  $nuevo = "<!--MR:$Nombre-->`n" + (($Lineas | ForEach-Object { $Sangria + $_ }) -join "`n") + "`n$Sangria<!--/MR:$Nombre-->"
  return [regex]::Replace($Html, $patron, { param($x) $nuevo })
}
$index = Set-Bloque $index 'HEAD' $cabecera '  '
$index = Set-Bloque $index 'LINKS' $enlaces '      '
[IO.File]::WriteAllText($rutaIndex, $index, $Utf8)
[void]$Generadas.Insert(0, [pscustomobject]@{ url = "$Base/"; prioridad = '1.0' })

# Mapa id → página, para que la web enlace cada ficha con su página
$mapa = [ordered]@{}; foreach ($m in $Modelos) { $mapa[$m.id] = "moto/$($Slug[$m.id])/" }
[IO.File]::WriteAllText((Join-Path $Raiz 'data\paginas.js'), "/* Generado por scripts/generar-paginas.ps1 */`nwindow.PAGINAS = " + (ConvertTo-Json -InputObject $mapa -Compress) + ";`n", $Utf8)

# Borra páginas de motos o marcas que ya no existen
foreach ($dir in 'moto', 'marca') {
  $raizDir = Join-Path $Raiz $dir
  if (-not (Test-Path $raizDir)) { continue }
  $validos = @{}
  foreach ($g in $Generadas) { $p = ([Uri]$g.url).AbsolutePath; if ($p -match "/$dir/([^/]+)/$") { $validos[$Matches[1]] = $true } }
  foreach ($d in Get-ChildItem $raizDir -Directory) { if (-not $validos[$d.Name]) { Remove-Item $d.FullName -Recurse -Force -Confirm:$false; Write-Host "Eliminada página antigua: $dir/$($d.Name)" } }
}

# ───────────────────────── sitemap, robots, imagen para redes ─────────────────────────

$sb = New-Object Text.StringBuilder
[void]$sb.AppendLine('<?xml version="1.0" encoding="UTF-8"?>')
[void]$sb.AppendLine('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
foreach ($g in $Generadas) { [void]$sb.AppendLine("  <url><loc>$([Security.SecurityElement]::Escape($g.url))</loc><lastmod>$Hoy</lastmod><priority>$($g.prioridad)</priority></url>") }
[void]$sb.AppendLine('</urlset>')
[IO.File]::WriteAllText((Join-Path $Raiz 'sitemap.xml'), $sb.ToString(), $Utf8)
[IO.File]::WriteAllText((Join-Path $Raiz 'robots.txt'), "User-agent: *`nAllow: /`n`nSitemap: $Base/sitemap.xml`n", $Utf8)
# ads.txt: obligatorio para cobrar AdSense (Google comprueba que el anunciante autorizado eres tú)
$rutaAds = Join-Path $Raiz 'ads.txt'
if ($Sitio.adsense -match '^ca-(pub-\d{10,20})$') { [IO.File]::WriteAllText($rutaAds, "google.com, $($Matches[1]), DIRECT, f08c47fec0942fa0`n", $Utf8) }
elseif (Test-Path $rutaAds) { Remove-Item $rutaAds -Confirm:$false }

Add-Type -AssemblyName System.Drawing
$bmp = New-Object Drawing.Bitmap 1200, 630
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
$g.Clear([Drawing.Color]::FromArgb(7, 7, 10))
$lima = [Drawing.Color]::FromArgb(215, 255, 58)
$penR = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(60, 215, 255, 58)), 2
foreach ($r in 120, 230, 340) { $g.DrawEllipse($penR, 980 - $r, 315 - $r, 2 * $r, 2 * $r) }
$g.FillPie((New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(70, 215, 255, 58))), 640, -25, 680, 680, -90, 40)
$fuente = { param($tam, $estilo) New-Object Drawing.Font 'Arial Black', $tam, $estilo, ([Drawing.GraphicsUnit]::Pixel) }
$g.DrawString('MOTO', (& $fuente 110 ([Drawing.FontStyle]::Regular)), [Drawing.Brushes]::White, 60, 80)
$g.DrawString('RADAR', (& $fuente 110 ([Drawing.FontStyle]::Regular)), (New-Object Drawing.SolidBrush $lima), 60, 200)
$g.DrawString("$($Ofertas.Count) ofertas de motos en España", (New-Object Drawing.Font 'Arial', 40, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)), [Drawing.Brushes]::White, 66, 370)
$g.DrawString("Hasta $(Format-Eur $maxDto) de descuento · actualizado a diario", (New-Object Drawing.Font 'Arial', 30, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)), (New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(170, 172, 185))), 68, 430)
$g.FillRectangle((New-Object Drawing.SolidBrush $lima), 0, 600, 1200, 30)
$bmp.Save((Join-Path $Raiz 'og.png'), [Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

Write-Host "Generadas $($Generadas.Count) páginas + sitemap.xml, robots.txt, 404.html, og.png y data/paginas.js"
