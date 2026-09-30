<#
.SYNOPSIS
    Pushes silent MSI/EXE software installation to all 27 laptops in SI 110.
.DESCRIPTION
    Uses WinRM PowerShell Remoting to execute installer files from a central network share
    across all domain-joined laptops in OU=SI110 simultaneously.
.EXAMPLE
    .\03_Deploy_RemoteSoftware.ps1 -InstallerPath "\\LEI-DC\SoftwareShare\GoogleChrome.msi"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$InstallerPath,
    
    [string]$SearchBaseOU = "OU=SI110,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
)

Import-Module ActiveDirectory

Write-Host "[+] Querying computer accounts in $SearchBaseOU..." -ForegroundColor Cyan
$Computers = Get-ADComputer -Filter * -SearchBase $SearchBaseOU | Select-Object -ExpandProperty Name

if (-not $Computers) {
    Write-Host "[!] No computer objects found in $SearchBaseOU." -ForegroundColor Red
    exit
}

Write-Host "[+] Found $($Computers.Count) computers: $($Computers -join ', ')" -ForegroundColor Yellow
Write-Host "[+] Initiating remote installation of $InstallerPath..." -ForegroundColor Cyan

Invoke-Command -ComputerName $Computers -ScriptBlock {
    param($Path)
    Write-Host "Running silent installation on $env:COMPUTERNAME..."
    if ($Path.EndsWith(".msi")) {
        Start-Process msiexec.exe -ArgumentList "/i `"$Path`" /qn /norestart" -Wait -NoNewWindow
    } else {
        Start-Process -FilePath $Path -ArgumentList "/S", "/silent", "/quiet" -Wait -NoNewWindow
    }
} -ArgumentList $InstallerPath

Write-Host "[✓] Remote installation completed across all available laptops!" -ForegroundColor Green
