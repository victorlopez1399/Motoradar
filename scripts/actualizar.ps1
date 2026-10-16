#requires -Version 5.1
<#
  Actualizador automático de MotoRadar.

  Lee las webs oficiales de las marcas y genera:
    data/auto.json  estado completo (lo usa este script en la siguiente ejecución)
    data/auto.js    lo que carga la web: modelos nuevos y ofertas vigentes

  Qué hace por marca:
    Honda, Kawasaki, Suzuki, KTM, BMW  → ofertas + modelos nuevos
    Triumph, Harley-Davidson, Royal Enfield → modelos nuevos
    Yamaha, Ducati, Aprilia, CFMoto → no se pueden leer automáticamente (se mantienen a mano)

  Seguridad: si una marca falla o devuelve datos sospechosos, se conservan sus datos
  de la ejecución anterior. Nunca modifica data/catalogo.js, data/ofertas.js ni data/fotos.js.

  Uso:  powershell -ExecutionPolicy Bypass -File scripts/actualizar.ps1
#>
param([string]$Raiz = (Split-Path -Parent $PSScriptRoot))

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$EUR = [string][char]0x20AC
$UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130 Safari/537.36'
$Hoy = (Get-Date).ToString('yyyy-MM-dd')
$Utf8 = New-Object Text.UTF8Encoding $false
$Inv = [Globalization.CultureInfo]::InvariantCulture
$Meses = @{ enero = 1; febrero = 2; marzo = 3; abril = 4; mayo = 5; junio = 6; julio = 7; agosto = 8; septiembre = 9; setiembre = 9; octubre = 10; noviembre = 11; diciembre = 12 }

# ───────────────────────── Utilidades ─────────────────────────

function Get-Pagina([string]$Url) {
  for ($i = 0; $i -lt 3; $i++) {
    $raw = (& curl.exe -s -L --compressed -A $UA -H 'Accept-Language: es-ES,es;q=0.9' --max-time 45 -w "`n__HTTP__%{http_code}" $Url) -join "`n"
    $pos = $raw.LastIndexOf('__HTTP__')
    if ($pos -ge 0) {
      $code = $raw.Substring($pos + 8).Trim()
      if ($code -eq '200') { Start-Sleep -Milliseconds 400; return $raw.Substring(0, $pos) }
      if ($code -eq '404' -or $code -eq '403' -or $code -eq '410') { return $null }
    }
    Start-Sleep -Seconds (2 + 4 * $i)
  }
  return $null
}

function Get-Texto([string]$Html) {
  if (-not $Html) { return '' }
  $t = $Html -replace '(?is)<script.*?</script>', ' ' -replace '(?is)<style.*?</style>', ' ' -replace '<[^>]+>', ' '
  $t = [Net.WebUtility]::HtmlDecode($t)
  return ($t -replace '\s+', ' ').Trim()
}

function Get-Titulo([string]$Html) {
  $m = [regex]::Match($Html, '(?is)<title[^>]*>(.*?)</title>')
  if ($m.Success) { return ([Net.WebUtility]::HtmlDecode($m.Groups[1].Value) -replace '\s+', ' ').Trim() }
  return ''
}

function ConvertTo-Numero([string]$s) {
  if (-not $s) { return $null }
  $s = $s.Trim() -replace '\s', ''
  if ($s -match ',') { $s = $s -replace '\.', '' -replace ',', '.' }
  elseif ($s -match '^\d{1,3}(\.\d{3})+$') { $s = $s -replace '\.', '' }
  $d = 0.0
  if ([double]::TryParse($s, [Globalization.NumberStyles]::Float, $Inv, [ref]$d)) { return [math]::Round($d, 1) }
  return $null
}

function Find-Num([string]$Texto, [string]$Patron) {
  $m = [regex]::Match($Texto, $Patron, 'IgnoreCase')
  if ($m.Success) { return ConvertTo-Numero $m.Groups[1].Value }
  return $null
}

function Find-Precio([string]$Texto, [string]$Patron) {
  $v = Find-Num $Texto $Patron
  if ($v -and $v -ge 500 -and $v -le 100000) { return [int][math]::Round($v) }
  return $null
}

function Remove-Tildes([string]$s) {
  if (-not $s) { return '' }
  $n = $s.Normalize([Text.NormalizationForm]::FormD)
  $sb = New-Object Text.StringBuilder
  foreach ($c in $n.ToCharArray()) {
    if ([Globalization.CharUnicodeInfo]::GetUnicodeCategory($c) -ne [Globalization.UnicodeCategory]::NonSpacingMark) { [void]$sb.Append($c) }
  }
  return $sb.ToString()
}

# Nombre "base" para comparar modelos: sin marca, año, versiones (SE, A2, 70 kW, ediciones…) ni símbolos
$Variantes = '\b(20\d\d|se|a2|\d\d\s?kw|abs|std|dx|es|hamamatsu|edition|edicion|especial|special|limited|black\s+ball|carbon|white|black|red|blue|blanco|negro|rojo|azul|e-?clutch|dct|y-?amt|nueva|nuevo|new)\b'
$MarcasTxt = '\b(honda|yamaha|kawasaki|suzuki|bmw|motorrad|ktm|ducati|triumph|harley-davidson|harley|davidson|aprilia|royal\s+enfield|cfmoto)\b'
function Get-Base([string]$s) {
  $x = (Remove-Tildes $s).ToLowerInvariant() -replace '_', ' '
  $x = [regex]::Replace($x, $MarcasTxt, ' ')
  $x = [regex]::Replace($x, $Variantes, ' ')
  return ($x -replace '[^a-z0-9]', '')
}
function Get-Clave([string]$s) { $b = Get-Base $s; return (($b.ToCharArray() | Sort-Object) -join '') }

function Get-UrlClave([string]$Url) {
  if (-not $Url) { return '' }
  $u = $Url.ToLowerInvariant() -replace '^https?://(www\.)?', '' -replace '[?#].*$', '' -replace '/+$', ''
  $u = $u -replace '(^|[/_-])20\d\d(?=[/_.-]|$)', '$1' -replace '[/_.-]+', '-'
  return $u.Trim('-')
}

function Format-Nombre([string]$s) {
  # "1390 SUPER DUKE R" → "1390 Super Duke R"; las siglas cortas se quedan en mayúsculas
  $out = foreach ($w in ($s.Trim() -split '\s+')) {
    if ($w -match '\d') { $w.ToUpperInvariant() }
    else {
      # "V-STROM" → "V-Strom"
      (($w -split '-') | ForEach-Object {
        if ($_.Length -le 3) { $_.ToUpperInvariant() } else { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1).ToLowerInvariant() }
      }) -join '-'
    }
  }
  return ($out -join ' ')
}

