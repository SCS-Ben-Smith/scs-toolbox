function Show-Menu {
    Clear-Host
    Write-Host "SCS Toolbox"
    Write-Host "1. Run SFC"
    Write-Host "2. Run DISM"
    Write-Host "3. Run CHKDSK"
    Write-Host "4. Install Custom App"
    Write-Host "5. Exit"
}

function Run-SFC {
    sfc /scannow
}

function Run-DISM {
    DISM /Online /Cleanup-Image /RestoreHealth
}

function Run-CHKDSK {
    chkdsk C: /f /r
}

function Install-CustomApp {
    Invoke-WebRequest -Uri "https://yourdomain.com/app1.exe" -OutFile "$env:TEMP\app1.exe"
    Start-Process "$env:TEMP\app1.exe"
}

do {
    Show-Menu
    $choice = Read-Host "Choose an option"

    switch ($choice) {
        "1" { Run-SFC }
        "2" { Run-DISM }
        "3" { Run-CHKDSK }
        "4" { Install-CustomApp }
        "5" { break }
        default { Write-Host "Invalid selection" }
    }

    Pause
} while ($true)
