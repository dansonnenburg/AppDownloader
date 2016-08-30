$URL = "https://notepad-plus-plus.org/repository/6.x/6.9.1/npp.6.9.1.Installer.exe"
$fileName = ($URL).split('/')[-1]
$DownloadPath = "C:\Users\dan.sonnenburg\Downloads\PSDownloads\$fileName"

$Parameters = gc 'MDTDev.json' -Raw | ConvertFrom-Json

Invoke-WebRequest $URL -OutFile $DownloadPath


#(Invoke-WebRequest -Uri "https://notepad-plus-plus.org/repository/6.x/").Links.Href | measure -Maximum