#$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$here = (Get-Item -Path ".\" -Verbose).FullName
$json = gc "$here\Download.json" -Raw | ConvertFrom-Json

# Download all applications in the array
foreach ( $app in $json.Applications ) {
    echo $app.URL
    $fileName = ($app.URL).split('/')[-1]
    $DownloadPath = "C:\Users\dan.sonnenburg\Downloads\PSDownloads\$fileName"
    Invoke-WebRequest $app.URL -OutFile $DownloadPath
}


#(Invoke-WebRequest -Uri "https://notepad-plus-plus.org/repository/6.x/").Links.Href | measure -Maximum