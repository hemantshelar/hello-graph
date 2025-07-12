using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Extensions.Logging;
using HelloGraphFunction.Services;
using System.Net;
using System.Text.Json;

namespace HelloGraphFunction.Functions;

/// <summary>
/// Azure Function to query app registration and secret details
/// </summary>
public class AppRegistrationFunction
{
    private readonly ILogger<AppRegistrationFunction> _logger;
    private readonly IGraphService _graphService;

    public AppRegistrationFunction(ILogger<AppRegistrationFunction> logger, IGraphService graphService)
    {
        _logger = logger;
        _graphService = graphService;
    }

    /// <summary>
    /// HTTP trigger function to get app registration details
    /// Usage: POST /api/app-registration with JSON body: {"appId": "your-app-id"}
    /// </summary>
    [Function("GetAppRegistration")]
    public async Task<HttpResponseData> GetAppRegistration(
        [HttpTrigger(AuthorizationLevel.Function, "post", Route = "app-registration")] HttpRequestData req)
    {
        _logger.LogInformation("HTTP trigger function GetAppRegistration processed a request");

        try
        {
            // Read request body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            
            if (string.IsNullOrWhiteSpace(requestBody))
            {
                return await CreateErrorResponse(req, HttpStatusCode.BadRequest, "Request body is required");
            }

            // Parse JSON request
            var requestData = JsonSerializer.Deserialize<AppRegistrationRequest>(requestBody, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            if (requestData == null || string.IsNullOrWhiteSpace(requestData.AppId))
            {
                return await CreateErrorResponse(req, HttpStatusCode.BadRequest, "AppId is required in request body");
            }

            _logger.LogInformation("Processing request for app ID: {AppId}", requestData.AppId);

            // Get app registration details
            var appInfo = await _graphService.GetAppRegistrationDetailsAsync(requestData.AppId);

            // Create response
            var response = req.CreateResponse(HttpStatusCode.OK);
            response.Headers.Add("Content-Type", "application/json");

            var responseData = new
            {
                success = true,
                data = new
                {
                    appId = appInfo.AppId,
                    displayName = appInfo.DisplayName,
                    createdDateTime = appInfo.CreatedDateTime,
                    secrets = appInfo.Secrets.Select(s => new
                    {
                        keyId = s.KeyId,
                        displayName = s.DisplayName,
                        startDateTime = s.StartDateTime,
                        endDateTime = s.EndDateTime,
                        isExpired = s.IsExpired,
                        daysUntilExpiration = s.DaysUntilExpiration,
                        status = s.IsExpired ? "Expired" : 
                               s.DaysUntilExpiration <= 30 ? "Expiring Soon" : "Active"
                    })
                },
                timestamp = DateTime.UtcNow
            };

            await response.WriteStringAsync(JsonSerializer.Serialize(responseData, new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = true
            }));

            _logger.LogInformation("Successfully processed request for app ID: {AppId}", requestData.AppId);
            return response;
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "App registration not found");
            return await CreateErrorResponse(req, HttpStatusCode.NotFound, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access to Graph API");
            return await CreateErrorResponse(req, HttpStatusCode.Unauthorized, "Unauthorized access to Microsoft Graph API");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing app registration request");
            return await CreateErrorResponse(req, HttpStatusCode.InternalServerError, "An error occurred while processing the request");
        }
    }

    /// <summary>
    /// Health check endpoint
    /// </summary>
    [Function("HealthCheck")]
    public async Task<HttpResponseData> HealthCheck(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = "health")] HttpRequestData req)
    {
        _logger.LogInformation("Health check requested");

        var response = req.CreateResponse(HttpStatusCode.OK);
        response.Headers.Add("Content-Type", "application/json");

        var responseData = new
        {
            status = "healthy",
            timestamp = DateTime.UtcNow,
            version = "1.0.0"
        };

        await response.WriteStringAsync(JsonSerializer.Serialize(responseData, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true
        }));

        return response;
    }

    private async Task<HttpResponseData> CreateErrorResponse(HttpRequestData req, HttpStatusCode statusCode, string message)
    {
        var response = req.CreateResponse(statusCode);
        response.Headers.Add("Content-Type", "application/json");

        var errorData = new
        {
            success = false,
            error = message,
            timestamp = DateTime.UtcNow
        };

        await response.WriteStringAsync(JsonSerializer.Serialize(errorData, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            WriteIndented = true
        }));

        return response;
    }
}

/// <summary>
/// Request model for app registration queries
/// </summary>
public class AppRegistrationRequest
{
    public string AppId { get; set; } = string.Empty;
}
