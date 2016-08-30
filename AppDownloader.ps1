#$here = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$here = (Get-Item -Path ".\" -Verbose).FullName
$json = gc "$here\Download.json" -Raw | ConvertFrom-Json
$outPath = "C:\Users\dan.sonnenburg\Downloads\PSDownloads\"

# Download all applications in the array
foreach ( $app in $json.Applications ) {
    $fileName = ($app.URL).split('/')[-1]
    $applicationDirectory = $app.Name
    $DownloadFolder = [io.path]::combine($outPath,$applicationDirectory)
    $DownloadPath = [io.path]::combine($outPath,$applicationDirectory,$fileName)
    If (!(Test-Path $DownloadFolder)) {
        New-Item -Path $DownloadFolder -ItemType Directory
    } else {
        Write-host "$DownloadFolder already exists!"
    }
    Invoke-WebRequest $app.URL -OutFile $DownloadPath
}

<#
$list = (Invoke-WebRequest -Uri "https://notepad-plus-plus.org/repository/6.x/").Links.Href

$i = 1
foreach ($item in $list) {
    echo $item
    echo $i
    $i++
}
#>

