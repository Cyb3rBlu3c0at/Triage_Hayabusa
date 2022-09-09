<#
.DESCRIPTION
This script was created for the purpose of triaging a Client's environment using the DFIR tool Hayabusa. The script will create a folder, download the application,
execute the program, and upload the results to AWS S3 bucket.

Version:            1
Author:             Mike Dunn
Creation Date:      September 2022
    
.NOTES
Verify that you are using the latest version of Hayabusa prior to using this script.
#>

$AccessKey = "ACCESS KEY GOES HERE"
$SecretKey = "SECRET KEY GOES HERE"
$Bucket = "NAME OF BUCKET"
$Folder = "NAME OF FOLDER/FILE IN AWS"
$Hostname = hostname
$FilePath = "C:\Windows\Temp\Hayabusa"

function Create_Folders{
    New-Item -Path C:\Windows\Temp -Name Hayabusa -ItemType Directory
    New-Item -Path C:\Windows\Temp\Hayabusa -Name Results -ItemType Directory
}

function Download_Hayabusa{
    Invoke-WebRequest -uri "https://github.com/Yamato-Security/hayabusa/releases/download/v1.5.1/hayabusa-1.5.1-windows-64-bit.zip" -Outfile "$FilePath\hayabusa.zip"
    Expand-Archive -Path "$FilePath\hayabusa.zip" -DestinationPath "$FilePath"
}

function Execute_Hayabusa{
    cd $FilePath
    .\hayabusa-1.5.1-win-x64.exe -d C:\Windows\System32\winevt\Logs -o $FilePath\Results\$Hostname.csv
}

function Install_AWS{
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
    Install-PackageProvider -Name Nuget -MinimumVersion 2.8.5.201 -Force
    Find-Module -Name AWSPowerShell | Save-Module -Path "C:\Program Files\WindowsPowerShell\Modules"
    Import-Module AWSPowerShell
}

function Upload_Hayabusa{
    Set-AWSCredential -AccessKey $AccessKey -SecretKey $SecretKey -StoreAs Triage
    Initialize-AWSDefaultConfiguration -ProfileName Triage -Region us-east-1
    Write-S3Object -BucketName $Bucket -KeyPrefix $Folder -Folder C:\Windows\Temp\Hayabusa\Results
}

function Cleanup{
    Remove-AWSCredentialProfile -ProfileName Triage -Force
    cd C:\Windows\Temp
    Remove-Item -Path $FilePath -Force -Recurse
}

Create_Folders
Download_Hayabusa
Execute_Hayabusa
Install_AWS
Upload_Hayabusa
Cleanup
