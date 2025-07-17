using Microsoft.Graph;
using Microsoft.Extensions.Logging;
using Azure.Identity;
using Microsoft.Graph.Models;

namespace HelloGraphFunction.Services;

/// <summary>
/// Service to interact with Microsoft Graph API using Managed Identity
/// </summary>
public interface IGraphService
{
    Task<AppRegistrationInfo> GetAppRegistrationDetailsAsync(string appId);
}

public class GraphService : IGraphService
{
    private readonly GraphServiceClient _graphClient;
    private readonly ILogger<GraphService> _logger;

    public GraphService(ILogger<GraphService> logger)
    {
        _logger = logger;

        // Get the client ID from environment variable
        var clientId = Environment.GetEnvironmentVariable("AZURE_CLIENT_ID");
        
        DefaultAzureCredential credential;
        if (string.IsNullOrEmpty(clientId))
        {
            _logger.LogInformation("AZURE_CLIENT_ID not set, using default managed identity");
            credential = new DefaultAzureCredential();
        }
        else
        {
            _logger.LogInformation("Using managed identity with client ID: {ClientId}", clientId);
            credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                ManagedIdentityClientId = clientId
            });
        }

        // Create Graph client with managed identity
        _graphClient = new GraphServiceClient(credential);
        
        _logger.LogInformation("GraphServiceClient initialized");
    }

    /// <summary>
    /// Get app registration details including secret expiration information
    /// </summary>
    /// <param name="appId">Application ID of the app registration</param>
    /// <returns>App registration information with secret details</returns>
    public async Task<AppRegistrationInfo> GetAppRegistrationDetailsAsync(string appId)
    {
        try
        {
            _logger.LogInformation("Retrieving app registration details for input: {AppId}", appId);

            // Try to get the application using a filter approach
            var applicationsResponse = await _graphClient.Applications.GetAsync(requestConfiguration =>
            {
                // Try to determine if the input is an Object ID (GUID format) or App ID
                if (Guid.TryParse(appId, out var guid))
                {
                    // If it's a valid GUID, try both id (Object ID) and appId filters
                    requestConfiguration.QueryParameters.Filter = $"id eq '{appId}' or appId eq '{appId}'";
                    _logger.LogInformation("Searching for application using both Object ID and App ID filters for: {AppId}", appId);
                }
                else
                {
                    // If it's not a GUID, assume it's an App ID
                    requestConfiguration.QueryParameters.Filter = $"appId eq '{appId}'";
                    _logger.LogInformation("Searching for application using App ID filter for: {AppId}", appId);
                }
                requestConfiguration.QueryParameters.Select = new string[] { "id", "appId", "displayName", "createdDateTime", "passwordCredentials" };
            });

            var application = applicationsResponse?.Value?.FirstOrDefault();
            if (application == null)
            {
                throw new InvalidOperationException($"Application with input '{appId}' not found. Note: You can provide either an App ID (Application ID) or Object ID.");
            }

            _logger.LogInformation("Successfully found application: {DisplayName} (Object ID: {ObjectId}, App ID: {FoundAppId})", 
                application.DisplayName, application.Id, application.AppId);

            // Get password credentials (secrets)
            var secrets = application.PasswordCredentials?.Select(pc => new SecretInfo
            {
                KeyId = pc.KeyId?.ToString() ?? string.Empty,
                DisplayName = pc.DisplayName ?? "No display name",
                EndDateTime = pc.EndDateTime,
                StartDateTime = pc.StartDateTime,
                IsExpired = pc.EndDateTime.HasValue && pc.EndDateTime.Value < DateTimeOffset.UtcNow,
                DaysUntilExpiration = pc.EndDateTime.HasValue
                    ? (int?)(pc.EndDateTime.Value - DateTimeOffset.UtcNow).TotalDays
                    : null
            }).ToList() ?? new List<SecretInfo>();

            var result = new AppRegistrationInfo
            {
                AppId = application.AppId ?? string.Empty,
                DisplayName = application.DisplayName ?? string.Empty,
                CreatedDateTime = application.CreatedDateTime,
                Secrets = secrets
            };

            _logger.LogInformation("Successfully retrieved app registration details for {DisplayName}", result.DisplayName);
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving app registration details for input: {AppId}", appId);
            throw;
        }
    }
}

/// <summary>
/// App registration information model
/// </summary>
public class AppRegistrationInfo
{
    public string AppId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public DateTimeOffset? CreatedDateTime { get; set; }
    public List<SecretInfo> Secrets { get; set; } = new();
}

/// <summary>
/// Secret information model
/// </summary>
public class SecretInfo
{
    public string KeyId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public DateTimeOffset? StartDateTime { get; set; }
    public DateTimeOffset? EndDateTime { get; set; }
    public bool IsExpired { get; set; }
    public int? DaysUntilExpiration { get; set; }
}
