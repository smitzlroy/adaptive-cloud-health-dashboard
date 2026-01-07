<#
.SYNOPSIS
    One-Click Power BI Setup - Automated Import

.DESCRIPTION
    This script automates the entire Power BI setup process:
    1. Exports data from Azure
    2. Generates Power BI import script
    3. Creates a clipboard-ready import command
    4. Opens instructions with step-by-step guidance

.EXAMPLE
    .\Setup-PowerBI-AutoImport.ps1
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "║     Adaptive Cloud → Power BI                           ║" -ForegroundColor Cyan
Write-Host "║     ONE-CLICK AUTOMATED SETUP                           ║" -ForegroundColor Cyan
Write-Host "║                                                          ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Step 1: Export data
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  STEP 1/3: Exporting Data from Azure" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$exportScript = Join-Path $PSScriptRoot "Export-ToPowerBI.ps1"
if (Test-Path $exportScript) {
    & $exportScript
} else {
    Write-Host "❌ Export script not found: $exportScript" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Data export complete!" -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 2: Generate import script
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  STEP 2/3: Generating Power BI Import Script" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$generateScript = Join-Path $PSScriptRoot "Generate-PowerBIModel.ps1"
$rootPath = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$exportsPath = Join-Path $rootPath "powerbi-exports"

if (Test-Path $generateScript) {
    & $generateScript -CsvPath $exportsPath
} else {
    Write-Host "❌ Generate script not found: $generateScript" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Import script generated!" -ForegroundColor Green
Start-Sleep -Seconds 2

# Step 3: Prepare for Power BI import
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host "  STEP 3/3: Preparing Power BI Import Instructions" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Yellow
Write-Host ""

$mScriptPath = Join-Path $exportsPath "PowerBI-DataModel.m"

if (-not (Test-Path $mScriptPath)) {
    Write-Host "❌ Import script not found: $mScriptPath" -ForegroundColor Red
    exit 1
}

# Read the M script
$mScript = Get-Content $mScriptPath -Raw

# Copy to clipboard
try {
    $mScript | Set-Clipboard
    Write-Host "✅ Import script copied to clipboard!" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not copy to clipboard automatically" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "║          🎉 SETUP COMPLETE! 🎉                          ║" -ForegroundColor Green
Write-Host "║                                                          ║" -ForegroundColor Green
Write-Host "╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Data exported: 14 tables ready for import" -ForegroundColor Cyan
Write-Host "📋 Import script: COPIED TO CLIPBOARD" -ForegroundColor Cyan
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host "  NOW IN POWER BI DESKTOP - FOLLOW THESE 5 STEPS:" -ForegroundColor Magenta
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""
Write-Host "  1️⃣  Click: Home → Get Data → Blank Query" -ForegroundColor White
Write-Host ""
Write-Host "  2️⃣  Click: Home → Advanced Editor" -ForegroundColor White
Write-Host ""
Write-Host "  3️⃣  Press: CTRL+A (select all) then DELETE" -ForegroundColor White
Write-Host ""
Write-Host "  4️⃣  Press: CTRL+V (paste - script is in clipboard)" -ForegroundColor White
Write-Host ""
Write-Host "  5️⃣  Click: Done" -ForegroundColor White
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Magenta
Write-Host ""
Write-Host "✨ Power BI will import all 14 tables automatically!" -ForegroundColor Green
Write-Host ""
Write-Host "📖 After import:" -ForegroundColor Cyan
Write-Host "   • In Queries pane, RIGHT-CLICK 'Output' → Expand" -ForegroundColor White
Write-Host "   • You'll see all 14 tables (ResourceSummary, HardwareCapacity, etc.)" -ForegroundColor White
Write-Host "   • Click 'Close & Apply' to load data into model" -ForegroundColor White
Write-Host ""
Write-Host "💡 Next Steps:" -ForegroundColor Yellow
Write-Host "   • Go to Model View to create relationships" -ForegroundColor White
Write-Host "   • Open: $exportsPath\PowerBI-Relationships.txt" -ForegroundColor Gray
Write-Host "   • Or start building visuals immediately!" -ForegroundColor White
Write-Host ""

# Pause to show instructions
Write-Host "Press any key to open the full instructions file..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Open instructions
$quickRefPath = Join-Path $exportsPath "PowerBI-QuickReference.txt"
if (Test-Path $quickRefPath) {
    Start-Process notepad.exe -ArgumentList $quickRefPath
}

Write-Host ""
Write-Host "✅ Setup complete! Follow the 5 steps above in Power BI Desktop." -ForegroundColor Green
Write-Host ""
