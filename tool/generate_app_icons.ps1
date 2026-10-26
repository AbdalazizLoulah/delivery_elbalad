# توليد أيقونة التطبيق (launcher) وشعار شاشة البداية من نفس شكل اللوجو
# اللي جوّه التطبيق: مربع أبيض بحواف دائرية + أيقونة "delivery_dining" الخضراء.
#
# التشغيل من جذر المشروع:
#   powershell -ExecutionPolicy Bypass -File tool\generate_app_icons.ps1
Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$res = Join-Path $root 'android\app\src\main\res'

# مسار خط Material Icons جوه Flutter SDK (بيتغير حسب مكان الفلاتر).
$flutterRoot = Split-Path (Split-Path (Get-Command flutter).Source -Parent) -Parent
$fontPath = Join-Path $flutterRoot 'bin\cache\artifacts\material_fonts\materialicons-regular.otf'
if (-not (Test-Path $fontPath)) {
  $fontPath = Join-Path $env:LOCALAPPDATA 'flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf'
}
if (-not (Test-Path $fontPath)) { throw "MaterialIcons font not found at $fontPath" }

$fonts = New-Object System.Drawing.Text.PrivateFontCollection
$fonts.AddFontFile($fontPath)
$family = $fonts.Families[0]

$Glyph = [string][char]0xE1BD            # Icons.delivery_dining
$Green = [System.Drawing.Color]::FromArgb(255, 15, 110, 92)   # AppColors.primary
$White = [System.Drawing.Color]::White
$Supersample = 4

function New-Canvas([int]$size) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $bmp.SetResolution(96, 96)
  $graphics = [System.Drawing.Graphics]::FromImage($bmp)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
  return @{ Bitmap = $bmp; Graphics = $graphics }
}

function New-RoundedPath([float]$w, [float]$h, [float]$radius) {
  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $d = $radius * 2
  $path.AddArc(0, 0, $d, $d, 180, 90)
  $path.AddArc($w - $d, 0, $d, $d, 270, 90)
  $path.AddArc($w - $d, $h - $d, $d, $d, 0, 90)
  $path.AddArc(0, $h - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  return $path
}

function Get-GlyphFont([System.Drawing.Graphics]$graphics, [float]$targetHeight) {
  $probeSize = 200
  $probe = New-Object System.Drawing.Font($script:family, $probeSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $fmt = [System.Drawing.StringFormat]::GenericTypographic
  $m = $graphics.MeasureString($script:Glyph, $probe, [System.Drawing.PointF]::new(0, 0), $fmt)
  $probe.Dispose()
  $ratio = $m.Height / $probeSize
  return [float]($targetHeight / $ratio)
}

# بترسم الأيقونة على كانفاس مربع: خلفية (اختيارية) + الجليف في النص بالظبط.
function Draw-Icon([System.Drawing.Graphics]$graphics, [float]$canvas, [bool]$withBackground, [float]$glyphRatio, [float]$radiusRatio = 0.23) {
  if ($withBackground) {
    $path = New-RoundedPath $canvas $canvas ($canvas * $radiusRatio)
    $brush = New-Object System.Drawing.SolidBrush($script:White)
    $graphics.FillPath($brush, $path)
    $brush.Dispose()
    $path.Dispose()
  }

  $fontSize = Get-GlyphFont $graphics ($canvas * $glyphRatio)
  $font = New-Object System.Drawing.Font($script:family, $fontSize, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
  $fmt = New-Object System.Drawing.StringFormat
  $fmt.Alignment = [System.Drawing.StringAlignment]::Center
  $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
  $fmt.FormatFlags = [System.Drawing.StringFormatFlags]::NoClip
  $rect = New-Object System.Drawing.RectangleF 0, 0, $canvas, $canvas
  $fill = New-Object System.Drawing.SolidBrush($script:Green)
  $graphics.DrawString($script:Glyph, $font, $fill, $rect, $fmt)
  $fill.Dispose()
  $font.Dispose()
}

# بترسم بحجم أكبر 4 مرات وبعدين تصغّر — نتيجة أنعم وأنضف.
function Save-Icon([string]$path, [int]$size, [bool]$withBackground, [float]$glyphRatio, [float]$radiusRatio = 0.23) {
  $big = $size * $script:Supersample
  $canvas = New-Canvas $big
  Draw-Icon $canvas.Graphics $big $withBackground $glyphRatio $radiusRatio
  $canvas.Graphics.Dispose()

  $target = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  $target.SetResolution(96, 96)
  $tg = [System.Drawing.Graphics]::FromImage($target)
  $tg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $tg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $tg.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $tg.DrawImage($canvas.Bitmap, 0, 0, $size, $size)
  $tg.Dispose()
  $canvas.Bitmap.Dispose()

  $dir = Split-Path $path -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  $target.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $target.Dispose()
  Write-Host "saved $path"
}

# أيقونة اللانشر (النسخة القديمة 48..192 بكسل) — مربع أبيض + سكوتر أخضر.
$legacySizes = @{ 'mipmap-mdpi' = 48; 'mipmap-hdpi' = 72; 'mipmap-xhdpi' = 96; 'mipmap-xxhdpi' = 144; 'mipmap-xxxhdpi' = 192 }
foreach ($entry in $legacySizes.GetEnumerator()) {
  Save-Icon (Join-Path $res "$($entry.Key)\ic_launcher.png") $entry.Value $true 0.56
}

# طبقة واجهة الأيقونة التكيفية (Android 8+) — الجليف لوحده على خلفية شفافة.
$adaptiveSizes = @{ 'mipmap-mdpi' = 108; 'mipmap-hdpi' = 162; 'mipmap-xhdpi' = 216; 'mipmap-xxhdpi' = 324; 'mipmap-xxxhdpi' = 432 }
foreach ($entry in $adaptiveSizes.GetEnumerator()) {
  Save-Icon (Join-Path $res "$($entry.Key)\ic_launcher_foreground.png") $entry.Value $false 0.50
}

# شعار شاشة البداية (native splash) — نفس مقاس اللوجو اللي في شاشة فلاتر
# بالظبط (104dp) عشان مفيش "نطّة" لما التطبيق يفتح.
$splashSizes = @{ 'drawable-mdpi' = 104; 'drawable-hdpi' = 156; 'drawable-xhdpi' = 208; 'drawable-xxhdpi' = 312; 'drawable-xxxhdpi' = 416 }
foreach ($entry in $splashSizes.GetEnumerator()) {
  Save-Icon (Join-Path $res "$($entry.Key)\splash_logo.png") $entry.Value $true 0.577 0.2885
}
$oldSplash = Join-Path $res 'drawable-nodpi\splash_logo.png'
if (Test-Path $oldSplash) { Remove-Item $oldSplash }

Write-Host 'Done.'
