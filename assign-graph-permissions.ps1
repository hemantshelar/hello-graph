# Script to assign Microsoft Graph API permissions to User-Assigned Managed Identity
# This script assigns the required Graph API permissions to your managed identity

param(
    [Parameter(Mandatory=$true)]
    [string]$ManagedIdentityName = "umi-asmp",
    
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string[]]$GraphPermissions = @("Application.Read.All", "Directory.Read.All", "Application.ReadWrite.All", "Directory.ReadWrite.All")
)

Write-Host "Assigning Graph API permissions to User-Assigned Managed Identity: $ManagedIdentityName" -ForegroundColor Green

# Step 1: Get the Object ID (Principal ID) of the User-Assigned Managed Identity
Write-Host "Step 1: Getting the Principal ID of the managed identity..." -ForegroundColor Yellow
$principalId = az identity show --name $ManagedIdentityName --resource-group $ResourceGroupName --query "principalId" --output tsv

if (-not $principalId) {
    Write-Host "Error: Could not find managed identity '$ManagedIdentityName' in resource group '$ResourceGroupName'" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Principal ID: $principalId" -ForegroundColor Green

# Step 2: Get Microsoft Graph Service Principal ID
Write-Host "Step 2: Getting Microsoft Graph Service Principal ID..." -ForegroundColor Yellow
$graphServicePrincipalId = az ad sp list --display-name "Microsoft Graph" --query "[0].id" --output tsv

if (-not $graphServicePrincipalId) {
    Write-Host "Error: Could not find Microsoft Graph service principal" -ForegroundColor Red
    exit 1
}

Write-Host "✓ Microsoft Graph Service Principal ID: $graphServicePrincipalId" -ForegroundColor Green

# Step 3: Get the App Role IDs for the required permissions
Write-Host "Step 3: Getting App Role IDs for the permissions..." -ForegroundColor Yellow

$appRoles = @{}
$graphAppRoles = az ad sp show --id $graphServicePrincipalId --query "appRoles[?value=='Application.Read.All' || value=='Directory.Read.All' || value=='Application.ReadWrite.All' || value=='Directory.ReadWrite.All'].{value:value, id:id}" --output json | ConvertFrom-Json

foreach ($role in $graphAppRoles) {
    $appRoles[$role.value] = $role.id
    Write-Host "✓ Found permission '$($role.value)' with ID: $($role.id)" -ForegroundColor Green
}

# Step 4: Assign the permissions using Microsoft Graph API
Write-Host "Step 4: Assigning permissions to the managed identity..." -ForegroundColor Yellow

foreach ($permission in $GraphPermissions) {
    if ($appRoles.ContainsKey($permission)) {
        Write-Host "Assigning permission: $permission" -ForegroundColor Cyan
        
        # Create the app role assignment
        $bodyObject = @{
            principalId = $principalId
            resourceId = $graphServicePrincipalId
            appRoleId = $appRoles[$permission]
        }
        $body = $bodyObject | ConvertTo-Json -Compress
        
        # Write body to temporary file to avoid PowerShell escaping issues
        $tempFile = [System.IO.Path]::GetTempFileName()
        $body | Out-File -FilePath $tempFile -Encoding utf8 -NoNewline
        
        try {
            # Use file input for body to avoid header issues
            $result = az rest --method POST --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments" --body "@$tempFile" --headers "Content-Type=application/json" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ Successfully assigned permission: $permission" -ForegroundColor Green
            } else {
                Write-Host "✗ Failed to assign permission: $permission" -ForegroundColor Red
                Write-Host "Error: $result" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "✗ Failed to assign permission: $permission" -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
        finally {
            # Clean up temp file
            if (Test-Path $tempFile) {
                Remove-Item $tempFile -Force
            }
        }
    }
    else {
        Write-Host "✗ Permission '$permission' not found in available app roles" -ForegroundColor Red
    }
}

# Step 5: Verify the assignments
Write-Host "Step 5: Verifying the permission assignments..." -ForegroundColor Yellow
$assignments = az rest --method GET --uri "https://graph.microsoft.com/v1.0/servicePrincipals/$principalId/appRoleAssignments" | ConvertFrom-Json

Write-Host "Current permission assignments for the managed identity:" -ForegroundColor Cyan
foreach ($assignment in $assignments.value) {
    $roleInfo = $graphAppRoles | Where-Object { $_.id -eq $assignment.appRoleId }
    if ($roleInfo) {
        Write-Host "✓ $($roleInfo.value)" -ForegroundColor Green
    }
}

Write-Host "`nScript completed! The managed identity now has the required Graph API permissions." -ForegroundColor Green
Write-Host "You can now use this managed identity in your Azure Functions to access Microsoft Graph." -ForegroundColor Cyan
