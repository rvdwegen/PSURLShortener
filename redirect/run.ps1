using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK

$Slug = ([uri]$Request.Headers.'x-ms-original-url').Segments[1]

$Request.Headers.'x-ms-original-url'

$Request.query.path

$Request | fl

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $Slug
})