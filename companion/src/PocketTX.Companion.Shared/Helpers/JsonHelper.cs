using System.Text.Json;
using System.Text.Json.Serialization;

namespace PocketTX.Companion.Shared.Helpers;

/// <summary>
/// Centralized JSON serialization helpers with consistent formatting options.
/// </summary>
public static class JsonHelper
{
    public static JsonSerializerOptions DefaultOptions { get; } = new()
    {
        WriteIndented = true,
        PropertyNameCaseInsensitive = true,
        Converters =
        {
            new JsonStringEnumConverter()
        }
    };

    public static string Serialize<T>(T obj)
    {
        return JsonSerializer.Serialize(obj, DefaultOptions);
    }

    public static T? Deserialize<T>(string json)
    {
        if (string.IsNullOrWhiteSpace(json))
            return default;

        return JsonSerializer.Deserialize<T>(json, DefaultOptions);
    }
}
