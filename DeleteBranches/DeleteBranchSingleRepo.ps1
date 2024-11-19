$orgName = "humana"
$projectName = "DevOps"
$repoName = "ado_wrapper"
$pat = "3lDZTzaOVNq1v6INrtA2MmzeEl8pSKFW8XAmNnpjH0FE4cbmDglPJQQJ99AKACAAAAAd7FPDAAASAZDOTZhV"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

$excludedBranches = @("main", "prod", "master", "stg", "dev", "prd")

$cutoffDate = [DateTime]::Parse("2024-08-31T00:00:00")

$deletedBranches = @()



Write-Output "Processing Repo: $repoName"

# Fetch the repository details to get the repository ID
$reposUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories?api-version=7.1-preview.1"
$repos = Invoke-RestMethod -Uri $reposUrl -Headers @{Authorization = "Basic $base64AuthInfo"} -Method Get

$repoId = ($repos.value | Where-Object { $_.name -eq $repoName }).id

if (-not $repoId) {
    Write-Error "Repository '$repoName' not found in project '$projectName'."
    return
}

# Fetch Branches for the 'ado_wrapper' repository
$branchesUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories/$repoId/refs?filter=heads&api-version=7.1-preview.1"
$branches = Invoke-RestMethod -Uri $branchesUrl -Headers @{Authorization = "Basic $base64AuthInfo"} -Method Get

foreach ($branch in $branches.value) {
    $branchName = $branch.name -replace "refs/heads/", ""

    # Skip the excluded branches (e.g., main, prod, master, etc.)
    if ($excludedBranches -contains $branchName) { continue }

    # Get the latest commit in the branch (get the latest commit by using the $top=1 query parameter)
    $branchCommitsUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories/$repoId/commits?searchCriteria.itemVersion.version=$branchName&searchCriteria.itemVersion.versionType=branch&\$top=1&api-version=7.1-preview.1"

    try {
        $branchCommits = Invoke-RestMethod -Uri $branchCommitsUrl -Headers @{Authorization = "Basic $base64AuthInfo"} -Method Get

        if ($branchCommits.value.Count -gt 0) {
            $latestCommit = $branchCommits.value[0]

            $latestCommitDate = [DateTime]::Parse($latestCommit.committer.date)

            Write-Output "Repo Name: $repoName"
            Write-Output "Branch Name: $branchName"
            Write-Output "Date: $latestCommitDate"
            Write-Output "Commit Message: $($latestCommit.comment)"
            Write-Output "Commit ID: $($latestCommit.commitId)"
            Write-Output "---------------------------------------------"

            if ($latestCommitDate -lt $cutoffDate) {
                Write-Output "The latest commit is before $cutoffDate, attempting to delete branch $branchName..."

                $AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)")) }
                $UriOrganization = "https://dev.azure.com/$orgName/"
                $urlDeleteBranch = "$($UriOrganization)$($projectName)/_apis/git/repositories/$repoId/refs?api-version=7.1-preview.1"

                $body = ConvertTo-Json (
                                                        @(
                                                            @{
                                                                name        = "refs/heads/$branchName";
                                                                oldObjectId = $branch.objectId;
                                                                newObjectId = "0000000000000000000000000000000000000000";
                                                            }
                                                        )
                                                    )

                $DeleteBranchResult = Invoke-RestMethod -Uri $urlDeleteBranch -Method Post -Headers $AzureDevOpsAuthenicationHeader -Body $body -ContentType "application/json"

                if ($DeleteBranchResult) {
                    Write-Output "Branch '$branchName' deleted successfully."
                    $deletedBranches += "$repoName - $branchName"
                } else {
                    Write-Error "Failed to delete branch '$branchName'."
                }
            }
        } else {
            Write-Output "No commits found for branch: $branchName in Repo: $repoName"
        }
    } catch {
        Write-Host "Error fetching commits for branch '$branchName' in repository '$repoName': $_" -ForegroundColor Red
    }
}

if ($deletedBranches.Count -gt 0) {
    Write-Output "Deleted branches:"
    $deletedBranches | ForEach-Object { Write-Output $_ }
} else {
    Write-Output "No branches were deleted."
}
