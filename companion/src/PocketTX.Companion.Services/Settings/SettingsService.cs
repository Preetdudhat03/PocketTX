using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Shared.Constants;
using PocketTX.Companion.Shared.Helpers;

namespace PocketTX.Companion.Services.Settings;

public sealed class SettingsService : ISettingsService
{
    private readonly string _settingsFilePath;
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public AppSettings CurrentSettings => _stateStore.CurrentSettings;

    public SettingsService(IStateStore stateStore, ILoggerService logger)
    {
        _stateStore = stateStore;
        _logger = logger;
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        string folder = Path.Combine(localAppData, AppConstants.DefaultFolderName, AppConstants.SettingsFolderName);
        Directory.CreateDirectory(folder);
        _settingsFilePath = Path.Combine(folder, AppConstants.AppSettingsFileName);
    }

    public async Task LoadSettingsAsync(CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            AppSettings settings;
            if (File.Exists(_settingsFilePath))
            {
                string json = await File.ReadAllTextAsync(_settingsFilePath, cancellationToken);
                settings = JsonHelper.Deserialize<AppSettings>(json) ?? new AppSettings();
            }
            else
            {
                settings = new AppSettings();
                string json = JsonHelper.Serialize(settings);
                await File.WriteAllTextAsync(_settingsFilePath, json, cancellationToken);
            }

            _stateStore.UpdateSettings(settings);
            _logger.LogInfo($"Loaded application settings (v{settings.Version}). Theme: {settings.Theme}", "SettingsService");
        }
        catch (Exception ex)
        {
            _logger.LogError("Failed to load settings, using defaults.", ex, "SettingsService");
            _stateStore.UpdateSettings(new AppSettings());
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task SaveSettingsAsync(AppSettings settings, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            string json = JsonHelper.Serialize(settings);
            await File.WriteAllTextAsync(_settingsFilePath, json, cancellationToken);
            _stateStore.UpdateSettings(settings);
            _logger.LogInfo("Saved application settings.", "SettingsService");
        }
        catch (Exception ex)
        {
            _logger.LogError("Failed to save settings.", ex, "SettingsService");
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
