function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host "loc: $((Get-Item $PSScriptRoot).Parent.Parent.FullName)"
    Write-Host "Functionname is $($TriggerMetadata.FunctionName)"

    $APIName = $TriggerMetadata.FunctionName
    $FunctionName = 'Invoke-{0}' -f $APIName

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }

    try {
        & $FunctionName @HttpTrigger
    } catch {
        throw "Failed to execute URL redirect: $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function @('Receive-HttpTrigger')