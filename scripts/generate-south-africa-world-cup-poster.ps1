$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$outDir = Join-Path $root 'assets'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$out = Join-Path $outDir 'south-africa-world-cup-poster.png'

Add-Type -AssemblyName System.Drawing

$w = 1536
$h = 2048
$bmp = [System.Drawing.Bitmap]::new($w, $h)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

function Color-Hex($hex) {
    $hex = $hex.TrimStart('#')
    [System.Drawing.Color]::FromArgb(
        [Convert]::ToInt32($hex.Substring(0, 2), 16),
        [Convert]::ToInt32($hex.Substring(2, 2), 16),
        [Convert]::ToInt32($hex.Substring(4, 2), 16)
    )
}

function Color-Alpha($alpha, $hex) {
    $c = Color-Hex $hex
    [System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)
}

function Use-Brush([System.Drawing.Color]$color, [scriptblock]$body) {
    if ($color.IsEmpty) {
        throw "Brush color was empty near: $((Get-PSCallStack | Select-Object -Skip 1 -First 1).FunctionName)"
    }
    $brush = [System.Drawing.SolidBrush]::new($color)
    try { & $body $brush } finally { $brush.Dispose() }
}

function Use-Pen([System.Drawing.Color]$color, [single]$width, [scriptblock]$body) {
    $pen = [System.Drawing.Pen]::new($color, $width)
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    try { & $body $pen } finally { $pen.Dispose() }
}

function Fill-Poly($points, [System.Drawing.Color]$color) {
    Use-Brush $color { param($brush) $g.FillPolygon($brush, [System.Drawing.PointF[]]$points) }
}

function Stroke-Bezier($p1, $p2, $p3, $p4, [System.Drawing.Color]$color, [single]$width) {
    Use-Pen $color $width { param($pen) $g.DrawBezier($pen, $p1, $p2, $p3, $p4) }
}

function Draw-CenteredText([string]$text, [System.Drawing.Font]$font, [System.Drawing.Color]$color, [single]$y, [single]$height = 260) {
    $sf = [System.Drawing.StringFormat]::new()
    $sf.Alignment = [System.Drawing.StringAlignment]::Center
    $sf.LineAlignment = [System.Drawing.StringAlignment]::Near
    $rect = [System.Drawing.RectangleF]::new(0, $y, $script:w, $height)
    Use-Brush $color { param($brush) $script:g.DrawString($text, $font, $brush, $rect, $sf) }
    $sf.Dispose()
}

