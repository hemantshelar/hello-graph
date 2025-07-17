# Setup script for HelloGraph Function App
# This script helps set up the development environment

Write-Host "Setting up HelloGraph Function App..." -ForegroundColor Green

# Check if .NET 8 is installed
Write-Host "Checking .NET 8 installation..." -ForegroundColor Yellow
$dotnetVersion = dotnet --version
if ($dotnetVersion -notmatch "^8\.") {
    Write-Host "Warning: .NET 8 is required but not detected. Please install .NET 8 SDK." -ForegroundColor Red
    Write-Host "Download from: https://dotnet.microsoft.com/download/dotnet/8.0" -ForegroundColor Yellow
} else {
    Write-Host "✓ .NET 8 is installed: $dotnetVersion" -ForegroundColor Green
}

# Check if Azure Functions Core Tools are installed
Write-Host "Checking Azure Functions Core Tools..." -ForegroundColor Yellow
try {
    $funcVersion = func --version
    Write-Host "✓ Azure Functions Core Tools is installed: $funcVersion" -ForegroundColor Green
} catch {
    Write-Host "Warning: Azure Functions Core Tools not found." -ForegroundColor Red
    Write-Host "Install with: npm install -g azure-functions-core-tools@4 --unsafe-perm true" -ForegroundColor Yellow
}

# Check if Azure CLI is installed
Write-Host "Checking Azure CLI..." -ForegroundColor Yellow
try {
    $azVersion = az --version | Select-String "azure-cli"
    Write-Host "✓ Azure CLI is installed: $azVersion" -ForegroundColor Green
} catch {
    Write-Host "Warning: Azure CLI not found." -ForegroundColor Red
    Write-Host "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" -ForegroundColor Yellow
}

# Restore NuGet packages
Write-Host "Restoring NuGet packages..." -ForegroundColor Yellow
dotnet restore
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ NuGet packages restored successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to restore NuGet packages" -ForegroundColor Red
}

# Check if local.settings.json exists
Write-Host "Checking local.settings.json..." -ForegroundColor Yellow
if (Test-Path "local.settings.json") {
    Write-Host "✓ local.settings.json exists" -ForegroundColor Green
} else {
    Write-Host "Creating local.settings.json from template..." -ForegroundColor Yellow
    if (Test-Path "local.settings.json.template") {
        Copy-Item "local.settings.json.template" "local.settings.json"
        Write-Host "✓ local.settings.json created from template" -ForegroundColor Green
        Write-Host "Please update the configuration values in local.settings.json" -ForegroundColor Yellow
    } else {
        Write-Host "✗ local.settings.json.template not found" -ForegroundColor Red
    }
}

# Check Azure authentication
Write-Host "Checking Azure authentication..." -ForegroundColor Yellow
try {
    $azAccount = az account show --query "name" --output tsv 2>$null
    if ($azAccount) {
        Write-Host "✓ Authenticated with Azure as: $azAccount" -ForegroundColor Green
    } else {
        Write-Host "⚠ Not authenticated with Azure. Run 'az login' to authenticate." -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ Could not check Azure authentication status." -ForegroundColor Yellow
}

Write-Host "`nSetup complete! Next steps:" -ForegroundColor Green
Write-Host "1. Update local.settings.json with your Azure configuration" -ForegroundColor Cyan
Write-Host "2. Ensure you have the required Graph API permissions" -ForegroundColor Cyan
Write-Host "3. Assign Graph permissions to your managed identity (see assign-graph-permissions.ps1)" -ForegroundColor Cyan
Write-Host "4. Run 'func start' to start the function app locally" -ForegroundColor Cyan
Write-Host "5. Test the endpoints using the examples in TESTING.md" -ForegroundColor Cyan

Write-Host "`nRequired Graph API permissions:" -ForegroundColor Yellow
Write-Host "- Application.Read.All" -ForegroundColor White
Write-Host "- Directory.Read.All" -ForegroundColor White

Write-Host "`nTo assign Graph permissions to your managed identity:" -ForegroundColor Yellow
Write-Host "Run: .\assign-graph-permissions.ps1 -ManagedIdentityName 'umi-asmp' -ResourceGroupName '<your-rg>'" -ForegroundColor Cyan
Write-Host "Or follow the step-by-step guide: .\assign-permissions-guide.ps1" -ForegroundColor Cyan
