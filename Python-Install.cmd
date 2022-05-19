@echo off
powershell -command curl.exe "https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe" --output "C:\Users\%USERNAME%\Downloads\python-3.10.4-amd64.exe"

powershell -command start-sleep -m 2000

powershell -command start-process -Filepath "python-3.10.4-amd64.exe" -workingdirectory "C:\Users\%USERNAME%\Downloads" -argumentlist "/quiet, InstallAllUsers=1, PrependPath=1, Include_test=0"

powershell -command start-sleep -m 2000

powershell -command pip install -r "C:\Users\%USERNAME%\Desktop\requirements.txt"

ECHO Python successfully installed
REM pip install -r C:\Users\%USERNAME%\Desktop\requirements.txt

