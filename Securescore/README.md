# Accessing Secure Score via the Graph API
Secure Score comes with a method to access histrocial data using the Microsoft Graph API framework using REST.

The format for accessing your Secure Score data is as follows:-
https://graph.microsoft.com/v1.0/reports/getTenantSecureScores(period=1)/content

Where 'period=X' with X representing an ingteger value between 1 and 90, indicating the number of days historical data you wish to query from todays date.

## Getting Started
In the repro you will find a file called Secure Score Demo API.ps1 file, this is sample script of how to use PowerShell to query Secure Score via the API using InvokeRestMethod.

## Prerequisites
You will need to ensure the following are in place.

You are a tenant admin.

The latest version of the Azure PowerShell module is installed for the the ADAL .NET assemblies. http://azure.microsoft.com/en-us/documentation/articles/install-configure-powershell/ 

In order to obtain an access token for authenticating to an application, we need to specify a few unique application details so that we can create an appropriate token.  We need to specify the application's unique Client ID, Redirect URI, and Application ID URI. Details on registering an application in Azure AD here to setup a new application can be found here https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-authentication-scenarios.

A good 3rd Party reference blog can be found here https://blog.kloud.com.au/2016/09/13/leveraging-the-microsoft-graph-api-with-powershell-and-oauth-2-0/ 

Once you have created your application, you will also need to ensure grant Admin Consent.

## Edit the Secore Score Demo API.ps1
Once you have met the above prerequisites.

Edit the following lines from the script with your values.

### Defining Azure AD tenant name, this is the name of your Azure Active Directory, where xxxxxxxxxxxxxxxxxxx is the ID of your O365 Tenant
$adTenant = "xxxxxxxxxxxxxxxxxxxxxxxxxx.onmicrosoft.com”

### Use the Client ID of native App that was registered in the Azure App Portal, where xxxxxx-xxxx-xxxx-xxxxxxx is the ID of your Client app
$clientId = "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx"

### Execute the REST query, where X = the integer value of 1-90 of the number of days history you wish to retrieve.
$resource = "https://graph.microsoft.com/v1.0/reports/getTenantSecureScores(period=X)/content"
