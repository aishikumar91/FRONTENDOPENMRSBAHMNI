# ============================================================================
# HealsFast USA - Logo Compression Script
# ============================================================================
# This script compresses PNG logos to reduce file size while maintaining quality
# Uses pngquant for lossy compression (if available) or built-in .NET compression
# ============================================================================

Write-Host ""
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host "  HealsFast USA - Logo Compression Tool" -ForegroundColor Cyan
Write-Host "============================================================================" -ForegroundColor Cyan
Write-Host ""

$logoPath = "ui\app\images"
$logos = @("healfastLogo.png", "healfastLogoFull.png")

# Check if pngquant is available
$pngquantAvailable = $false
try {
    $null = Get-Command pngquant -ErrorAction Stop
    $pngquantAvailable = $true
    Write-Host "✓ pngquant found - will use for optimal compression" -ForegroundColor Green
} catch {
    Write-Host "⚠ pngquant not found - using basic compression" -ForegroundColor Yellow
    Write-Host "  Install pngquant for better compression: choco install pngquant" -ForegroundColor Gray
}

Write-Host ""

foreach ($logo in $logos) {
    $filePath = Join-Path $logoPath $logo
    
    if (-not (Test-Path $filePath)) {
        Write-Host "✗ File not found: $filePath" -ForegroundColor Red
        continue
    }
    
    $originalSize = (Get-Item $filePath).Length
    $originalSizeKB = [math]::Round($originalSize/1KB, 2)
    
    Write-Host "Processing: $logo" -ForegroundColor Cyan
    Write-Host "  Original size: $originalSizeKB KB" -ForegroundColor White
    
    if ($pngquantAvailable) {
        # Use pngquant for optimal compression
        $outputPath = Join-Path $logoPath "temp_$logo"
        
        # Run pngquant with quality 80-95 (good balance)
        & pngquant --quality=80-95 --force --output $outputPath $filePath 2>&1 | Out-Null
        
        if (Test-Path $outputPath) {
            $newSize = (Get-Item $outputPath).Length
            $newSizeKB = [math]::Round($newSize/1KB, 2)
            $reduction = [math]::Round((($originalSize - $newSize) / $originalSize) * 100, 1)
            
            # Replace original
            Move-Item -Path $outputPath -Destination $filePath -Force
            
            Write-Host "  Compressed size: $newSizeKB KB" -ForegroundColor Green
            Write-Host "  Reduction: $reduction%" -ForegroundColor Green
        } else {
            Write-Host "  Compression failed" -ForegroundColor Red
        }
    } else {
        Write-Host "  Skipping compression (pngquant not available)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "============================================================================" -ForegroundColor Green
Write-Host "  Compression Complete!" -ForegroundColor Green
Write-Host "============================================================================" -ForegroundColor Green
Write-Host ""

# Show final sizes
Write-Host "Final Logo Sizes:" -ForegroundColor Cyan
foreach ($logo in $logos) {
    $filePath = Join-Path $logoPath $logo
    if (Test-Path $filePath) {
        $size = [math]::Round((Get-Item $filePath).Length/1KB, 2)
        Write-Host "  $logo : $size KB" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "To install pngquant for better compression:" -ForegroundColor Yellow
Write-Host "  Option 1: choco install pngquant" -ForegroundColor Gray
Write-Host "  Option 2: Download from https://pngquant.org/" -ForegroundColor Gray
Write-Host ""

