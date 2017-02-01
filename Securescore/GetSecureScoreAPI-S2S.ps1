#This script will pull a config from a local config file, then get a service to service oauth token for an application you have registered in AAD
#Then the script will call the Secure Score API and return the data to the console

Function Get-GlobalConfig( $configFile)
{
    Write-Output "Loading Global Config File"
    
    $config = Get-Content $globalConfigFile -Raw | ConvertFrom-Json
    
    return $config;
}

$globalConfigFile="ConfigForSecureScoreAPI.json";
$globalConfig = Get-GlobalConfig $globalConfigFile

#Pre-reqs for REST API calls
$ClientID = $globalConfig.SSAPIAppId
$ClientSecret = $globalConfig.SSAPIAppSecret
$loginURL = $globalConfig.LoginURL
$tenantdomain = $globalConfig.SSAPITenantDomain
$TenantGUID = $globalConfig.SSAPITenantGUID
$resource = $globalConfig.ResourceAPI
$ssAPI = $globalConfig.SecureScoreAPI

# Get an Oauth 2 access token based on client id, secret and tenant domain
$body = @{grant_type="client_credentials";resource=$resource;client_id=$ClientID;client_secret=$ClientSecret}
$oauth = Invoke-RestMethod -Method Post -Uri $loginURL/$tenantdomain/oauth2/token?api-version=1.0 -Body $body

#Let's put the oauth token in the header, where it belongs
$headerParams  = @{'Authorization'="$($oauth.token_type) $($oauth.access_token)"}

# Execute the Rest Query
Invoke-RestMethod -Method Get -Uri $ssAPI -Headers $authHeader

#Do Some Magic here to process, store, or otherwise use the data being returned
