# ============================================================================
# HealsFast USA - Logo Optimization Script
# ============================================================================
# This script optimizes logo files by:
# 1. Making white backgrounds transparent
# 2. Reducing file size
# 3. Creating backup of originals
# ============================================================================

Add-Type -AssemblyName System.Drawing

function Optimize-Logo {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$WhiteThreshold = 240
    )

    Write-Host "Processing: $InputPath" -ForegroundColor Cyan

    # Load the image
    $originalImage = New-Object System.Drawing.Bitmap($InputPath)
    
    Write-Host "  Original size: $([math]::Round((Get-Item $InputPath).Length/1KB, 2)) KB"
    Write-Host "  Dimensions: $($originalImage.Width) x $($originalImage.Height) pixels"
    Write-Host "  Format: $($originalImage.PixelFormat)"

    # Create a new bitmap with transparency support
    $newImage = New-Object System.Drawing.Bitmap($originalImage.Width, $originalImage.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    # Process each pixel
    $pixelsChanged = 0
    for ($y = 0; $y -lt $originalImage.Height; $y++) {
        for ($x = 0; $x -lt $originalImage.Width; $x++) {
            $pixel = $originalImage.GetPixel($x, $y)
            
            # Check if pixel is white or near-white (background)
            if ($pixel.R -ge $WhiteThreshold -and $pixel.G -ge $WhiteThreshold -and $pixel.B -ge $WhiteThreshold) {
                # Make it transparent
                $newImage.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
                $pixelsChanged++
            } else {
                # Keep original color
                $newImage.SetPixel($x, $y, $pixel)
            }
        }
        
        # Progress indicator
        if ($y % 50 -eq 0) {
            $progress = [math]::Round(($y / $originalImage.Height) * 100, 1)
            Write-Host "  Processing: $progress%" -NoNewline -ForegroundColor Yellow
            Write-Host "`r" -NoNewline
        }
    }

    Write-Host "  Processing: 100% - Complete!                    " -ForegroundColor Green
    Write-Host "  Pixels made transparent: $pixelsChanged" -ForegroundColor Green

    # Save to temporary file first
    $tempPath = $OutputPath + ".tmp"
    $newImage.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)

    # Cleanup
    $originalImage.Dispose()
    $newImage.Dispose()

    # Replace original file
    Start-Sleep -Milliseconds 100
    Move-Item -Path $tempPath -Destination $OutputPath -Force

    $newSize = [math]::Round((Get-Item $OutputPath).Length/1KB, 2)
    $originalSize = [math]::Round((Get-Item $InputPath).Length/1KB, 2)
    $reduction = [math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1)

    Write-Host "  New size: $newSize KB (Reduced by $reduction%)" -ForegroundColor Green
    Write-Host "  Saved to: $OutputPath" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# Main Script
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  HealsFast USA - Logo Optimization Tool" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$logoPath = "ui\app\images"
$backupPath = "ui\app\images\backup"

# Create backup directory
if (-not (Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Write-Host "Created backup directory: $backupPath" -ForegroundColor Yellow
    Write-Host ""
}

# Backup original files
$logos = @("healfastLogo.png", "healfastLogoFull.png")

foreach ($logo in $logos) {
    $sourcePath = Join-Path $logoPath $logo
    $backupFile = Join-Path $backupPath "$([System.IO.Path]::GetFileNameWithoutExtension($logo))_original.png"
    
    if (Test-Path $sourcePath) {
        if (-not (Test-Path $backupFile)) {
            Copy-Item $sourcePath $backupFile -Force
            Write-Host "Backed up: $logo -> $backupFile" -ForegroundColor Yellow
        } else {
            Write-Host "Backup already exists: $backupFile" -ForegroundColor Gray
        }
    }
}

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  Optimizing Logos (Making backgrounds transparent)" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

# Optimize logos
foreach ($logo in $logos) {
    $inputPath = Join-Path $logoPath $logo
    $outputPath = Join-Path $logoPath $logo  # Overwrite original
    
    if (Test-Path $inputPath) {
        Optimize-Logo -InputPath $inputPath -OutputPath $outputPath -WhiteThreshold 240
    } else {
        Write-Host "File not found: $inputPath" -ForegroundColor Red
    }
}

Write-Host "============================================================================" -ForegroundColor Green
Write-Host "  Optimization Complete!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review the optimized logos in: $logoPath" -ForegroundColor White
Write-Host "2. Original files backed up to: $backupPath" -ForegroundColor White
Write-Host "3. If satisfied, rebuild the application: cd ui && yarn build" -ForegroundColor White
Write-Host "4. Commit changes: git add . && git commit -m 'Optimize logos with transparency'" -ForegroundColor White
Write-Host ""

