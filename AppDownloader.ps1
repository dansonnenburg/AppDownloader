# Written by Dan Sonnenburg
# Portions borrowed from other sources available online:
#   Get-MsiFileInformation borrowed from Nickolaj Andersen @ http://www.scconfigmgr.com/2014/08/22/how-to-get-msi-file-information-with-powershell/
#   Find-ZipExtractor borrowed from Microsoft PDT team @ https://gallery.technet.microsoft.com/PowerShell-Deployment-f20bb605

<#
next steps
 - have a function that processes JSON file and calls necessary functions, like Invoke-Main
 - build up a hash table to splat to new-cmapplication
    - when building the hash
 - still need to figure out how to add a detection method
#>

<#
Function Invoke-Main {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$JsonFile,
        [Parameter(Mandatory=$true)]$DirectoryRoot
    )

    # Import ConfigMgr Module
    Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
    # Change to Configuration Manager site PSDrive
    Push-Location LF1:
    #New-CMApplication
    # Change back to the original directory
    Pop-Location
}
#>

Function Get-Json {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$jsonFile
    )
    $json = gc $jsonFile -Raw | ConvertFrom-Json
    return $json
}

Function Get-ExecutableVersion {
    [cmdletbinding()]
    param (
       [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$fileName 
    )
    $version = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($fileName).FileVersion
    return $version
}

Function Invoke-AppDownload {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)]$Json,
        [Parameter(Mandatory=$true)]$DirectoryRoot      
    )
    try {
        foreach ( $app in $json.Applications ) {
            $applicationName = ($app.Uri).split('/')[-1]
            $outFile = [io.path]::combine($DirectoryRoot,"temp",$applicationName)
            $appDirectory = [io.path]::combine($DirectoryRoot,$app.Name + '-' + $app.SoftwareVersion,$applicationName)
            # ensures that the file does exist in the temp directory or (and implies that the file is not present in either location) 
            #  the final ConfigMgr source directory before downloading.
            If (!(Test-Path $outFile) -and !(Test-Path $appDirectory)) {
                Write-Debug "$outFile or $appDirectory does not exist"
                Invoke-WebRequest -Uri $app.Uri -OutFile $OutFile -UserAgent [Microsoft.PowerShell.Commands.PSUserAgent]::InternetExplorer
            } else {
                Write-Verbose "$outFile already exists! No need to download."
            }
        }
    } catch {
        Throw "An Exception has occured: $_.Exception"  
    }
}

Function New-AppDirectory {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$true)]$Json,
        [Parameter(Mandatory=$true)]$DirectoryRoot
    )
    foreach ( $app in $json.Applications ) {
        $appDirectory = [io.path]::combine($DirectoryRoot,$app.Name + '-' + $app.SoftwareVersion)
        If (!(Test-Path $appDirectory)) {
            New-Item -Path $appDirectory -ItemType Directory
        } else {
            Write-Verbose "$appDirectory already exists!"
        }
    }
}

Function Parse-WebForLatestVersion {
<#
$list = (Invoke-WebRequest -Uri "https://notepad-plus-plus.org/repository/6.x/").Links.Href
$a = Invoke-WebRequest -Uri "https://2.na.dl.wireshark.org/win64/Wireshark-win64-2.0.5.exe"
$a.Headers
#powershell switch statement for each content type (exe, msi, e.g.x-msdos-program), then switch statement will call the handlers
$i = 1
foreach ($item in $list) {
    echo $item
    echo $i
    $i++
}
#>
}

Function Get-MsiFileInformation {
    [cmdletbinding()]
    param(
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.IO.FileInfo]$Path,
 
        [parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("ProductCode", "ProductVersion", "ProductName", "Manufacturer", "ProductLanguage", "FullVersion")]
        [string]$Property
    )
    Process {
        try {
            # Read property from MSI database
            $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
            $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($Path.FullName, 0))
            $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
            $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
            $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
            $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
            $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
 
            # Commit database and close view
            $MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
            $View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)           
            $MSIDatabase = $null
            $View = $null
 
            # Return the value
            return $Value
        } 
        catch {
            Write-Warning -Message $_.Exception.Message ; break
        }
    }
    End {
        # Run garbage collection and release ComObject
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WindowsInstaller) | Out-Null
        [System.GC]::Collect()
    }
}

