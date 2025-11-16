# PowerShell script to build Flutter app with GRADLE_USER_HOME set
# This fixes the Windows path-with-spaces issue

$env:GRADLE_USER_HOME = "C:\gradle-home"
$env:GRADLE_OPTS = "-Dfile.encoding=UTF-8 -Duser.home=C:\gradle-home"

# Get the script directory (project root)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

# Run Flutter command with all arguments passed to this script
& flutter $args

