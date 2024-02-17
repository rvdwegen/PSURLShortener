using namespace System.Net

function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host (Get-Item $PSScriptRoot).Parent.Parent.FullName
    $APIName = $TriggerMetadata.FunctionName

    $FunctionName = 'Invoke-{0}' -f $APIName

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }

    & $FunctionName @HttpTrigger
}

function Invoke-URLRedirect {
    # Input bindings are passed in via param block.
    param($Request, $TriggerMetadata)
    
    try {
        Connect-AzAccount -Identity
        $urlTableContext = New-AzDataTableContext -TableName 'shorturls' -StorageAccountName 'stourlshort' -ManagedIdentity
        Write-Host "here1"
    } catch {
        throw $_.Exception.Message
    }

    try {
        Write-Host "here2"
        $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($Request.Params.URLslug)'" -context $urlTableContext)

        if ($urlObject) {
            Write-Host "here3"
            # Increase visit count
            $urlObject.visitors++
            Update-AzDataTableEntity -Entity $urlObject -context $urlTableContext

            # Give a 302 response back
            $httpResponse = [HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::Found
                Headers     = @{ Location = $urlObject.url }
                Body        = ''
            }
            Write-Host "here4"
        } else {

            # Get the notfound HTML content
            $data = Get-Content -Path 'C:\home\site\wwwroot\Resources\notfound.html' -Raw
            $data = $data.Replace('{URLSLUG}',$($Request.Params.URLslug))

            $httpResponse = [HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                Headers     = @{ 'content-type' = 'text/html' }
                Body        = $data #"<html><body>Code $($Request.Params.URLslug) could not be matched to a stored URL</body></html>"
            }
        }

    } catch {
        Write-Warning $_.Exception.Message
    }
    Write-Host "here5"
    # Associate values to output bindings by calling 'Push-OutputBinding'.
    Push-OutputBinding -Name Response -Value (
        $httpResponse
    )

}

Export-ModuleMember -Function @('Receive-HttpTrigger', 'Invoke-URLRedirect')