Function Find-ZipExtractor {
    # Check for WinRAR,7Zip, or PeaZip
    Write-Verbose " Verifying extraction software... " #-NoNewLine
    $WR = (Get-ItemProperty -Path "HKLM:\SOFTWARE\WinRAR" -ErrorAction SilentlyContinue).Exe64
    If (($WR -ne $null) -and (Test-Path "$WR"))
    {
	    $script:Extractor = "WinRAR"
	    $script:ExtractorExe = "$WR"
    }
    $7z = (Get-ItemProperty -Path "HKLM:\SOFTWARE\7-Zip" -ErrorAction SilentlyContinue).Path
    If ($7z -ne $null)
    {
	    if (!($7z.EndsWith("\"))) { $7z = $7z + "\" }
	    if (Test-Path "$7z`7z.exe")
	    {
		    $script:Extractor = "7-Zip"
		    $script:ExtractorExe = "$7z`7z.exe"
	    }
    }
    $PZ = (Get-ItemProperty -Path "HKLM:\SOFTWARE\PeaZip" -ErrorAction SilentlyContinue)
    If ($PZ -ne $null)
    {
	    $PZLoc = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{5A2BC38A-406C-4A5B-BF45-6991F9A05325}_is1" -ErrorAction SilentlyContinue).InstallLocation
	    if (Test-Path "$PZLoc`peazip.exe")
	    {
            $script:Extractor = "7-Zip"
		    $script:ExtractorExe = "$PZLoc" + "res\7z\7z.exe"
	    }
    }
    If (!($Extractor))
    {
	    Write-Verbose "Warning" #-ForegroundColor Yellow
	    Write-Verbose "   7-Zip, PeaZip, or WinRAR not found. Please install one of these tools to enable Downloader to extract files." #-ForegroundColor Yellow
    }Else
    {
	    Write-Verbose "Passed" #-ForegroundColor Green
    }
}

Function Export-Zip {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]$Json,
        [Parameter(Mandatory = $true)]$DirectoryRoot
    )
  
    Find-ZipExtractor
    Write-Debug "Extractor is $Extractor"
    Write-Debug "Extractor executable path is $ExtractorExe"
    foreach ($app in $json.Applications) {
        #Extract file only if it is a file type that needs to be extracted.
        If ($app.Extract -eq $true) {
            write-Debug "$app.Name Extraction value is true"
            $extractionDir =[io.path]::combine($DirectoryRoot,"temp",$app.Name + '-' + $app.SoftwareVersion)
            Write-Debug "Zip extraction directory is $extractionDir"
            If (!(Test-Path $extractionDir)) {
                New-Item -Path $extractionDir -ItemType Directory
                Write-Debug "Creating new directory: $extractionDir"
            } else {
                Write-Debug "$extractionDir already exists!"
            }
            # Ensures that the directory is empty before extracting
            if (!((Get-Item $extractionDir).EnumerateFileSystemInfos() | select -First 1)) {
                Write-Debug "$appDirectory is empty.  Begin extraction."
                #Determine the type of compressed file, then perform commands respectively.
                Switch($app.ExtractType) {
                    "ZIP" {          
                        $filePath = [io.path]::combine($DirectoryRoot,"temp",($app.Uri).split('/')[-1])
                        Write-Debug "Zip file path returned is: $filePath"
                        Switch ($Extractor){
                            "WinRAR" { Start-Process -FilePath "$ExtractorExe" -ArgumentList "x `"$filePath`"" -Wait -WindowStyle Hidden }
			                "7-Zip" { Write-Debug "...in the 7-Zip switch statement"
                                Start-Process -FilePath "$ExtractorExe" -ArgumentList "x `"$filePath`" -o`"$extractionDir`"" -Wait -WindowStyle Hidden }
	                    }
                    }
                }
            }
        }
    }
}

Function New-CommandLineString {
    [cmdletbinding()]
    param (
        $CommandLinePrefix,
        [Parameter(Mandatory = $true)]$fileName,
        [Parameter(Mandatory = $true)]$CommandLineSuffix
    )
    #concatenate command line into a single string
    if ($CommandLinePrefix -ne $null) {
        $newString = "$CommandLinePrefix $fileName $CommandlineSuffix"
    } else {
        $newString = "$fileName $CommandlineSuffix"
    }
    return $newString
}


Function Move-InstallerToSourceDir {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true)]$Json,
        [Parameter(Mandatory = $true)]$DirectoryRoot
    )
        try {
            foreach ( $app in $json.Applications ) {
                if ($app.ExtractType -ne "ZIP") {
                    Write-Debug "$app.Name is not a zip file.  File will be moved to ConfigMgr source directory."
                    $appDirectory = [io.path]::combine($DirectoryRoot,$app.Name + '-' + $app.SoftwareVersion)
                    $applicationName = ($app.Uri).split('/')[-1]
                    $fileName = [io.path]::combine($DirectoryRoot,"temp",$applicationName)
                    #Check to see if the ConfigMgr source directory is empty
                    if (!((Get-Item $appDirectory).EnumerateFileSystemInfos() | select -First 1)) {
                        Write-Debug "$appDirectory is empty."
                        Move-Item -Path $fileName -Destination $appDirectory
                    }
                }         
            }
        } catch {
            Throw "An Exception has occured: $_.Exception"
        }   
}

Function New-AppHashForSplat {
}