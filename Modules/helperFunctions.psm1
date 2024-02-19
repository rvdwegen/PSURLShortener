function Invoke-URLRedirect {
    # Input bindings are passed in via param block.
    param($Request, $TriggerMetadata)

    try {
        Connect-AzAccount -Identity | Out-Null
    } catch {
        throw "Failed to authenticate to Azure using the function app identity: $($_.Exception.Message)"
    }

    try {
        $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity
        $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($Request.Params.URLslug)'" -context $urlTableContext)

        if ($urlObject) {
            # Give a 302 response back
            $httpResponse = [HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Found
                Headers     = @{ Location = $urlObject.originalURL }
                Body        = ''
            }

            $count = $true
        } else {
            # Get the notfound HTML content
            #$data = Get-Content -Path 'C:\home\site\wwwroot\Resources\notfound.html' -Raw
            #$data = $data.Replace('{URLSLUG}',$($Request.Params.URLslug))

            $httpResponse = [HttpResponseContext]@{
                #StatusCode  = [HttpStatusCode]::OK
                StatusCode  = [HttpStatusCode]::NotFound
                #Headers     = @{ 'content-type' = 'text/html' }
                #Body        = $data #"<html><body>Code $($Request.Params.URLslug) could not be matched to a stored URL</body></html>"
            }
        }
    } catch {
        throw $_.Exception.Message
    }

    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value (
        $httpResponse
    )

    if ($count) {
        $visitsTableContext = New-AzDataTableContext -TableName 'visits' -StorageAccountName 'stourlshort' -ManagedIdentity
        $visit = @{
            PartitionKey = "VISIT"
            RowKey = [string](New-Guid).Guid
            ClientIp = $request.headers.'client-ip'
            UserAgent = $request.headers.'user-agent'
            Platform = $request.headers.'sec-ch-ua-platform'
            slug = $urlObject.RowKey
        }
        Add-AzDataTableEntity -Entity $visit -context $visitsTableContext

        # Increase visit count
        $urlObject.visitors++
        Update-AzDataTableEntity -Entity $urlObject -context $urlTableContext
    }
}

Export-ModuleMember -Function @('Invoke-URLRedirect')