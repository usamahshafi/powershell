$organizationUrl = "***"
$projectName = "***"
$pat = "***"

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))

$headers = @{
    Authorization = "Basic $base64AuthInfo"
}
function Get-Repositories {
    $url = "$organizationUrl/$projectName/_apis/git/repositories?api-version=7.1-preview.1"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    return $response.value
}

function Get-Branches {
    param (
        [string]$repoId
    )
    $url = "$organizationUrl/$projectName/_apis/git/repositories/$repoId/refs?filter=&api-version=7.1-preview.1"
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    return $response.value
}

$repositories = Get-Repositories

$branchData = @()

foreach ($repo in $repositories) {
    $repoName = $repo.name
    $repoId = $repo.id
    
    Write-Host "Fetching branches for repository: $repoName"
    
    $branches = Get-Branches -repoId $repoId
    
    foreach ($branch in $branches) {
        $branchData += [PSCustomObject]@{
            RepositoryName = $repoName
            BranchName = $branch.name
        }
    }
}
$branchData | Export-Csv -Path "AzureDevOpsBranches.csv" -NoTypeInformation
Write-Host "Branches data saved to 'AzureDevOpsBranches.csv'"
