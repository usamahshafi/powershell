$owner = "***"
$repos = @("repo1", "repo2", "repo3")
$token = "***"
$excludedBranches = @("main", "dev", "qa", "uat", "stg", "prd", "prod")
$cutoffDate = Get-Date "2024-08-01"

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "application/vnd.github.v3+json"
}

foreach ($repo in $repos) {
    $branchesUrl = "https://api.github.com/repos/$owner/$repo/branches"

    Write-Host "Requesting branches from repository ${repo}"
    
    try {
        $branches = Invoke-RestMethod -Uri $branchesUrl -Headers $headers -Method Get
        Write-Host "Branches in the repository ${repo}:"

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
                
                if ($firstCommitAuthoredDate -lt $cutoffDate) {
                    Write-Host "Deleting branch: $branchName (Created on: $firstCommitAuthoredDate)"
                    $deleteBranchUrl = "https://api.github.com/repos/$owner/$repo/git/refs/heads/$branchName"
                    
                    try {
                        Invoke-RestMethod -Uri $deleteBranchUrl -Headers $headers -Method Delete
                        Write-Host "Branch $branchName deleted successfully."
                    } catch {
                        Write-Host "Error deleting branch ${branchName} from repo ${repo}: $_"
                    }
                } else {
                    Write-Host "Branch $branchName was created after $cutoffDate, skipping."
                }
            } else {
                Write-Host "No commits found for this branch."
            }

            Write-Host "-------------------------"
        }
    } catch {
        Write-Host "Error retrieving branches for repository ${repo}: $_"
    }
}
