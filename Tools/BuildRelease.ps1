. $PSScriptRoot\Common.ps1

function Build-Release([Bool] $PopupFolders) {
    Push-Location $PSScriptRoot\..\..\Release | Out-Null

    try {
        # Import
        Write-Host "Copying Source Code ..."
        New-Item .\Import\Skins -ItemType directory -ErrorAction SilentlyContinue | Out-Null
        New-Item .\Import\Skins\DarkSkin -ItemType directory -ErrorAction SilentlyContinue | Out-Null
        Copy-Item ..\Vlpp\Release\*.h .\Import
        Copy-Item ..\Vlpp\Release\*.cpp .\Import
        Copy-Item ..\Workflow\Release\*.h .\Import
        Copy-Item ..\Workflow\Release\*.cpp .\Import
        Copy-Item ..\GacUI\Release\Gac*.h .\Import
        Copy-Item ..\GacUI\Release\Gac*.cpp .\Import
        Copy-Item ..\GacUI\Release\DarkSkin* .\Import\Skins\DarkSkin

        # Deploy
        Write-Host "Deploying Binaries ..."
        Copy-Item $PSScriptRoot\CppMerge.exe .\Tools
        Copy-Item $PSScriptRoot\GacGen32.exe .\Tools
        Copy-Item $PSScriptRoot\GacGen64.exe .\Tools
        Copy-Item $PSScriptRoot\GacGen.ps1 .\Tools
        Copy-Item $PSScriptRoot\StartProcess.ps1 .\Tools

        # ControlTemplate\BlackSkin
        Write-Host "Deploying Tutorial\GacUI_ControlTemplate\BlackSkin ..."
        Push-Location $PSScriptRoot\..\..\Release\Tutorial\GacUI_ControlTemplate\BlackSkin\UI | Out-Null
        Remove-Item .\FullControlTest -Force -Recurse | Out-Null
        Copy-Item $PSScriptRoot\..\..\GacUI\Test\GacUISrc\Host\Resources\FullControlTest . -Recurse | Out-Null
        Pop-Location

        # GacGen
        Write-Host "Compiling Resources ..."
        Get-ChildItem -Path .\Tutorial -Filter Resource.xml -Recurse | %{
            if ($_.FullName.IndexOf("\GacUI_HelloWorlds\Xml\") -ne -1) {
                Write-Host "Compiling GacUI Resource (x86): $($_.FullName) ..."
                Start-Process-And-Wait (,("$PSScriptRoot\GacGen32.exe", "`"$($_.FullName)`""))
            } else {
                & $PSScriptRoot\GacGen.ps1 -FileName $_.FullName
            }
        }

        # Debug Build
        Write-Host "Create Debug Builds ..."
        Get-ChildItem -Path .\Tutorial -Filter *.sln -Recurse | %{
            if ($_.FullName.IndexOf("\Lib\") -eq -1) {
                Build-Sln $_.FullName "Debug" "Win32" "OutDir" "$($_.DirectoryName)\Debug\"
            }
        }

        # Check Debug Build
        Write-Host "Checking Debug Builds ..."
        $failed = $false
        Get-ChildItem -Path .\Tutorial -Filter *.vcxproj -Recurse | %{
            if ($_.FullName.IndexOf("\Lib\") -eq -1) {
                $exe_file = "$($_.DirectoryName)\..\Debug\$($_.BaseName).exe"
                if (!(Test-Path $exe_file)) {
                    Write-Host "Binary not found: $exe_file" -ForegroundColor Red
                    $failed = $true
                }
            }
        }
        if ($failed) {
            throw "Failed"
        }

        # Release Build
        Write-Host "Create Release Builds ..."
        Get-ChildItem -Path .\Tutorial -Filter *.sln -Recurse | %{
            if ($_.FullName.IndexOf("\Lib\") -eq -1) {
                Build-Sln $_.FullName "Release" "Win32" "OutDir" "$($_.DirectoryName)\Release\"
            }
        }

        if ($PopupFolders) {
            start .\Tutorial\GacUI_HelloWorlds\Release
            start .\Tutorial\GacUI_Layout\Release
            start .\Tutorial\GacUI_Controls\Release
            start .\Tutorial\GacUI_ControlTemplate\Release
            start .\Tutorial\GacUI_Xml\Release
        }
    }
    catch {
        throw
    }
    finally {
        Pop-Location | Out-Null
    }
}