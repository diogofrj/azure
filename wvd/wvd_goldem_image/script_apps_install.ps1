#InstallNotepadplusplus
Write-Host "`nDownloading and Install Notepad++..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v7.9.2/npp.7.9.2.Installer.x64.exe' -OutFile 'c:\temp\notepadplusplus.exe'
    Invoke-Expression -Command 'c:\temp\notepadplusplus.exe /S'

#Start sleep
Start-Sleep -Seconds 10

Write-Host "`nDownloading and Install 7Zip..." -ForegroundColor Yellow
    Invoke-WebRequest "https://www.7-zip.org/a/7z1900-x64.msi" -OutFile "C:\temp\7z1900-x64.msi"
    msiexec /i "C:\temp\7z1900-x64.msi" /qb

#Start sleep
Start-Sleep -Seconds 10


#InstallFSLogix
Write-Host "`nDownloading and Install FSLogix for Azure Files..." -ForegroundColor Yellow    
Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile 'c:\temp\fslogix.zip'
Start-Sleep -Seconds 10
Expand-Archive -Path 'C:\temp\fslogix.zip' -DestinationPath 'C:\temp\fslogix\'  -Force
Invoke-Expression -Command 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe /install /quiet /norestart'

#Start sleep
Start-Sleep -Seconds 10

#Install Chrome
Write-Host "`nDownloading and Install Google Chrome..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force; $LocalTempDir = $env:TEMP; $ChromeInstaller = "ChromeInstaller.exe"; (new-object System.Net.WebClient).DownloadFile('http://dl.google.com/chrome/install/375.126/chrome_installer.exe', "$LocalTempDir\$ChromeInstaller"); & "$LocalTempDir\$ChromeInstaller" /silent /install; $Process2Monitor = "ChromeInstaller"; Do { $ProcessesFound = Get-Process | ? { $Process2Monitor -contains $_.Name } | Select-Object -ExpandProperty Name; If ($ProcessesFound) { "Still running: $($ProcessesFound -join ', ')" | Write-Host; Start-Sleep -Seconds 2 } else { rm "$LocalTempDir\$ChromeInstaller" -ErrorAction SilentlyContinue -Verbose } } Until (!$ProcessesFound)

#Start sleep
Start-Sleep -Seconds 10

#InstallTeamsMachinemode
# https://docs.microsoft.com/en-us/microsoftteams/teams-for-vdi#deploy-the-teams-desktop-app-to-the-vm
Write-Host "`nDownloading and Install Teams Machine Mode..." -ForegroundColor Yellow
    New-Item -Path 'HKLM:\SOFTWARE\Citrix\PortICA' -Force | Out-Null
    Invoke-WebRequest -Uri 'https://teams.microsoft.com/downloads/desktopurl?env=production&plat=windows&download=true&managedInstaller=true&arch=x64' -OutFile $env:TEMP\Teams.msi
    Invoke-Expression -Command 'msiexec /i $env:TEMP\Teams.msi OPTIONS="noAutoStart=true" /quiet /l*v $env:TEMP\teamsinstall.log ALLUSER=1 ALLUSERS=1'
Start-Sleep -Seconds 60
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' -Name Teams -PropertyType Binary -Value ([byte[]](0x01, 0x00, 0x00, 0x00, 0x1a, 0x19, 0xc3, 0xb9, 0x62, 0x69, 0xd5, 0x01)) -Force


    Write-Host "`nDeleting Installers..." -ForegroundColor Yellow    
    Remove-Item "C:\temp\*" -Force -Recurse

