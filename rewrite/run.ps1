using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$Request.query.path

$Request | fl

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $Request
})