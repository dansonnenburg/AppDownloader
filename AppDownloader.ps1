Function Get-Json {
    cd (Split-Path -Parent $MyInvocation.MyCommand.Path)
    $here = (Get-Item -Path ".\" -Verbose).FullName
    $json = gc "$here\Download.json" -Raw | ConvertFrom-Json
    $outPath = "C:\Users\dan.sonnenburg\Downloads\PSDownloads\"
}

Function Invoke-AppDownload {
    Get-Json
    # Download all applications in the array
    foreach ( $app in $json.Applications ) {
        $fileName = ($app.Uri).split('/')[-1]
        $applicationDirectory = $app.Name
        $DownloadFolder = [io.path]::combine($outPath,$applicationDirectory)
        $FilePath = [io.path]::combine($outPath,$applicationDirectory,$fileName)
        If (!(Test-Path $DownloadFolder)) {
            New-Item -Path $DownloadFolder -ItemType Directory
        } else {
            Write-host "$DownloadFolder already exists!"
        }
        If (!(Test-Path $FilePath)) {
            Invoke-WebRequest -Uri $app.Uri -OutFile $FilePath -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer
        } else {
            Write-host "$FilePath already exists!"
        }
        $uri = 'http://go.microsoft.com/fwlink/?LinkID=210601'
    }
}

Function Get-LatestVersion {


<#
$list = (Invoke-WebRequest -Uri "https://notepad-plus-plus.org/repository/6.x/").Links.Href

$i = 1
foreach ($item in $list) {
    echo $item
    echo $i
    $i++
}
#>
}

Invoke-AppDownload