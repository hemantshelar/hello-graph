# Quick Commands to Assign Graph Permissions to User-Assigned Managed Identity
# Run these commands one by one in PowerShell

# Replace these variables with your actual values
$managedIdentityName = "umi-asmp"
$resourceGroupName = "<YOUR_RESOURCE_GROUP_NAME>"  # Replace with your resource group name

Write-Host "Quick setup for assigning Graph API permissions to managed identity: $managedIdentityName" -ForegroundColor Green

Write-Host "`n=== STEP 1: Get Principal ID ===" -ForegroundColor Yellow
Write-Host "Run this command and note the Principal ID:" -ForegroundColor Cyan
Write-Host "az identity show --name `"$managedIdentityName`" --resource-group `"$resourceGroupName`" --query `"principalId`" --output tsv" -ForegroundColor White

Write-Host "`n=== STEP 2: Get Microsoft Graph Service Principal ID ===" -ForegroundColor Yellow
Write-Host "Run this command and note the Graph Service Principal ID:" -ForegroundColor Cyan
Write-Host "az ad sp list --display-name `"Microsoft Graph`" --query `"[0].id`" --output tsv" -ForegroundColor White

Write-Host "`n=== STEP 3: Get App Role IDs ===" -ForegroundColor Yellow
Write-Host "Run this command to get the Application.Read.All permission ID:" -ForegroundColor Cyan
Write-Host "az ad sp show --id <GRAPH_SP_ID> --query `"appRoles[?value=='Application.Read.All'].id`" --output tsv" -ForegroundColor White

Write-Host "Run this command to get the Directory.Read.All permission ID:" -ForegroundColor Cyan
Write-Host "az ad sp show --id <GRAPH_SP_ID> --query `"appRoles[?value=='Directory.Read.All'].id`" --output tsv" -ForegroundColor White

Write-Host "`n=== STEP 4: Assign Permissions ===" -ForegroundColor Yellow
Write-Host "For Application.Read.All permission:" -ForegroundColor Cyan
Write-Host "az rest --method POST --uri `"https://graph.microsoft.com/v1.0/servicePrincipals/<PRINCIPAL_ID>/appRoleAssignments`" --body `"{'principalId':'<PRINCIPAL_ID>','resourceId':'<GRAPH_SP_ID>','appRoleId':'<APP_ROLE_ID>'}`" --headers `"Content-Type=application/json`"" -ForegroundColor White

Write-Host "`nFor Directory.Read.All permission:" -ForegroundColor Cyan
Write-Host "az rest --method POST --uri `"https://graph.microsoft.com/v1.0/servicePrincipals/<PRINCIPAL_ID>/appRoleAssignments`" --body `"{'principalId':'<PRINCIPAL_ID>','resourceId':'<GRAPH_SP_ID>','appRoleId':'<DIRECTORY_ROLE_ID>'}`" --headers `"Content-Type=application/json`"" -ForegroundColor White

Write-Host "`n=== STEP 5: Verify Assignments ===" -ForegroundColor Yellow
Write-Host "Run this command to verify the permissions were assigned:" -ForegroundColor Cyan
Write-Host "az rest --method GET --uri `"https://graph.microsoft.com/v1.0/servicePrincipals/<PRINCIPAL_ID>/appRoleAssignments`"" -ForegroundColor White

Write-Host "`n=== IMPORTANT NOTES ===" -ForegroundColor Red
Write-Host "1. Replace <YOUR_RESOURCE_GROUP_NAME> with your actual resource group name" -ForegroundColor Yellow
Write-Host "2. Replace <PRINCIPAL_ID>, <GRAPH_SP_ID>, <APP_ROLE_ID>, and <DIRECTORY_ROLE_ID> with the actual values from steps 1-3" -ForegroundColor Yellow
Write-Host "3. You must be logged in to Azure CLI with sufficient permissions (Global Administrator or Application Administrator)" -ForegroundColor Yellow
Write-Host "4. Make sure you're authenticated: az login" -ForegroundColor Yellow

Write-Host "`n=== ALTERNATIVE: Use the automated script ===" -ForegroundColor Green
Write-Host "You can also run the automated script with:" -ForegroundColor Cyan
Write-Host ".\assign-graph-permissions.ps1 -ManagedIdentityName `"umi-asmp`" -ResourceGroupName `"<YOUR_RESOURCE_GROUP_NAME>`"" -ForegroundColor White
