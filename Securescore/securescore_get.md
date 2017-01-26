# Get tenantsecurescores

Retrieve all tenant secure score data for the specified date range. The data can be queried on the period field which holds the days for which the data was collected. 
## Prerequisites
The following **scopes** are required to execute this API: Reports.Read.All 
## HTTP request
<!-- { "blockType": "ignored" } -->
```http
GET /reports/{id}
```
## Optional query parameters
This method supports the [OData Query Parameters](http://graph.microsoft.io/docs/overview/query_parameters) to help customize the response.

## Request headers
| Name       | Type | Description|
|:-----------|:------|:----------|
| Authorization  | string  | Bearer <token>. Required. |

## Request body
Do not supply a request body for this method.
## Response
If successful, this method returns a 200 OK response code version object and collection of score data objects for every Secure Score control in the response body. 
## Example
##### Request
Here is an example of the request.
<!-- {
  "blockType": "request",
  "name": "get_application"
}-->
```http
GET https://graph.microsoft.com/v1.0/reports/getTenantSecureScores(period=1)/content
```
##### Response
Here is an example of the response. Note: The response object shown here may be truncated for brevity. All of the properties will be returned from an actual call.
<!-- {
  "blockType": "response",
  "truncated": true,
  "@odata.type": "microsoft.graph.application"
} -->
```http
HTTP/1.1 200 OK
Content-type: application/json
Content-length: 636
{ 
"value":[ 
{ 
      "tenantId":"12bce6d0-bfeb-4a82-abe6-98ccf3196a11", 
      "createdDateTime":"2016-10-16T00:00:00+00:00", 
      "licensedUsersCount":28, 
      "activeUsersCount":0, 
      "secureScore":115, 
      "organizationMaxScore":243, 
      "accountScore":33, 
      "dataScore":45, 
      "deviceScore":37, 
}] 
} 

```

<!-- uuid: 8fcb5dbc-d5aa-4681-8e31-b001d5168d79
2015-10-25 14:57:30 UTC -->
<!-- {
  "type": "#page.annotation",
  "description": "Get application",
  "keywords": "",
  "section": "documentation",
  "tocPath": ""
}-->
