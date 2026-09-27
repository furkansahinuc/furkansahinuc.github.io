# Prepares collection photos for the site. Run from anywhere:
#   powershell -ExecutionPolicy Bypass -File scripts/resize-photos.ps1
#
# For every photo in misc/<collection>/images/ that is new (no thumbnail yet,
# larger than 1600px, or still carrying an EXIF rotation), it:
#   - turns the photo upright according to its EXIF orientation
#     (rotate sideways photos in the Windows Photos app first),
#   - shrinks the photo itself to at most 1600px on its longest side,
#   - saves a thumbnail (longest side 512px) to misc/<collection>/thumbs/.
# Already processed photos are skipped, so it is safe to run any time.
# Replaced a photo with a small one under the same name? Delete its thumbnail first.
# Remember to add the photo to _data/<collection>.yml as well.

Add-Type -AssemblyName System.Drawing
$site = Split-Path -Parent $PSScriptRoot
$jpeg = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }

function Save-Resized($img, $maxEdge, $quality, $outPath) {
  $scale = [Math]::Min(1.0, $maxEdge / [Math]::Max($img.Width, $img.Height))
  $w = [int][Math]::Round($img.Width * $scale); $h = [int][Math]::Round($img.Height * $scale)
  $bmp = New-Object System.Drawing.Bitmap($w, $h)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
  $g.DrawImage($img, 0, 0, $w, $h)
  $g.Dispose()
  $p = New-Object System.Drawing.Imaging.EncoderParameters(1)
  $p.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality)
  $bmp.Save($outPath, $jpeg, $p)
  $bmp.Dispose()
}

$count = 0
$photos = Get-ChildItem "$site\misc\*\images\*" -File | Where-Object { $_.Extension -match '^\.(jpe?g|png)$' }
foreach ($photo in $photos) {
  $thumbDir = Join-Path $photo.Directory.Parent.FullName 'thumbs'
  $thumb = Join-Path $thumbDir $photo.Name
  # Read into memory so the original file can be overwritten.
  $ms = New-Object System.IO.MemoryStream(, [System.IO.File]::ReadAllBytes($photo.FullName))
  $img = [System.Drawing.Image]::FromStream($ms)
  $orientation = 1
  if ($img.PropertyIdList -contains 0x0112) {
    $orientation = [BitConverter]::ToUInt16($img.GetPropertyItem(0x0112).Value, 0)
  }
  $isNew = ($orientation -ne 1) -or ([Math]::Max($img.Width, $img.Height) -gt 1600) -or -not (Test-Path $thumb)
  if (-not $isNew) { $img.Dispose(); continue }

  switch ($orientation) {
    3 { $img.RotateFlip('Rotate180FlipNone') }
    6 { $img.RotateFlip('Rotate90FlipNone') }
    8 { $img.RotateFlip('Rotate270FlipNone') }
  }

  New-Item -ItemType Directory -Force $thumbDir | Out-Null
  Save-Resized $img 1600 82 $photo.FullName
  Save-Resized $img 512 80 $thumb
  $img.Dispose()
  "Processed $($photo.Directory.Parent.Name)/$($photo.Name)"
  $count++
}
"$count photo(s) processed."
