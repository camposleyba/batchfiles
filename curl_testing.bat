powershell -command curl.exe "https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe" --output "C:\Users\%USERNAME%\Downloads\python-3.10.4-amd64.exe"

powershell -command start-sleep -m 3000

powershell -noexit -command start-process -Filepath "python-3.10.4-amd64.exe" -workingdirectory "C:\Users\%USERNAME%\Downloads" -argumentlist "/quiet, InstallAllUsers=1, PrependPath=1, Include_test=0"

