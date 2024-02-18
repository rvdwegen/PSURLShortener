function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host "loc: $((Get-Item $PSScriptRoot).Parent.Parent.FullName)"

    $APIName = $TriggerMetadata.FunctionName
    $FunctionName = 'Invoke-{0}' -f $APIName

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }
    Write-Host "here in http1"
    try {
        & $FunctionName @HttpTrigger
        Write-Host "here in http2"
    } catch {
        throw "Failed to execute URL redirect: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @('Receive-HttpTrigger')