# HelloGraph Function App

A .NET 8 Azure Function App that queries Microsoft Graph API to retrieve app registration and secret details using Managed Identity authentication.

## Features

- **HTTP Trigger**: Manual HTTP trigger for querying app registration details
- **Managed Identity**: Uses Azure Managed Identity for secure authentication with Microsoft Graph API
- **Dependency Injection**: Configured with proper DI container
- **Secret Monitoring**: Tracks secret expiration dates and provides alerts for expiring secrets
- **Local Development**: Configured for local debugging and testing

## Prerequisites

- .NET 8 SDK
- Azure Functions Core Tools v4
- Visual Studio Code or Visual Studio
- Azure subscription with appropriate permissions

## Project Structure

```
HelloGraphFunction/
├── Functions/
│   └── AppRegistrationFunction.cs    # HTTP trigger function
├── Services/
│   └── GraphService.cs               # Graph API service
├── Program.cs                        # Dependency injection setup
├── host.json                         # Function app configuration
├── local.settings.json               # Local development settings
└── HelloGraphFunction.csproj         # Project file
```

## Configuration

### Local Development

1. Update `local.settings.json`:
   ```json
   {
     "IsEncrypted": false,
     "Values": {
       "AzureWebJobsStorage": "UseDevelopmentStorage=true",
       "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
       "AZURE_CLIENT_ID": "your-client-id",
       "AZURE_TENANT_ID": "your-tenant-id",
       "APPLICATIONINSIGHTS_CONNECTION_STRING": "your-app-insights-connection-string"
     }
   }
   ```

2. For local development, you can use:
   - Visual Studio: Sign in with your Azure account
   - Azure CLI: Run `az login`
   - Service Principal: Set environment variables for client credentials

### Azure Deployment

When deployed to Azure, the function will automatically use the assigned Managed Identity.

## Required Permissions

The Managed Identity (or service principal for local development) needs the following Microsoft Graph permissions:

- `Application.Read.All` - To read application registrations
- `Directory.Read.All` - To read directory information

## API Endpoints

### Get App Registration Details

**POST** `/api/app-registration`

Request body:
```json
{
  "appId": "your-app-registration-id"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "appId": "12345678-1234-1234-1234-123456789012",
    "displayName": "My App Registration",
    "createdDateTime": "2024-01-01T00:00:00Z",
    "secrets": [
      {
        "keyId": "87654321-4321-4321-4321-210987654321",
        "displayName": "Primary Secret",
        "startDateTime": "2024-01-01T00:00:00Z",
        "endDateTime": "2025-01-01T00:00:00Z",
        "isExpired": false,
        "daysUntilExpiration": 180,
        "status": "Active"
      }
    ]
  },
  "timestamp": "2024-07-06T12:00:00Z"
}
```

### Health Check

**GET** `/api/health`

Response:
```json
{
  "status": "healthy",
  "timestamp": "2024-07-06T12:00:00Z",
  "version": "1.0.0"
}
```

## Local Development

1. Install dependencies:
   ```bash
   dotnet restore
   ```

2. Start the function app locally:
   ```bash
   func start
   ```

3. Test the function:
   ```bash
   curl -X POST http://localhost:7071/api/app-registration \
     -H "Content-Type: application/json" \
     -d '{"appId": "your-app-id"}'
   ```

## Deployment

### Using Azure CLI

1. Create a function app:
   ```bash
   az functionapp create --resource-group myResourceGroup --consumption-plan-location westus --runtime dotnet-isolated --functions-version 4 --name myFunctionApp --storage-account mystorageaccount
   ```

2. Enable managed identity:
   ```bash
   az functionapp identity assign --name myFunctionApp --resource-group myResourceGroup
   ```

3. Deploy the function:
   ```bash
   func azure functionapp publish myFunctionApp
   ```

### Using Visual Studio

1. Right-click the project in Solution Explorer
2. Select "Publish"
3. Choose "Azure Functions" as the target
4. Follow the deployment wizard

## Security Considerations

- Uses Managed Identity for authentication (no credentials in code)
- Function-level authorization for the main endpoint
- Proper error handling without exposing sensitive information
- Logging for monitoring and debugging

## Monitoring

The function app includes:
- Application Insights integration for telemetry
- Structured logging for debugging
- Health check endpoint for monitoring

## Error Handling

The function includes comprehensive error handling for:
- Invalid requests
- Authentication failures
- App registration not found
- Graph API errors
- General exceptions

## Best Practices Implemented

- ✅ Uses latest .NET 8 and Azure Functions v4
- ✅ Isolated process model for better performance
- ✅ Managed Identity for secure authentication
- ✅ Dependency injection for testability
- ✅ Proper error handling and logging
- ✅ Extension bundles for simplified dependency management
- ✅ Health check endpoint for monitoring
- ✅ Structured response format
- ✅ Local development configuration

