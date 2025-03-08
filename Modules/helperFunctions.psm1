function New-TableContext {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TableName
    )
    $Context = New-AzDataTableContext -ConnectionString $env:AzureWebJobsStorage -TableName $TableName
    New-AzDataTable -Context $Context | Out-Null
    return $Context
}

Export-ModuleMember -Function @('New-TableContext')