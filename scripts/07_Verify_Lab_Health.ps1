<#
.SYNOPSIS
    Live health check and GPO verification dashboard for Salle SILYCEE.
.DESCRIPTION
    Pings all laptops in OU=SILYCEE, checks if GPO registry keys arrived over WinRM,
    and automatically triggers Invoke-GPUpdate on any laptop that needs an immediate sync.
#>

Import-Module ActiveDirectory

$OU = "OU=SILYCEE,OU=CAMPUS IBN BADIS,DC=LEI,DC=IDEMY"
$Computers = (Get-ADComputer -Filter * -SearchBase $OU | Sort-Object Name).Name

Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "   SALLE SILYCEE - LIVE GPO & HEALTH CHECK                " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$Online = 0
$GpoOk = 0

foreach ($PC in $Computers) {
    if (Test-Connection -ComputerName $PC -Count 1 -Quiet) {
        $Online++
        
        # Check remotely via WinRM if GPO registry keys exist on the laptop
        $Check = Invoke-Command -ComputerName $PC -ScriptBlock {
            $edgeBlock = Test-Path "HKLM:\Software\Policies\Microsoft\Edge\URLBlocklist"
            $cmdBlock  = Test-Path "HKCU:\Software\Policies\Microsoft\Windows\System"
            return ($edgeBlock -and $cmdBlock)
        } -ErrorAction SilentlyContinue

        if ($Check) {
            $GpoOk++
            Write-Host "  [ONLINE]  $PC --> GPO Status: [✓] FULLY ACTIVE & PROTECTED" -ForegroundColor Green
        } else {
            Write-Host "  [ONLINE]  $PC --> GPO Status: [!] PULLING UPDATE NOW..." -ForegroundColor Yellow
            Invoke-GPUpdate -Computer $PC -Force -RandomDelayInMinutes 0 -ErrorAction SilentlyContinue
        }
    } else {
        Write-Host "  [OFFLINE] $PC" -ForegroundColor Red
    }
}

Write-Host "----------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Summary: $Online/$($Computers.Count) Laptops Online | $GpoOk Protected with Latest GPO" -ForegroundColor Yellow
Write-Host "==========================================================`n" -ForegroundColor Cyan