function New-Font($name, $size, $style = [System.Drawing.FontStyle]::Regular) {
    $font = [System.Drawing.Font]::new($name, $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
    if ($font.Name -eq $name) { return $font }
    $font.Dispose()
    [System.Drawing.Font]::new('Arial', $size, $style, [System.Drawing.GraphicsUnit]::Pixel)
}

function Draw-Vuvuzela($x, $y, $angle, $scale, $colorHex) {
    $state = $g.Save()
    $g.TranslateTransform($x, $y)
    $g.RotateTransform($angle)
    $g.ScaleTransform($scale, $scale)
    Use-Brush (Color-Alpha 205 $colorHex) {
        param($brush)
        $pts = @(
            [System.Drawing.PointF]::new(0, 0),
            [System.Drawing.PointF]::new(470, -42),
            [System.Drawing.PointF]::new(470, 42)
        )
        $g.FillPolygon($brush, [System.Drawing.PointF[]]$pts)
        $g.FillEllipse($brush, 420, -92, 168, 184)
    }
    Use-Pen ([System.Drawing.Color]::FromArgb(165, 255, 255, 255)) 5 {
        param($pen) $g.DrawLine($pen, 12, 0, 465, 0)
    }
    $g.Restore($state)
}

# Poster background: South African flag energy without copying official event art.
$bgRect = [System.Drawing.Rectangle]::new(0, 0, $w, $h)
$grad = [System.Drawing.Drawing2D.LinearGradientBrush]::new($bgRect, (Color-Hex '#ff9f1c'), (Color-Hex '#006b3f'), 90)
$blend = [System.Drawing.Drawing2D.ColorBlend]::new()
$blend.Positions = [single[]](0, 0.34, 0.68, 1)
$blend.Colors = [System.Drawing.Color[]]@((Color-Hex '#f7b733'), (Color-Hex '#e43d30'), (Color-Hex '#005bbb'), (Color-Hex '#006b3f'))
$grad.InterpolationColors = $blend
$g.FillRectangle($grad, $bgRect)
$grad.Dispose()

$center = [System.Drawing.PointF]::new($w / 2, 720)
for ($i = 0; $i -lt 44; $i++) {
    $a1 = (2 * [Math]::PI / 44) * $i
    $a2 = (2 * [Math]::PI / 44) * ($i + 0.58)
    $r = 1750
    Fill-Poly -points @(
        $center,
        [System.Drawing.PointF]::new($center.X + [Math]::Cos($a1) * $r, $center.Y + [Math]::Sin($a1) * $r),
        [System.Drawing.PointF]::new($center.X + [Math]::Cos($a2) * $r, $center.Y + [Math]::Sin($a2) * $r)
    ) -color (Color-Alpha $(if ($i % 2 -eq 0) { 62 } else { 28 }) '#fff4b8')
}

Stroke-Bezier ([System.Drawing.PointF]::new(-170, 440)) ([System.Drawing.PointF]::new(290, 130)) ([System.Drawing.PointF]::new(690, 350)) ([System.Drawing.PointF]::new(1720, 110)) (Color-Alpha 230 '#ffcc00') 96
Stroke-Bezier ([System.Drawing.PointF]::new(-150, 535)) ([System.Drawing.PointF]::new(240, 310)) ([System.Drawing.PointF]::new(720, 535)) ([System.Drawing.PointF]::new(1715, 325)) (Color-Alpha 240 '#ffffff') 48
Stroke-Bezier ([System.Drawing.PointF]::new(-170, 610)) ([System.Drawing.PointF]::new(325, 455)) ([System.Drawing.PointF]::new(780, 650)) ([System.Drawing.PointF]::new(1700, 505)) (Color-Alpha 230 '#007a4d') 86
Stroke-Bezier ([System.Drawing.PointF]::new(-170, 1725)) ([System.Drawing.PointF]::new(360, 1455)) ([System.Drawing.PointF]::new(930, 1710)) ([System.Drawing.PointF]::new(1720, 1390)) (Color-Alpha 210 '#002395') 94
Stroke-Bezier ([System.Drawing.PointF]::new(-170, 1840)) ([System.Drawing.PointF]::new(430, 1630)) ([System.Drawing.PointF]::new(980, 1860)) ([System.Drawing.PointF]::new(1720, 1650)) (Color-Alpha 210 '#de3831') 76
Stroke-Bezier ([System.Drawing.PointF]::new(-110, 1580)) ([System.Drawing.PointF]::new(370, 1325)) ([System.Drawing.PointF]::new(760, 1535)) ([System.Drawing.PointF]::new(1690, 1205)) (Color-Alpha 210 '#ffb612') 42

$rand = [System.Random]::new(2010)
$palette = @('#ffffff', '#ffcc00', '#de3831', '#007a4d', '#002395')
for ($i = 0; $i -lt 360; $i++) {
    $x = $rand.Next(0, $w)
    $y = $rand.Next(190, $h - 220)
    $size = $rand.Next(4, 15)
    $hex = $palette[$rand.Next(0, $palette.Count)]
    Use-Brush (Color-Alpha ($rand.Next(55, 135)) $hex) { param($brush) $g.FillEllipse($brush, $x, $y, $size, $size) }
}

$glowPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$stadiumRect = [System.Drawing.RectangleF]::new(118, 1128, 1300, 355)
$glowPath.AddEllipse($stadiumRect)
$stadiumBrush = [System.Drawing.Drawing2D.PathGradientBrush]::new($glowPath)
$stadiumBrush.CenterColor = [System.Drawing.Color]::FromArgb(170, 255, 255, 255)
$stadiumBrush.SurroundColors = [System.Drawing.Color[]]@([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
$g.FillEllipse($stadiumBrush, $stadiumRect)
$stadiumBrush.Dispose()
$glowPath.Dispose()

$buildings = @(
    @(80, 1165, 74, 330), @(170, 1225, 95, 270), @(290, 1125, 70, 370), @(395, 1185, 120, 310),
    @(550, 1085, 72, 410), @(650, 1210, 104, 295), @(795, 1140, 92, 365), @(930, 1195, 128, 305),
    @(1100, 1088, 82, 410), @(1220, 1220, 96, 285), @(1340, 1160, 105, 345)
)

Use-Brush (Color-Alpha 218 '#111111') {
    param($brush)
    $g.FillRectangle($brush, 0, 1295, $w, 210)
    foreach ($b in $buildings) { $g.FillRectangle($brush, $b[0], $b[1], $b[2], $b[3]) }
}

Fill-Poly -points @(
    [System.Drawing.PointF]::new(0, 1510), [System.Drawing.PointF]::new(160, 1462), [System.Drawing.PointF]::new(330, 1493),
    [System.Drawing.PointF]::new(520, 1440), [System.Drawing.PointF]::new(765, 1498), [System.Drawing.PointF]::new(960, 1435),
    [System.Drawing.PointF]::new(1215, 1495), [System.Drawing.PointF]::new(1536, 1448), [System.Drawing.PointF]::new(1536, 2048),
    [System.Drawing.PointF]::new(0, 2048)
) -color (Color-Alpha 225 '#10140f')

Use-Brush ([System.Drawing.Color]::FromArgb(90, 255, 206, 80)) {
    param($brush)
    foreach ($b in $buildings) {
        for ($xx = $b[0] + 14; $xx -lt $b[0] + $b[2] - 14; $xx += 26) {
            for ($yy = $b[1] + 22; $yy -lt $b[1] + $b[3] - 32; $yy += 42) {
                if ($rand.NextDouble() -gt 0.56) { $g.FillRectangle($brush, $xx, $yy, 9, 17) }
            }
        }
    }
}

Draw-Vuvuzela 135 1660 -20 1.02 '#ffcc00'
Draw-Vuvuzela 1280 1718 198 0.98 '#de3831'

$ballX = 506
$ballY = 745
$ballS = 525
$ballRect = [System.Drawing.RectangleF]::new($ballX, $ballY, $ballS, $ballS)
$ballPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$ballPath.AddEllipse($ballRect)
$ballGrad = [System.Drawing.Drawing2D.LinearGradientBrush]::new($ballRect, (Color-Hex '#ffffff'), (Color-Hex '#c6d5dc'), 135)
$g.FillEllipse($ballGrad, $ballRect)
$clipState = $g.Save()
$g.SetClip($ballPath)

$centerBall = [System.Drawing.PointF]::new($ballX + $ballS / 2, $ballY + $ballS / 2)
$pentPts = @()
for ($i = 0; $i -lt 5; $i++) {
    $a = -[Math]::PI / 2 + $i * 2 * [Math]::PI / 5
    $pentPts += [System.Drawing.PointF]::new($centerBall.X + [Math]::Cos($a) * 86, $centerBall.Y + [Math]::Sin($a) * 86)
}

$pent = [System.Drawing.Drawing2D.GraphicsPath]::new()
$pent.AddPolygon([System.Drawing.PointF[]]$pentPts)
Use-Brush (Color-Hex '#111111') { param($brush) $g.FillPath($brush, $pent) }

Use-Pen (Color-Hex '#111111') 15 {
    param($pen)
    for ($i = 0; $i -lt 5; $i++) {
        $p = $pentPts[$i]
        $a = -[Math]::PI / 2 + $i * 2 * [Math]::PI / 5
        $q = [System.Drawing.PointF]::new($centerBall.X + [Math]::Cos($a) * 250, $centerBall.Y + [Math]::Sin($a) * 250)
        $g.DrawLine($pen, $p, $q)
        $hexPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
        $hx = @()
        for ($j = 0; $j -lt 6; $j++) {
            $aa = $a + $j * 2 * [Math]::PI / 6
            $hx += [System.Drawing.PointF]::new($q.X + [Math]::Cos($aa) * 54, $q.Y + [Math]::Sin($aa) * 54)
        }
        $hexPath.AddPolygon([System.Drawing.PointF[]]$hx)
        $g.DrawPath($pen, $hexPath)
        if ($i % 2 -eq 0) {
            Use-Brush ([System.Drawing.Color]::FromArgb(35, 0, 122, 77)) { param($brush) $g.FillPath($brush, $hexPath) }
        }
        $hexPath.Dispose()
    }
}

Use-Brush ([System.Drawing.Color]::FromArgb(105, 255, 255, 255)) { param($brush) $g.FillEllipse($brush, $ballX + 120, $ballY + 95, 165, 90) }
$g.Restore($clipState)
Use-Pen ([System.Drawing.Color]::FromArgb(230, 255, 255, 255)) 8 { param($pen) $g.DrawEllipse($pen, $ballRect) }
$ballGrad.Dispose()
$ballPath.Dispose()
$pent.Dispose()

Use-Brush ([System.Drawing.Color]::FromArgb(205, 0, 0, 0)) {
    param($brush)
    for ($i = 0; $i -lt 44; $i++) {
        $x = 40 + $i * 35 + $rand.Next(-7, 8)
        $y = 1450 + $rand.Next(-20, 40)
        $g.FillEllipse($brush, $x, $y, 18, 18)
        $g.FillRectangle($brush, $x + 5, $y + 16, 9, 36)
        if ($rand.NextDouble() -gt 0.35) {
            Use-Pen ([System.Drawing.Color]::FromArgb(180, 0, 0, 0)) 5 { param($pen) $g.DrawLine($pen, $x + 7, $y + 23, $x + $rand.Next(-20, 24), $y + $rand.Next(-12, 12)) }
        }
    }
}

$titleFont = New-Font 'Franklin Gothic Heavy' 116 ([System.Drawing.FontStyle]::Bold)
$yearFont = New-Font 'Franklin Gothic Heavy' 154 ([System.Drawing.FontStyle]::Bold)
$subFont = New-Font 'Bahnschrift SemiBold' 50 ([System.Drawing.FontStyle]::Bold)
$bodyFont = New-Font 'Bahnschrift' 38
$smallFont = New-Font 'Bahnschrift' 30
$cnFont = New-Font 'Microsoft YaHei UI' 76 ([System.Drawing.FontStyle]::Bold)
$cnTitle = [string]::Concat([char[]]@(21335, 38750, 19990, 30028, 26479, 23459, 20256, 28023, 25253))
$cnSubtitle = [string]::Concat([char[]]@(38750, 23448, 26041, 27010, 24565, 28023, 25253, 32, 32, 124, 32, 32, 24425, 34425, 22269, 24230, 32, 183, 32, 36275, 29699, 30427, 22799))

Draw-CenteredText -text 'SOUTH AFRICA' -font $titleFont -color (Color-Hex '#ffffff') -y 128
Draw-CenteredText -text '2010' -font $yearFont -color (Color-Hex '#ffcc00') -y 250
Draw-CenteredText -text 'WORLD FOOTBALL FESTIVAL' -font $subFont -color (Color-Hex '#ffffff') -y 450
Draw-CenteredText -text 'CELEBRATE THE BEAUTIFUL GAME' -font $bodyFont -color (Color-Hex '#ffffff') -y 560
Draw-CenteredText -text $cnTitle -font $cnFont -color (Color-Hex '#ffffff') -y 1725
Draw-CenteredText -text $cnSubtitle -font $smallFont -color (Color-Alpha 235 '#ffffff') -y 1838

Use-Pen ([System.Drawing.Color]::FromArgb(210, 255, 255, 255)) 16 { param($pen) $g.DrawRectangle($pen, 34, 34, $w - 68, $h - 68) }

for ($i = 0; $i -lt 9000; $i++) {
    $a = $rand.Next(10, 32)
    $gray = $rand.Next(210, 256)
    Use-Brush ([System.Drawing.Color]::FromArgb($a, $gray, $gray, $gray)) {
        param($brush) $g.FillRectangle($brush, $rand.Next(0, $w), $rand.Next(0, $h), 1, 1)
    }
}

$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)

$titleFont.Dispose()
$yearFont.Dispose()
$subFont.Dispose()
$bodyFont.Dispose()
$smallFont.Dispose()
$cnFont.Dispose()
$g.Dispose()
$bmp.Dispose()

Write-Output $out