function Get-Carnet($cc, $cv) {
  if ($null -eq $cv) { if ($cc -and $cc -le 125) { return 'A1' } elseif ($cc -and $cc -le 400) { return 'A2' } else { return 'A' } }
  $kw = $cv / 1.36
  if ((-not $cc -or $cc -le 125) -and $kw -le 11.1) { return 'A1' }
  if ($kw -le 35.1) { return 'A2' }
  return 'A'
}

function Get-FechaNum([string]$Texto) {
  $m = [regex]::Match($Texto, 'hasta(?: el| del)?\s+(\d{1,2})/(\d{1,2})/(20\d\d)', 'IgnoreCase')
  if ($m.Success) { return ('{0}-{1:D2}-{2:D2}' -f $m.Groups[3].Value, [int]$m.Groups[2].Value, [int]$m.Groups[1].Value) }
  return $null
}
function Get-FechaTexto([string]$Texto) {
  $m = [regex]::Match((Remove-Tildes $Texto), 'hasta(?: el| del)?\s+(\d{1,2})\s+de\s+([a-z]+)\s+de\s+(20\d\d)', 'IgnoreCase')
  if ($m.Success -and $Meses.ContainsKey($m.Groups[2].Value.ToLowerInvariant())) {
    return ('{0}-{1:D2}-{2:D2}' -f $m.Groups[3].Value, $Meses[$m.Groups[2].Value.ToLowerInvariant()], [int]$m.Groups[1].Value)
  }
  return $null
}

# Write-Host y no Write-Output: así los mensajes no se mezclan con lo que devuelven las funciones
function Log([string]$m) { Write-Host ("[{0}] {1}" -f (Get-Date).ToString('HH:mm:ss'), $m) }

# ───────────────────────── Catálogo y estado ─────────────────────────

$RutaCatalogo = Join-Path $Raiz 'data\catalogo.js'
$RutaEstado = Join-Path $Raiz 'data\auto.json'
$RutaSalida = Join-Path $Raiz 'data\auto.js'

$Manual = @()
foreach ($l in [IO.File]::ReadAllLines($RutaCatalogo, [Text.Encoding]::UTF8)) {
  $m = [regex]::Match($l, 'id:\s*"([^"]+)",\s*marca:\s*"([^"]+)",\s*modelo:\s*"([^"]+)"')
  if (-not $m.Success) { continue }
  $u = [regex]::Match($l, 'url:\s*"([^"]+)"')
  $p = [regex]::Match($l, 'precio:\s*(\d+)')
  $Manual += [pscustomobject]@{ id = $m.Groups[1].Value; marca = $m.Groups[2].Value; modelo = $m.Groups[3].Value; url = $(if ($u.Success) { $u.Groups[1].Value } else { '' }); precio = $(if ($p.Success) { [int]$p.Groups[1].Value } else { $null }) }
}
if ($Manual.Count -lt 20) { throw "No se ha podido leer data/catalogo.js ($($Manual.Count) modelos)" }
Log "Catálogo manual: $($Manual.Count) modelos"

$Estado = $null
if (Test-Path $RutaEstado) { $Estado = [IO.File]::ReadAllText($RutaEstado, [Text.Encoding]::UTF8) | ConvertFrom-Json }
function Get-Previo([string]$Marca) {
  if ($Estado -and $Estado.marcas -and $Estado.marcas.PSObject.Properties[$Marca]) { return $Estado.marcas.$Marca }
  return $null
}

# Modelos conocidos de una marca: los manuales + los automáticos de esta ejecución
$Conocidos = @{}
function Get-Conocidos([string]$Marca) {
  $lista = @($Manual | Where-Object { $_.marca -eq $Marca })
  if ($Conocidos.ContainsKey($Marca)) { $lista += $Conocidos[$Marca] }
  return $lista
}

function Find-Modelo([string]$Marca, [string]$Nombre, [string]$Url) {
  $lista = Get-Conocidos $Marca
  if ($Url) {
    $k = Get-UrlClave $Url
    foreach ($x in $lista) { if ($x.url -and (Get-UrlClave $x.url) -eq $k) { return $x } }
  }
  if ($Nombre) {
    $b = Get-Base $Nombre
    if ($b.Length -ge 2) {
      foreach ($x in $lista) { if ((Get-Base $x.modelo) -eq $b) { return $x } }
      if ($b.Length -ge 4) {
        $c = Get-Clave $Nombre
        foreach ($x in $lista) { if ((Get-Clave $x.modelo) -eq $c) { return $x } }
      }
    }
  }
  return $null
}

function Limit-Dato($v, $min, $max) { if ($null -ne $v -and $v -ge $min -and $v -le $max) { return $v }; return $null }

function New-Modelo([string]$Marca, [string]$Nombre, [string]$Tipo, [hashtable]$F, [string]$Url) {
  # Valores fuera de rango = lectura errónea de la página → se dejan vacíos
  $F.cc = Limit-Dato $F.cc 49 2600; $F.cv = Limit-Dato $F.cv 3 350; $F.nm = Limit-Dato $F.nm 5 250
  $F.peso = Limit-Dato $F.peso 60 500; $F.asiento = Limit-Dato $F.asiento 600 1000; $F.deposito = Limit-Dato $F.deposito 2 40
  $cc = $F.cc; if ($cc) { $cc = [int][math]::Round($cc) }
  $id = "$Marca-auto-" + ((Get-Base $Nombre) -replace '[^a-z0-9]', '')
  $prev = Get-Previo $Marca
  $desde = $Hoy
  if ($prev) { foreach ($pm in @($prev.modelos)) { if ($pm.id -eq $id -and $pm.desde) { $desde = $pm.desde } } }
  $o = [ordered]@{
    id = $id; marca = $Marca; modelo = $Nombre; tipo = $Tipo
    cc = $cc; cv = $F.cv; nm = $F.nm; peso = $F.peso; asiento = $F.asiento; deposito = $F.deposito
    carnet = $(if ($F.carnet) { $F.carnet } elseif (-not $cc -and $null -eq $F.cv -and $Nombre -match '(^|\D)125(\D|$)') { 'A1' } else { Get-Carnet $cc $F.cv })
    precio = $F.precio; precioOk = [bool]$F.precio; url = $Url; auto = $true; desde = $desde
  }
  if ($F.electrica) { $o.electrica = $true }
  return [pscustomobject]$o
}

function Add-Conocido([string]$Marca, $Modelo) {
  if (-not $Conocidos.ContainsKey($Marca)) { $Conocidos[$Marca] = @() }
  $Conocidos[$Marca] += $Modelo
}

