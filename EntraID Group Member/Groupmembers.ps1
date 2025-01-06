# Define the list of group names that we are interested in
$GroupNames = @(
    "BIaaS Administrators",
    "BIaaS Data Factory Contributors",
    "BIaaS DB Contributor",
    "BIaaS Developers",
    "BIaaS Readers",
    "biaas-cube-dev-svc",
    "biaas-cube-prod-svc",
    "biaas-cube-stage-svc",
    "BIAAS-DEV-CAPSIS-ADMIN",
    "BIAAS-DEV-CAPSIS-ENGINEERS",
    "BIAAS-DEV-CAPSIS-READERS",
    "BIAAS-DEV-CAPSIS-STORAGE-CONTRIB",
    "BIAAS-DEV-CUBE-ADMIN",
    "BIAAS-DEV-CUBE-ENGINEERS",
    "BIAAS-DEV-CUBE-READER",
    "BIAAS-DEV-CUBE-STORAGE-CONTRIB",
    "BIAAS-DHSCONNECT-DEV-AI",
    "BIAAS-DHSCONNECT-DEV-Contributors",
    "BIAAS-DHSCONNECT-DEV-Engineers",
    "BIAAS-DHSCONNECT-DEV-STORAGE-Contributors",
    "BIAAS-DHSCONNECT-PRD-AI",
    "BIAAS-DHSCONNECT-PRD-Contributors",
    "BIAAS-DHSCONNECT-PRD-Engineers",
    "BIAAS-DHSCONNECT-PRD-STORAGE-Contributors",
    "BIAAS-DHSCONNECT-READERS",
    "BIAAS-DHSCONNECT-Sub-Contributors",
    "BIAAS-FULLSTACK-DEV-AI",
    "BIAAS-FULLSTACK-DEV-Contributors",
    "BIAAS-FULLSTACK-DEV-Engineers",
    "BIAAS-FULLSTACK-DEV-STORAGE-Contributors",
    "BIAAS-FULLSTACK-PRD-AI",
    "BIAAS-FULLSTACK-PRD-Contributors",
    "BIAAS-FULLSTACK-PRD-Engineers",
    "BIAAS-FULLSTACK-PRD-STORAGE-Contributors",
    "BIAAS-FULLSTACK-READERS",
    "BIAAS-FULLSTACK-Sub-Contributors",
    "BIAAS-OPENAI-DEV-AI",
    "BIAAS-OPENAI-DEV-Contributors",
    "BIAAS-OPENAI-DEV-Engineers",
    "BIAAS-OPENAI-DEV-STORAGE-Contributors",
    "BIAAS-OPENAI-PRD-AI",
    "BIAAS-OPENAI-PRD-Contributors",
    "BIAAS-OPENAI-PRD-Engineers",
    "BIAAS-OPENAI-PRD-STORAGE-Contributors",
    "BIAAS-OPENAI-READERS",
    "BIAAS-OPENAI-Sub-Contributors",
    "BIAAS-PRD-CAPSIS-ADMIN",
    "BIAAS-PRD-CAPSIS-ENGINEERS",
    "BIAAS-PRD-CAPSIS-READERS",
    "BIAAS-PRD-CAPSIS-STORAGE-CONTRIB",
    "BIAAS-PRD-CUBE-ADMIN",
    "BIAAS-PRD-CUBE-ENGINEERS",
    "BIAAS-PRD-CUBE-READER",
    "BIAAS-PRD-CUBE-STORAGE-CONTRIB",
    "BIAAS-STG-CAPSIS-ADMIN",
    "BIAAS-STG-CAPSIS-ENGINEERS",
    "BIAAS-STG-CAPSIS-READERS",
    "BIAAS-STG-CAPSIS-STORAGE-CONTRIB",
    "BIAAS-STG-CUBE-ADMIN",
    "BIAAS-STG-CUBE-ENGINEERS",
    "BIAAS-STG-CUBE-READER",
    "BIAAS-STG-CUBE-STORAGE-CONTRIB",
    "BIaaS-USM Administrators",
    "BIaaS-USM Readers",
    "BIaaS-USM-FPS Storage Contributors",
    "BIaaS-USM-TSA Storage Contributors"
)


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
