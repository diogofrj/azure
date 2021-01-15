
Write-Host "`nOptimizing Virtual Desktop Image..." -ForegroundColor Yellow    
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/diogofrj/azure/master/wvd/optimizer/Optimizer.zip' -OutFile 'C:\temp\Optimizer.zip'
Start-Sleep -Seconds 10
Expand-Archive -Path 'C:\temp\Optimizer.zip' -DestinationPath 'C:\temp\' -Force
Set-ExecutionPolicy Bypass -Scope Process -Force
C:\temp\Optimizer\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2009 
Remove-Item "C:\temp\*" -Force -Recurse