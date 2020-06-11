#Script to setup golden image with Azure Image Builder

#Create temp folder
New-Item -Path 'C:\temp' -ItemType Directory -Force | Out-Null

#Install VSCode
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?Linkid=852157' -OutFile 'c:\temp\VScode.exe'
Invoke-Expression -Command 'c:\temp\VScode.exe /verysilent'

#Start sleep
Start-Sleep -Seconds 10

#InstallNotepadplusplus
Invoke-WebRequest -Uri 'https://notepad-plus-plus.org/repository/7.x/7.7.1/npp.7.7.1.Installer.x64.exe' -OutFile 'c:\temp\notepadplusplus.exe'
Invoke-Expression -Command 'c:\temp\notepadplusplus.exe /S'

#Start sleep
Start-Sleep -Seconds 10

#InstallFSLogix
Invoke-WebRequest -Uri 'https://aka.ms/fslogix_download' -OutFile 'c:\temp\fslogix.zip'
Start-Sleep -Seconds 10
Expand-Archive -Path 'C:\temp\fslogix.zip' -DestinationPath 'C:\temp\fslogix\'  -Force
Invoke-Expression -Command 'C:\temp\fslogix\x64\Release\FSLogixAppsSetup.exe /install /quiet /norestart'

#Start sleep
Start-Sleep -Seconds 10

#InstallTeamsMachinemode Preview Media Optimisations - Reg pre-reqs
New-Item -Path HKLM:\SOFTWARE\Microsoft\Teams -Force | Out-Null
New-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Teams -name IsWVDEnvironment -Value “1” -Force | Out-Null

#Install VC++ & WebSocket Service then Teams with media optimisations
Invoke-WebRequest -Uri 'https://support.microsoft.com/help/2977003/the-latest-supported-visual-c-downloads' -OutFile 'c:\temp\vc.msi'
Invoke-Expression -Command 'c:\temp\vc.msi /quiet'
#Start sleep
Start-Sleep -Seconds 10
Invoke-WebRequest -Uri 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE4vkL6' -OutFile 'c:\temp\websocket.msi'
Invoke-Expression -Command 'c:\temp\websocket.msi /quiet'
#Start sleep
Start-Sleep -Seconds 10
Invoke-WebRequest -Uri 'https://statics.teams.cdn.office.net/production-windows-x64/1.3.00.4461/Teams_windows_x64.msi' -OutFile 'c:\temp\Teams.msi'
Invoke-Expression -Command 'msiexec /i C:\temp\Teams.msi /quiet /l*v C:\temp\teamsinstall.log ALLUSER=1 ALLUSERS=1'