function New-Oferta($Modelo, [string]$Campana, $Descuento, $PrecioOferta, $Cuota, [string]$Regalo, [string[]]$Extras, [string]$Hasta, [string]$Enlace) {
  $ex = @($Extras | Where-Object { $_ })
  return [pscustomobject][ordered]@{
    id = ''; modelo = $Modelo.id; campana = $Campana
    descuento = $Descuento; precioOferta = $PrecioOferta; cuota = $Cuota; regalo = $(if ($Regalo) { $Regalo } else { $null })
    extras = $ex; hasta = $Hasta; estado = 'confirmada'; enlace = $Enlace; revisada = $Hoy; auto = $true
  }
}

function Test-Oferta($o) {
  if ($o.precioOferta -and ($o.precioOferta -lt 500 -or $o.precioOferta -gt 100000)) { return $false }
  if ($o.descuento -and ($o.descuento -le 0 -or $o.descuento -gt 20000)) { return $false }
  if ($o.cuota -and ($o.cuota -lt 10 -or $o.cuota -gt 2000)) { return $false }
  return [bool]($o.descuento -or $o.cuota -or $o.regalo)
}

# ───────────────────────── Honda ─────────────────────────

function Update-Honda {
  $base = 'https://www.honda.es'
  $html = Get-Pagina "$base/motorcycles/range.html"
  if (-not $html) { throw 'No responde la gama de Honda' }
  $tipos = @{ '125cc' = 'Naked'; 'adventure' = 'Trail'; 'electric' = 'Eléctrica / híbrida'; 'scooter' = 'Scooter'; 'sport-touring' = 'Touring'; 'street' = 'Naked'; 'super-sport' = 'Deportiva'; 'touring' = 'Touring' }
  $links = [regex]::Matches($html, 'href="(/motorcycles/range/([a-z0-9-]+)/([a-z0-9_-]+)/overview\.html)"', 'IgnoreCase') |
    ForEach-Object { [pscustomobject]@{ path = $_.Groups[1].Value; cat = $_.Groups[2].Value.ToLowerInvariant(); slug = $_.Groups[3].Value } } |
    Where-Object { $tipos.ContainsKey($_.cat) } | Sort-Object path -Unique
  if (@($links).Count -lt 15) { throw "Gama de Honda incompleta ($(@($links).Count) modelos)" }

  foreach ($l in $links) {
    $url = $base + $l.path
    if (Find-Modelo 'honda' '' $url) { continue }
    $ov = Get-Pagina $url
    if (-not $ov) { continue }
    $segs = @((Get-Titulo $ov) -split '\|' | ForEach-Object { ($_ -replace '^\s*Honda\s+', '').Trim() } | Where-Object { $_ -and $_ -ne 'Honda' })
    if (-not $segs) { continue }
    $nombre = ($segs[0] -replace '\s+ES$', '').Trim()
    if (Find-Modelo 'honda' $nombre '') { continue }
    $sm = [regex]::Match($ov, ('href="([^"]*/' + [regex]::Escape($l.slug) + '/[^"]*specification[^"]*\.html)"'), 'IgnoreCase')
    $t = ''
    if ($sm.Success) { $sp = Get-Pagina ($base + $sm.Groups[1].Value); $t = Get-Texto $sp }
    $f = @{
      cc = Find-Num $t 'Cilindrada del motor\s*([\d.,]+)\s*cc'
      cv = Find-Num $t 'Potencia de salida m.x[^)]*\)\s*[\d.,]+\s*kW\s*\(\s*([\d.,]+)\s*CV'
      nm = Find-Num $t 'Par m.ximo[^)]*\)\s*([\d.,]+)\s*N'
      peso = Find-Num $t 'Peso en vac.o \(kg\)\s*([\d.,]+)'
      asiento = Find-Num $t 'Altura del asiento \(mm\)\s*([\d.,]+)'
      deposito = Find-Num $t 'Capacidad (?:del dep.sito )?de combustible[^\d]{0,8}([\d.,]+)'
      precio = Find-Precio $t ('(?:Especificaciones y precio|Precios? y especificaciones)\s+.{1,60}?\s(\d{1,3}(?:\.\d{3})+|\d{3,5})\s?' + $EUR)
    }
    if ($l.cat -eq 'electric' -or ($nombre -match '\be:' -and -not $f.cc)) { $f.electrica = $true }
    $mod = New-Modelo 'honda' $nombre $tipos[$l.cat] $f $url
    Add-Conocido 'honda' $mod
    Log "  Honda nuevo modelo: $nombre"
  }

  # Ofertas: cada bloque termina en "ENCUENTRA TU CONCESIONARIO"
  $enlace = "$base/motorcycles/range/offers/ofertas-honda.html"
  $t = Get-Texto (Get-Pagina $enlace)
  if (-not $t) { throw 'No responde la página de ofertas de Honda' }
  $ofertas = @()
  $bloques = [regex]::Split($t, 'ENCUENTRA TU CONCESIONARIO( M.S CERCANO)?', 'IgnoreCase')
  foreach ($b in $bloques) {
    if ($b.Length -lt 40) { continue }
    # Sensible a mayúsculas: el nombre del modelo empieza siempre por mayúscula o número
    $nm = [regex]::Match($b, '(?:para|v.lida para)\s+([A-Z0-9][A-Za-z0-9 \-]{1,30}?)(?=\s+incluyendo|\.|,|\s+con\s|\s+20\d\d|\s+STD|\s+DX)')
    if (-not $nm.Success) { continue }
    $nombre = $nm.Groups[1].Value.Trim()
    $mod = Find-Modelo 'honda' $nombre ''
    if (-not $mod) {
      $alias = @{ 'africatwin' = 'honda-africatwin'; 'xadv750' = 'honda-xadv'; 'xadv' = 'honda-xadv' }
      $k = Get-Base $nombre
      if ($alias.ContainsKey($k)) { $mod = Get-Conocidos 'honda' | Where-Object { $_.id -eq $alias[$k] } | Select-Object -First 1 }
    }
    if (-not $mod) { Log "  Honda: oferta sin modelo ($nombre)"; continue }
    $hasta = Get-FechaNum $b
    $cuota = Find-Num $b ('POR (?:S.LO )?(\d{2,4})\s?' + $EUR + '\s?AL MES')
    $precioOf = Find-Precio $b ('\bPOR\s+(\d{1,3}(?:\.\d{3})+|\d{3,5})\s?' + $EUR + '(?!\s?AL MES)')
    $ahorro = Find-Num $b ('ahorro de\s+([\d.]+)\s?' + $EUR)
    $regalo = $null
    $rg = [regex]::Match($b, '(PACK [A-Z]+) DE REGALO', 'IgnoreCase')
    if ($rg.Success) {
      $regalo = (Format-Nombre $rg.Groups[1].Value)
      $val = [regex]::Match($b, ('valorado en (m.s de )?([\d.]+)\s?' + $EUR), 'IgnoreCase')
      if ($val.Success) { $regalo += ' (valorado en ' + $(if ($val.Groups[1].Success) { 'más de ' } else { '' }) + $val.Groups[2].Value + ' ' + $EUR + ')' }
    }
    $desc = $null
    if ($precioOf) {
      if ($ahorro) { $desc = [int]$ahorro }
      elseif ($mod.precio -and $precioOf -lt $mod.precio) { $desc = [int]($mod.precio - $precioOf) }
      else { $precioOf = $null }
    }
    $extras = @()
    if ($b -match 'stock') { $extras += 'Unidades en stock' }
    if ($b -match '3 a.os de mantenimiento') { $extras += '3 años de mantenimiento' }
    if ($b -match '6 a.os de garant.a') { $extras += '6 años de garantía con Honda Plus' }
    if ($b -match 'Matriculaci.n gratuita|matriculaci.n incluid') { $extras += 'Matrícula incluida' }
    if ($b -match 'Pen.nsula y Baleares') { $extras += 'Península y Baleares' }
    $camp = $(if ($b -match 'HONDA PLUS GO') { 'Honda Plus Go' } elseif ($cuota) { 'Honda Plus' } elseif ($regalo) { $regalo } else { 'Oferta Honda' })
    $o = New-Oferta $mod $camp $desc $precioOf $cuota $regalo $extras $hasta $enlace
    if (Test-Oferta $o) { $ofertas += $o }
  }
  return $ofertas
}

