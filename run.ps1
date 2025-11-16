# PowerShell script to run Flutter app - handles Windows path-with-spaces issue
# Usage: .\run.ps1 [flutter-arguments]

$env:GRADLE_USER_HOME = "C:\gradle-home"
$env:GRADLE_OPTS = "-Dfile.encoding=UTF-8 -Duser.home=C:\gradle-home"

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

Write-Host "Project directory: $scriptDir" -ForegroundColor Cyan
Write-Host "GRADLE_USER_HOME: $env:GRADLE_USER_HOME" -ForegroundColor Cyan

# Check if path contains spaces
if ($scriptDir -match ' ') {
    Write-Host "`n⚠️  Warning: Project path contains spaces!" -ForegroundColor Yellow
    Write-Host "This may cause Gradle build issues." -ForegroundColor Yellow
    Write-Host "`nRecommended solutions:" -ForegroundColor Cyan
    Write-Host "1. Run setup_junction.ps1 as Administrator to create a junction" -ForegroundColor White
    Write-Host "2. Or move the project to a path without spaces (e.g., C:\Projects\Linkster)" -ForegroundColor White
    Write-Host "`nAttempting build anyway..." -ForegroundColor Yellow
}

# Run Flutter
& flutter $args
