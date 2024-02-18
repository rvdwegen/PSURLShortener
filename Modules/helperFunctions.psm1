function Invoke-URLRedirect {
    # Input bindings are passed in via param block.
    param($Request, $TriggerMetadata)
    
    try {
        Connect-AzAccount -Identity | Out-Null
        $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity
    } catch {
        throw "Failed to authenticate to Azure using the function app identity: $($_.Exception.Message)"
    }

    $request.headers

    $request.headers

    try {
        $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($Request.Params.URLslug)'" -context $urlTableContext)

        if ($urlObject) {
            # Increase visit count
            $urlObject.visitors++
            Update-AzDataTableEntity -Entity $urlObject -context $urlTableContext

            # Give a 302 response back
            $httpResponse = [HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Found
                Headers     = @{ Location = $urlObject.originalURL }
                Body        = ''
            }
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
}

Export-ModuleMember -Function @('Invoke-URLRedirect')