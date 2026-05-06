<#
.SYNOPSIS
Installs the IntuneStack module from GitHub.

.DESCRIPTION
Clones the IntuneStack repository and creates a symbolic link to the module
folder in the user's PowerShell module path, following the pattern from
Practical Automation with PowerShell (Dowst, 2023).

.EXAMPLE
Invoke-Expression (Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/AllwaysHyPe/IntuneStack/refs/heads/main/Install-IntuneStack.ps1')
#>

$RepoUrl = 'https://github.com/AllwaysHyPe/IntuneStack.git'

function Test-CmdInstall {
    param(
        $TestCommand
    )
    try {
        $Before = $ErrorActionPreference
        $ErrorActionPreference = 'Stop'
        $testResult = Invoke-Expression -Command $TestCommand
    } catch {
        $testResult = $null
    } finally {
        $ErrorActionPreference = $Before
    }
    $testResult
}

function Set-EnvPath {
    $env:Path =
    [System.Environment]::GetEnvironmentVariable("Path", "Machine") +
    ";" +
    [System.Environment]::GetEnvironmentVariable("Path", "User")
}

$GitVersion = Test-CmdInstall 'git --version'

if (-not $GitVersion) {
    if ($IsWindows) {
        Write-Host "Installing Git for Windows..."
        $wingetParams = 'winget install --id Git.Git' +
        ' -e --source winget --accept-package-agreements' +
        ' --accept-source-agreements'
        Invoke-Expression $wingetParams
    } elseif ($IsLinux) {
        Write-Host "Installing Git for Linux..."
        apt-get install git -y
    } elseif ($IsMacOS) {
        Write-Host "Installing Git for macOS..."
        brew install git
    }

    Set-EnvPath
    $GitVersion = Test-CmdInstall 'git --version'

    if (-not $GitVersion) {
        throw "Unable to locate git. Please install manually and rerun this script."
    }

    Write-Host "Git $GitVersion installed"
} else {
    Write-Host "Git $GitVersion already installed"
}

if ($IsWindows) {
    Set-Location $env:USERPROFILE
} else {
    Set-Location $env:HOME
}

Invoke-Expression -Command "git clone $RepoUrl"

# The module folder is the IntuneStack subfolder inside the cloned repo
$ModuleFolder = Get-Item './IntuneStack'

$UserPowerShellModules =
[Environment]::GetEnvironmentVariable("PSModulePath").Split(';')[0]

$SimLinkProperties = @{
    ItemType = 'SymbolicLink'
    Path     = Join-Path $UserPowerShellModules 'IntuneStack'
    Target   = $ModuleFolder.FullName
    Force    = $true
}
New-Item @SimLinkProperties

Write-Host "IntuneStack installed. Run 'Import-Module IntuneStack' to get started."
