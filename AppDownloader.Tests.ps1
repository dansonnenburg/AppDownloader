$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"
cd (Split-Path -Parent $MyInvocation.MyCommand.Path)

Describe "AppDownloader" {
    BeforeAll {
        . ".\AppDownloader.ps1"
        #directoryRoot is the path where we create a temporary directory to download the files, then stage all the source folders/files
        New-Variable -Name directoryRoot -Value "C:\Users\dan.sonnenburg\Downloads\Pester" -Scope Script
        #Set the path the json definition file
        New-Variable -Name jsonFile -Value Download.json -Scope Script
        #Get the json file
        $jsonContents = Get-Json -jsonFile $JsonFile
        #Set the value of json to the contents of the jsonFile
        New-Variable -Name json -Value $jsonContents -Scope Script
    }
    It "Gets the json file" {
        Get-Json -jsonFile $jsonFile
    }
    It "makes the source directory structure" {
        New-AppDirectory -Json $jsonContents -DirectoryRoot $directoryRoot
    }

    It "Invokes application downloads"  {
        Invoke-AppDownload -Json $jsonContents -DirectoryRoot $directoryRoot
    }

    It "Finds a zip extractor application" {
        Find-ZipExtractor 
        $script:Extractor | should not be $null
        $script:ExtractorExe | should not be $null
    }
    It "Extracts a zip file" {
        Export-Zip -Json $jsonContents -DirectoryRoot $directoryRoot
    }

    It "Moves file to ConfigMgr source directory" {
        Move-InstallerToSourceDir -Json $jsonContents -DirectoryRoot $directoryRoot
        <#
        {
            Try {
                $testPath = "C:\Users\dan.sonnenburg\Downloads\Pester\7zip-16.02"
                if (!($testPath.EnumerateFileSystemInfos() | select -First 1)) {
                    Write-Debug "The directory: $testPath is empty and it shouldn't be."
                    throw
                }
            } Catch {
                
            } 
        }| Should not throw
        #>
    }
    It "Creates a command line" {
        foreach ( $app in $json.Applications ) {
            $fileName = ($app.Uri).split('/')[-1]
            New-CommandLineString -CommandLinePrefix $app.CommandLinePrefix -fileName $fileName -CommandLineSuffix $app.CommandLineSuffix
        }
    }
    
    It "Gets the file version of an executable" {
        $exe = "C:\Users\dan.sonnenburg\Downloads\Pester\HeidiSQL-9.3.0.5114\HeidiSQL_9.3.0.5114_Setup.exe"
        Get-ExecutableVersion -fileName $exe
    }
    It "Gets MSI file version" {
        $msi = "C:\Users\dan.sonnenburg\Downloads\Pester\Google Chrome-52.0.2743.116\googlechromestandaloneenterprise64.msi"
        Get-MsiFileInformation -Path $msi -Property ProductVersion
    }

    It "Creates a ConfigMgr application" {
        #Create new application with splatting
        # Import ConfigMgr Module
        Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1)
        # Change to Configuration Manager site PSDrive
        Push-Location LF1:     
        Foreach ( $app in $json.Applications ) {
            $splat = $app | select Name, SoftwareVersion, Description, IconLocationFile, IsFeatured, Keyword, LocalizedApplicationDescription, LocalizedApplicationName,`
                Owner, Publisher, SupportContact, UserDocumentation
            Write-Host @splat
            break
            #New-CMApplication @splat
            #Add-CMDeploymentType @app -WhatIf
        }
        # Change back to the original directory
        Pop-Location
    }

    It "Creates a JSON template" {
        
    }

    <#
    It "parses the website for the latest version" {
    }
    #> 
       
    It "Invokes main function to download and create application in ConfigMgr" {
        #Invoke-Main -json $jsonContents -DirectoryRoot $directoryRoot
    }
    AfterAll {
        Remove-Variable -Name directoryRoot -Scope Script
        Remove-Variable -Name jsonFile -Scope Script
        Remove-Variable -Name json -Scope Script
        #remove-item -Path ([io.path]::combine($directoryRoot,"temp","extracted")) -Recurse -Force
        #remove-item -Path $directoryRoot -Recurse -Force
    }
}
