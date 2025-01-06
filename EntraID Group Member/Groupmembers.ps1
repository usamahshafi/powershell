# Define the list of group names that we are interested in
$GroupNames = @("Group1", "Group2")

# Retrieve all Azure AD groups and filter only the ones that match the names in $GroupNames
$groups = Get-AzureADGroup -All $true | Where-Object {
    $GroupNames -contains $_.DisplayName
}

# Build a report of users in the filtered groups
$report = foreach ($group in $groups) {
    $users = $group | Get-AzureADGroupMember
    foreach ($user in $users) {
        [PSCustomObject][ordered]@{
            GroupDisplayName = $group.DisplayName
            UserDisplayName  = $user.DisplayName
        }
    }
}

# Export the report to CSV
$report | Export-Csv "Users_groups_wrt_groups.csv" -NoTypeInformation
