# PowerShell script to test the HelloGraph Function App locally
# Run this after starting your function with 'func start'

Write-Host "Testing HelloGraph Function App..." -ForegroundColor Green

# Test 1: Health Check
Write-Host "`n1. Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:7071/api/health" -Method GET
    Write-Host "✓ Health Check Success:" -ForegroundColor Green
    $healthResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "✗ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: App Registration Query (you'll need a real App ID)
Write-Host "`n2. Testing App Registration Endpoint..." -ForegroundColor Yellow
Write-Host "Note: You need to replace 'your-app-id-here' with an actual App Registration ID" -ForegroundColor Cyan

$appId = Read-Host "Enter an App Registration ID to test (or press Enter to skip)"
if ($appId -and $appId -ne "") {
    try {
        $body = @{ appId = $appId } | ConvertTo-Json
        $appResponse = Invoke-RestMethod -Uri "http://localhost:7071/api/app-registration" -Method POST -Body $body -ContentType "application/json"
        Write-Host "✓ App Registration Query Success:" -ForegroundColor Green
        $appResponse | ConvertTo-Json -Depth 5
    } catch {
        Write-Host "✗ App Registration Query Failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "This is normal if you don't have the required permissions or used an invalid App ID" -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipping App Registration test" -ForegroundColor Yellow
}

Write-Host "`nTesting complete!" -ForegroundColor Green
Write-Host "To debug, set breakpoints in VS Code and use F5 to attach debugger" -ForegroundColor Cyan
