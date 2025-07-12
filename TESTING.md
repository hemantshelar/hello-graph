# Test the Function App

## Using curl (PowerShell)

```powershell
# Test health endpoint
Invoke-RestMethod -Uri "http://localhost:7071/api/health" -Method GET

# Test app registration endpoint
$body = @{
    appId = "your-app-registration-id-here"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:7071/api/app-registration" -Method POST -Body $body -ContentType "application/json"
```

## Using curl (Bash)

```bash
# Test health endpoint
curl -X GET http://localhost:7071/api/health

# Test app registration endpoint
curl -X POST http://localhost:7071/api/app-registration \
  -H "Content-Type: application/json" \
  -d '{"appId": "your-app-registration-id-here"}'
```

## Using Postman

### Health Check
- **Method**: GET
- **URL**: `http://localhost:7071/api/health`

### App Registration Query
- **Method**: POST
- **URL**: `http://localhost:7071/api/app-registration`
- **Headers**: `Content-Type: application/json`
- **Body** (raw JSON):
```json
{
  "appId": "your-app-registration-id-here"
}
```

## Expected Responses

### Health Check Response
```json
{
  "status": "healthy",
  "timestamp": "2024-07-06T12:00:00.000Z",
  "version": "1.0.0"
}
```

### App Registration Response
```json
{
  "success": true,
  "data": {
    "appId": "12345678-1234-1234-1234-123456789012",
    "displayName": "My App Registration",
    "createdDateTime": "2024-01-01T00:00:00.000Z",
    "secrets": [
      {
        "keyId": "87654321-4321-4321-4321-210987654321",
        "displayName": "Primary Secret",
        "startDateTime": "2024-01-01T00:00:00.000Z",
        "endDateTime": "2025-01-01T00:00:00.000Z",
        "isExpired": false,
        "daysUntilExpiration": 180,
        "status": "Active"
      }
    ]
  },
  "timestamp": "2024-07-06T12:00:00.000Z"
}
```

## Error Responses

### Invalid Request
```json
{
  "success": false,
  "error": "AppId is required in request body",
  "timestamp": "2024-07-06T12:00:00.000Z"
}
```

### App Not Found
```json
{
  "success": false,
  "error": "Application with ID your-app-id not found",
  "timestamp": "2024-07-06T12:00:00.000Z"
}
```

### Unauthorized
```json
{
  "success": false,
  "error": "Unauthorized access to Microsoft Graph API",
  "timestamp": "2024-07-06T12:00:00.000Z"
}
```
