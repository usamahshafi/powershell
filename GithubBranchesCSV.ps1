$owner = "***"
$repos = @("repo1", "repo2", "repo3")
$token = "***"
$excludedBranches = @("main", "dev", "qa", "uat", "stg", "prd", "prod")

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "application/vnd.github.v3+json"
}

$branchData = @()

foreach ($repo in $repos) {
    $branchesUrl = "https://api.github.com/repos/$owner/$repo/branches"

    Write-Host "Requesting branches from repository ${repo}"
    
    try {
        $branches = Invoke-RestMethod -Uri $branchesUrl -Headers $headers -Method Get

        foreach ($branch in $branches) {
            $branchName = $branch.name

            if ($excludedBranches -contains $branchName) {
                Write-Host "Skipping branch: $branchName (protected)"
                continue
            }

            Write-Host "Processing branch: $branchName"
            
            $branchCommitUrl = "https://api.github.com/repos/$owner/$repo/commits?sha=$branchName"
            $commits = Invoke-RestMethod -Uri $branchCommitUrl -Headers $headers -Method Get

            if ($commits.Count -gt 0) {
                $firstCommitAuthoredDate = $commits[0].commit.author.date
                $firstCommitAuthoredDate = [datetime]::Parse($firstCommitAuthoredDate)

                Write-Host "First commit authored on: $firstCommitAuthoredDate"
                
                $branchData += [PSCustomObject]@{
                    Repository   = $repo
                    Branch       = $branchName
                    AuthoredDate = $firstCommitAuthoredDate
                }
            } else {
                Write-Host "No commits found for this branch."
            }
        }
    } catch {
        Write-Host "Error retrieving branches for repository ${repo}: $_"
    }
}

$scriptDirectory = $PSScriptRoot

$csvFilePath = Join-Path -Path $scriptDirectory -ChildPath "branch_data.csv"

$branchData | Export-Csv -Path $csvFilePath -NoTypeInformation

Write-Host "Branch data exported to $csvFilePath"
