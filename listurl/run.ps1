using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

$StatusCode = [HttpStatusCode]::OK
 
try {
    $urlTableContext = New-TableContext -TableName 'shorturls'
    $result = (Get-AzDataTableEntity -context $urlTableContext)
} catch {
    $StatusCode = [HttpStatusCode]::BadRequest
    throw $_.Exception.Message
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = [array]$result
})