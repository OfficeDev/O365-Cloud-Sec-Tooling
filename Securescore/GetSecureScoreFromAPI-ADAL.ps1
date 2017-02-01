function Load-ActiveDirectoryAuthenticationLibrary(){
  $moduleDirPath = [Environment]::GetFolderPath("MyDocuments") + "\WindowsPowerShell\Modules"
  $modulePath = $moduleDirPath + "\AADGraph"
  if(-not (Test-Path ($modulePath+"\Nugets"))) {New-Item -Path ($modulePath+"\Nugets") -ItemType "Directory" | out-null}
  $adalPackageDirectories = (Get-ChildItem -Path ($modulePath+"\Nugets") -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory)
  if($adalPackageDirectories.Length -eq 0){
    Write-Host "Active Directory Authentication Library Nuget doesn't exist. Downloading now ..." -ForegroundColor Yellow
    if(-not(Test-Path ($modulePath + "\Nugets\nuget.exe")))
    {
      Write-Host "nuget.exe not found. Downloading from http://www.nuget.org/nuget.exe ..." -ForegroundColor Yellow
      $wc = New-Object System.Net.WebClient
      $wc.DownloadFile("http://www.nuget.org/nuget.exe",$modulePath + "\Nugets\nuget.exe");
    }
    $nugetDownloadExpression = $modulePath + "\Nugets\nuget.exe install Microsoft.IdentityModel.Clients.ActiveDirectory -Version 2.14.201151115 -OutputDirectory " + $modulePath + "\Nugets | out-null"
    Invoke-Expression $nugetDownloadExpression
  }
  $adalPackageDirectories = (Get-ChildItem -Path ($modulePath+"\Nugets") -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory)
  $ADAL_Assembly = (Get-ChildItem "Microsoft.IdentityModel.Clients.ActiveDirectory.dll" -Path $adalPackageDirectories[$adalPackageDirectories.length-1].FullName -Recurse)
  $ADAL_WindowsForms_Assembly = (Get-ChildItem "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll" -Path $adalPackageDirectories[$adalPackageDirectories.length-1].FullName -Recurse)
  if($ADAL_Assembly.Length -gt 0 -and $ADAL_WindowsForms_Assembly.Length -gt 0){
    Write-Host "Loading ADAL Assemblies ..." -ForegroundColor Green
    [System.Reflection.Assembly]::LoadFrom($ADAL_Assembly[0].FullName) | out-null
    [System.Reflection.Assembly]::LoadFrom($ADAL_WindowsForms_Assembly.FullName) | out-null
    return $true
  }
  else{
    Write-Host "Fixing Active Directory Authentication Library package directories ..." -ForegroundColor Yellow
    $adalPackageDirectories | Remove-Item -Recurse -Force | Out-Null
    Write-Host "Not able to load ADAL assembly. Delete the Nugets folder under" $modulePath ", restart PowerShell session and try again ..."
    return $false
  }
}

function Get-AuthenticationResult($tenant = "common", $env="prod"){
  $clientId = "YOUR APPLICATION ID"
  $redirectUri = "YOUR APPLICATION REDIRECT URI"
  $resourceAppIdURI = "https://graph.microsoft.com/"
  $authority = "https://login.windows.net/" + $tenant
  $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority,$false
  $authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, [Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always)
  return $authResult
}

function Connect-AAD ($tenant = "common", $env="prod", $graphVer="beta") {
  PROCESS {
    $global:aadGPoShAuthResult = $null
    $global:aadGPoShEnv = $env
    $global:aadGPoShGraphVer = $graphVer
    $global:aadGPoShGraphUrl = "https://graph.microsoft.com/"
    $global:aadGPoShAuthResult = Get-AuthenticationResult -Tenant $tenant -Env $env
  }
}

Load-ActiveDirectoryAuthenticationLibrary
Connect-AAD

$header = $global:aadGPoShAuthResult.CreateAuthorizationHeader()
$headerParams = @{"Authorization"=$header;"Content-Type"="application/json"}
$tenantdomain = $global:aadGPoShAuthResult.TenantId

$myReport = (Invoke-WebRequest -Headers $headerParams -Uri "https://graph.microsoft.com/stagingBeta/reports/getTenantSecureScores(period=9)/content")
$myReport.Content | ConvertFrom-Json