# ───────────────────────── Kawasaki ─────────────────────────

function Update-Kawasaki {
  $base = 'https://www.kawasaki.es'
  $html = Get-Pagina "$base/es_es/Motorcycles.html"
  if (-not $html) { throw 'No responde la gama de Kawasaki' }
  $tipos = @{ 'Supernaked' = 'Naked'; 'Supersport_Sport' = 'Deportiva'; 'Hypersport' = 'Deportiva'; 'Adventure' = 'Trail'; 'Adventure_Tourer' = 'Trail'; 'Sport_Tourer' = 'Touring'; 'Retro_Sport' = 'Retro'; 'Classic' = 'Retro'; 'Urban_Cruiser' = 'Custom'; 'EV_HEV' = 'Eléctrica / híbrida' }
  $links = [regex]::Matches($html, 'href="(/es_es/Motorcycles/([A-Za-z_]+)/([A-Za-z0-9_.-]+)\.html)"') |
    ForEach-Object { [pscustomobject]@{ path = $_.Groups[1].Value; cat = $_.Groups[2].Value; file = $_.Groups[3].Value } } |
    Where-Object { $tipos.ContainsKey($_.cat) } | Sort-Object path -Unique
  if (@($links).Count -lt 15) { throw "Gama de Kawasaki incompleta ($(@($links).Count))" }
  # Kawasaki publica qué modelos tienen versión para carnet A2
  $aptasA2 = @{}
  foreach ($a in [regex]::Matches($html, 'href="/es_es/Motorcycles/A2_Bikes/([A-Za-z0-9_.-]+)\.html"')) { $aptasA2[(Get-Base $a.Groups[1].Value)] = $true }

  # Una entrada por modelo: se agrupan versiones (SE, 70 kW, años…) y se prefiere la versión base más reciente
  $grupos = $links | Group-Object { Get-Base $_.file }
  foreach ($g in $grupos) {
    $rep = $g.Group | Sort-Object @{ e = { if ((Get-Base ($_.file -replace '_20\d\d$', '')) -eq ((Remove-Tildes ($_.file -replace '_20\d\d$', '')).ToLowerInvariant() -replace '[^a-z0-9]', '')) { 0 } else { 1 } } }, @{ e = { $_.file }; Descending = $true } | Select-Object -First 1
    $url = $base + $rep.path
    $existe = $false
    foreach ($x in $g.Group) { if (Find-Modelo 'kawasaki' '' ($base + $x.path)) { $existe = $true } }
    if ($existe) { continue }
    $p = Get-Pagina $url
    if (-not $p) { continue }
    $nombre = ((Get-Titulo $p) -split '\|')[0].Trim()
    if (-not $nombre -or (Find-Modelo 'kawasaki' $nombre '')) { continue }
    $t = Get-Texto $p
    $f = @{
      cc = Find-Num $t 'Cilindrada\s+([\d.,]+)\s*cm'
      cv = Find-Num $t 'Potencia m.xima\s+[\d.,]+\s*kW\s*\{\s*([\d.,]+)\s*PS'
      nm = Find-Num $t 'Par m.ximo\s+([\d.,]+)\s*N'
      peso = Find-Num $t 'Peso en orden de marcha\*?\s*([\d.,]+)\s*kg'
      asiento = Find-Num $t 'Altura del asiento\s+([\d.,]+)\s*mm'
      deposito = Find-Num $t 'Capacidad de combustible\s+([\d.,]+)\s*l'
    }
    if ($rep.cat -eq 'EV_HEV' -and -not $f.cc) { $f.electrica = $true }
    if ($aptasA2.ContainsKey($g.Name) -and (Get-Carnet $f.cc $f.cv) -eq 'A') { $f.carnet = 'A2' }
    $mod = New-Modelo 'kawasaki' $nombre $tipos[$rep.cat] $f $url
    Add-Conocido 'kawasaki' $mod
    Log "  Kawasaki nuevo modelo: $nombre"
  }

  # Ofertas Kawa-GO!
  $promo = "$base/es_es/kawa-go----promociones.html"
  $ph = Get-Pagina $promo
  if (-not $ph) { throw 'No responde Kawa-GO' }
  $hasta = Get-FechaTexto (Get-Texto $ph)
  $ofertas = @()
  $fichas = [regex]::Matches($ph, 'href="(https://kawa-go\.kawasaki\.es/modelo/[a-z0-9-]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  foreach ($u in $fichas) {
    $h = Get-Pagina $u
    if (-not $h) { continue }
    $titulo = ((Get-Titulo $h) -split '\|')[0] -replace '(?i)kawasaki', ''
    $titulo = ($titulo -replace '\s+', ' ').Trim()
    $mod = Find-Modelo 'kawasaki' $titulo ''
    if (-not $mod) { continue }
    $t = Get-Texto $h
    $pvp = Find-Precio $t ('PVP:\s*([\d.]+)\s*' + $EUR)
    $ahora = Find-Precio $t ('Ahora por s.lo:\s*([\d.]+)\s*' + $EUR)
    $desc = Find-Num $t ('Descuento\s*([\d.]+)\s*' + $EUR)
    if (-not $desc -and $pvp -and $ahora -and $ahora -lt $pvp) { $desc = $pvp - $ahora }
    if (-not $ahora) { continue }
    $extras = @("Versión $titulo")
    if ($t -match 'Seguro GRATIS') { $extras += 'Seguro a todo riesgo gratis el primer año financiando' }
    $o = New-Oferta $mod 'Kawa-GO!' $(if ($desc) { [int]$desc } else { $null }) $ahora $null $null $extras $hasta $u
    if (Test-Oferta $o) { $ofertas += $o }
  }
  return $ofertas
}

