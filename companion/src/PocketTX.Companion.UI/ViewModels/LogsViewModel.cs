using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Logging.Models;
using System.Collections.ObjectModel;
using System.Windows;

namespace PocketTX.Companion.UI.ViewModels;

public partial class LogsViewModel : ObservableObject, IRecipient<LogEntry>
{
    private readonly List<LogEntry> _allLogs = new();

    [ObservableProperty]
    private string _filterText = string.Empty;

    [ObservableProperty]
    private LogLevel? _selectedLevelFilter = null;

    public ObservableCollection<LogEntry> FilteredLogs { get; } = new();

    public LogsViewModel(IMessenger messenger)
    {
        messenger.RegisterAll(this);
    }

    public void Receive(LogEntry log)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            _allLogs.Add(log);
            if (MatchesFilter(log))
            {
                FilteredLogs.Add(log);
            }
        });
    }

    partial void OnFilterTextChanged(string value) => ApplyFilters();
    partial void OnSelectedLevelFilterChanged(LogLevel? value) => ApplyFilters();

    [RelayCommand]
    private void ClearLogs()
    {
        _allLogs.Clear();
        FilteredLogs.Clear();
    }

    private void ApplyFilters()
    {
        FilteredLogs.Clear();
        foreach (var log in _allLogs)
        {
            if (MatchesFilter(log))
            {
                FilteredLogs.Add(log);
            }
        }
    }

    private bool MatchesFilter(LogEntry log)
    {
        if (SelectedLevelFilter.HasValue && log.Level != SelectedLevelFilter.Value)
            return false;

        if (!string.IsNullOrWhiteSpace(FilterText))
        {
            return log.Message.Contains(FilterText, StringComparison.OrdinalIgnoreCase) ||
                   log.Category.Contains(FilterText, StringComparison.OrdinalIgnoreCase);
        }

        return true;
    }
}
