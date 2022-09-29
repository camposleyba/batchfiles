@echo off

:: BatchGotAdmin
:-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"=""
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"                                 
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------


if exist utils (
    echo Utils found
) else (
    goto noUtils
)

reg query HKEY_LOCAL_MACHINE\SOFTWARE\IBM\DB2\CurrentVersion >nul 2>&1

if %errorlevel% EQU 0 (
    goto checkVersion
) else ( goto wrongDB2 )

:: --> Check DB2 version
:checkVersion
for /f "tokens=3" %%a in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\IBM\DB2\CurrentVersion /v Version 2^>NUL ^| find /i "Version"') do set v=%%a 
for /f "tokens=3" %%a in ('reg query HKEY_LOCAL_MACHINE\SOFTWARE\IBM\DB2\CurrentVersion /v Release 2^>NUL ^| find /i "Release"') do set r=%%a


if %v% EQU 10 if %r% EQU 5 (
    goto setupDB2v105
) else (
    goto wrongDB2
)

:wrongDB2

echo DB2 version is not 10.5 please uninstall any IBM data server client version you have and 
echo install DB2 10.5.0.6 from Windows 7 PC@IBM Appstore. Then restart PC before running this script again.
echo The tool will now exit witout any changes made
@pause
exit

:setupDB2v105
for /f "delims=" %%a in ('net localgroup DB2ADMNS') do  (
call set "db2group=%%db2group%% %%prev%%" 
set prev=%%a
)
set db2group=%db2group:*- =%
echo %db2group% | findstr /c:"Everyone" > nul && (
    goto db2license
) || (
net localgroup db2admns Everyone /add
net localgroup db2users Everyone /add
net localgroup db2admns Administrator /add
net localgroup db2users Administrator /add
)

:db2license
db2cmd -c -w -i db2licm -a utils\db2consv_ee.lic

::  --> Install GSKit version 57
rmdir /S /Q "C:\Program Files (x86)\IBM\gsk8\"
rmdir /S /Q "C:\Program Files\IBM\gsk8\"

cls
echo The tool will now install GSKit it will take about 3-4 minutes. Please
echo do not touch the mouse or keyboard

utils\8.0.50.57-ISS-GSKIT-WinX64-FP0057\64\gsk8crypt64.exe /s /v"/quiet"
echo GSKit Crypto 64 bit installed
utils\8.0.50.57-ISS-GSKIT-WinX64-FP0057\64\gsk8ssl64.exe /s /v"/quiet"
echo GSKit SSL 64 bit installed
utils\8.0.50.57-ISS-GSKIT-WinX64-FP0057\32\gsk8crypt32.exe /s /v"/quiet"
echo GSKit Crypto 32 bit installed
utils\8.0.50.57-ISS-GSKIT-WinX64-FP0057\32\gsk8ssl32.exe /s /v"/quiet"
echo GSKit SSL 32 bit installed
 
:checkPath
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /f gsk8\lib\ >nul 2>&1

if %errorlevel% NEQ 0 (
    goto editPATH
) else ( goto checkKDB )


:editPATH
echo.>utils\setenv.exe:Zone.Identifier
SET Key="HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
FOR /F "usebackq tokens=2*" %%A IN (`REG QUERY %Key% /v PATH`) DO Set CurrPath=%%B
utils\setenv.exe -m PATH "%%Systemroot%%;C:\Program Files (x86)\IBM\gsk8\bin\;C:\Program Files (x86)\IBM\gsk8\lib\;C:\Program Files\IBM\gsk8\lib64\;C:\Program Files\IBM\gsk8\bin\;%CurrPath%


:checkKDB
if exist "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.kdb" (
    del "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.crl"
    del "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.kdb"
    del "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.rdb"
    del "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.sth"
    goto createKDB
) else ( goto createKDB ) 


:createKDB
cmd /c "set PATH = C:\Program Files (x86)\IBM\gsk8\bin\;C:\Program Files (x86)\IBM\gsk8\lib\;C:\Program Files\IBM\gsk8\lib64\;c:\Program Files\IBM\gsk8\bin\;%PATH% && start gsk8capicmd_64.exe -keydb -create -db "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.kdb" -pw "n0nexp1r" -stash"
PING localhost -n 3 >NUL
cmd /c "set PATH = C:\Program Files (x86)\IBM\gsk8\bin\;C:\Program Files (x86)\IBM\gsk8\lib\;C:\Program Files\IBM\gsk8\lib64\;c:\Program Files\IBM\gsk8\bin\;%PATH% && start gsk8capicmd_64.exe -cert -add -db "c:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.kdb" -pw "n0nexp1r" -label "IBMRoot" -file "utils\carootcert.der" -format binary"

REM --> Grant permissions to stash file
icacls "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.kdb" /inheritance:e
icacls "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.sth" /inheritance:e

