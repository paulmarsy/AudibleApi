function Get-AudibleProduct {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)][ValidateSet('US','UK','FR','DE','JP','IT','AU')]$Region
    )

    DynamicParam {   
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        $CategoryAttributes = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $CategoryAttributes.Add([System.Management.Automation.ParameterAttribute]@{Position = 1; Mandatory = $true})
        $CategoryAttributes.Add((New-Object System.Management.Automation.ValidateSetAttribute(Get-AudibleCategory -Region $Region | % name)))
        $RuntimeParameterDictionary.Add('Category', (New-Object System.Management.Automation.RuntimeDefinedParameter('Category', [string], $CategoryAttributes)))

        return $RuntimeParameterDictionary
    }

    process {
        $CategoryId = Get-AudibleCategory -Region $Region | ? name -eq $PsBoundParameters['Category'] | % id
        $num_results = 50
        $baseUri= '{0}/catalog/products?response_groups=contributors,rating,product_desc&num_results={1}&category_id={2}&page=' -f `
            (Get-AudibleStore -Region $Region), `
            $num_results, `
            $CategoryId

        $products = @()
        $page = 0
        do {
            $result = Invoke-RestMethod -UseBasicParsing -Uri ($baseUri + $page)
            $products += $result.products
            $page++
            #TODO: replace with Write-Progress
            Write-Host ('Downloaded page {0} of {1} ({2}/{3})...' -f $page, [math]::Ceiling($result.total_results / $num_results), $products.Count, $result.total_results)
        } while ($products.Count -lt $result.total_results)
        return $products
    }
}

function Get-AudibleCategory($Region) {
     if ($null -eq $script:categories) {
        $script:categories = Invoke-RestMethod -UseBasicParsing -Uri ('{0}/catalog/categories' -f (Get-AudibleStore -Region $Region)) | % categories
     }
     $script:categories
}

function Get-AudibleStore([ValidateSet('US','UK','FR','DE','JP','IT','AU')]$Region) {
    switch ($Region) {
        'US' { 'https://api.audible.com/1.0' }
        'UK' { 'https://api.audible.co.uk/1.0' }
        'FR' { 'https://api.audible.fr/1.0' }
        'DE' { 'https://api.audible.de/1.0' }
        'JP' { 'https://api.audible.co.jp/1.0' }
        'IT' { 'https://api.audible.it/1.0' }
        'AU' { 'https://api.audible.com.au/1.0' }
    }
}