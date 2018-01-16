@echo off
setlocal
set hour=%time:~0,2%
set minute=%time:~3,2%
set /A minute+=2
if %minute% GTR 59 (
 set /A minute-=60
 set /A hour+=1
)
if %hour%==24 set hour=00
if "%hour:~0,1%"==" " set hour=0%hour:~1,1%
if "%hour:~1,1%"=="" set hour=0%hour%
if "%minute:~1,1%"=="" set minute=0%minute%
set tasktime=%hour%:%minute%

mkdir C:\Source
pushd "C:\Source\"
echo [+] Downloading Chrome install...
@powershell (new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/pmccowat/oms-scripts/master/Install-Chrome.ps1','C:\Source\Install-Chrome.ps1')"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command C:\Source\Install-Chrome.ps1
echo [+] Chrome msi installed..
echo [+] Downloading Microsoft Monitoring Agent...
@powershell (new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/pmccowat/oms-scripts/master/InstallOMSAgent.ps1','C:\Source\InstallOMSAgent.ps1')"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command C:\Source\InstallOMSAgent
echo [+] Microsoft Monitoring Agent..

mkdir C:\ProgramData\sysmon
pushd "C:\ProgramData\sysmon\"
echo [+] Downloading Sysmon...
@powershell (new-object System.Net.WebClient).DownloadFile('https://live.sysinternals.com/Sysmon64.exe','C:\ProgramData\sysmon\sysmon64.exe')"
echo [+] Downloading Sysmon config...
@powershell (new-object System.Net.WebClient).DownloadFile('https://raw.githubusercontent.com/SwiftOnSecurity/sysmon-config/master/sysmonconfig-export.xml','C:\ProgramData\sysmon\sysmonconfig-export.xml')"
@powershell (new-object System.Net.WebClient).DownloadFile('https://lgdatastorage.blob.core.windows.net/oms/Auto_Update.bat','C:\ProgramData\sysmon\Auto_Update.bat')"
@powershell (new-object System.Net.WebClient).DownloadFile('https://lgdatastorage.blob.core.windows.net/oms/sysmon-schema-4.ps1','C:\ProgramData\sysmon\sysmon-schema-4.ps1')"
PowerShell -NoProfile -ExecutionPolicy Bypass -Command C:\ProgramData\sysmon\sysmon-schema-4.ps1
sysmon64.exe -accepteula -i sysmonconfig-export.xml
sc failure Sysmon actions= restart/10000/restart/10000// reset= 120
echo [+] Sysmon Successfully Installed!
echo [+] Creating Auto Update Task set to Hourly..
SchTasks /Create /RU SYSTEM /RL HIGHEST /SC HOURLY /TN Update_Sysmon_Rules /TR C:\ProgramData\sysmon\Auto_Update.bat /F /ST %tasktime%

sc sdset Sysmon D:(D;;DCLCWPDTSD;;;IU)(D;;DCLCWPDTSD;;;SU)(D;;DCLCWPDTSD;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)

timeout /t 10
exit
