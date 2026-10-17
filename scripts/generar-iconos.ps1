#requires -Version 5.1
<#
  Dibuja la identidad visual de MotoRadar (logotipo de radar) en todos los tamaños que piden
  la web instalable y las tiendas de aplicaciones:

    icons/                 iconos de la web instalable (192, 512, maskable) y apple-touch-icon
    app/assets/            fuentes para la app nativa: icono 1024, primer plano y fondo
                           del icono adaptable de Android, pantallas de carga
    app/tienda/graficos/   icono 512 de Google Play y gráfico destacado 1024x500

  Uso:  powershell -ExecutionPolicy Bypass -File scripts/generar-iconos.ps1
#>
param([string]$Raiz = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$Fondo = [Drawing.Color]::FromArgb(7, 7, 10)
$Lima = [Drawing.Color]::FromArgb(215, 255, 58)

function New-Lienzo([int]$w, [int]$h, [bool]$transparente = $false) {
  $bmp = New-Object Drawing.Bitmap $w, $h, ([Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $g = [Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.PixelOffsetMode = 'HighQuality'; $g.TextRenderingHint = 'AntiAliasGridFit'
  if ($transparente) { $g.Clear([Drawing.Color]::Transparent) } else { $g.Clear($Fondo) }
  return @{ bmp = $bmp; g = $g }
}

# Radar: aro, barrido, aguja y punto central. (cx, cy) centro, r radio exterior
function Draw-Radar($g, [double]$cx, [double]$cy, [double]$r) {
  $grosor = [math]::Max(2, $r * 0.13)
  # barrido con degradado de transparencia (varias porciones)
  for ($i = 0; $i -lt 18; $i++) {
    $alfa = [int](10 + $i * 9)
    $b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb($alfa, 215, 255, 58))
    $g.FillPie($b, [float]($cx - $r * 0.86), [float]($cy - $r * 0.86), [float]($r * 1.72), [float]($r * 1.72), [float](-130 + $i * 3), [float]3.4)
    $b.Dispose()
  }
  $pen = New-Object Drawing.Pen $Lima, ([float]$grosor)
  $g.DrawEllipse($pen, [float]($cx - $r + $grosor / 2), [float]($cy - $r + $grosor / 2), [float](2 * $r - $grosor), [float](2 * $r - $grosor))
  $penFino = New-Object Drawing.Pen ([Drawing.Color]::FromArgb(90, 215, 255, 58)), ([float]([math]::Max(1, $r * 0.035)))
  $g.DrawEllipse($penFino, [float]($cx - $r * 0.55), [float]($cy - $r * 0.55), [float]($r * 1.1), [float]($r * 1.1))
  $aguja = New-Object Drawing.Pen $Lima, ([float]$grosor)
  $aguja.StartCap = 'Round'; $aguja.EndCap = 'Round'
  $ang = -78 * [math]::PI / 180
  $g.DrawLine($aguja, [float]$cx, [float]$cy, [float]($cx + [math]::Cos($ang) * $r * 0.72), [float]($cy + [math]::Sin($ang) * $r * 0.72))
  $d = $r * 0.26
  $g.FillEllipse((New-Object Drawing.SolidBrush $Lima), [float]($cx - $d / 2), [float]($cy - $d / 2), [float]$d, [float]$d)
  # eco detectado
  $e = $r * 0.12
  $g.FillEllipse((New-Object Drawing.SolidBrush $Lima), [float]($cx + $r * 0.38), [float]($cy + $r * 0.22), [float]$e, [float]$e)
}

function Save-Png($lienzo, [string]$ruta) {
  New-Item -ItemType Directory -Force (Split-Path $ruta -Parent) | Out-Null
  $lienzo.bmp.Save($ruta, [Drawing.Imaging.ImageFormat]::Png)
  $lienzo.g.Dispose(); $lienzo.bmp.Dispose()
}

function New-Icono([int]$tam, [double]$escala, [string]$ruta, [bool]$transparente = $false) {
  $l = New-Lienzo $tam $tam $transparente
  Draw-Radar $l.g ($tam / 2) ($tam / 2) ($tam / 2 * $escala)
  Save-Png $l $ruta
}

# Web instalable
New-Icono 192 0.78 (Join-Path $Raiz 'icons\icon-192.png')
New-Icono 512 0.78 (Join-Path $Raiz 'icons\icon-512.png')
New-Icono 512 0.58 (Join-Path $Raiz 'icons\icon-maskable-512.png')   # zona segura del 80 %
New-Icono 180 0.74 (Join-Path $Raiz 'icons\apple-touch-icon.png')

# App nativa (@capacitor/assets genera todos los tamaños a partir de estos)
New-Icono 1024 0.74 (Join-Path $Raiz 'app\assets\icon-only.png')
New-Icono 1024 0.50 (Join-Path $Raiz 'app\assets\icon-foreground.png') $true
$lienzoFondo = New-Lienzo 1024 1024; Save-Png $lienzoFondo (Join-Path $Raiz 'app\assets\icon-background.png')
foreach ($nombre in 'splash.png', 'splash-dark.png') {
  $l = New-Lienzo 2732 2732
  Draw-Radar $l.g 1366 1250 260
  $f = New-Object Drawing.Font 'Arial Black', 150, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)
  $fmt = New-Object Drawing.StringFormat; $fmt.Alignment = 'Center'
  $l.g.DrawString('MOTO', $f, [Drawing.Brushes]::White, (New-Object Drawing.RectangleF 0, 1580, 2732, 200), $fmt)
  $l.g.DrawString('RADAR', $f, (New-Object Drawing.SolidBrush $Lima), (New-Object Drawing.RectangleF 0, 1760, 2732, 200), $fmt)
  Save-Png $l (Join-Path $Raiz "app\assets\$nombre")
}

# Fichas de tienda
New-Icono 512 0.74 (Join-Path $Raiz 'app\tienda\graficos\icono-play-512.png')
$l = New-Lienzo 1024 500
Draw-Radar $l.g 820 250 190
$l.g.DrawString('MOTO', (New-Object Drawing.Font 'Arial Black', 92, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)), [Drawing.Brushes]::White, 52, 70)
$l.g.DrawString('RADAR', (New-Object Drawing.Font 'Arial Black', 92, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)), (New-Object Drawing.SolidBrush $Lima), 52, 170)
$l.g.DrawString('Ofertas oficiales de motos en España', (New-Object Drawing.Font 'Arial', 30, ([Drawing.FontStyle]::Bold), ([Drawing.GraphicsUnit]::Pixel)), [Drawing.Brushes]::White, 58, 320)
$l.g.DrawString('Actualizadas cada día', (New-Object Drawing.Font 'Arial', 26, ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel)), (New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(170, 172, 185))), 58, 365)
Save-Png $l (Join-Path $Raiz 'app\tienda\graficos\grafico-destacado-1024x500.png')

Write-Host 'Iconos e imágenes generados.'
