cls
$cred = Get-Credential
$mycred = new-object Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential($cred.UserName,$cred.Password)

# Defining Azure AD tenant name, this is the name of your Azure Active Directory, where xxxxxxxxxxxxxxxxxxx is the ID of your O365 Tenant
$adTenant = "xxxxxxxxxxxxxxxxxxxxxxxxxx.onmicrosoft.com”

# Load Active Directory Authentication Library (ADAL) Assemblies
$adal = “${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll”
$adalforms = “${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll”
[System.Reflection.Assembly]::LoadFrom($adal)
[System.Reflection.Assembly]::LoadFrom($adalforms)

# Use the Client ID of native App that was registered in the Azure App Portal
$clientId = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"

# Set redirect URI for Azure PowerShell
$redirectUri = “urn:ietf:wg:oauth:2.0:oob”

# Set Resource URI to Azure Service Management API
$resourceAppIdURI = “https://graph.microsoft.com/”

# Set Authority to Azure AD Tenant
$authority = “https://login.windows.net/$adTenant“

# Create AuthenticationContext tied to Azure AD Tenant
$authContext = New-Object “Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext” -ArgumentList $authority

# Acquire token
$authResult = $authContext.AcquireToken($resourceAppIdURI, $clientId, $mycred)

# Building Rest Api header with authorization token
$authHeader = @{

‘Content-Type’=‘application\json’

‘Authorization’=$authResult.CreateAuthorizationHeader()
}

# Execute the REST query, where X = the integer value of 1-90 of the number of days history you wish to retrieve.
$resource = "https://graph.microsoft.com/stagingBeta/reports/getTenantSecureScores(period=X)/content"
Invoke-RestMethod -Method Get -Uri $resource -Headers $authHeader