# ───────────────────────── Suzuki ─────────────────────────

function Update-Suzuki {
  $base = 'https://moto.suzuki.es'
  $tipos = @{ 'carretera' = 'Naked'; 'deportivas' = 'Deportiva'; 'scooter' = 'Scooter'; 'trail-sport-turismo' = 'Trail' }
  $todos = @()
  foreach ($cat in $tipos.Keys) {
    $h = Get-Pagina "$base/motos/$cat"
    if (-not $h) { throw "No responde Suzuki ($cat)" }
    $todos += [regex]::Matches($h, ('href="(' + [regex]::Escape($base) + '/motos/' + $cat + '/(20\d\d)/([A-Za-z0-9-]+))"')) |
      ForEach-Object { [pscustomobject]@{ url = $_.Groups[1].Value; cat = $cat; anio = [int]$_.Groups[2].Value; slug = $_.Groups[3].Value } }
  }
  $todos = $todos | Sort-Object url -Unique
  if (@($todos).Count -lt 8) { throw "Gama de Suzuki incompleta ($(@($todos).Count))" }

  foreach ($g in ($todos | Group-Object { Get-Base $_.slug })) {
    $existe = $false
    foreach ($x in $g.Group) { if (Find-Modelo 'suzuki' '' $x.url) { $existe = $true } }
    if ($existe) { continue }
    $rep = $g.Group | Sort-Object @{ e = { if ($_.slug -match '(?i)hamamatsu|edition|edicion|special') { 1 } else { 0 } } }, @{ e = { $_.slug.Length } }, @{ e = { $_.anio }; Descending = $true } | Select-Object -First 1
    $h = Get-Pagina $rep.url
    if (-not $h) { continue }
    $nombre = Format-Nombre (((Get-Titulo $h) -split '\|')[-1].Trim())
    if (-not $nombre -or (Find-Modelo 'suzuki' $nombre '')) { continue }
    $t = Get-Texto $h
    $f = @{
      cc = Find-Num $t 'Cilindrada:\s*([\d.,]+)\s*cc'
      cv = Find-Num $t 'Potencia:\s*([\d.,]+)\s*cv'
      nm = Find-Num $t 'Par m.ximo:\s*([\d.,]+)'
      peso = Find-Num $t 'Peso en vac.o:\s*([\d.,]+)'
      asiento = Find-Num $t 'Altura del asiento:\s*([\d.,]+)'
      deposito = Find-Num $t 'Dep.sito de gasolina:\s*([\d.,]+)'
      precio = Find-Precio $t ('Precio:\s*([\d.]+)\s*' + $EUR)
    }
    $tipo = $tipos[$rep.cat]
    if ($nombre -match 'GT\b|1000GX\b') { $tipo = 'Touring' } elseif ($nombre -match 'TT\b') { $tipo = 'Retro' } elseif ($nombre -match 'SM\b') { $tipo = 'Supermotard' }
    $mod = New-Modelo 'suzuki' $nombre $tipo $f $rep.url
    Add-Conocido 'suzuki' $mod
    Log "  Suzuki nuevo modelo: $nombre"
  }

  # Ofertas: cada tarjeta acaba en su enlace "solicita-informacion/<categoría>/<año>/<modelo>"
  $enlace = "$base/promociones"
  $ph = Get-Pagina $enlace
  if (-not $ph) { throw 'No responde la página de promociones de Suzuki' }
  $ofertas = @()
  $marcas = [regex]::Matches($ph, 'href="https://moto\.suzuki\.es/solicita-informacion/([a-z-]+)/(20\d\d)/([A-Za-z0-9-]+)"')
  $inicio = 0
  foreach ($m in $marcas) {
    # El trozo de cada tarjeta acaba justo antes de la etiqueta <a> de su enlace
    $fin = $ph.LastIndexOf('<a', $m.Index)
    if ($fin -lt $inicio) { $fin = $m.Index }
    $trozo = Get-Texto $ph.Substring($inicio, $fin - $inicio)
    $inicio = $m.Index + $m.Length
    $url = "$base/motos/$($m.Groups[1].Value)/$($m.Groups[2].Value)/$($m.Groups[3].Value)"
    $mod = Find-Modelo 'suzuki' $m.Groups[3].Value $url
    if (-not $mod) { continue }
    $precio = Find-Precio $trozo ('Precio:\s*([\d.]+)\s*' + $EUR)
    $promo = Find-Precio $trozo ('Precio promoci.n:\s*([\d.]+)\s*' + $EUR)
    if (-not ($precio -and $promo -and $promo -lt $precio)) { continue }
    $extras = @("Unidades $($m.Groups[2].Value)")
    $ext = [regex]::Match($trozo, ('Precio promoci.n:\s*[\d.]+\s*' + $EUR + '\*?\s*(.{4,160})$'))
    if ($ext.Success) {
      $e = ($ext.Groups[1].Value -replace '\*', '').Trim()
    }
    if ($ext.Success -and $e.Length -ge 4) {
      $e = $e.Substring(0, 1).ToUpperInvariant() + $e.Substring(1).ToLowerInvariant()
      $extras += $e
    }
    $o = New-Oferta $mod 'Promoción Suzuki' ($precio - $promo) $promo $null $null $extras $null $enlace
    if (Test-Oferta $o) { $ofertas += $o }
  }
  return $ofertas
}

# ───────────────────────── KTM ─────────────────────────

