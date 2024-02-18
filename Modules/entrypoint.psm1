function Receive-HttpTrigger {
    Param($Request, $TriggerMetadata)

    Set-Location (Get-Item $PSScriptRoot).Parent.Parent.FullName
    Write-Host (Get-Item $PSScriptRoot).Parent.Parent.FullName

    $FunctionName = 'Invoke-URLRedirect'

    $HttpTrigger = @{
        Request         = $Request
        TriggerMetadata = $TriggerMetadata
    }

    & $FunctionName @HttpTrigger
}

Export-ModuleMember -Function @('Receive-HttpTrigger')