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

        // Use Managed Identity for authentication
        var credential = new DefaultAzureCredential();

        // Create Graph client with managed identity
        _graphClient = new GraphServiceClient(credential);
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
            _logger.LogInformation("Retrieving app registration details for app ID: {AppId}", appId);

            // Get the application
            var allApps = await _graphClient.Applications.GetAsync();
            var application = await _graphClient.Applications[appId].GetAsync();

            if (application == null)
            {
                throw new InvalidOperationException($"Application with ID {appId} not found");
            }

            // Get password credentials (secrets)
            var secrets = application.PasswordCredentials?.Select(pc => new SecretInfo
            {
                KeyId = pc.KeyId?.ToString() ?? string.Empty,
                DisplayName = pc.DisplayName ?? "No display name",
                EndDateTime = pc.EndDateTime?.DateTime,
                StartDateTime = pc.StartDateTime?.DateTime,
                IsExpired = pc.EndDateTime?.DateTime < DateTime.UtcNow,
                DaysUntilExpiration = pc.EndDateTime?.DateTime != null
                    ? (int)(pc.EndDateTime.Value.DateTime - DateTime.UtcNow).TotalDays
                    : null
            }).ToList() ?? new List<SecretInfo>();

            var result = new AppRegistrationInfo
            {
                AppId = application.AppId ?? string.Empty,
                DisplayName = application.DisplayName ?? string.Empty,
                CreatedDateTime = application.CreatedDateTime?.DateTime,
                Secrets = secrets
            };

            _logger.LogInformation("Successfully retrieved app registration details for {DisplayName}", result.DisplayName);
            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving app registration details for app ID: {AppId}", appId);
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
    public DateTime? CreatedDateTime { get; set; }
    public List<SecretInfo> Secrets { get; set; } = new();
}

/// <summary>
/// Secret information model
/// </summary>
public class SecretInfo
{
    public string KeyId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public DateTime? StartDateTime { get; set; }
    public DateTime? EndDateTime { get; set; }
    public bool IsExpired { get; set; }
    public int? DaysUntilExpiration { get; set; }
}
