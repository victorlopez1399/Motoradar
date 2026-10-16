#requires -Version 5.1
<#
  Publica en un canal de Telegram las ofertas que han aparecido desde la última actualización.

  Necesita dos secretos del repositorio de GitHub (ver MONETIZAR.md):
    TELEGRAM_BOT_TOKEN   token del bot creado con @BotFather
    TELEGRAM_CHAT_ID     nombre del canal (ej. @motoradar_ofertas) con el bot como administrador
  Sin ellos, solo muestra en el registro lo que publicaría.

  Uso:  scripts/telegram.ps1 -Previo <ruta del data/auto.json anterior>
#>
param([string]$Previo, [string]$Raiz = (Split-Path -Parent $PSScriptRoot), [int]$Maximo = 10)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$EUR = [string][char]0x20AC

if (-not $Previo -or -not (Test-Path $Previo)) { Write-Host 'Sin datos anteriores: no se publica nada (evita repetir todas las ofertas en la primera ejecución).'; return }
$actual = [IO.File]::ReadAllText((Join-Path $Raiz 'data\auto.json'), [Text.Encoding]::UTF8) | ConvertFrom-Json
$antes = [IO.File]::ReadAllText($Previo, [Text.Encoding]::UTF8) | ConvertFrom-Json

function Get-Ofertas($e) { $l = @(); foreach ($k in $e.marcas.PSObject.Properties.Name) { $l += @($e.marcas.$k.ofertas | Where-Object { $_ }) }; return $l }
function Get-Clave($o) { return '{0}|{1}|{2}|{3}|{4}' -f $o.modelo, $o.precioOferta, $o.cuota, $o.descuento, $o.regalo }

$vistas = @{}; foreach ($o in (Get-Ofertas $antes)) { $vistas[(Get-Clave $o)] = $true }
$nuevas = @(Get-Ofertas $actual | Where-Object { -not $vistas[(Get-Clave $_)] } | Sort-Object @{ e = { [double]$(if ($_.descuento) { $_.descuento } else { 0 }) }; Descending = $true } | Select-Object -First $Maximo)
if (-not $nuevas.Count) { Write-Host 'No hay ofertas nuevas.'; return }

# Nombres de marcas y modelos, y dirección de la página de cada moto
$marcas = @{}; $modelos = @{}
foreach ($l in [IO.File]::ReadAllLines((Join-Path $Raiz 'data\catalogo.js'), [Text.Encoding]::UTF8)) {
  $m = [regex]::Match($l, 'id:\s*"([^"]+)",\s*nombre:\s*"([^"]+)"'); if ($m.Success) { $marcas[$m.Groups[1].Value] = $m.Groups[2].Value }
  $m = [regex]::Match($l, 'id:\s*"([^"]+)",\s*marca:\s*"([^"]+)",\s*modelo:\s*"([^"]+)"'); if ($m.Success) { $modelos[$m.Groups[1].Value] = @{ marca = $m.Groups[2].Value; modelo = $m.Groups[3].Value } }
}
foreach ($k in $actual.marcas.PSObject.Properties.Name) { foreach ($m in @($actual.marcas.$k.modelos)) { if ($m) { $modelos[$m.id] = @{ marca = $m.marca; modelo = $m.modelo } } } }
$paginas = @{}
$rutaPag = Join-Path $Raiz 'data\paginas.js'
if (Test-Path $rutaPag) {
  $j = [IO.File]::ReadAllText($rutaPag, [Text.Encoding]::UTF8)
  $j = $j.Substring($j.IndexOf('{')).Trim().TrimEnd(';')
  $pj = $j | ConvertFrom-Json
  foreach ($p in $pj.PSObject.Properties) { $paginas[$p.Name] = $p.Value }
}
$base = ''
$ms = [regex]::Match([IO.File]::ReadAllText((Join-Path $Raiz 'data\sitio.js'), [Text.Encoding]::UTF8), 'url:\s*"([^"]+)"')
if ($ms.Success) { $base = $ms.Groups[1].Value.TrimEnd('/') }

function Format-Eur($n) { $s = ([math]::Round([double]$n)).ToString('0'); return ([regex]::Replace($s, '\B(?=(\d{3})+(?!\d))', '.')) + " $EUR" }
function Enc($s) { if ($null -eq $s) { return '' }; return ([string]$s).Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;').Replace('"', '&quot;') }
$token = $env:TELEGRAM_BOT_TOKEN; $chat = $env:TELEGRAM_CHAT_ID
foreach ($o in $nuevas) {
  $info = $modelos[$o.modelo]; if (-not $info) { continue }
  $nombre = "$($marcas[$info.marca]) $($info.modelo)".Trim()
  $linea = $(if ($o.descuento -and $o.precioOferta) { "<b>$(Format-Eur $o.precioOferta)</b> (−$(Format-Eur $o.descuento))" } elseif ($o.cuota) { "<b>$($o.cuota) $EUR/mes</b>" } elseif ($o.regalo) { "<b>Regalo:</b> $(Enc $o.regalo)" } else { '' })
  $hasta = $(if ($o.hasta) { "`nVálida hasta el " + ([datetime]::ParseExact($o.hasta, 'yyyy-MM-dd', $null)).ToString('d/M/yyyy') } else { '' })
  $extras = $(if ($o.extras) { "`n" + (Enc ((@($o.extras)) -join ' · ')) } else { '' })
  $enlace = $(if ($base -and $paginas[$o.modelo]) { "$base/$($paginas[$o.modelo])" } else { $o.enlace })
  $texto = "🏍️ <b>$(Enc $nombre)</b>`n$linea$hasta$extras`n`n👉 <a href=""$(Enc $enlace)"">Ver ficha y oferta oficial</a>"
  if (-not $token -or -not $chat) { Write-Host "[sin bot configurado] $($texto -replace '<[^>]+>', '')"; continue }
  # El texto va en un archivo UTF-8: así las tildes y los emojis llegan bien desde Windows
  $tmp = [IO.Path]::GetTempFileName()
  [IO.File]::WriteAllText($tmp, $texto, (New-Object Text.UTF8Encoding $false))
  $r = & curl.exe -s -X POST "https://api.telegram.org/bot$token/sendMessage" --data-urlencode "chat_id=$chat" --data-urlencode "text@$tmp" --data-urlencode 'parse_mode=HTML'
  Remove-Item $tmp -Confirm:$false
  if (($r -join '') -notmatch '"ok":true') { Write-Host "Telegram rechazó el mensaje: $($r -join '')" } else { Write-Host "Publicada: $nombre" }
  Start-Sleep -Seconds 3
}
