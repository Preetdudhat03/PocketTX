using System.Collections.ObjectModel;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.UI.ViewModels;

public partial class ProfilesViewModel : ObservableObject
{
    private readonly IProfileService _profileService;
    private readonly ILoggerService _logger;

    [ObservableProperty]
    private ControllerProfile? _selectedProfile;

    public ObservableCollection<ControllerProfile> Profiles { get; } = new();

    public ProfilesViewModel(IProfileService profileService, ILoggerService logger)
    {
        _profileService = profileService;
        _logger = logger;

        LoadProfiles();
    }

    private async void LoadProfiles()
    {
        await _profileService.LoadProfilesAsync();
        Profiles.Clear();
        foreach (var profile in _profileService.AvailableProfiles)
        {
            Profiles.Add(profile);
        }
        SelectedProfile = _profileService.ActiveProfile;
    }

    [RelayCommand]
    private async Task SelectProfile(ControllerProfile? profile)
    {
        if (profile == null) return;
        SelectedProfile = profile;
        await _profileService.SelectProfileAsync(profile.Name);
    }

    [RelayCommand]
    private async Task SaveCurrentProfile()
    {
        if (SelectedProfile == null) return;
        await _profileService.SaveProfileAsync(SelectedProfile);
        _logger.LogInfo($"Profile '{SelectedProfile.Name}' saved successfully.", "Profiles");
    }
}
