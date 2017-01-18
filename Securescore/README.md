# Accessing Secure Score via the Graph API

Secure Score comes with an access to an API utilizing the Microsoft Graph framework using REST.

The format for accessing your Secure Score data is as follows:-
https://graph.microsoft.com/v1.0/reports/getTenantSecureScores(period=1)/content

Where 'period=1' means the number of days data you wish to query.

