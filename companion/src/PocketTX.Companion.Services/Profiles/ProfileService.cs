using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Shared.Constants;
using PocketTX.Companion.Shared.Helpers;

namespace PocketTX.Companion.Services.Profiles;

public sealed class ProfileService : IProfileService
{
    private readonly List<ControllerProfile> _profiles = new();
    private readonly string _profilesDirectory;
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public IReadOnlyList<ControllerProfile> AvailableProfiles => _profiles.AsReadOnly();
    public ControllerProfile ActiveProfile => _stateStore.CurrentProfile;

    public ProfileService(IStateStore stateStore, ILoggerService logger)
    {
        _stateStore = stateStore;
        _logger = logger;
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        _profilesDirectory = Path.Combine(localAppData, AppConstants.DefaultFolderName, AppConstants.SettingsFolderName, AppConstants.ProfilesFolderName);
        Directory.CreateDirectory(_profilesDirectory);
    }

    public async Task LoadProfilesAsync(CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            _profiles.Clear();
            string[] jsonFiles = Directory.GetFiles(_profilesDirectory, "*.json");

            if (jsonFiles.Length == 0)
            {
                // Seed default profiles
                await SeedDefaultProfilesAsync(cancellationToken);
                jsonFiles = Directory.GetFiles(_profilesDirectory, "*.json");
            }

            foreach (string filePath in jsonFiles)
            {
                try
                {
                    string json = await File.ReadAllTextAsync(filePath, cancellationToken);
                    var profile = JsonHelper.Deserialize<ControllerProfile>(json);
                    if (profile != null)
                    {
                        _profiles.Add(profile);
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning($"Failed to read profile file '{filePath}': {ex.Message}", "ProfileService");
                }
            }

            if (_profiles.Count == 0)
            {
                _profiles.Add(ControllerProfile.CreateDefaultAcro());
            }

            ControllerProfile defaultSelection = _profiles.FirstOrDefault(p => p.Name == _stateStore.CurrentSettings.SelectedProfileName) ?? _profiles[0];
            _stateStore.UpdateProfile(defaultSelection);
            _logger.LogInfo($"Loaded {_profiles.Count} profiles. Selected: {defaultSelection.Name}", "ProfileService");
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task<ControllerProfile> SelectProfileAsync(string profileName, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            var match = _profiles.FirstOrDefault(p => p.Name.Equals(profileName, StringComparison.OrdinalIgnoreCase));
            if (match == null)
            {
                match = _profiles.FirstOrDefault() ?? ControllerProfile.CreateDefaultAcro();
            }

            _stateStore.UpdateProfile(match);
            _logger.LogInfo($"Selected profile '{match.Name}'.", "ProfileService");
            return match;
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task SaveProfileAsync(ControllerProfile profile, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            profile.Modified = DateTime.UtcNow;
            string fileName = $"{SanitizeFileName(profile.Name)}.json";
            string filePath = Path.Combine(_profilesDirectory, fileName);

            string json = JsonHelper.Serialize(profile);
            await File.WriteAllTextAsync(filePath, json, cancellationToken);

            int existingIdx = _profiles.FindIndex(p => p.Name.Equals(profile.Name, StringComparison.OrdinalIgnoreCase));
            if (existingIdx >= 0)
            {
                _profiles[existingIdx] = profile;
            }
            else
            {
                _profiles.Add(profile);
            }

            _stateStore.UpdateProfile(profile);
            _logger.LogInfo($"Saved profile '{profile.Name}' to disk.", "ProfileService");
        }
        finally
        {
            _semaphore.Release();
        }
    }

    private async Task SeedDefaultProfilesAsync(CancellationToken cancellationToken)
    {
        var defaults = new List<ControllerProfile>
        {
            ControllerProfile.CreateDefaultAcro(),
            ControllerProfile.CreateLiftoffMicro(),
            ControllerProfile.CreateVelocidrone(),
            ControllerProfile.CreateFPVSkyDive(),
            ControllerProfile.CreatePicaSim()
        };

        foreach (var profile in defaults)
        {
            string filePath = Path.Combine(_profilesDirectory, $"{SanitizeFileName(profile.Name)}.json");
            string json = JsonHelper.Serialize(profile);
            await File.WriteAllTextAsync(filePath, json, cancellationToken);
            _profiles.Add(profile);
        }
    }

    private static string SanitizeFileName(string name)
    {
        foreach (char c in Path.GetInvalidFileNameChars())
        {
            name = name.Replace(c, '_');
        }
        return name;
    }
}
