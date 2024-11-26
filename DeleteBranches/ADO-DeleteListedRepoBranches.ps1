# This script deletes the branches dated before 1st Aug 2024 in the listed repos except the excluded branches. 
$orgName = "humana"
$projectName = "SCS"
$pat = "3lDZTzaOVNq1v6INrtA2MmzeEl8pSKFW8XAmNnpjH0FE4cbmDglPJQQJ99AKACAAAAAd7FPDAAASAZDOTZhV"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))

$repoNames = @(
    "cfes-cft-management-hub",
    "fws-cdf-npe-foundation",
    "fws-cdf-prd-foundation",
    "fws-cfes-npe-foundation",
    "fws-cfes-prd-foundation",
    "fws-cst-npe-foundation",
    "fws-cst-prd-foundation",
    "fws-dccc-npe-foundation",
    "fws-dccc-pci-npe-foundation",
    "fws-dccc-pci-prd-foundation",
    "fws-dccc-prd-foundation",
    "fws-dse-npe-foundation",
    "fws-dse-prd-foundation",
    "fws-ea-npe-foundation",
    "fws-ea-prd-foundation",
    "fws-eip-npe-foundation",
    "fws-eip-prd-foundation",
    "fws-forge-npe-foundation",
    "fws-forge-prd-foundation",
    "fws-grp-npe-foundation",
    "fws-grp-prd-foundation",
    "fws-hcs-npe-foundation",
    "fws-hcs-prd-foundation",
    "fws-hpe-npe-foundation",
    "fws-hpe-prd-foundation",
    "fws-idea-bi-npe-foundation",
    "fws-idea-npe-foundation",
    "fws-idea-prd-foundation",
    "fws-management-spoke-npe-foundation-build",
    "fws-management-spoke-npe-foundation",
    "fws-medc-npe-foundation",
    "fws-medc-prd-foundation",
    "fws-sao-npe-foundation",
    "fws-sao-prd-foundation",
    "fws-sqm-npe-foundation"
)

$excludedBranches = @("main", "prod", "master", "stg", "dev", "prd")

$cutoffDate = [DateTime]::Parse("2024-08-01T00:00:00")

$deletedBranches = @()

foreach ($repoName in $repoNames) {
    Write-Output "Processing Repo: $repoName"

    # Fetch the repository details to get the repository ID
    $reposUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories?api-version=7.1-preview.1"
    $repos = Invoke-RestMethod -Uri $reposUrl -Headers @{Authorization = "Basic $base64AuthInfo"} -Method Get

    $repoId = ($repos.value | Where-Object { $_.name -eq $repoName }).id

    if (-not $repoId) {
        Write-Error "Repository '$repoName' not found in project '$projectName'."
        continue
    }

    # Fetch Branches for the repository
    $branchesUrl = "https://dev.azure.com/$orgName/$projectName/_apis/git/repositories/$repoId/refs?filter=heads&api-version=7.1-preview.1"
    $branches = Invoke-RestMethod -Uri $branchesUrl -Headers @{Authorization = "Basic $base64AuthInfo"} -Method Get

    foreach ($branch in $branches.value) {
        $branchName = $branch.name -replace "refs/heads/", ""

        # Skip the excluded branches
        if ($excludedBranches -contains $branchName) { continue }

        # Get the latest commit in the branch
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
}

if ($deletedBranches.Count -gt 0) {
    Write-Output "Deleted branches:"
    $deletedBranches | ForEach-Object { Write-Output $_ }
} else {
    Write-Output "No branches were deleted."
}
