using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

try {
    try {
        $urlTableContext = New-TableContext -TableName 'shorturls'
    } catch {
        $StatusCode = [HttpStatusCode]::InternalServerError
        throw "Failed to create table context $($_.Exception.Message)"
    }

    switch ($Request.Method) {
        'POST' {
            if ($Request.body.slug) {
                $slug = $Request.body.slug
            } else {
                $slug = (("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").ToCharArray() | Get-Random -Count 6) -Join ""
            }
    
            $functions = @(
                'list',
                'login',
                'logout'
            )
        
            if ($slug -in $functions) {
                $StatusCode = [HttpStatusCode]::BadRequest
                throw "slug $($Slug) is banned word"
            }
        
            if ($slug.Length -lt 6) {
                $StatusCode = [HttpStatusCode]::BadRequest
                throw "not enough letters in the slug $($Slug)"
            }
        
            if (-Not $Request.body.url) {
                $StatusCode = [HttpStatusCode]::BadRequest
                throw "no url lol"
            }

            $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)
            if ($urlObject) {
                $StatusCode  = [HttpStatusCode]::BadRequest
                throw "Slug $($Slug) already exists"
            }

            try {
                [array]$domains = @("short.vdwegen.app")

                $result = @{
                    PartitionKey = "URL"
                    RowKey = [string]((New-Guid).Guid)
                    slug = $slug
                    originalURL = $Request.body.url
                    domains = [string](ConvertTo-Json -InputObject $domains -Compress)
                    shortURL = "https://short.vdwegen.app/$slug" # don't hardcode the url
                    visitors = 0
                    CreatedOn = [DateTime]::SpecifyKind((Get-Date), [DateTimeKind]::Utc) #(Get-Date).ToUniversalTime().ToString("yyyy-MM-dd'T'HH:mm:ss.fffffffK")
                    CreatedBy = $Request.Headers.'x-ms-client-principal-name'
                }
            
                Add-AzDataTableEntity -Entity $result -context $urlTableContext
                $StatusCode = [HttpStatusCode]::OK
                $result.Remove('PartitionKey')
                $result.Remove('RowKey')
                $result.Remove('visitors')
            } catch {
                $StatusCode = [HttpStatusCode]::InternalServerError
                throw "Failed to write to table: $($_.Exception.Message)"  
            }
        }
        'PATCH' {
            $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)

            if ($Request.Body.Slug) {

            }

            if ($Request.Body.Domains) {

            }

            if ($Request.Body.originalURL) {

            }
        }
        'DELETE' {
            $Slug = $Request.body.slug

            $urlObject = (Get-AzDataTableEntity -Filter "RowKey eq '$($slug)'" -context $urlTableContext)
            $urlObject | Remove-AzDataTableEntity -context $urlTableContext

            $StatusCode = [HttpStatusCode]::NoContent
        }
        Default {}
    }
} catch {
    $Result = @{ message = $($_.Exception.Message) }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $StatusCode
    Body       = $result
})