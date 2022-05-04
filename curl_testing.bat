powershell -command curl.exe "https://www.python.org/ftp/python/3.10.4/python-3.10.4-amd64.exe" --output "C:\Users\%USERNAME%\Downloads\python-3.10.4-amd64.exe"
powershell -command cd C:\Users\%USERNAME%\Downloads\ && start python-3.10.4-amd64.exe /quiet -ArgumentList "InstallAllUsers=1 PrependPath=1 Include_test=0"