function Update-Ktm {
  $html = Get-Pagina 'https://www.ktm.com/es-es.html'
  if (-not $html) { throw 'No responde KTM' }
  $tipos = @{ 'naked-bike' = 'Naked'; 'adventure' = 'Trail'; 'sports-tourer' = 'Touring'; 'supersport' = 'Deportiva'; 'supermoto' = 'Supermotard'; 'dual-sport' = 'Trail' }
  $links = [regex]::Matches($html, 'href="(https://www\.ktm\.com/es-es/models/([a-z-]+)/(20\d\d)-ktm-([a-z0-9-]+)\.html)"') |
    ForEach-Object { [pscustomobject]@{ url = $_.Groups[1].Value; cat = $_.Groups[2].Value; anio = [int]$_.Groups[3].Value; slug = $_.Groups[4].Value } } |
    Where-Object { $tipos.ContainsKey($_.cat) } |
    Where-Object { $_.slug -notmatch 'track|rallyreplica|^690-rally$|^450-smr|^rc-8c' } |  # solo competición/circuito
    Sort-Object url -Unique
  if (@($links).Count -lt 10) { throw "Gama de KTM incompleta ($(@($links).Count))" }

  $ofertas = @()
  foreach ($g in ($links | Group-Object slug)) {
    $rep = $g.Group | Sort-Object anio -Descending | Select-Object -First 1
    $h = Get-Pagina $rep.url
    if (-not $h) { continue }
    $t = Get-Texto $h
    $tm = [regex]::Match((Get-Titulo $h), '^\s*20\d\d\s+KTM\s+(.+?)\s+-\s')
    $nombre = $(if ($tm.Success) { Format-Nombre $tm.Groups[1].Value } else { Format-Nombre ($rep.slug -replace '-', ' ') })
    $base = Find-Precio $t ('Precio Base:\s*([\d.,]+)\s*(?:EUR|' + $EUR + ')')
    $of = [regex]::Match($t, ('Precio en oferta:\s*([\d.,]+)\s*(?:EUR|' + $EUR + ')\*?\s*([\d.,]+)\s*(?:EUR|' + $EUR + ')'))
    $precioOf = $null; $pvp = $base
    if ($of.Success) { $precioOf = Find-Precio $of.Groups[1].Value '([\d.,]+)'; $pvp = Find-Precio $of.Groups[2].Value '([\d.,]+)' }

    $mod = Find-Modelo 'ktm' '' $rep.url
    if (-not $mod) {
      foreach ($x in $g.Group) { if (-not $mod) { $mod = Find-Modelo 'ktm' '' $x.url } }
    }
    if (-not $mod) {
      $f = @{
        cc = Find-Num $t 'Cilindrada\s+([\d.,]+)\s*cm'
        cv = Find-Num $t 'Potencia\s+([\d.,]+)\s*(?:PS|CV)'
        nm = Find-Num $t 'Par m.ximo\s+([\d.,]+)\s*Nm'
        precio = $pvp
      }
      $mod = New-Modelo 'ktm' $nombre $tipos[$rep.cat] $f $rep.url
      Add-Conocido 'ktm' $mod
      Log "  KTM nuevo modelo: $nombre"
    }
    if ($precioOf -and $pvp -and $precioOf -lt $pvp) {
      $o = New-Oferta $mod "Ofertas $($rep.anio)" ($pvp - $precioOf) $precioOf $null $null @('IVA incluido') $null $rep.url
      if (Test-Oferta $o) { $ofertas += $o }
    }
  }
  return $ofertas
}

# ───────────────────────── BMW Motorrad (web de promociones) ─────────────────────────

function Update-Bmw {
  $base = 'https://promociones.bmw-motorrad.es/motos-scooters/'
  $slug = { param($n) ((Remove-Tildes $n).ToLowerInvariant().Trim() -replace '[^a-z0-9]+', '-').Trim('-') }
  $cola = New-Object Collections.Generic.Queue[string]
  $vistos = @{}
  $aptaA2 = @{}
  foreach ($x in (Get-Conocidos 'bmw')) { $cola.Enqueue((& $slug $x.modelo)) }
  $ofertas = @()
  $leidas = 0
  while ($cola.Count -gt 0 -and $leidas -lt 60) {
    $s = $cola.Dequeue()
    if ($vistos.ContainsKey($s)) { continue }
    $vistos[$s] = $true
    $h = Get-Pagina ($base + $s)
    if (-not $h) { continue }
    $leidas++
    $t = Get-Texto $h
    # Modelos relacionados: "DESDE 9.960 € F 900 R  DISPONIBLE PARA CARNÉ A2"
    foreach ($r in [regex]::Matches($t, ('DESDE\s+([\d.]+)\s?' + $EUR + '\s+(.+?)\s+(?=(DISPONIBLE PARA CARN. A2)|DESDE\s+[\d.]+\s?' + $EUR + '|Precios recomendados)'))) {
      $n = $r.Groups[2].Value.Trim()
      if ($n.Length -gt 40) { continue }
      $sn = & $slug $n
      if ($r.Groups[3].Success) { $aptaA2[$sn] = $true }
      $cola.Enqueue($sn)
    }
    $cm = [regex]::Match($t, ('Precio de venta al contado para BMW\s+(.+?):\s*([\d.,]+)\s?' + $EUR))
    if (-not $cm.Success) { continue }
    $nombre = $cm.Groups[1].Value.Trim()
    $contado = Find-Precio $cm.Groups[2].Value '([\d.,]+)'
    $pvp = Find-Precio $t ('([\d.]+)\s?' + $EUR + '\s+PVP Recomendado')
    $cuota = Find-Num $t ('DESDE\s+([\d.,]+)\s?' + $EUR + '\s?/\s?mes')
    $url = $base + $s
    $mod = Find-Modelo 'bmw' $nombre ''
    if (-not $mod) {
      $a2 = $aptaA2.ContainsKey($s)
      $tipo = $(if ($nombre -match '^(CE|C)\s') { 'Scooter' } elseif ($nombre -match '\bGS\b') { 'Trail' } elseif ($nombre -match '\bRR\b') { 'Deportiva' } elseif ($nombre -match '\b(RT|XR|GT|K 1600)\b') { 'Touring' } elseif ($nombre -match '^(CE|C)\s') { 'Scooter' } elseif ($nombre -match '^R\s?\d+\s?$|nineT|R 18') { 'Retro' } else { 'Naked' })
      $f = @{ precio = $pvp }
      if ($a2) { $f.carnet = 'A2' } else { $f.carnet = 'A' }
      $mod = New-Modelo 'bmw' $nombre $tipo $f $url
      Add-Conocido 'bmw' $mod
      Log "  BMW nuevo modelo: $nombre"
    }
    if ($contado -and $pvp -and $contado -lt $pvp) {
      $extras = @('Precio al contado, sin matriculación ni pre-entrega')
      if ($cuota) { $extras += "O desde $cuota $EUR/mes con BMW Bank" }
      $o = New-Oferta $mod 'Precio al contado' ($pvp - $contado) $contado $null $null $extras (Get-FechaNum $t) $url
      if (Test-Oferta $o) { $ofertas += $o }
    }
  }
  if ($leidas -lt 3) { throw "Web de promociones de BMW sin datos ($leidas páginas)" }
  return $ofertas
}

# ───────────────────────── Triumph (solo modelos nuevos) ─────────────────────────