REM --> Update database manager configuration

db2cmd -c -w -i db2 update dbm cfg using SSL_CLNT_KEYDB "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.kdb" 
db2cmd -c -w -i db2 update dbm cfg using SSL_CLNT_STASH "C:\ProgramData\IBM\DB2\DB2COPY1\DB2\ibmca.sth"
net stop DB2MGMTSVC_DB2COPY1
net start DB2MGMTSVC_DB2COPY1
goto success

:noUtils
echo Missing utils folder
goto exit 

:success
REM --> AIW setup
db2cmd -c -w -i db2 uncatalog node TCP0001
db2cmd -c -w -i db2 uncatalog odbc data source DP1H
db2cmd -c -w -i db2 uncatalog db DP1H
db2cmd -c -w -i db2 uncatalog dcs db DP1H
db2cmd -c -w -i db2 catalog tcpip node TCP0001 remote usibmvrdp1h.ssiplex.pok.ibm.com server 5520 security ssl
db2cmd -c -w -i db2 catalog db DP1H as DP1H at node TCP0001 authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db DP1H as USIBMVRDP1H parms ',,INTERRUPT_ENABLED,,,,,,'
db2cmd -c -w -i db2 catalog user odbc data source DP1H

REM --> FIW setup
db2cmd -c -w -i db2 uncatalog node NDEEEFA1
db2cmd -c -w -i db2 uncatalog odbc data source EUHADBM0
db2cmd -c -w -i db2 uncatalog db EUHADBM0
db2cmd -c -w -i db2 uncatalog dcs db EUHADBM0
db2cmd -c -w -i db2 catalog tcpip node NDEEEFA1 remote meuhc.vipa.uk.ibm.com server 3210 security ssl
db2cmd -c -w -i db2 catalog db EUHADBM0 as EUHADBM0 at node NDEEEFA1 authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db EUHADBM0 as EUHADBM0 parms ',,INTERRUPT_ENABLED,,,,,,'
db2cmd -c -w -i db2 catalog user odbc data source EUHADBM0

REM --> FDW setup
db2cmd -c -w -i db2 uncatalog node NDED1262
db2cmd -c -w -i db2 uncatalog odbc data source EUHADB2A
db2cmd -c -w -i db2 uncatalog db EUHADB2A
db2cmd -c -w -i db2 uncatalog dcs db EUHADB2A
db2cmd -c -w -i db2 catalog tcpip node NDED1262 remote meuha.S390.uk.ibm.com server 447 security ssl
db2cmd -c -w -i db2 catalog db EUHADB2A as EUHADB2A at node NDED1262 authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db EUHADB2A as EUHADB2A
db2cmd -c -w -i db2 catalog user odbc data source EUHADB2A
db2cmd -c -w -i db2 update cli cfg for section COMMON using AsyncEnable 0

REM --> FIRE setup
db2cmd -c -w -i db2 uncatalog node BHPRDFPD
db2cmd -c -w -i db2 uncatalog odbc data source BHPRDFPD
db2cmd -c -w -i db2 uncatalog db BHPRDFPD
db2cmd -c -w -i db2 uncatalog dcs db BHPRDFPD
db2cmd -c -w -i db2 catalog tcpip node BHPRDFPD remote ierpfire.bhprod.ibm.com server 5520 security ssl
db2cmd -c -w -i db2 catalog db BHPRDFPD as BHPRDFPD at node BHPRDFPD authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db BHPRDFPD as BHPRDFPD
db2cmd -c -w -i db2 catalog user odbc data source BHPRDFPD
db2cmd -c -w -i db2 update cli cfg for section COMMON using AsyncEnable 0


echo.>utils\DB2 Database Setup with SSL.xlsm:Zone.Identifier
echo.>utils\db2ca.bat:Zone.Identifier

copy /y "utils\DB2 Database Setup with SSL.xlsm"  "DB2 Database Setup with SSL.xlsm"
copy /y "utils\db2ca.bat" "c:\Program Files\IBM\SQLLIB\BIN\db2ca.bat"
copy /y "utils\ConfigurationAssistant.icon" "c:\Windows\Installer\{5F3AC8C5-2EB8-4443-AC5D-D4AA4BD5BC21}\ConfigurationAssistant.icon"
copy /y "utils\Configuration Assistant.lnk" "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\IBM DB2 DB2COPY1 (Default)\Configuration Assistant.lnk"

echo Setup completed successfull.
echo You now have encrypted connection setup for AIW, FIW, iERP FIRE and FDW
echo To be able to use the new connections in Excel or SPSS you need to restart the PC
echo 
echo To add more databases you can use the Excel file DB2 Database Setup with SSL.xlsm in DB2SSL folder 

:exit
@pause
     