function Update-Triumph {
  $base = 'https://www.triumphmotorcycles.es'
  $sm = Get-Pagina "$base/sitemap.xml"
  if (-not $sm) { throw 'No responde el mapa web de Triumph' }
  $tipos = @{ 'classic' = 'Retro'; 'roadsters' = 'Naked'; 'adventure' = 'Trail'; 'sport' = 'Deportiva'; 'rocket-3' = 'Custom'; 'cruiser' = 'Custom' }
  $raices = [regex]::Matches($sm, '<loc>(https://www\.triumphmotorcycles\.es/bikes/([a-z0-9-]+)/([a-z0-9-]+))/specification</loc>') |
    ForEach-Object { [pscustomobject]@{ url = $_.Groups[1].Value; cat = $_.Groups[2].Value; slug = $_.Groups[3].Value } } |
    Where-Object { $tipos.ContainsKey($_.cat) } | Sort-Object url -Unique
  if (@($raices).Count -lt 6) { throw "Gama de Triumph incompleta ($(@($raices).Count))" }
  # Fuera páginas antiguas cuyo nombre es prefijo de otra más concreta (street-triple → street-triple-765)
  $raices = $raices | Where-Object { $r = $_; -not ($raices | Where-Object { $_.slug -ne $r.slug -and $_.slug.StartsWith($r.slug + '-') }) }
  foreach ($r in $raices) {
    if (Find-Modelo 'triumph' '' $r.url) { continue }
    $h = Get-Pagina $r.url
    if (-not $h) { continue }
    # Nombre del título si es corto y no es una frase; si no, el de la dirección (speed-400 → Speed 400)
    $corte = '\||\s[-' + [char]0x2013 + ']\s'
    $tn = (((Get-Titulo $h) -split $corte)[0] -replace '(?i)^\s*triumph\s+', '').Trim()
    if (-not $tn -or $tn.Length -gt 28 -or $tn -match '(?i)\s(de|la|las|el|por|para|con|tu)\s') { $tn = $r.slug -replace '-', ' ' }
    $nombre = Format-Nombre $tn
    if (-not $nombre -or (Find-Modelo 'triumph' $nombre '')) { continue }
    $t = Get-Texto (Get-Pagina ($r.url + '/specification'))
    $f = @{
      cc = Find-Num $t 'Cilindrada\s+([\d.,]+)\s*cc'
      cv = Find-Num $t 'Potencia m.xima CE\s+([\d.,]+)\s*(?:CV|PS)'
      nm = Find-Num $t 'Par m.ximo CE\s+([\d.,]+)\s*Nm'
      peso = Find-Num $t 'Peso en orden de marcha\s+([\d.,]+)'
      asiento = Find-Num $t 'Altura del asiento\s+([\d.,]+)'
      deposito = Find-Num $t 'Capacidad del dep.sito\s+([\d.,]+)'
      precio = Find-Precio (Get-Texto (Get-Pagina ($r.url + '/models'))) ('Desde\s+([\d.,]+)\s*' + $EUR)
    }
    # Sin cilindrada ni precio no es una ficha de modelo a la venta (páginas antiguas o genéricas)
    if (-not $f.cc -or -not $f.precio -or $nombre -match '(?i)website|motorcycles') { continue }
    $mod = New-Modelo 'triumph' $nombre $tipos[$r.cat] $f $r.url
    Add-Conocido 'triumph' $mod
    Log "  Triumph nuevo modelo: $nombre"
  }
  return @()
}

# ───────────────────────── Harley-Davidson (solo modelos nuevos) ─────────────────────────

function Update-Harley {
  $base = 'https://www.harley-davidson.com'
  $html = Get-Pagina "$base/es/es/motorcycles/index.html"
  if (-not $html) { throw 'No responde Harley-Davidson' }
  $categorias = @('index', 'adventure-touring', 'cruiser', 'sport', 'touring', 'trike', 'grand-american-touring', 'street', 'future', 'electric')
  $links = [regex]::Matches($html, 'href=["''](?:https://www\.harley-davidson\.com)?(/es/es/motorcycles/([a-z0-9-]+)\.html)["''#?]') |
    ForEach-Object { [pscustomobject]@{ url = $base + $_.Groups[1].Value; slug = $_.Groups[2].Value } } |
    Where-Object { $categorias -notcontains $_.slug -and $_.slug -notmatch '^tri-|glide-3' } | Sort-Object url -Unique  # fuera los triciclos
  if (@($links).Count -lt 6) { throw "Gama de Harley-Davidson incompleta ($(@($links).Count))" }
  foreach ($l in $links) {
    if (Find-Modelo 'harley' '' $l.url) { continue }
    $nombre = (($l.slug -split '-') | ForEach-Object { if ($_ -in @('cvo', 'st', 's', 'gt')) { $_.ToUpperInvariant() } else { $_.Substring(0, 1).ToUpperInvariant() + $_.Substring(1) } }) -join ' '
    if (Find-Modelo 'harley' $nombre '') { continue }
    $t = Get-Texto (Get-Pagina $l.url)
    if (-not $t) { continue }
    $f = @{
      cc = Find-Num $t 'Cilindrada\s+([\d.,]+)\s*cc'
      cv = Find-Num $t 'Potencia\s+([\d.,]+)\s*CV'
      nm = Find-Num $t 'Par motor\s*\+?\s*([\d.,]+)\s*Nm'
      peso = Find-Num $t '([\d.,]+)\s*kg\s+Peso en orden de marcha'
      asiento = Find-Num $t '([\d.,]+)\s*mm\s+Altura del asiento'
      precio = Find-Precio $t ('A partir de\s+([\d.]+)\s*' + $EUR)
    }
    $tipo = $(if ($nombre -match 'Glide|Road King|Electra') { 'Touring' } elseif ($nombre -match 'Pan America') { 'Trail' } else { 'Custom' })
    $mod = New-Modelo 'harley' $nombre $tipo $f $l.url
    Add-Conocido 'harley' $mod
    Log "  Harley-Davidson nuevo modelo: $nombre"
  }
  return @()
}

# ───────────────────────── Royal Enfield (solo modelos nuevos) ─────────────────────────

function Update-RoyalEnfield {
  $lista = 'https://www.royalenfield.com/es/es/motorcycles/'
  $html = Get-Pagina $lista
  if (-not $html) { throw 'No responde Royal Enfield' }
  $links = [regex]::Matches($html, '/es/es/motorcycles/([a-z0-9-]+)/') |
    ForEach-Object { [pscustomobject]@{ url = 'https://www.royalenfield.com/es/es/motorcycles/' + $_.Groups[1].Value + '/'; slug = $_.Groups[1].Value } } |
    Sort-Object url -Unique
  if (@($links).Count -lt 5) { throw "Gama de Royal Enfield incompleta ($(@($links).Count))" }
  foreach ($l in $links) {
    if (Find-Modelo 'royalenfield' '' $l.url) { continue }
    $h = Get-Pagina $l.url
    if (-not $h) { continue }
    # "Royal Enfield Bullet 350 Precio, Imágenes…" o "Precio y colores de la Royal Enfield Goan Classic 350 en España"
    $tm = [regex]::Match((Get-Titulo $h), '(?i)Royal Enfield\s+(.+?)(?=\s+(?:(?:Moto|Motorcycle|Precios?|Prices?|Motocicleta|Colou?rs?)\b|en Espa)|\s*[|&,]|$)')
    $nombre = $(if ($tm.Success) { $tm.Groups[1].Value.Trim() } else { Format-Nombre ($l.slug -replace '-', ' ') })
    if (-not $nombre -or $nombre.Length -gt 40 -or (Find-Modelo 'royalenfield' $nombre '')) { continue }
    $t = Get-Texto $h
    $kw = Find-Num $t '([\d.,]+)\s*kW'
    $f = @{
      cc = Find-Num $t '(\d{3})\s*cc'
      cv = $(if ($kw) { [math]::Round($kw * 1.36, 1) } else { $null })
      nm = Find-Num $t '([\d.,]+)\s*Nm'
      precio = Find-Precio $t ('([\d.]+)\s*' + $EUR)
      carnet = 'A2'  # toda la gama Royal Enfield está por debajo de 35 kW
    }
    $tipo = $(if ($nombre -match 'Himalayan|Scram') { 'Trail' } elseif ($nombre -match 'Meteor|Shotgun') { 'Custom' } elseif ($nombre -match 'Guerrilla') { 'Naked' } else { 'Retro' })
    $mod = New-Modelo 'royalenfield' $nombre $tipo $f $l.url
    Add-Conocido 'royalenfield' $mod
    Log "  Royal Enfield nuevo modelo: $nombre"
  }
  return @()
}

# ───────────────────────── Ejecución ─────────────────────────

$Fuentes = [ordered]@{
  honda = ${function:Update-Honda}; kawasaki = ${function:Update-Kawasaki}; suzuki = ${function:Update-Suzuki}; ktm = ${function:Update-Ktm}
  bmw = ${function:Update-Bmw}; triumph = ${function:Update-Triumph}; harley = ${function:Update-Harley}; royalenfield = ${function:Update-RoyalEnfield}
}
$ConOfertas = @('honda', 'kawasaki', 'suzuki', 'ktm', 'bmw')

$Resultado = [ordered]@{}
foreach ($marca in $Fuentes.Keys) {
  Log "== $marca"
  $previo = Get-Previo $marca
  try {
    $ofs = @(& $Fuentes[$marca])
    $mods = @(); if ($Conocidos.ContainsKey($marca)) { $mods = @($Conocidos[$marca]) }
    # Si una marca con ofertas no devuelve ninguna pero antes tenía varias, se sospecha de un cambio en su web
    if ($ConOfertas -contains $marca -and $ofs.Count -eq 0 -and $previo -and @($previo.ofertas).Count -ge 2) { throw 'Cero ofertas cuando antes había varias: se conservan las anteriores' }
    $n = 0
    foreach ($o in $ofs) { $n++; $o.id = "$marca-auto-$n-" + ($o.modelo -replace '^[a-z]+-', '') }
    $Resultado[$marca] = [ordered]@{ ok = $true; revisado = $Hoy; error = $null; modelos = $mods; ofertas = $ofs }
    Log "   OK: $($mods.Count) modelos nuevos, $($ofs.Count) ofertas"
  } catch {
    Log "   ERROR: $($_.Exception.Message)"
    if ($previo) {
      $Resultado[$marca] = [ordered]@{ ok = $false; revisado = $previo.revisado; error = $_.Exception.Message; modelos = @($previo.modelos); ofertas = @($previo.ofertas) }
      # Los modelos anteriores siguen siendo conocidos para las marcas siguientes
      foreach ($pm in @($previo.modelos)) { Add-Conocido $marca $pm }
    } else {
      $Resultado[$marca] = [ordered]@{ ok = $false; revisado = $null; error = $_.Exception.Message; modelos = @(); ofertas = @() }
    }
  }
}

# ───────────────────────── Escritura ─────────────────────────

$todosModelos = @(); $todasOfertas = @(); $marcasOk = @()
foreach ($k in $Resultado.Keys) {
  $todosModelos += @($Resultado[$k].modelos)
  $todasOfertas += @($Resultado[$k].ofertas)
  if ($ConOfertas -contains $k -and $Resultado[$k].revisado) { $marcasOk += $k }
}
$estadoNuevo = [ordered]@{ actualizado = $Hoy; marcas = $Resultado }
[IO.File]::WriteAllText($RutaEstado, (ConvertTo-Json -InputObject $estadoNuevo -Depth 8), $Utf8)

$publico = [ordered]@{ actualizado = $Hoy; marcasConOfertasAuto = $marcasOk; modelos = $todosModelos; ofertas = $todasOfertas }
$json = ConvertTo-Json -InputObject $publico -Depth 6 -Compress
$js = @"
/*
 * GENERADO AUTOMÁTICAMENTE por scripts/actualizar.ps1 — no editar a mano.
 * Añade al catálogo los modelos nuevos detectados en las webs oficiales y sustituye
 * las ofertas de las marcas que se leen automáticamente por las vigentes hoy.
 */
window.AUTO = $json;
(function () {
  var A = window.AUTO, C = window.CATALOGO;
  if (!A || !C) return;
  var ids = {}, marcaDe = {}, auto = {};
  C.modelos.forEach(function (m) { ids[m.id] = true; });
  (A.modelos || []).forEach(function (m) { if (!ids[m.id]) { C.modelos.push(m); ids[m.id] = true; } });
  C.modelos.forEach(function (m) { marcaDe[m.id] = m.marca; });
  (A.marcasConOfertasAuto || []).forEach(function (b) { auto[b] = true; });
  window.OFERTAS = (window.OFERTAS || []).filter(function (o) { return !auto[marcaDe[o.modelo]]; })
    .concat((A.ofertas || []).filter(function (o) { return ids[o.modelo]; }));
  if (A.actualizado) C.revisado = A.actualizado;
})();
"@
[IO.File]::WriteAllText($RutaSalida, $js, $Utf8)
Log "Escrito data/auto.js: $($todosModelos.Count) modelos nuevos y $($todasOfertas.Count) ofertas"
$fallos = @($Resultado.Keys | Where-Object { -not $Resultado[$_].ok })
if ($fallos.Count) { Log "Marcas con error (se han conservado sus datos anteriores): $($fallos -join ', ')" }
